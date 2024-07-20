class_name PanelHistory
extends PanelContainer


signal command_pressed(text: String)


const COMMAND_BUTTON := preload("res://ui/tabs/tab_messages/panel_history/command_button/command_button.tscn")


var max_scroll_length = 0 


@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var scrollbar := scroll_container.get_v_scroll_bar()
@onready var container: Container = %CommandsContainer


func _ready() -> void:
	max_scroll_length = scrollbar.max_value
	scrollbar.changed.connect(func ():
		await get_tree().process_frame 
		if max_scroll_length != scrollbar.max_value: 
			max_scroll_length = scrollbar.max_value 
			scroll_container.scroll_vertical = max_scroll_length
	)


func add_command(text: String):
	var command: Button = COMMAND_BUTTON.instantiate()
	container.add_child(command)
	#container.move_child(command, 0)
	if container.get_child_count() > 32:
		container.get_child(32).queue_free()
		
	scroll_container.scroll_vertical = 10000
	
	command.text = text
	command.pressed.connect(func (): 
		command_pressed.emit(text)
	)
	
