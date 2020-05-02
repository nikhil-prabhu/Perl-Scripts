#!/usr/bin/env perl

#
# corona.pl
#
# A simple Perl script to extract and display
# statistics of the global Covid-19 situation.
#

# Modules

use Modern::Perl;
use LWP::Simple;
use Text::Table;
use Number::Format;
use Getopt::Long;
use JSON qw(decode_json);

# Subroutine declarations

sub total_stats();		# Display total statistics
sub daily_stats();		# Display daily statistics

# Variables

my $uri		= 'https://api.coronatracker.com/v3/stats/worldometer/topCountry'; # API key
my $response	= get( $uri );		    # Response from URI
my $data	= decode_json( $response ); # Parsed JSON data
my %params;				    # Script parameters

# Get script parameters
GetOptions(
	   \%params,
	   "daily",
	   "country:s",
	   "top:s",
	   "reverse",
	   "less",
	   "help"
	  );

# Use pager to print results
my $PAGER;
if ( $params{ less } ) {
  open $PAGER, "| less" or die "$!\n";
} else {
  open $PAGER, "| more" or die "$!\n";
}

if ( $params{ help } ) {
  print <<EOF;

$0:	A simple Perl script to display total or daily
		statistics of the global Covid-19 situation.

USAGE: $0 [--help| --country=cc| --top=n| --daily]

	--help		: Print this help message and exit.
	--country=cc	: Display stats for country specifed by code 'cc'.
	--top=n		: Only display top 'n' countries.
	--daily		: Display daily stats and active cases.
	--reverse	: Display stats in reverse (ascending) order.
	--less		: Use 'less' as the pager instead of 'more'.

EOF
  exit( 0 );
} else {
  if ( $params{ reverse } ) {
    @$data = reverse @$data;	# Reverse order of data
  }

  if ( $params{ daily } ) {
    daily_stats();
  } else {
    total_stats();
  }
}

# Subroutine definitions

sub total_stats() {
  # Displays total statistics

  my $countryCode;
  my $countryName;
  my $totalConfirmed;
  my $totalRecovered;
  my $totalDeaths;
  my $row;
  my $num_format = Number::Format->new( -thousands_sep => ',' );
  state $counter = 1;

  # Define output table header format
  my $table = Text::Table->new(
			       \'| ',
			       "Code",
			       \' | ',
			       "Country        ",
			       \' | ',
			       "Total Confirmed ",
			       \' | ',
			       "Total Recovered ",
			       \' | ',
			       "Total Deaths ",
			       \' |'
			      );
  my $table_rule = $table->rule( qw/- +/ ); # Output table formatting rule

  # Assign extracted data to variables
  for ( @$data ) {
    $countryCode	= $_->{ countryCode };
    $countryName	= $_->{ country };
    $totalConfirmed	= $_->{ totalConfirmed };
    $totalRecovered	= $_->{ totalRecovered };
    $totalDeaths	= $_->{ totalDeaths };

    # Encode country names into utf8
    utf8::encode( $countryName );

    # Truncate country name
    if ( length( $countryName ) > 12 ) {
      $countryName = substr( $countryName, 0, 11 ) . "...";
    }

    # Null country code
    unless ( $countryCode ) {
      $countryCode = "-";
    }

    # Format numeric data
    $totalConfirmed	= $num_format->format_number( $totalConfirmed );
    $totalRecovered	= $num_format->format_number( $totalRecovered );
    $totalDeaths	= $num_format->format_number( $totalDeaths );

    # Define a table row
    $row = [
	    $countryCode,
	    $countryName,
	    $totalConfirmed,
	    $totalRecovered,
	    $totalDeaths
	   ];

    # Load rows into output table
    if ( $params{ country }) {
      if ( $countryCode =~ /$params{ country }/i ) {
	$table->load( $row );
	last;
      }
    } else {
      $table->load( $row );
    }

    # Quit if max results reached
    last if $params{ top } and $counter++ == $params{ top };
  }

  # Print table header
  $PAGER->print( $table_rule . $table->title() . $table_rule );

  # Print table body
  for ($table->body()) {
    $PAGER->print( $_ . $table_rule );
  }
}

sub daily_stats() {
  # Displays daily statistics

  my $countryCode;
  my $countryName;
  my $dailyConfirmed;
  my $dailyDeaths;
  my $activeCases;
  my $row;
  my $num_format = Number::Format->new( -thousands_sep => ',' );
  state $counter = 1;

  # Define output table header format
  my $table = Text::Table->new(
			       \'| ',
			       "Code",
			       \' | ',
			       "Country        ",
			       \' | ',
			       "Daily Confirmed ",
			       \' | ',
			       "Daily Deaths ",
			       \' | ',
			       "Active Cases ",
			       \' |'
			      );
  my $table_rule = $table->rule( qw/- +/ ); # Output table formatting rule

  # Assign extracted data to variables
  for ( @$data ) {
    $countryCode	= $_->{ countryCode };
    $countryName	= $_->{ country };
    $dailyConfirmed	= $_->{ dailyConfirmed };
    $dailyDeaths	= $_->{ dailyDeaths };
    $activeCases	= $_->{ activeCases };

    # Encode country names into utf8
    utf8::encode( $countryName );

    # Truncate country name
    if ( length( $countryName ) > 12 ) {
      $countryName = substr( $countryName, 0, 11 ) . "...";
    }

    # Null country code
    unless ( $countryCode ) {
      $countryCode = "-";
    }

    # Format numeric data
    $dailyConfirmed	= $num_format->format_number( $dailyConfirmed );
    $dailyDeaths	= $num_format->format_number( $dailyDeaths );
    $activeCases	= $num_format->format_number( $activeCases );

    # Define a table row
    $row = [
	    $countryCode,
	    $countryName,
	    $dailyConfirmed,
	    $dailyDeaths,
	    $activeCases
	   ];

    # Load rows into output table
    if ( $params{ country }) {
      if ( $countryCode =~ /$params{ country }/i ) {
	$table->load( $row );
	last;
      }
    } else {
      $table->load( $row );
    }

    # Quit if max results reached
    last if $params{ top } and $counter++ == $params{ top };
  }

  # Print table header
  $PAGER->print( $table_rule . $table->title() . $table_rule );

  # Print table body
  for ($table->body()) {
    $PAGER->print( $_ . $table_rule );
  }
}
