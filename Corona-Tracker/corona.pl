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

# Run headless Chrome instance and
# dump generated HTMl to tempfile.
system(
       "google-chrome --headless --disable-gpu --dump-dom $url > $tmpfile"
      );

$table->parse_file( $tmpfile );		# Parse dumped HTML

# Load table rows into output table
for ( $table->tables() ) {
  for my $row ( $_->rows() ) {
    $_ = trim( $_ ) for ( @$row ); # Trim additional whitespace
    $output->load( $row );
  }
}

# Print table title
print $output_rule . $output->title() . $output_rule;

# Print table body
for ( $output->body() ) {
  print $_ . $output_rule;
}

unlink $tmpfile;		# Remove temporary file
unlink $tmpdir;			# Remove temporary directory
