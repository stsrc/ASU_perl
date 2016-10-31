#!/usr/bin/perl
use warnings;

use Date::Calendar::Profiles qw( $Profiles );
use Date::Calendar;
use Date::Calc qw(:all);
use Scalar::Util qw(openhandle);
use Switch;
use IO::File;

package Tex;

format cal_entry_tex =
@*.@*.@*. & @* & @* \\ \hline 
$year, $month, $day, $day_of_w_txt, $notes
.

sub new {
	my $class = shift;
	my $self = {
			_fh => shift,
			_translate => shift, 
	};
	bless $self, $class;
	return $self;
}

sub set_outputs {
	$fh = $_[1];
	select($fh);
	$~ = cal_entry_tex;
}

sub format_ref {
	$year = $_[1];
	$month = $_[2];
	$day = $_[3];
	$day_of_w_txt = $_[4];
	$notes = $_[5];
	write;
}

sub write_header {
	my $self = $_[0];
	my $fh = $self->{_fh};
	
	print $fh "\\documentclass[12pt, oneside]{article}\n";
	print $fh "\\usepackage[T1]{fontenc}\n";
	print $fh "\\usepackage[utf8]{inputenc}\n";
	print $fh "\\usepackage{longtable}\n";
	if ($self->{_translate} == 0) {
		print $fh "\\usepackage[english]{babel}\n";
		print $fh "\\title{Calendar}\n";
	} else {
		print $fh "\\usepackage[polish]{babel}";
		print $fh "\\title{Kalendarz}\n";
	}
	print $fh "\\author{Konrad Gotfryd}\n";
	print $fh "\\begin{document}\n";
	print $fh "\\maketitle\n";
	print $fh "\\begin{longtable}{|c|c|p{6cm}|}\n";
	print $fh "\\hline\n";
	if ($self->{_translate} == 0) {
		print $fh "Date & Day & Note\\\\ \\hline\n";
	} else {
		print $fh "Data & Dzień & Notatka\\\\ \\hline\n";
	}	
}

sub write_footer {
	my $fh = $_[1];

	print $fh "\\end{longtable}\n";
	print $fh "\\end{document}\n";

}

sub set_nl_before_notes {
	my $notes = $_[1];
	return $notes;	
}

sub check_note {
	my $note = $_[1];
	return $note;
}

package Txt;
$dash_line = "--------------------------------------------------------------------------------";

format cal_entry_txt =
@*
$dash_line
@*.@*.@*. @* @*
$year, $month, $day, $day_of_w_txt, $notes
.

sub set_outputs {
	$fh = $_[1];
	select($fh);
	$~ = cal_entry_txt;
}

sub format_ref {
	$year = $_[1];
	$month = $_[2];
	$day = $_[3];
	$day_of_w_txt = $_[4];
	$notes = $_[5];
	write;
}

sub new {
	my $class = shift;
	my $self = {
			_fh => shift,
			_translate => shift, 
	};
	bless $self, $class;
	return $self;
}

sub write_header {
	my $self = $_[0];
	my $fh = $self->{_fh};
	if ($self->{_translate} == 0) {
		print $fh "\nCalendar\nAuthor: Konrad Gotfryd\n\n";
	} else {
		print $fh "\nKalendarz\nAutor: Konrad Gotfryd\n\n";
	}
}

sub write_footer {
	my $fh = $_[1];
	print $fh "$dash_line\n";
}

sub set_nl_before_notes {
	my $notes = $_[1];

	if (length $notes ne 0) {
		return "\n\t".$notes;
	} else {
		return $notes;
	}

	return $notes;	
}

sub check_note {
	my $note = $_[1];
	
	$note =~ s/(.{2,80})/$1\n/gs;

	return $note;
}

package main;

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
	my $line = $_[0];
	my @parsed = [];

	my($parsed_date, $parsed_note) = split(/ /, $line, 2);
	@parsed = split(/\./, $parsed_date);

	return ($parsed[0], $parsed[1], $parsed[2], $parsed_note);
}

sub print_args_info {
	print "\nArgument wymagany (jeden z trzech poniżej):\n";
	print "\"-d [liczba]\" liczba dni do wydrukowania.\n";
	print "\"-w [liczba]\" liczba tygodni do wydrukowania.\n";
	print "\"-m [liczba]\" liczba miesięcy do wydrykowania.\n";
	print "\nArgumenty dodatkowe:\n";
	print "\"-p [ścieżka]\" ścieżka do pliku z notatkami. Gdy parametr nie";
	print " podany wczytywany jest plik ./notes.txt.\n";
	print "\"-s [ścieżka]\" ścieżka do pliku z zapisem kalendarza. Gdy";
	print " parametr nie podany, wydruk do konsoli.\n";
	print "\"-t [txt/tex]\" typ kalendarza (tabelka tekstowa lub TeX'owa).";
	print " Gdy parametr nie podany drukowana jest tabelka tekstowa.\n";
	print "\"-a [rrrr.mm.dd]\" Data od której kalendarz ma być wydrukowa";
	print "ny.\n Gdy argument nie jest podany kalendarz zaczyna się od dn";
	print "ia bierzącego.\n";
	print "\"-pl: kaneldarz z dniami tygodnia po polsku.\n\n";
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
	
	($year, $month, $day) = Today();	

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
					$am_flag = $arg_val;
				}
				$days = calculate_days($year, $month, $day, $arg_val);
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
				} else {
					$am_flag = 1;	
				}
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

sub ignore_notes_before_actual_date {
	
	while($arr_cnt < scalar @file_arr) {
		($year_f, $month_f, $day_f, $notes_f) = parse_data($file_arr[$arr_cnt]);
		$arr_cnt++;
		if ($year_f < $year) {
			next;
		} elsif ($year_f > $year) {
			last;
		} elsif ($month_f < $month) {
			next;
		} elsif ($month_f > $month) {
			last;
		} elsif ($day_f < $day) {
			next;
		} elsif ($day_f >= $day) {
			last;
		}	
	}
	return ($year_f, $month_f, $day_f, $notes_f);
}

sub constructor {
	my $fh = $_[0];
	my $type = $_[1];
	my $translate = $_[2];
	my $obj;
	if ($type eq "cal_entry_tex") {
		$obj = new Tex($fh, $translate); 
	} else {
		$obj = new Txt($fh, $translate);
	}
	return $obj;
}

#There is no PL-MA in profiles.
$calendar = Date::Calendar->new($Profiles->{'US-FL'});

($loop_size, $file_path, $save_path, $type, $translate, 
	$year, $month, $day) = parse_input_args();

my $save_file = IO::File->new;

if (length $save_path == 0) {
	*$save_file = STDOUT;
} else {
	open $save_file, ">$save_path" or die "Nie można utworzyć pliku $save_path!";
}

@file_arr = read_file($file_path);
$arr_cnt = 0;

ignore_notes_before_actual_date();

$text_object = constructor($save_file, $type, $translate);
$text_object->set_outputs($save_file);
$text_object->write_header();

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
		if ($arr_cnt < scalar @file_arr) {
			($year_f, $month_f, $day_f, $notes_f) = parse_data($file_arr[$arr_cnt]);	
			$arr_cnt++;	
		}
	}

	$notes = $text_object->set_nl_before_notes($notes);
	$notes = $text_object->check_note($notes);
	$day = sprintf("%02d", $day);
	$month = sprintf("%02d", $month);

	$text_object->format_ref($year, $month, $day, $day_of_w_txt, $notes);

	$index++;
	if ($month == 12 && $day == 31) {
		$date_year = $calendar->year($year + 1);
		$index = 0;
	}
}

$text_object->write_footer($save_file);

close($save_file);

