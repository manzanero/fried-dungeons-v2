extends Node


enum Code {
	ROLL,
}


class Command:
	var code: Code
	var args: Array
	var kwargs: Dictionary
	var origin: Element
	
	func _init(_code : Code, _kwargs : Dictionary, _args: Array, _origin: Element = null):
		code = _code
		args = _args
		kwargs = _kwargs
		origin = _origin


func execute(command : Command):
	match command.code:
		Code.ROLL: _command_roll(command.args, command.kwargs)


func _command_roll(args, kwargs):
	var dice_string: String = kwargs['dice_string']
	Debug.print_message(Debug.WARNING, dice_string)
