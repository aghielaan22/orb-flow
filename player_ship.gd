extends CharacterBody2D

@export var speed: float = 600.0
@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@onready var muzzle: Node2D = $Muzzle

var can_shoot: bool = true
var fire_rate: float = 0.15 
var gyro_sensitivity: float = 35.0

func _ready() -> void:
	# Strip away any old placeholder ColorRects or rectangular sprites causing the box look
	for child in get_children():
		if child is ColorRect or (child is Sprite2D and child.name != "Muzzle"):
			child.queue_free()

	# Automatically generate a sleek cyberpunk fighter graphic
	if not has_node("ShipVisual"):
		var ship_visual = Line2D.new()
		ship_visual.name = "ShipVisual"
		ship_visual.width = 3.5
		ship_visual.default_color = Color(0.0, 0.95, 1.0) # Electric Cyan
		
		# Aerodynamic fighter wedge points
		var ship_points = [
			Vector2(0, -28),     # Nose tip pointing up
			Vector2(-10, -10),   # Left cockpit taper
			Vector2(-24, 22),    # Left wing tip
			Vector2(-8, 14),     # Left engine recess
			Vector2(0, 20),      # Center tail notch
			Vector2(8, 14),      # Right engine recess
			Vector2(24, 22),     # Right wing tip
			Vector2(10, -10),    # Right cockpit taper
			Vector2(0, -28)      # Loop back to nose
		]
		for p in ship_points:
			ship_visual.add_point(p)
		add_child(ship_visual)
		
		# Add a subtle engine glow under the ship
		var engine_glow = Line2D.new()
		engine_glow.name = "EngineGlow"
		engine_glow.width = 6.0
		engine_glow.default_color = Color(0.0, 0.5, 1.0, 0.6)
		engine_glow.add_point(Vector2(-6, 16))
		engine_glow.add_point(Vector2(6, 16))
		add_child(engine_glow)

func _physics_process(delta: float) -> void:
	var screen_width = get_viewport_rect().size.x
	
	# 1. Mobile Gyroscope / Accelerometer Tilt
	var accel = Input.get_accelerometer()
	if accel.x != 0.0:
		var tilt_dir = clamp(accel.x * gyro_sensitivity, -1.0, 1.0)
		global_position.x += tilt_dir * speed * delta
	else:
		# 2. PC Keyboard Fallback (A/D or Arrow keys)
		var direction := 0.0
		if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
			direction -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
			direction += 1.0
		
		velocity.x = direction * speed
		move_and_slide()

	# Keep player locked to the bottom area and inside horizontal bounds
	global_position.x = clamp(global_position.x, 40.0, screen_width - 40.0)
	global_position.y = get_viewport_rect().size.y - 150.0
	
	# Continuous shooting (Spacebar or holding touch/click)
	if can_shoot and (Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		shoot()

func shoot() -> void:
	if bullet_scene == null:
		return
		
	can_shoot = false
	var bullet = bullet_scene.instantiate()
	bullet.global_position = muzzle.global_position
	
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
