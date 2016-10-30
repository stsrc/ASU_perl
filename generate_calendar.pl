#!/usr/bin/perl

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc qw(:all);
use Scalar::Util qw(openhandle);
use Switch;

format cal_entry_tex =
\noindent @*.@*.@*. @* @* @* @*
$year, ${month}, ${day}, $day_of_w_txt, $nl_before_notes, $notes, $nl_after_notes
.

format cal_entry_txt =
@*
$dash_line
@*.@*.@*. @* @* @*
$year, ${month}, ${day}, $day_of_w_txt, $nl_before_notes, $notes
.

$dash_line = "--------------------------------------------------------------------------------";

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
	print "\nUse one of specific argument:\n";
	print "\"-d [count]\" count of days to print.\n";
	print "\"-w [count]\" count of weeks to print.\n";
	print "\"-m [count]\" count of months to print.\n";
	print "\nAdditional arguments:\n";
	print "\"-p [path]\" path to file with notes. If parameter not passed";
	print " path defaults to notes.txt.\n";
	print "\"-s [path]\" path to save output.\n";
	print "\"-t [txt/tex]\" output type. txt is the default type.\n\n";
}

sub print_warn_args_info {
	print "\nWrong input arguments.\n";
	print_args_info();
}


sub parse_input_args {
	my $type = 0;
	my $arg_val = 0;
	my $days = 0;
	my $notes_path = "notes.txt";
	my $cnt = scalar @ARGV;
	my $i = 0;
	my $save_path;
	my $form_type = "cal_entry_txt";

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
				$notes_path = $arg_val;
			}
			
			case /-s/ {
				$save_path = $arg_val;
			}
			
			case /-t/ {
				if ($arg_val eq "txt") {
					$form_type = "cal_entry_txt";
				} elsif ($arg_val eq "tex") {
					$form_type = "cal_entry_tex";
				} else {
					print_warn_args_info();
					exit(1);
				}
			}
			case /-h.*/ {
				print_args_info();
				exit(1);
			}

			else {
				print_warn_args_info();
				exit(1);
			}
		}
	}
	return ($days, $notes_path, $save_path, $form_type);
}

sub write_header {
	my $type = $_[0];
	my $fh = $_[1];

	if ($type eq "cal_entry_tex") {
		print $fh "\\documentclass[12pt, a4paper, oneside]{article}";
		print $fh "\\title{Calendar}";
		print $fh "\\author{Konrad Gotfryd}";
		print $fh "\\begin{document}";
		print $fh "\\maketitle"; 
	} else {
		print $fh "\nCalendar\nAuthor: Konrad Gotfryd\n\n";
	}
}

sub write_footer {
	my $type = $_[0];
	my $fh = $_[1];

	if ($type eq "cal_entry_tex") {
		print save_file "\\end{document}";
	} else {
		print save_file "$dash_line\n";
	}
}

sub set_nl_before_notes {
	my $type = $_[0];
	my $notes = $_[1];
	my $nl_before_notes;

	if (length($notes) != 0) {
		if ($type eq "cal_entry_tex") {
			$nl_before_notes = "\\par";
		} else {
			$nl_before_notes = "\n     ";
		}
	} else {
		$nl_before_notes = "";
	}
	return $nl_before_notes;	
}

sub set_nl_after_notes {
	my $i = $_[0];
	my $loop_size = $_[1];
	my $type = $_[2];
	
	if ($type eq "cal_entry_txt") {
		return "";
	}

	if ($i + 1 != $loop_size) {
		return "\\\\";
	} else {
		return "";
	}
}

($loop_size, $file_path, $save_path, $type) = parse_input_args();

open(save_file, ">", $save_path);
unless (save_file) {
	if (length $save_path != 0) {
		print "Could not open file $save_path. Writing output";
		print " to the console.\n";
	}
	*save_file = STDOUT;
}

select(save_file);

$~ = $type;
@file_arr = read_file($file_path);

write_header($type, save_file);

$arr_cnt = 0;
($year_f, $month_f, $day_f, $notes_f) = parse_data(@file_arr[$arr_cnt]);
$arr_cnt++;

#There is no PL-MA in profiles.
$calendar = Date::Calendar->new($Profiles->{'US-FL'});

($year, $month, $day) = Today();

$date_year = $calendar->year($year);
$index = $calendar->date2index($year, $month, $day);


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

	$nl_before_notes = set_nl_before_notes($type, $notes);
	$nl_after_notes = set_nl_after_notes($i, $loop_size, $type);

	$day = sprintf("%02d", $day);
	$month = sprintf("%02d", $month);

	write;

	$index++;
	if ($month == 12 && $day == 31) {
		$date_year = $calendar->year($year + 1);
		$index = 0;
	}
}

write_footer($type, save_file);

close(save_file);

