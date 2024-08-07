extends Node


signal send_message(text: String)


const DEBUG := 10
const INFO := 20
const WARNING := 30
const ERROR := 40
const CRITICAL := 50

const DEBUG_STR := "[color=blue][b][DEBUG][/b][/color]"
const INFO_STR := "[color=dark_green][b][INFO][/b][/color]"
const WARNING_STR := "[color=dark_goldenrod][b][WARNING][/b][/color]"
const ERROR_STR := "[color=red][b][ERROR][/b][/color]"
const CRITICAL_STR := "[color=dark_red][b][CRITICAL][/b][/color]"

var is_debug := true
var level := INFO

func print_message(debug_level: int, message: String):
	if is_debug and debug_level >= level:
		var time_str := "[color=dark_gray]%s.%03d[/color]" % [
			Time.get_time_string_from_system(false), Time.get_ticks_msec() % 1000]

		var level_str: String
		if debug_level <= DEBUG:
			level_str = DEBUG_STR
		elif debug_level <= INFO:
			level_str = INFO_STR
		elif debug_level <= WARNING:
			level_str = WARNING_STR
		elif debug_level <= ERROR:
			level_str = ERROR_STR
		else:
			level_str = CRITICAL_STR
		
		var debug_str = "%s %s %s" % [time_str, level_str, message]
		print_rich(debug_str)
		send_message.emit(debug_str)
