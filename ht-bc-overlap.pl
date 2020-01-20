#!C:/Perl/bin/perl -w 
use strict;

use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';
use IO::File;
use utf8;
use Encode;
use Cwd;

my %hathi;
my %hrights;
my %haccess;
my $outputfile = "overlap_analysis.txt";
my $hathi_files = shift(@ARGV);
my $alma_records = shift(@ARGV);

my $fh = IO::File->new($outputfile, 'w')
	or die "unable to open output file for writing: $!";
binmode($fh, ':utf8');

hathi_oclc_numbers();

alma();

$fh->close();


#########
sub alma 
#########
{
	$/="\n\n";

	open (ALMA_RECORDS, $alma_records);
		while (<ALMA_RECORDS>) 
		{ 
			chomp;
			my $record = decode_utf8( $_ );
			my ($alma, $status, $call_no, $country, $date_type, $date1, $date2, %oclc, $pages, $bcdigitized, $title)=();
						
			my $holcount=0;
			my $otherhol="";
									
			#find specific fields, change them here or in subroutine
			my @record_parts = split(/\n/, $record);

			foreach my $record_part (@record_parts) 
			{
				if ($record_part =~ m/=001  (.*)/) {$alma=$1};
				
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
						$_ =~ s/^\s+|\s+$//g;
						$_ =~ s/[^\d]//g;
						$_=~s/^0+//g; 
						$oclc{ $_ }=();
					}
				}

			if ($record_part =~ m/^\=035.{7}OCoLC.o/) 
			{
					my $n=substr($record_part, 19);

				

						$n =~ s/\D//g;
						$n =~ s/^\s+|\s+$//g;
						$n =~s/^0+//g; 
						$oclc{ $n }=();


			}

	 		if ($record_part  =~ m/^=245.*\$a(.*)/)
 				{$title=$1;
				 $title=~s/\$[a-z]/ /g;
				 $title=~s/\.$//;	
				 $title=substr($title, 0, 100); }


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
		
			
#=852  0\$83942808840001021$bTML$cSTACK$hBR350.E7 P320

			if ($record_part =~ m/^=852/) 
			{

				if (($record_part =~ m/ONL\$cSTACK_NL/) or ($record_part =~ m/ONL\$cSTACK/) or ($record_part =~ m/ONL\$cOVER/) or ($record_part =~ m/ONL\$cOVER_NL/) or ($record_part =~ m/ONL\$cREF_NL/) or ($record_part =~ m/ONL\$cRFDSK/))
					{
						$record_part =~ m/\$b(.*)/;
						$call_no=$1;
					}

				else

					{
						$record_part =~ m/\$b(.*)/;
						$otherhol=$otherhol.'|'.$1;

					} 
				$holcount++;

			}

			if ($record_part =~ m/^=901.*\$a(.*)/) 
			{
				$bcdigitized = $1;			
			}

			if ($record_part =~ m/^=940/ && $record_part =~ m/EAST/i ) 
			{
				$status="Retain for East";
			}
			

        	}




#Write some data to a tab delimited file
			
			$fh->print("$alma\t");

			$fh->print("$holcount\t");

			if ($status) {$fh->print("$status\t")} 
			else {$fh->print("\t")};
		
			if ($call_no) {$fh->print("$call_no\t")} 
			else {$fh->print("\t")};

			if ($otherhol) {$fh->print("$otherhol\t")} 
			else {$fh->print("\t")};
			
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
				}


			}
		
		if ($oclc_count == 0){$fh->print("\t\t\t")}

			if ($title) {$fh->print("$title\t")}
			else {$fh->print("\t")};
			

		
			$fh->print("\n");
	}
};



####################
sub hathi_oclc_numbers
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
				$hrights {$_} = $hathi_row[2];
				$haccess {$_} = $hathi_row[1];
			}
		}
#		if ($hathi_row[10]) {$hathi_row[10] =~ s/ //g; print "$hathi_row[10]\n"};
	}

#  while ( my ($key, $value) = each(%hathi) ) {print "$key => $value\n";}

close (HATHI_FILE);
}

=pod

use: temp.pl hathi_full_20140301.txt records.mrk

hathi_full_20140301.txt is a tab-delimited download of the most recent full Hathi File

records.mrk is a file of records downloaded from ALMA and converted to .mrk for analysis

 
Outputs overlap_analysis.txt

betsy.post@bc.edu March 31, 2013


=cut

	



