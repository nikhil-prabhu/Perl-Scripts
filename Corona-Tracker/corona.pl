#!/usr/bin/env perl

#
# corona.pl
#
# A simple Perl script to extract and display
# statistics of the global Covid-19 situation.
#

use Modern::Perl;
use HTML::TableExtract;
use Text::Table;
use String::Util qw(trim);
use File::Tempdir;
use Getopt::Long;

my $tmp		= File::Tempdir->new();
my $tmpdir	= $tmp->name();		 # Temporary directory
my $tmpfile	= "$tmpdir/corona.html"; # Temporary file
my $url		= "https://coronatracker.com/analytics"; # Tracker URL
my $table	= HTML::TableExtract->new( headers =>
					   ["Country",
					    "Total Confirmed",
					    "Total Recovered",
					    "Total Deaths"] );
my $output	= Text::Table->new( \'| ',
				    "Country               ",
				    \' | ',
				    "Total Confirmed ",
				    \' | ',
				    "Total Recovered ",
				    \' | ',
				    "Total Deaths ",
				    \' |' );
my $output_rule = $output->rule(qw/- +/); # Table formatting rule
my %params;				  # Script parameters
my $results;			# Number of results to display

GetOptions( \%params, "top:s", "help");

# Custom number of results to display
if ( $params{ top } ) {
  $results = $params{ top };
}

# Help message
if ( $params{ help } ) {
  print <<EOF;
$0:	A simple Perl script to display statistics of the
		global Covid-19 situation.

USAGE: $0 [--top=n| --help]

	--top=n : Display only top 'n' results.
	--help	: Display this help message and exit.
EOF
  exit( 0 );
}

# Run headless Chrome instance and
# dump generated HTMl to tempfile.
system(
       "google-chrome --headless --disable-gpu --dump-dom $url > $tmpfile"
      );

$table->parse_file( $tmpfile ); # Parse dumped HTML

# Load table rows into output table
LOAD: for ( $table->tables() ) {
  for my $row ( $_->rows() ) {
    state $counter = 1;			# Loop counter
    $_ = trim( $_ ) for ( @$row );	# Trim additional whitespace
    $output->load( $row );
    last LOAD if $results and $counter++ == $results; # Quit if max number of results reached
  }
}

# Use UNIX 'more' utility as pager
open my $PAGER, "| more" or die "$!\n";

# Print table title
$PAGER->print( $output_rule . $output->title() . $output_rule );

# Print table body
for ( $output->body() ) {
  $PAGER->print( $_ . $output_rule );
}

unlink $tmpfile;		# Remove temporary file
unlink $tmpdir;			# Remove temporary directory
