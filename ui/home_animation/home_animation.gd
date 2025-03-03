class_name HomeAnimation
extends Node2D
 
@export var spawn_margin: float = -100.0   

const IMAGES := [
	preload("res://resources/images/barbaro.png"),
	preload("res://resources/images/caballero.png"),
	preload("res://resources/images/hamburguesa.png"),
	preload("res://resources/images/helado.png"),
	preload("res://resources/images/hotdog.png"),
	preload("res://resources/images/mago.png"),
	preload("res://resources/images/nigiri.png"),
	preload("res://resources/images/patatas.png"),
	preload("res://resources/images/rogue.png"),
]
@onready var projectile_scene := preload("res://ui/home_animation/projectile.tscn")
@onready var spawn_timer: Timer = %SpawnTimer


func _ready():
	randomize()  
	spawn_timer.timeout.connect(spawn_projectile)
	#reset()
	

func start():
	visible = true
	reset()
	
func stop():
	visible = false
	spawn_timer.stop()


func reset():
	await get_tree().create_timer(4).timeout
	spawn_timer.wait_time = 4
	spawn_timer.start()
	create_tween().tween_property(spawn_timer, "wait_time", 0.2, 30.0)


func spawn_projectile():
	var screen_size = get_viewport_rect().size
	var projectile: Projectile = projectile_scene.instantiate()
	#var images := Array(Game.preloader.get_resource_list())
	#projectile.sprite_2d.texture = Game.preloader.get_resource(images.pick_random())
	projectile.sprite_2d.texture = IMAGES.pick_random()

	# Choose a random edge: 0 = left, 1 = right, 2 = top, 3 = bottom
	var edge = randi() % 4
	var direction: Vector2

	match edge:
		0:
			# Left edge: spawn a bit inside using spawn_margin
			projectile.position = Vector2(spawn_margin, randf_range(spawn_margin, screen_size.y - spawn_margin))
			direction = Vector2(1, randf_range(-0.5, 0.5)).normalized()
		1:
			# Right edge
			projectile.position = Vector2(screen_size.x - spawn_margin, randf_range(spawn_margin, screen_size.y - spawn_margin))
			direction = Vector2(-1, randf_range(-0.5, 0.5)).normalized()
		2:
			# Top edge
			projectile.position = Vector2(randf_range(spawn_margin, screen_size.x - spawn_margin), spawn_margin)
			direction = Vector2(randf_range(-0.5, 0.5), 1).normalized()
		3:
			# Bottom edge
			projectile.position = Vector2(randf_range(spawn_margin, screen_size.x - spawn_margin), screen_size.y - spawn_margin)
			direction = Vector2(randf_range(-0.5, 0.5), -1).normalized()

	add_child(projectile)
	projectile.apply_central_impulse(direction * 500)
