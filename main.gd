extends Node2D

var is_drawing: bool = false
var current_line: Line2D = null
var current_collision: StaticBody2D = null
var points: Array = []

var orb: RigidBody2D = null
var spawn_position: Vector2 = Vector2(360, 150)

func _ready() -> void:
	print("Orb Flow Core Prototype Loaded!")
	setup_game_elements()
	spawn_orb()

func setup_game_elements() -> void:
	# 1. Create a Goal Area at the bottom right
	var goal_area = Area2D.new()
	goal_area.position = Vector2(550, 1100)
	
	var goal_shape = CollisionShape2D.new()
	var goal_circle = CircleShape2D.new()
	goal_circle.radius = 50.0
	goal_shape.shape = goal_circle
	goal_area.add_child(goal_shape)
	
	# Visual ring for the goal
	var goal_visual = Line2D.new()
	goal_visual.width = 6.0
	goal_visual.default_color = Color(1.0, 0.84, 0.0) # Gold Color
	for i in range(33):
		var angle = i * (PI * 2 / 32)
		goal_visual.add_point(Vector2(cos(angle) * 50, sin(angle) * 50))
	goal_area.add_child(goal_visual)
	
	goal_area.body_entered.connect(_on_goal_entered)
	add_child(goal_area)

	# 2. Add UI Buttons (Reset & Spawn)
	var canvas_layer = CanvasLayer.new()
	var reset_button = Button.new()
	reset_button.text = " Reset Level "
	reset_button.position = Vector2(40, 40)
	reset_button.pressed.connect(reset_level)
	canvas_layer.add_child(reset_button)
	add_child(canvas_layer)

func spawn_orb() -> void:
	if orb:
		orb.queue_free() # Remove old orb if present
		
	orb = RigidBody2D.new()
	orb.position = spawn_position
	
	# Add Physics collision shape
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	collision.shape = circle
	orb.add_child(collision)
	
	# Draw the visual circle for the Orb
	var orb_visual = Line2D.new()
	orb_visual.width = 20.0
	orb_visual.default_color = Color(0.2, 1.0, 0.4) # Bright Cyan/Green Orb
	orb_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	orb_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	orb_visual.add_point(Vector2(-1, 0))
	orb_visual.add_point(Vector2(1, 0))
	orb.add_child(orb_visual)
	
	add_child(orb)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			start_drawing(event.position)
		else:
			stop_drawing()
			
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_drawing:
			add_point_to_line(event.position)

func start_drawing(pos: Vector2) -> void:
	is_drawing = true
	points = [pos]
	
	current_line = Line2D.new()
	current_line.width = 12.0
	current_line.default_color = Color(0.0, 0.8, 1.0) # Neon Blue Line
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(current_line)
	current_line.add_point(pos)
	
	current_collision = StaticBody2D.new()
	add_child(current_collision)

func add_point_to_line(pos: Vector2) -> void:
	if points.size() > 0 and pos.distance_to(points[-1]) < 10.0:
		return
		
	points.append(pos)
	current_line.add_point(pos)
	
	if points.size() >= 2:
		var p1 = points[-2]
		var p2 = points[-1]
		
		var collision_shape = CollisionShape2D.new()
		var segment = SegmentShape2D.new()
		segment.a = p1
		segment.b = p2
		collision_shape.shape = segment
		current_collision.add_child(collision_shape)

func stop_drawing() -> void:
	is_drawing = false

func _on_goal_entered(body: Node2D) -> void:
	if body == orb:
		print("VICTORY! The Orb reached the goal!")
		# Flash screen or reset for next test
		await get_tree().create_timer(0.5).timeout
		reset_level()

func reset_level() -> void:
	get_tree().reload_current_scene()
