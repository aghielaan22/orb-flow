extends CharacterBody2D

@export var speed: float = 650.0
@export var bullet_scene: PackedScene = preload("res://bullet.tscn")

var can_shoot: bool = true
var fire_rate: float = 0.15 

func _ready() -> void:
	# Clean up any old placeholder nodes
	for child in get_children():
		if child is ColorRect or (child is Sprite2D and child.name != "Muzzle" and child.name != "ShipVisual"):
			child.queue_free()

	# Ensure visual exists if not in scene
	if not has_node("ShipVisual"):
		var ship_visual = Line2D.new()
		ship_visual.name = "ShipVisual"
		ship_visual.width = 3.5
		ship_visual.default_color = Color(0.0, 0.95, 1.0)
		var ship_points = [
			Vector2(0, -28), Vector2(-10, -10), Vector2(-24, 22),
			Vector2(-8, 14), Vector2(0, 20), Vector2(8, 14),
			Vector2(24, 22), Vector2(10, -10), Vector2(0, -28)
		]
		for p in ship_points:
			ship_visual.add_point(p)
		add_child(ship_visual)

func _physics_process(delta: float) -> void:
	var screen_width = get_viewport_rect().size.x
	if screen_width <= 0:
		screen_width = 720.0

	var direction := 0.0
	var space_shooter_node = get_parent()
	
	# 1. Read Left/Right arcade button input from space_shooter.gd
	if space_shooter_node and "input_dir" in space_shooter_node:
		direction = space_shooter_node.input_dir

	# 2. PC Keyboard Fallback (A/D or Arrow keys for testing)
	if direction == 0.0:
		if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
			direction += 1.0

	# Move ship horizontally
	global_position.x += direction * speed * delta

	# Keep player locked within horizontal bounds and fixed at the bottom
	global_position.x = clamp(global_position.x, 40.0, screen_width - 40.0)
	global_position.y = get_viewport_rect().size.y - 180.0 if get_viewport_rect().size.y > 0 else 1100.0
	
	# 3. Read FIRE button input (or Spacebar on PC)
	var is_firing = false
	if space_shooter_node and "firing_pressed" in space_shooter_node:
		is_firing = space_shooter_node.firing_pressed
		
	if not is_firing:
		is_firing = Input.is_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept")
	
	if is_firing and can_shoot:
		shoot()

func shoot() -> void:
	if bullet_scene == null:
		return
		
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	
	# Force bullet to spawn directly at the ship's exact top nose tip
	bullet.global_position = global_position + Vector2(0, -40)
	
	if not bullet.has_node("OuterGlow"):
		var outer_glow = Line2D.new()
		outer_glow.name = "OuterGlow"
		outer_glow.width = 12.0
		outer_glow.default_color = Color(0.0, 0.9, 1.0, 0.35)
		outer_glow.add_point(Vector2(0, -12))
		outer_glow.add_point(Vector2(0, 12))
		bullet.add_child(outer_glow)

		var inner_core = Line2D.new()
		inner_core.name = "InnerCore"
		inner_core.width = 4.0
		inner_core.default_color = Color(1.0, 1.0, 1.0, 1.0)
		inner_core.add_point(Vector2(0, -10))
		inner_core.add_point(Vector2(0, 10))
		bullet.add_child(inner_core)

	get_tree().root.add_child(bullet)
	
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true
