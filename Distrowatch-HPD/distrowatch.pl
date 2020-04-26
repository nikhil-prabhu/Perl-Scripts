#!/usr/bin/env perl

#
# distrowatch.pl:
#
# A simple Perl script that retrieves a table containing
# the top 100 most popular Linux/UNIX based distributions
# of a particular year from distrowatch.com (based on page
# hit ranking).
#

use Modern::Perl;
use LWP::Simple;
use HTML::TableExtract;
use Text::Table;
use File::Tempdir;
use Getopt::Long;

my $dataspan = 1900 + (localtime)[5]; # Current year
my $results = 100;		      # Number of results to display
my $tmp = File::Tempdir->new();
my $tmpdir = $tmp->name;	# Temporary directory
my $tmpfile = "$tmpdir/distrowatch.html"; # Temporary file
my %params;				  # Script parameters

# Get command line parameters
GetOptions( \%params, "year:s", "top:s" );

if ($params{year}) {
  $dataspan = $params{year};	# Custom year
}

if ($params{top}) {
  $results = $params{top};
}

# Get distrowatch webpage and store it in a temporary file
mirror (
	"https://distrowatch.com/index.php?dataspan=$dataspan",
	"$tmpfile"
       );

# Page hit ranking table on Distrowatch
my $table = HTML::TableExtract->new( headers => [qw(Rank Distribution HPD*)] );
$table->parse_file($tmpfile);	# Parse html file and extract table

# Output table format
my $output = Text::Table->new(\'| ', "Rank ", \' | ', "Distribution ", \' | ', "HPD ", \' |');
my $output_rule = $output->rule(qw/- +/);

# Extract table rows and store it in output table
for ($table->tables) {
  for my $row ($_->rows) {
    $output->load($row);
    last if $results == $row->[0]; # Quit if max number of results reached
  }
}

# Use UNIX 'more' utility as pager
open (PAGER, "| more") or die "$!\n";

# Print output table
print PAGER $output_rule . $output->title . $output_rule; # Table header

for ($output->body) {
  print PAGER $_ . $output_rule;	# Table body
}

unlink $tmpfile;		# Remove temporary file
unlink $tmpdir;			# Remove temporary directory
