#!C:/Perl/bin/perl -w 
use strict;

use IO::File;
use utf8;
use Encode;

my (%hathi, %hrights, %haccess);
my $outputfile = "overlap_analysis.txt";
my $hathi_files = shift(@ARGV);
my $alma_records = shift(@ARGV);
my $items = shift(@ARGV);
my %bib_file;

main();

#########
sub main 
#########
{
	hathi_oclc_numbers();
	alma();

	(%hathi, %hrights, %haccess)=();

	read_bib_analysis();
	get_and_merge_items();
}

#########
sub alma 
#########
{
	my $fh = IO::File->new($outputfile, 'w')
		or die "unable to open output file for writing: $!";
	binmode($fh, ':utf8');

	$/="\n\n";

	open (ALMA_RECORDS, $alma_records);
		while (<ALMA_RECORDS>) 
		{ 
			chomp;
			my $record = decode_utf8( $_ );
			my ($alma, $east, $country, $date_type, $date1, $date2, %oclc, $pages, $bcdigitized, $title)=();
						
			my $holcount=0;
			my $holdings="";
									
			#find specific fields
			my @record_parts = split(/\n/, $record);

			foreach my $record_part (@record_parts) 
			{
				if ($record_part =~ m/=001  (.*)/) 
				{
					$alma=$1;

				};
				
				if ($record_part =~ m/^=008  /) 
				{
					$date_type=substr($record_part, 12,1 );
					$date1=substr($record_part,13,4);
					$date2=substr($record_part,17,4);	
					$country=substr($record_part,21,3);	
							
				}

				if ($record_part =~ m/^\=019/) 
				{
					my $other_oclc=substr($record_part, 10);	
					my @other_oclcs = split/\$/,$other_oclc;

					foreach(@other_oclcs)
					{
						$_ =~ s/[^\d]//g;
						$_=~s/^0+//g; 
						$oclc{ $_ }=();
					}
				}

			if ($record_part =~ m/^\=035.{7}OCoLC.o/) 
			{
				my $n=substr($record_part, 19);
				$n =~ s/\D//g;
				$n =~s/^0+//g; 
				$oclc{ $n }=();
			}

	 		if ($record_part  =~ m/^=245.*\$a(.*)/)
 			{
				 $title=$1;
				 $title=~s/\$[a-z]/ /g;
				 $title=~s/\.$//;	
				 $title=substr($title, 0, 100); 
			}

			if ($record_part =~ m/^=300(.*)\$a(.*)\$b/) 
			{
				$pages = $2;
				$pages =~ s/ ;| ://;		
			}
			elsif ($record_part =~ m/^=300.*\$a(.*)\$c/) 
			{
				$pages = $1;
				$pages =~ s/ ;| ://;
			}
			elsif ($record_part =~ m/^=300.*\$a(.*)/) 
			{
				$pages = $1;
				$pages =~ s/ ;| ://;
			};

			if ($record_part =~ m/^=852/) 
			{	
				$record_part =~ m/\$b(.*)/;
				$holdings=$holdings.'|||'.$1;
				$holcount++;
			}

			if ($record_part =~ m/^=86/) 
			{	
				if($record_part =~ m/\$a(.*)/) {$holdings=$holdings.'|'.$1;}
			}

			if ($record_part =~ m/^=901.*\$a(.*)/) 
			{
				$bcdigitized = $1;			
			}

			if ($record_part =~ m/^=940/ && $record_part =~ m/EAST/i ) 
			{
				$east="Retain for East";
			}
        	}

#Write some data to a tab delimited file
			
			$fh->print("$alma\t");

			$fh->print("$holcount\t");

			if ($east) {$fh->print("$east\t")} 
			else {$fh->print("\t")};

			$holdings =~ s/\$[a-z 0-9]/ /g;
			$fh->print("$holdings\t");
			
			if ($country) {$fh->print("$country\t")}
			else {$fh->print("\t")};

			if ($date_type) {$fh->print("$date_type\t")}
			else {$fh->print("\t")};

			if ($date1) {$fh->print("$date1\t")}
			else {$fh->print("\t")};

			if ($date2) {$fh->print("$date2\t")}
			else {$fh->print("\t")};

			if (%oclc) 
				{
					while ( my $k = each %oclc ) 
					{
						$fh->print($k.";");
					}
				}
			$fh->print("\t");

			if ($pages) {$fh->print("$pages\t")}
			else {$fh->print("\t")};

			if ($bcdigitized) {$fh->print("$bcdigitized\t")}
			else {$fh->print("\t")};
		
		my $oclc_count=0;
		while ( my $k = each %oclc ) 
			{
    				if ($k && $hathi{$k}) 
				{
					$fh -> print("$hathi{$k}\t$hrights{$k}\t$haccess{$k}\t");
					$oclc_count=$oclc_count + 1;
					last;
				}
			}
		
		if ($oclc_count == 0){$fh->print("\t\t\t")}

		if ($title) {$fh->print("$title\t")}
		else {$fh->print("\t")};

		$fh->print("\n");
	}

close (ALMA_RECORDS);
$/="\n";
$fh->close();

};


####################
sub hathi_oclc_numbers
####################
{
	open (HATHI_FILE, $hathi_files);
	while (<HATHI_FILE>) 
	{ 
		my @hathi_row = split('\t');

		if ($hathi_row[7])
		{
			my @hathi_oclc_numbers = split(',', $hathi_row[7]);
			
			foreach (@hathi_oclc_numbers)
			{
      			$hathi{ $_ } = $hathi_row[3];
				if ($hrights {$_}){$hrights {$_} = $hrights {$_}.'; '.$hathi_row[2]}
				else {$hrights {$_} = $hathi_row[2]}

				if ($haccess {$_})
				{
					$haccess {$_} = $haccess {$_}.'; '.$hathi_row[1];
					if ($hathi_row[4])
					{
						$haccess {$_} = $haccess {$_}.' ('.$hathi_row[4].')';
					}
				}
				else 
				{	
					$haccess {$_} = $hathi_row[1];
					if ($hathi_row[4])
					{
						$haccess {$_} = $haccess {$_}.' ('.$hathi_row[4].')';
					}
				}
			}
		}
	}

close (HATHI_FILE);
}


#########
sub read_bib_analysis 
#########
{	
	open (OVERLAP_ANALYSIS, $outputfile);
	binmode(OVERLAP_ANALYSIS, ':utf8');

	while (<OVERLAP_ANALYSIS>) 
	{
		chomp;			
		my @line = split(/\t/, $_);
		$bib_file{$line[0]} = $_;
		
	}
	close (OVERLAP_ANALYSIS);
}

#######################
sub get_and_merge_items
#######################
{
	my $lc_sorted;
	my $fh = IO::File->new($outputfile, 'w')
		or die "unable to open output file for writing: $!";
	binmode($fh, ':utf8');

	$fh->print("MMSID\tHoldings Record Count\tEast Commitment\tAll Holdings\tCountry\tDate Type\tDate 1\tDate 2\tOCLC Numbers\tExtent\tBC Digitization Activity\tHT record #\tHT rights\tHT access\tTitle\tBarcode\tBib Material Type\tPermament Call Number\tSort Call Number\tPermament Physical Location\tLocal Location\tHolding Type\tItem Material Type\tChronology\tEnumeration\tIssue year\tDescription\tPublic note\tFulfillment note\tInteral note (1)\tInteral note (2)\tInteral note (3)\tStatus\tNumber of loans\tLast loan\n");

	open (ITEMS, $items);
	binmode(ITEMS, ':utf8');
	while (<ITEMS>) 
	{
		chomp;		
		my @line = split(/\t/, $_);
		foreach (@line) {$_ =~ s/^'|'$//g;}

		if($bib_file{$line[0]})
		{
			if($line[9]=~m/^[A-Z]/) {$lc_sorted = lc_sorter($line[9])}	
			else {$lc_sorted = "not LC"}
			
			my $line_slice = $line[3]."\t".$line[6]."\t".$line[9]."\t".$lc_sorted."\t".$line[10]."\t".$line[11]."\t".$line[12]."\t".$line[13]."\t".$line[16]."\t".$line[17]."\t".$line[18]."\t".$line[19]."\t".$line[20]."\t".$line[21]."\t".$line[37]."\t".$line[38]."\t".$line[39]."\t".$line[45]."\t".$line[48]."\t".$line[49]."\t";

			$fh->print($bib_file{$line[0]}.$line_slice."\n");
		};
	}

	$fh->close();
}

#########
sub lc_sorter 
#########
{
	my $call=shift;
	$call =~ m/([A-Z]*)\s{0,1}(\d*)(.*)/;
	my $class=$1;
	$class = sprintf("%-3s", $class);
	my $number = $2;
	if ($2 ne "") 
	{
		$number = sprintf("%04d", $number);
		return($class.$number.$3);
	}
	else {return("not LC")}

};



=pod

use: ht-bc-overlap.pl hathi_full_yyyymm01.txt records.mrk PHYSICAL_ITEM_ddddddddddddddddd.txt

hathi_full_yyyymm01.txt is a tab-delimited download of the most recent full Hathi File

records.mrk is a file of records downloaded from Alma and converted to .mrk for analysis

PHYSICAL_ITEM_ddddddddddddddddd.txt is an export of Alma physical items associated with the bibliographic records in the .mrk file.  It is exported from Alma as a csv file, opened, and resaved as tab delimited text

 
Outputs overlap_analysis.txt

betsy.post@bc.edu March 31, 2013; last revised February 2020


=cut

	



