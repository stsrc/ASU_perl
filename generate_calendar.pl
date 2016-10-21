#!/usr/bin/perl



use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc qw(:all);

format cal_entry =
@####.@##.@##. @*
$year, $month, $day, $day_of_w_txt
     @*
$notes
.

select(STDOUT);
$~ = "cal_entry";


@file_arr;
$arr_cnt = 0;

sub read_file {
	my @file_arr;

	open(my $fh, "<", "notes.txt")
		or die "open notes.txt failed.\n";

	while(<$fh>) {
		chomp;
		push @file_arr, $_;
	}

	close $fh;
	return @file_arr;
}

sub parse_data {
	my @parsed;
	my $line = $_[0];

	@parsed = split(/\./, $line);

	return (@parsed[0], @parsed[1], @parsed[2], @parsed[3]);
}


@file_arr = read_file();

($year_f, $month_f, $day_f, $notes_f) = parse_data(@file_arr[$arr_cnt]);
$arr_cnt++;

$calendar = Date::Calendar->new($Profiles->{'US-FL'});
$date_year = $calendar->year( 2016 );
$index = $calendar->date2index(2016, 11, 10);

for (my $i = 0; $i < 14; $i++) {
	$date = $date_year->index2date($index);

	$year = $date->year;
	$month = $date->month;
	$day = $date->day;

	$day_of_w = Day_of_Week($year, $month, $day);
	$day_of_w_txt = Day_of_Week_to_Text($day_of_w);
	$notes = "";
	
	if ($day == $day_f && $month == $month_f && $year == $year_f) {
		$notes = $notes_f;
		($year_f, $month_f, $day_f, $notes_f) = parse_data(@file_arr[$arr_cnt]);	
		$arr_cnt++;	
	}
	
	write;

	$index++;
	if ($month == 12 && $day == 31) {
		$date_year = $calendar->year($year + 1);
		$index = 0;
	}
}

#output jaki chce:
#------------------
#01.01.01 monday
#--notes--
#------------------
