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
my $a = '*';
my @append = ();
my $A = '*';
my @Append = ();
my $A = '*';
my $q = '"';
my $Q = '"';
my $inner_join = 1;
my $print_heading = 1;
my @heading = ();
my @Heading = ();
my $verbose = 0;

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
	print "Syntax: $0 file1 file2 <OPTIONS>\n";
	print qq"OPTIONS:
	-t<separator char for first file (default: tab)>
	-T<separator char for second file (default: tab)> 
	-n <field sequency number to join from first file> (default: 1)
	-N <field sequency number to join from second file> (default: 1)
	-a <1,2,3,4,5 OR 1-5 OR 1-3,4,5 (default: all columns)> 
	-A <1,2,3,4,5 OR 1-5 OR 1-3,4,5 (default: all columns)> 
	-q <quote character for a field (default: \")>  # PENDING
	-Q <quote character for a field (default: \")>  # PENDING
	-v <verbose output? 0/1> (default: 0)  # PENDING
	-o <output file name> (default: STDOUT)  # PENDING
	-i <inner join? 0/1> (default: 1)
	-H <print heading (first line)? 0/1 (default: 1)> # PENDING

	* TODO: -a and -A options just ask the column numbers and not the ordering. Replace it with a better option
"
}

sub verbose
{
	my $msg = shift;
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
		if($_ eq '-a')
		{
			$a = shift;
			@append = split(',', $a);
			for(my $i=0;$i<=$#append;$i++)
			{
				if($append[$i] =~ /^\d+$/)
				{
					;
				}
				elsif($append[$i] =~ /^(\d+)-(\d+)$/)
				{
					my @vals = ($1..$2);
					splice(@append, $i, 0, @vals);
				}
				else
				{
					die "Allowed values for -a are: 1,2,3,4,5 OR 1,2-4,5 OR 1-5";
				}
			}
		}
		if($_ eq '-A')
		{
			$A = shift;
			@Append = split(',', $A);
			for(my $i=0;$i<=$#Append;$i++)
			{
				if($Append[$i] =~ /^\d+$/)
				{
					;
				}
				elsif($Append[$i] =~ /^(\d+)-(\d+)$/)
				{
					my @vals = ($1..$2);
					splice(@Append, $i, 0, @vals);
				}
				else
				{
					die "Allowed values for -A are: 1,2,3,4,5 OR 1,2-4,5 OR 1-5";
				}
			}
			@Append = map {$_ - 1} @Append;
		}
		if($_ eq '-i')
		{
			$inner_join = shift;
		}
		if($_ eq '-v')
		{
			$verbose = (shift + 0)?1:0;
		}
	}
	# return error if two file nameas are not passed
}

# check smaller file first
sub check_smaller_file
{
	my ($f1, $f2) = @_;
	# add logic to find file size and return smaller file
	# currently returning first file blindly
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

		print("@Heading");
		print("$T");
		if(scalar(@Append))
		{
			print("@heading[@Append]");
		}
		else
		{
			print("@heading");
		}
		print($/);
	}
	while(<FH>)
	{
		chomp;
		# mentioned third argument here to avoid trimming of trailing whitespaces
		my @f = split($T, $_, -1);
		# handle here if tab character is inside quote string field value should include that
		#

		if($key_based_data->{$f[$N-1]})
		{
			print("@f");
			print("$T");
			if(scalar(@Append))
			{
				print("@{$key_based_data->{$f[$N-1]}}[@Append]");
			}
			else
			{
				print("@{$key_based_data->{$f[$N-1]}}");
			}
			print($/);
		}
		else
		{
			print("@f$/") unless($inner_join);
		}
	}
}
