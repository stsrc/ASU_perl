#!/usr/bin/perl

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc qw(:all);
use Switch;

format cal_entry_tex =
\noindent @####.@##.@##. @* @* @* @*
$year, $month, $day, $day_of_w_txt, $nl_before_notes, $notes, $newline
.

format cal_entry_txt =
--------------------------------------------------------------------------------
@####.@##.@##. @* @*
$year, $month, $day, $day_of_w_txt, $notes
.

sub read_file {
	my @file_arr;

	open(my $fh, "<", $_[0])
		or die "file open failed.\n";

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

	my($parsed_date, $parsed_note) = split(/ /, $line, 2);
	@parsed = split(/\./, $parsed_date);

	return (@parsed[0], @parsed[1], @parsed[2], $parsed_note);
}

sub print_args_info {
	print "\nWrong input arguments.\n";
	print "Use one of specific arguments pair:\n";
	print "\"-d [count]\" for number of days to print.\n";
	print "\"-w [count]\" for number of weeks to print.\n";
	print "\"-m [count]\" for number of months to print.\n";
	print "\nAdditionally:\n \"-p [path]\" to write path to the notes file\n";
	print "\"-s [path]\" to save file to specific file\"\n\n";
}

sub parse_input_args {
	my $type = 0;
	my $arg_val = 0;
	my $days = 0;
	my $notes_path = "notes.txt";
	my $cnt = scalar @ARGV;
	my $i = 0;
	my $save_path;

	if ($cnt == 0) {
		print_args_info();
		exit(1);
	}

	while ($i != $cnt) {

		$type = @ARGV[$i];
		$arg_val = @ARGV[$i + 1];

		$i += 2;
		switch($type) {
			case /-d/ {
				$days = $arg_val; #TODO Value test
			}
			case /-w/ {
				$days = $arg_val * 7; #TODO Value test
			}
			case /-m/ {
				my $tmp = 0;
				my $year = 0;
				my $month = 0;
				my $day = 0;
				($year, $month, $day) = Today();
				$tmp += Days_in_Month($year, $month) - $day + 1;
				$month++;
				for (my $j = 0; $j < $arg_val - 1; $j++) {
					if ($month == 13) {
						$month = 1;
						$year++;
					}	
					$tmp += Days_in_Month($year, $month);
					$month++;
				}
				$days = $tmp;
			}

			case /-p/ {
				$notes_path = $arg_vail;
			}
			
			case /-s/ {
				$save_path = $arg_val;
			}

			else {
				print_args_info();
				break;
			}
		}
	}
	if (length ($save_path) == 0) {
		$save_path = "calendar.tex";
	}
	return ($days, $notes_path, $save_path);
}

select(STDOUT);
$~ = "cal_entry_tex";



($loop_size, $file_path, $save_path) = parse_input_args();

open(cal_entry_tex, ">", $save_path);

@file_arr = read_file($file_path);

$arr_cnt = 0;
($year_f, $month_f, $day_f, $notes_f) = parse_data(@file_arr[$arr_cnt]);
$arr_cnt++;

$calendar = Date::Calendar->new($Profiles->{'US-FL'});

($year, $month, $day) = Today();

$date_year = $calendar->year($year);
$index = $calendar->date2index($year, $month, $day);

print cal_entry_tex "\\documentclass[12pt, a4paper, oneside]{article}";
print cal_entry_tex "\\title{Calendar}";
print cal_entry_tex "\\author{Konrad Gotfryd}";
print cal_entry_tex "\\begin{document}";
print cal_entry_tex "\\maketitle";

for (my $i = 0; $i < $loop_size; $i++) {
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

	if (length($notes) != 0) {
		$nl_before_notes = "\\par";	
	} else {
		$nl_before_notes = "";
	}

	if ($i + 1 != $loop_size) {
		$newline = "\\\\";
	} else {
		$newline = "";
	}
	write(cal_entry_tex);

	$index++;
	if ($month == 12 && $day == 31) {
		$date_year = $calendar->year($year + 1);
		$index = 0;
	}
}

print cal_entry_tex "\\end{document}";
close(cal_entry_tex);
