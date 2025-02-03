extends Control

@onready var close_button: Button = %CloseButton

@onready var scene_button: Button = %SceneButton
@onready var messages_button: Button = %MessagesButton
@onready var edit_modes_button: Button = %EditModesButton
@onready var campaign_tabs_button: Button = %CampaignTabsButton

@onready var rich_text_label: RichTextLabel = %RichTextLabel



func _ready() -> void:
	close_button.pressed.connect(func (): visible = false)
	
	scene_button.pressed.connect(_on_scene_button_pressed)
	messages_button.pressed.connect(_on_messages_button_pressed)
	edit_modes_button.pressed.connect(_on_edit_modes_button_pressed)
	campaign_tabs_button.pressed.connect(_on_campaign_tabs_button_pressed)
	
	scene_button.button_pressed = true
	_on_scene_button_pressed()


func _on_scene_button_pressed():
	rich_text_label.text = """\
The scene is the central part of the app. It shows the status of the game in real time. \
 Scene is composed by:

[ul]
 [color=cyan]Ground[/color]: The base layer of the map where entities move. \
 Any elements placed outside the Ground will remain invisible to all players.
 [color=CRIMSON]Walls[/color]: Bounds that block light and restrict the movement of entities. \
 Each wall follows a path, either open or closed. The right side faces the player's view and \
 appears solid, while the left side is translucent and intended to remain unseen.
 [color=light_green]Elements[/color]: Interactable objects. Types:
[ul bullet=-]
 [color=LIGHT_CORAL]Entities[/color]: Controllable by players. \
 Players can view the world through their perspective and speak on \
 their behalf if the entities are assigned to them.
 [color=gold]Lights[/color]: They add luminosity to the map and other Elements.
 [color=orange_red]Props[/color]: Map decoration, may block light and movement.
[/ul]
[/ul]

The game can operate in various modes, which may differ between players:

[ul]
 [color=green]Play[/color]: The player can move and interact with the elements they control.
 [color=yellow]Pause[/color]: The player can interact with their elements but cannot move them.
 [color=red]Stop[/color]: The player loses visibility of the map and cannot interact with it.
[/ul]

[center][u]CONTROLS[/u][/center]
[ul]
 Hold [b]MOUSE_RIGHT_CLICK[/b]: makes the camera move
 Hold [b]MOUSE_MIDDLE_CLICK[/b]: makes the camera orbit
 [b]MOUSE_LEFT_CLICK[/b] on [color=light_green]Element[/color]: \
 selects [color=light_green]Element[/color] if the player has its control
 Hold [b]MOUSE_LEFT_CLICK[/b] on [color=light_green]Element[/color]: \
 drags [color=light_green]Element[/color] if the player has its control
 Hold [b]MOUSE_LEFT_CLICK + MOUSE_RIGHT_CLICK[/b] on [color=light_green]Element[/color]: \
 drags [color=light_green]Element[/color] and shows grid and inicial drag origin
 Hold [b]ALT + MOUSE_LEFT_CLICK[/b] on [color=light_green]Element[/color]: drags [color=light_green]Element[/color] to exact point
 [color=purple](Master only)[/color] Hold [b]CTRL + MOUSE_LEFT_CLICK[/b] on [color=light_green]Element[/color]: \
 moves [color=light_green]Element[/color] instantly to a position
 Hold [b]SHIFT + MOUSE_LEFT_CLICK[/b] on [color=light_green]Element[/color]: rotates selected [color=light_green]Element[/color]
 Hold [b]SHIFT + MOUSE_LEFT_CLICK + F[/b] on [color=light_green]Element[/color]: flips selected [color=light_green]Element[/color]
[/ul]
"""


func _on_messages_button_pressed():
	rich_text_label.text = """\
The Messages Tab is used to send messages to other players. \
You can select the message's origin, choosing either the [color=CADET_BLUE]Player[/color] or an [color=light_green]Element[/color] \
 controlled by the player. The [color=purple]Master[/color] can also send messages as a Narrator.

The top buttons provide access to utilities, which include:
[ul]
 [color=ORANGE]Dice[/color]: Allows for a physical dice roll.
 [color=ORANGE]History[/color]: Enables rewriting a previous command.
[/ul]

It is also possible to execute commands. Commands are written by starting the message with "/", \
 followed by a space, and the arguments separated by spaces. The available commands are:
[ul]
 [code][color=light_green]echo[/color][/code]: Sends a message. This is the default behaviour.
 [code][color=light_green]roll[/color][/code]: Performs a custom dice roll using the standard XdY notation, where X is the number of \
 dice and Y is the number of sides. Example: [code]/roll 2d20 + 1d4[/code]
[/ul]
"""


func _on_edit_modes_button_pressed():
	rich_text_label.text = """\
[u]Ground Editing[/u]
Pressing the C key copies hovered ground material.
[ul]
 [color=cyan]Paint[/color]: Hold the left mouse button to paint the ground with the selected material.
 [color=cyan]Paint Rect[/color]: Click and drag to create a rectangle and paint it with the selected material.
 [color=cyan]Bucket[/color]: Click to replace all connected tiles of the same material with the selected one.
 [color=cyan]Erase Rect[/color]: Click and drag to create a rectangle and erase the tiles within it.
[/ul]

[u]Wall Building[/u]
Pressing the C key copies hovered wall material.
[ul]
 [color=CRIMSON]Bound[/color]: A wall with only one visible side. Click to start creating the wall, \
 and successive clicks add points to it. Clicking the last point or using right-click ends the construction. \
 Clicking the first point created also finishes the wall and makes it a closed shape.
 [color=CRIMSON]Fence[/color]: A wall visible from both sides. Click to start creating the wall, \
 and successive clicks add points. Clicking the last point or using right-click ends the construction. \
 Clicking the first point created also finishes the wall and makes it a closed shape.
 [color=CRIMSON]Barrier[/color]: A thick wall with faces directed outward. \
 Click and drag to create two closely spaced parallel walls in the dragged direction.
 [color=CRIMSON]Box[/color]: A square-shaped wall. Click and drag to create a square of parallel \
 walls aligned to the grid, with one point at the origin and the other at the opposite diagonal.
 [color=CRIMSON]Passage[/color]: Two separated walls with their faces directed inward. \
 Click and drag to create two closely spaced parallel walls in the dragged direction.
[/ul]

[u]Wall Editing[/u]
Pressing the C key copies hovered wall material.
[ul]
 [color=CRIMSON]Select[/color]: Click and drag to move wall points. Dropping a contiguous point onto another merges them. \
 Dragging the endpoint of one wall and dropping it at the start of another wall of \
 the same material connects them. Controls:
[ul bullet=-]
 Drag Left-Click: Selects hovered points.
 Shift + Left-Click: Selects all points.
 Control + Left-Click: Adds points to the selection.
 Control + Right-Click: Removes points from the selection.
 Double Click in the middle of a wall, holding the second click: Adds an intermediate point when releasing the click.
 Double Click on the endpoint of a wall, holding the second click: Adds an additional point when releasing the click.
[/ul]
 [color=CRIMSON]Flip[/color]: Left-click to flip the visible face of the selected wall.
 [color=CRIMSON]Change[/color]: Left-click to convert a single-sided wall into a double-sided one.
 [color=CRIMSON]Paint[/color]: Left-click to paint the wall with the selected material.
 [color=CRIMSON]Cut[/color]: Click and drag to delete the section between two points.
[/ul]
"""


func _on_campaign_tabs_button_pressed():
	rich_text_label.text = """\
[ul]
 [color=purple]Elements[/color]: Selects and focuses on elements within the scene.
 [color=purple]Jukebox[/color]: Drag sound files from the resource tree to play them in sync.
 [color=purple]World[/color]: Manages open scenes.
[ul bullet=-]
 Double-click to open a scene.
 Play button sends players to the selected scene.
[/ul]
 [color=purple]Players[/color]: Manages the game state of players and allows assigning entities to them.
 [color=purple]Properties[/color]: Modifies the properties of the selected element in the scene.
 [color=purple]Settings[/color]: Adjusts the properties of the scene.
 [color=purple]Builder[/color]: Selects a texture to use when creating ground or walls.
 [color=purple]Resources[/color]: Manages the assets located in the "resources" folder of the campaign.
 [color=purple]Player[/color]: Modifies the properties of the player.
[/ul]
"""
