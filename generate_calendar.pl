#!/usr/bin/perl

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc qw(:all);
use Scalar::Util qw(openhandle);
use Switch;

use warnings;

format cal_entry_tex =
@*.@*.@*. & @* & @* \\ \hline 
$year, ${month}, ${day}, $day_of_w_txt, $notes
.

format cal_entry_txt =
@*
$dash_line
@*.@*.@*. @* @*
$year, ${month}, ${day}, $day_of_w_txt, $notes
.

$dash_line = "--------------------------------------------------------------------------------";
%translate_day = ('Monday', 'Poniedziałek', 'Tuesday', 'Wtorek', 'Wednesday', 'Środa', 
		  'Thursday', 'Czwartek', 'Friday', 'Piątek', 'Saturday', 'Sobota',
		  'Sunday', 'Niedziela');

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
	my @parsed = [];
	my $line = $_[0];

	my($parsed_date, $parsed_note) = split(/ /, $line, 2);
	@parsed = split(/\./, $parsed_date);

	return ($parsed[0], $parsed[1], $parsed[2], $parsed_note);
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
	print "\"-t [txt/tex]\" output type. txt is the default type.\n";
	print "\"-a [yyyy.mm.dd]\" sets date from which calendar should start.";
	print " If argument not passed, calendar starts from today.\n";
	print "\"-pl: calendar in polish language.\n\n";
}

sub print_warn_args_info {
	print "\nWrong input arguments.\n";
	print_args_info();
}

sub calculate_days {
	my $tmp = 0;
	my $year = $_[0];
	my $month = $_[1];
	my $day = $_[2];
	my $arg_val = $_[3];
	if ($year == 0 && $month == 0 && $day == 0) {

	}

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
	return $tmp;
}

sub parse_input_args {
	my $type = 0;
	my $arg_val = 0;
	my $days = 0;
	my $notes_path = "notes.txt";
	my $cnt = scalar @ARGV;
	my $i = 0;
	my $save_path = "";
	my $form_type = "cal_entry_txt";
	my $translate = 0;

	my $year = 0;
	my $month = 0;
	my $day = 0;
	my $am_flag = 0;
	
	if ($cnt == 0) {
		print_warn_args_info();
		exit(1);
	}

	while ($i != $cnt) {

		$type = $ARGV[$i];
		$arg_val = $ARGV[$i + 1];

		$i += 2;
		switch($type) {
			case /-d/ {
				$days = $arg_val; 
			}
			case /-w/ {
				$days = $arg_val * 7; 
			}
			case /-m/ {
				if ($am_flag == 0) {
					($year, $month, $day) = Today();	
					$days = calculate_days($year, $month, $day, $arg_val);
				}
				$am_flag = $arg_val;
			}

			case /-pl/ {
				$translate = 1;
				$i--;
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

			case /-a/ {
				($year, $month, $day) = parse_data($arg_val);
				if ($am_flag != 0) { #it means that -m parameter was passed before -a.
					$days = calculate_days($year, $month, $day, $am_flag);
				}
				$am_flag = 1;	
			}
			
			else {
				print_warn_args_info();
				exit(1);
			}
		}
	}
	return ($days, $notes_path, $save_path, $form_type, $translate,
		$year, $month, $day);
}

sub write_header {
	my $type = $_[0];
	my $fh = $_[1];
	my $translate = $_[2];
	
	if ($type eq "cal_entry_tex") {
		print $fh "\\documentclass[12pt, oneside]{article}\n";
		print $fh "\\usepackage[T1]{fontenc}\n";
		print $fh "\\usepackage[utf8]{inputenc}\n";
		if ($translate == 0) {
			print $fh "\\usepackage[english]{babel}\n";
			print $fh "\\title{Calendar}\n";
		} else {
			print $fh "\\usepackage[polish]{babel}\n";
			print $fh "\\title{Kalendarz}\n";
		}
		print $fh "\\author{Konrad Gotfryd}\n";
		print $fh "\\begin{document}\n";
		print $fh "\\maketitle\n";
		print $fh "\\begin{table}\n";
		print $fh "\\centering\n";
		print $fh "\\begin{tabular}{|c|c|c|}\n";
		print $fh "\\hline\n";
		if ($translate == 0) {
			print $fh "Date & Day & Note\\\\ \\hline\n";
		} else {
			print $fh "Data & Dzień & Notatka\\\\ \\hline\n";
		}	
	} else {
		if ($translate == 0) {
			print $fh "\nCalendar\nAuthor: Konrad Gotfryd\n\n";
		} else {
			print $fh "\nKalendarz\nAutor: Konrad Gotfryd\n\n";
		}
	}
}

sub write_footer {
	my $type = $_[0];
	my $fh = $_[1];

	if ($type eq "cal_entry_tex") {
		print $fh "\\end{tabular}\n";
		print $fh "\\end{table}\n";
		print $fh "\\end{document}\n";
	} else {
		print $fh "$dash_line\n";
	}
}

sub set_nl_before_notes {
	my $type = $_[0];
	my $notes = $_[1];

	if (length $notes ne 0) {
		if ($type eq "cal_entry_tex") {
			return "\\par ".$notes;
		} else {
			return "\n     ".$notes;
		}
	} else {
		return "".$notes;
	}
	return "".$notes;	
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

sub check_note {
	my $note = $_[0];
		
	if ($_[1] eq "cal_entry_tex") {
		return $note;
	}

	$note =~ s/(.{2,80})/$1\n/gs;

	return $note;
}

sub ignore_notes_before_date {
	my $cnt = $loop_size;
	while ($cnt) {
		($year_f, $month_f, $day_f, $notes_f) = parse_data($file_arr[$arr_cnt]);
		$arr_cnt++;

		if ($year > $year_f || $month > $month_f || $day > $day_f) {
			$cnt--;	
		} else {
			return $cnt;
		}
	}
	return -1;
}

#There is no PL-MA in profiles.
$calendar = Date::Calendar->new($Profiles->{'US-FL'});

($loop_size, $file_path, $save_path, $type, $translate, 
	$year, $month, $day) = parse_input_args();

if ($year == 0 && $month == 0 && $day == 0) {
	($year, $month, $day) = Today();
}

open(save_file, ">", $save_path);

if (length $save_path == 0) {
	if (length $save_path != 0) {
		print "Could not open file $save_path. Writing output";
		print " to the console.\n";
	}
	*save_file = STDOUT;
}

select(save_file);

$~ = $type;
@file_arr = read_file($file_path);
$arr_cnt = 0;

ignore_notes_before_date();

write_header($type, save_file, $translate);

$date_year = $calendar->year($year);
$index = $calendar->date2index($year, $month, $day);

for (my $i = 0; $i < $loop_size; $i++) {
	$date = $date_year->index2date($index);

	$year = $date->year;
	$month = $date->month;
	$day = $date->day;

	$day_of_w = Day_of_Week($year, $month, $day);
	$day_of_w_txt = Day_of_Week_to_Text($day_of_w);
	if ($translate == 1) {
		$day_of_w_txt = $translate_day{$day_of_w_txt};
	}
	$notes = "";
	
	if ($day == $day_f && $month == $month_f && $year == $year_f) {
		$notes = $notes_f;
		($year_f, $month_f, $day_f, $notes_f) = parse_data($file_arr[$arr_cnt]);	
		$arr_cnt++;	
	}

	$notes = set_nl_before_notes($type, $notes);
	$notes = check_note($notes, $type);
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

