class_name Dicer
extends Node3D


signal roll_result(origin_label, origin_color, dice_string, result: Array)

const SM = preload("res://addons/dice_syntax/string_manip.gd")
const DICE_ROLL = preload("res://assets/dicer/dice_roll/dice_roll.tscn")
const D4 := preload("res://assets/dicer/dices/d4.tscn")
const D6 := preload("res://assets/dicer/dices/d6.tscn")
const D8 := preload("res://assets/dicer/dices/d8.tscn")
const D10 := preload("res://assets/dicer/dices/d10.tscn")
const D12 := preload("res://assets/dicer/dices/d12.tscn")
const D20 := preload("res://assets/dicer/dices/d20.tscn")
const D100 := preload("res://assets/dicer/dices/d100.tscn")


var dice_roll: DiceRoll


@onready var dice_rolls: Node3D = %DiceRolls
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


@rpc("call_local", "any_peer", "reliable")
func create_dice_roll(origin_label: String, origin_color: Color, dice_string: String, dice_roll_seed: int) -> void:
	audio_stream_player.play()
	
	seed(dice_roll_seed)

	var parsed_dice = dice_syntax.dice_parser(dice_string)
	
	if is_instance_valid(dice_roll):
		dice_roll.visible = false
	
	dice_roll = DICE_ROLL.instantiate().init(dice_rolls, origin_label, origin_color, dice_string)
	if is_multiplayer_authority():
		dice_roll.timeout_error.connect(roll_parsed.bind(origin_label, origin_color, dice_string, parsed_dice))
		dice_roll.finished.connect(_on_dice_roll_finished)
	
	for rr in parsed_dice.rules_array:
		for i in range(rr.dice_count):
			var die: Die
			
			if rr.dice_side == 100:
				var die_100: Die = D100.instantiate().init(dice_roll, 100, origin_color, randi_range(0, 999999))
				die = D10.instantiate().init(dice_roll, 10, origin_color, randi_range(0, 999999), die_100)
				continue
				
			match rr.dice_side:
				4: die = D4.instantiate()
				6: die = D6.instantiate()
				8: die = D8.instantiate()
				10: die = D10.instantiate()
				12: die = D12.instantiate()
				20: die = D20.instantiate()
			
			if die:
				die.init(dice_roll, rr.dice_side, origin_color, randi_range(0, 999999))
			#else:
				#roll_parsed(origin_label, origin_color, dice_string, parsed_dice)


func _on_dice_roll_finished(origin_label: String, origin_color: Color, dice_string: String, result: Array):
	roll_result.emit(origin_label, origin_color, dice_string, result)


func roll_parsed(origin_label: String, origin_color: Color, dice_string: String, parsed_dice: Dictionary):
	var result_data := dice_syntax.roll_parsed(parsed_dice)
	if result_data.rolls:
		roll_result.emit(origin_label, origin_color, dice_string, result_data.rolls[0].dice)
	#else:
		#roll_result.emit(origin_label, origin_color, dice_string, []) 
	
	
	
