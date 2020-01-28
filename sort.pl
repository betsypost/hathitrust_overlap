#!C:/Perl/bin/perl -w 
use strict;

use Win32::OLE qw(in with);
use Win32::OLE::Const 'Microsoft Excel';
use IO::File;
use utf8;
use Encode;

my $outputfile = "sorted.txt";
my $unsorted = shift(@ARGV);

print "$unsorted\n";

my $fh = IO::File->new($outputfile, 'w')
	or die "unable to open output file for writing: $!";
binmode($fh, ':utf8');
sorter();

$fh->close();


#########
sub sorter 
#########
{

	open (UNSORTED, $unsorted);
		while (<UNSORTED>) 
		{ 

			chomp;
			my $call=$_;
			$call =~ m/(\d*)\s*([A-Z]*)(\d*)(.*)/;
			my $line=$1;	
			print "$line\n";
			my $class=$2;

			$class = sprintf("%-3s", $class);
			my $number = $3; 
			$number = sprintf("%04d", $number);
			print "$line  plus $class plus $number\n";


			$fh->print($line."\t".$class.$number.$4."\n");







		}

};




=pod

use: sort.pl call_nos.txt

call_nos.txt is a text file of LC call numbers


outputs sorted.txt

betsy.post@bc.edu March 31, 2013


=cut

	



