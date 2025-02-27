class_name CreditsWindow
extends FriedWindow

@onready var start_rich_text_label: RichTextLabel = %StartRichTextLabel


func _ready() -> void:
	super()
	visibility_changed.connect(_on_visibility_changed)
	start_rich_text_label.meta_clicked.connect(func (meta): 
		OS.shell_open(meta)
	)


func _on_visibility_changed() -> void:
	if visible:
		Game.ui.mouse_blocker.visible = true
