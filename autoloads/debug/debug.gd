extends Node


signal send_message(text: String)


const DEBUG := 10
const INFO := 20
const WARNING := 30
const ERROR := 40
const CRITICAL := 50

const _DEBUG_STR := "[color=blue][b][DEBUG][/b][/color]"
const _INFO_STR := "[color=dark_green][b][INFO][/b][/color]"
const _WARNING_STR := "[color=dark_goldenrod][b][WARNING][/b][/color]"
const _ERROR_STR := "[color=red][b][ERROR][/b][/color]"
const _CRITICAL_STR := "[color=dark_red][b][CRITICAL][/b][/color]"

var id := 1
var is_debug := true
var level := INFO


func print_debug_message(message: Variant):
	print_message(DEBUG, str(message))

func print_info_message(message: Variant):
	print_message(INFO, str(message))

func print_warning_message(message: Variant):
	print_message(WARNING, str(message))

func print_error_message(message: Variant):
	print_message(ERROR, str(message))

func print_critical_message(message: Variant):
	print_message(CRITICAL, str(message))


func print_message(debug_level: int, message: Variant):
	if is_debug and debug_level >= level:
		var id_str := "(%s)" % [id]
		var time_str := "[color=dark_gray]%s.%03d[/color]" % [
			Time.get_time_string_from_system(false), Time.get_ticks_msec() % 1000]

		var level_str: String
		if debug_level <= DEBUG:
			level_str = _DEBUG_STR
		elif debug_level <= INFO:
			level_str = _INFO_STR
		elif debug_level <= WARNING:
			level_str = _WARNING_STR
		elif debug_level <= ERROR:
			level_str = _ERROR_STR
		else:
			level_str = _CRITICAL_STR
		
		var debug_str = "%s %s %s %s" % [id_str, time_str, level_str, str(message)]
		print_rich(debug_str)
		send_message.emit(debug_str)
