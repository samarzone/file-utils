#!/usr/bin/perl

use strict;
use Data::Dumper;
$|=1;

my $f = '';
my $F = '';
my $t = "\t";
my $T = "\t";
my $n = 1;
my $N = 1;
my @seq;
my $q = '"';
my $Q = '"';
my $join = 'inner';
my $print_heading = 1;
my @heading = ();
my @Heading = ();
my $verbose = 0;
my $debug = 1;

if($ARGV[0] eq '-h' or $ARGV[0] eq '-H' or $ARGV[0] eq '--help' or $ARGV[0] eq '-help')
{
	show_help();
	exit(0);
}

read_options(@ARGV);

my $mem_file = check_smaller_file($f, $F);

my $key_based_data = read_file($mem_file, $t, $n);
print_joined_data($key_based_data, $F, $T, $N);

sub show_help
{
	print "Syntax: $0 file1 FILE2 <OPTIONS>\n";
	print qq"OPTIONS:
	-t<separator char for first file (default: tab)>
	-T<separator char for second file (default: tab)> 
	-n <field sequency number to join from first file> (default: 1)
	-N <field sequency number to join from second file> (default: 1)
	-a <1,2,3,4,5 OR 1-5 OR 1-3,4,5 (default: all columns)> 
	-A <1,2,3,4,5 OR 1-5 OR 1-3,4,5 (default: all columns)> 
	-q <quote character for a field (default: \")>  # PENDING
	-Q <quote character for a field (default: \")>  # PENDING

	-seq <sequence of columns from both files in output, example: f1,F3,f2,F4-5,f3,5 (default f*,F*)
	-v <verbose output? 0/1> (default: 0)  # PENDING
	-o <output file name> (default: STDOUT)  # PENDING
	-j <type of join> <inner,right> (default: inner)
	-H <print heading (first line)? 0/1 (default: 1)> # PENDING

	* TODO: -a and -A options just ask the column numbers and not the ordering. Replace it with a better option
	* TODO: currently smaller size file becomes key-based-data file and output is ordered by the data present in the larger file. if size is same for both files first file becomes key-based-data file
	* TODO: Logging level to be according to log level
	* TODO: common key (-n, -N) can be represented as column name also
"
}

sub log
{
	my $msg = shift;
	my $level = shift;
	if($verbose)
	{
		print $msg."\n";
	}
}

sub read_options
{
	$f = shift;
	$F = shift;
	while($_ = shift)
	{
		if($_ eq '-n')
		{
			$n = 0 + shift;
			die "n <field sequency number for first file> starts from 1 and hence only a positive integer value is allowed" if($n < 1);
		}
		if($_ eq '-N')
		{
			$N = 0 + shift;
			die "N <field sequency number for second file> starts from 1 and hence only a positive integer value is allowed" if($N < 1);
		}
		# args => array
		# f1F2 => ['f1', 'F2']
		# f1,3,F2-4 => ['f1','f3','F2','F3','F4']
		# f1,f3,F2-4 => ['f1','f3','F2','F3','F4']
		# f1,F2,f3,F4 => ['f1','F2','f3','F4']
		if($_ eq '-seq')
		{
			my $seq = shift;
			if($seq !~ /^f[0-9,*f-]+$/i)
			{
				die "Value of sequence is not appropriate. Please see help ($0 -h)";
			}
			# check for comma separated values of columns
			my @sequence = split(',', $seq);
			my $file = '';
			for(my $i=0;$i<=$#sequence;$i++)
			{
				# check file (f OR F)
				if($sequence[$i] =~ s/^(f|F)//)
				{
					$file = $1;
				}
				if($sequence[$i] =~ /^\d+$/)
				{
					push @seq, $file.$sequence[$i];
				}
				elsif($sequence[$i] =~ /^(\d+)-(\d+)$/)
				{
					my @vals = ($1..$2);
					push @seq, map {$file.$_} @vals;
				}
				else
				{
					die "Allowed values for -seq are: 1,2,3,4,5 OR 1,2-4,5 OR 1-5";
				}
			}
		}
		if($_ eq '-j')
		{
			$join = lc shift;
		}
		if($_ eq '-v')
		{
			$verbose = shift;
			$verbose = ($verbose)?1:0;
		}
	}
	# return error if two file nameas are not passed
}

# check smaller file first
sub check_smaller_file
{
	my ($f1, $f2) = @_;

	# following code is commented because in case $f2 is returned, the calling of print_joined_data need to be corrected
	# TODO: leaving above item for later.
	# TODO: left right join handling will also be required if we are chosing key_based_data file according to size and not according to left or right position
	# if(-s $f1 > -s $f2)
	# {
	# 	return $f2;
	# }
	return $f1;
}

# read smaller file into memory completely
# 	create a hash
# 	{
# 		key1 => [row1_col1, row1_col2, ..., row1_coln, ...]
# 		key2 => [row2_col1, row2_col2, ..., row2_coln, ...]
# 		...
# 		keyn => [rown_col1, rown_col2, ..., rown_coln, ...]
# 		...
# 	}
sub read_file
{
	my $file = shift;
	my $t = shift;
	my $n = shift;
	my $h = {};
	open(FH, $file) or die "Couldn't open file $file";
	if($print_heading)
	{
		my $line = <FH>;
		chomp($line);
		@heading = split($t, $line, -1);
	}
	while(<FH>)
	{
		chomp;
		# mentioned third argument here to avoid trimming of trailing whitespaces
		my @f = split($t, $_, -1);
		# handle here if tab character is inside quote string field value should include that
		#

		$h->{$f[$n-1]} = \@f;
	}
	return $h;
}

# loop over lines of larger file append relevant required columns each line
sub print_joined_data
{
	my ($key_based_data, $F, $T, $N) = @_;
	open(FH, $F) or die "Couldn't open file $F";

	$" = $T;

	if($print_heading)
	{
		my $line = <FH>;
		chomp($line);
		@Heading = split($T, $line, -1);

		my @hseq = ();
		for(@seq)
		{
			my $file;
			my $index;
		       	if(/^(f|F)([1-9]\d*)$/)
			{
				$file = $1;
				$index = $2 - 1;
			}
			else
			{
				die "Wrong sequence value $_\n";
			}
			if($file eq 'f')
			{
				push @hseq, $heading[$index];
			}
			else
			{
				push @hseq, $Heading[$index];
			}
		}
		print("@hseq");
		print($/);
	}
	# print Dumper($key_based_data);
	while(<FH>)
	{
		chomp;
		# print "===========================================\n";
		# mentioned third argument here to avoid trimming of trailing whitespaces
		my @fields = split($T, $_, -1);
		# print "fields:@fields:\n";
		# handle here if tab character is inside quote string field value should include that
		#

		my $can_join = '';
		# if common id exists
		if($key_based_data->{$fields[$N-1]})
		{
			$can_join = 'left inner right';
		}
		else
		{
			$can_join = 'right';
		}
		# print "seq:@seq:\n";
		my @dseq = ();
		for(@seq)
		{
			# print "seq:$_:\n";
			my $file;
			my $index;
			if(/^(f|F)([1-9]\d*)$/)
			{
				$file = $1;
				$index = $2 - 1;
			}
			else
			{
				die "Wrong sequence value $_\n";
			}

			if($file eq 'f')
			{
				# print "pushing:$key_based_data->{$fields[$N-1]}->[$index]:\n";
				push @dseq, ($key_based_data->{$fields[$N-1]}->[$index] || '');
			}
			else
			{
				# print "pushing:$fields[$index]:\n";
				push @dseq, $fields[$index];
			}
		}
		# print "can_join:$can_join:, join:$join\n";
		if($can_join =~ /\b$join\b/)
		{
			print("@dseq");
			print($/);
		}
	}
}
