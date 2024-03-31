extends Node


const DEBUG := 10
const INFO := 20
const WARNING := 30
const ERROR := 40
const CRITICAL := 50

#var debug := false
var is_debug := true
var debug_level := INFO

func print_message(level : int, message : String):
	if is_debug and level >= debug_level:
		print("%s.%03d [%s] %s" % [
			Time.get_time_string_from_system(false),
			Time.get_ticks_msec() % 1000, 
			level, 
			message
		])
