extends Node2D

# Level Tracking
static var current_level: int = 1
static var total_score: int = 0

var is_drawing: bool = false
var current_line: Line2D = null
var current_collision: StaticBody2D = null
var points: Array = []

var orb: RigidBody2D = null
var spawn_position: Vector2 = Vector2(360, 150)

# Ink & Scoring System Variables
var max_ink: float = 800.0
var current_ink: float = 800.0
var ink_bar: ProgressBar = null
var level_label: Label = null
var score_label: Label = null
var is_game_over: bool = false
var level_start_time: float = 0.0

func _ready() -> void:
	level_start_time = Time.get_ticks_msec()
	print("Orb Flow - Level " + str(current_level) + " Loaded!")
	setup_game_elements()
	spawn_orb()

func setup_game_elements() -> void:
	# 1. Cyberpunk Dark Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Goal Area at the bottom right (Cyber Yellow)
	var goal_area = Area2D.new()
	goal_area.position = Vector2(550, 1100)
	
	var goal_shape = CollisionShape2D.new()
	var goal_circle = CircleShape2D.new()
	goal_circle.radius = 50.0
	goal_shape.shape = goal_circle
	goal_area.add_child(goal_shape)
	
	var goal_visual = Line2D.new()
	goal_visual.width = 6.0
	goal_visual.default_color = Color(1.0, 0.85, 0.0)
	for i in range(33):
		var angle = i * (PI * 2 / 32)
		goal_visual.add_point(Vector2(cos(angle) * 50, sin(angle) * 50))
	goal_area.add_child(goal_visual)
	
	goal_area.body_entered.connect(_on_goal_entered)
	add_child(goal_area)

	# 3. Dynamic Level Layouts
	setup_level_configuration()

	# 4. CanvasLayer for UI (HUD Buttons, Level Indicator, Score & Ink Bar)
	var canvas_layer = CanvasLayer.new()
	
	# Reset Button
	var reset_button = Button.new()
	reset_button.text = " Reset "
	reset_button.position = Vector2(20, 40)
	reset_button.pressed.connect(reset_level)
	canvas_layer.add_child(reset_button)

	# Menu Button
	var menu_button = Button.new()
	menu_button.text = " Menu "
	menu_button.position = Vector2(95, 40)
	menu_button.pressed.connect(func(): 
		current_level = 1 
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	canvas_layer.add_child(menu_button)

	# Level Indicator Label
	level_label = Label.new()
	level_label.text = "L" + str(current_level)
	level_label.position = Vector2(170, 42)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5)) # Neon Magenta
	level_label.add_theme_font_size_override("font_size", 18)
	canvas_layer.add_child(level_label)

	# Score Indicator Label
	score_label = Label.new()
	score_label.text = "PTS: " + str(total_score)
	score_label.position = Vector2(215, 42)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0)) # Cyber Yellow
	score_label.add_theme_font_size_override("font_size", 16)
	canvas_layer.add_child(score_label)

	# Ink Progress Bar
	ink_bar = ProgressBar.new()
	ink_bar.position = Vector2(310, 45)
	ink_bar.custom_minimum_size = Vector2(370, 24)
	ink_bar.max_value = max_ink
	ink_bar.value = current_ink
	ink_bar.show_percentage = false
	
	# Cyberpunk Styling for the Ink Bar
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 0.9, 1.0) # Neon Cyan
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	ink_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.25)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	ink_bar.add_theme_stylebox_override("background", bg_style)
	
	canvas_layer.add_child(ink_bar)
	add_child(canvas_layer)

func setup_level_configuration() -> void:
	if current_level == 1:
		max_ink = 800.0
		setup_hazard(Vector2(360, 700), Vector2(300, 20))
	elif current_level == 2:
		max_ink = 650.0
		setup_hazard(Vector2(240, 600), Vector2(220, 20))
		setup_hazard(Vector2(480, 850), Vector2(220, 20))
	else:
		max_ink = 500.0
		setup_hazard(Vector2(360, 550), Vector2(260, 18))
		setup_hazard(Vector2(200, 800), Vector2(180, 18))
		setup_hazard(Vector2(520, 950), Vector2(180, 18))
		
	current_ink = max_ink

func setup_hazard(pos: Vector2, size: Vector2) -> void:
	var hazard_area = Area2D.new()
	hazard_area.position = pos
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	hazard_area.add_child(shape)
	
	var visual = ColorRect.new()
	visual.size = size
	visual.position = -size / 2.0
	visual.color = Color(1.0, 0.0, 0.4)
	hazard_area.add_child(visual)
	
	hazard_area.body_entered.connect(_on_hazard_entered)
	add_child(hazard_area)

func spawn_orb() -> void:
	if orb:
		orb.queue_free()
		
	orb = RigidBody2D.new()
	orb.position = spawn_position
	
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	collision.shape = circle
	orb.add_child(collision)
	
	var orb_visual = Line2D.new()
	orb_visual.width = 20.0
	orb_visual.default_color = Color(0.2, 1.0, 0.4)
	orb_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	orb_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	orb_visual.add_point(Vector2(-1, 0))
	orb_visual.add_point(Vector2(1, 0))
	orb.add_child(orb_visual)
	
	add_child(orb)

func _input(event: InputEvent) -> void:
	if is_game_over:
		return
		
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			start_drawing(event.position)
		else:
			stop_drawing()
			
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_drawing:
			add_point_to_line(event.position)

func start_drawing(pos: Vector2) -> void:
	if current_ink <= 0:
		return
		
	is_drawing = true
	points = [pos]
	
	current_line = Line2D.new()
	current_line.width = 12.0
	current_line.default_color = Color(0.0, 0.8, 1.0)
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(current_line)
	current_line.add_point(pos)
	
	current_collision = StaticBody2D.new()
	add_child(current_collision)

func add_point_to_line(pos: Vector2) -> void:
	if current_ink <= 0:
		stop_drawing()
		return
		
	if points.size() > 0 and pos.distance_to(points[-1]) < 10.0:
		return
		
	var dist = pos.distance_to(points[-1]) if points.size() > 0 else 0.0
	current_ink = max(0.0, current_ink - dist)
	if ink_bar:
		ink_bar.value = current_ink
		
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
		
	if current_ink <= 0:
		stop_drawing()

func stop_drawing() -> void:
	is_drawing = false

func _on_goal_entered(body: Node2D) -> void:
	if body == orb and not is_game_over:
		is_game_over = true
		
		# Calculate score bonus based on leftover ink and speed
		var elapsed_time = (Time.get_ticks_msec() - level_start_time) / 1000.0
		var time_bonus = max(0, int(100 - (elapsed_time * 2)))
		var ink_bonus = int(current_ink)
		var level_score = 500 + ink_bonus + time_bonus
		
		total_score += level_score
		print("VICTORY! Level score: ", level_score, " | Total Score: ", total_score)
		
		# --- HUAWEI GAME SERVICE (HMS) LEADERBOARD HOOK ---
		submit_score_to_huawei_leaderboard(total_score)
		
		show_victory_screen()

func _on_hazard_entered(body: Node2D) -> void:
	if body == orb and not is_game_over:
		is_game_over = true
		print("OOF! Orb hit a hazard!")
		call_deferred("reset_level")

func submit_score_to_huawei_leaderboard(score: int) -> void:
	# TODO: When exporting to Huawei AppGallery with the HMS Plugin enabled, 
	# replace this print statement with the official HMS Leaderboard API call, e.g.:
	# HMSGameService.submit_score("your_leaderboard_id_here", score)
	print("[HMS SDK Hook] Submitting total score to Huawei Game Service Leaderboard: ", score)

func show_victory_screen() -> void:
	is_drawing = false
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	canvas.add_child(vbox)
	
	var title = Label.new()
	title.text = "LEVEL " + str(current_level) + " CLEARED!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var score_display = Label.new()
	score_display.text = "TOTAL SCORE: " + str(total_score)
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_display.add_theme_font_size_override("font_size", 20)
	score_display.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(score_display)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 25)
	vbox.add_child(spacer)
	
	var next_btn = Button.new()
	next_btn.text = " NEXT LEVEL "
	next_btn.custom_minimum_size = Vector2(220, 50)
	next_btn.pressed.connect(func():
		current_level += 1
		if current_level > 3:
			current_level = 1
		get_tree().reload_current_scene()
	)
	vbox.add_child(next_btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	
	var menu_btn = Button.new()
	menu_btn.text = " MAIN MENU "
	menu_btn.custom_minimum_size = Vector2(220, 50)
	menu_btn.pressed.connect(func():
		current_level = 1
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)

func reset_level() -> void:
	is_game_over = false
	get_tree().reload_current_scene()
