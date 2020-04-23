#!/usr/bin/env perl

#
# distrowatch.pl:
#
# A simple Perl script that retrieves a table containing
# the top 100 most popular Linux/UNIX based distributions
# of a particular year (based on page hit ranking).
#

use Modern::Perl;
use LWP::Simple;
use HTML::TableExtract;
use Text::Table;
use File::Tempdir;

my $dataspan = 1900 + (localtime)[5]; # Current year
my $tmp = File::Tempdir->new();
my $tmpdir = $tmp->name;	# Temporary directory
my $tmpfile = "$tmpdir/distrowatch.html"; # Temporary file

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
  }
}

# Print output table
print $output_rule . $output->title . $output_rule; # Table header

for ($output->body) {
  print $_ . $output_rule;	# Table body
}

unlink $tmpfile;		# Remove temporary file
unlink $tmpdir;			# Remove temporary directory
