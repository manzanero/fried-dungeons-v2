class_name DiceRoll
extends Node3D


signal finished(dice_string: String, result: Array)
signal timeout_error()


var dice_string: String
var is_finished := false


func init(parent: Node, _dice_string: String):
	dice_string = _dice_string
	parent.add_child(self)
	name = Utils.random_string()
	return self
	

func _ready() -> void:
	
	child_entered_tree.connect(_on_added_die)
	
	# lifetime
	get_tree().create_timer(10).timeout.connect(_on_lifetime_end)


func _on_lifetime_end() -> void:
	if not is_finished:
		timeout_error.emit()
		queue_free()
	

func _process(_delta: float) -> void:
	####### workarround for non working physics
	#timeout_error.emit()
	#queue_free()
	#######
	
	if Input.is_action_just_pressed("left_click"):
		visible = false
	
	if is_finished and not visible:
		queue_free()
		 
	get_tree().create_timer(60).timeout.connect(queue_free)
	

func _on_added_die(die: Die) -> void:
	die.stopped.connect(_on_die_stopped)
	
	
func _on_die_stopped():
	var result := []
	
	for die: Die in get_children():
		if die.result:
			if die.faces == 100:
				continue
				
			result.append(die.result)
		else:
			return
			
	is_finished = true
	finished.emit(dice_string, result)
	
	#get_tree().create_timer(5).timeout.connect(queue_free)
