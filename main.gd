extends Node2D

static var current_level: int = 1
static var total_score: int = 0

var is_drawing: bool = false
var current_line: Line2D = null
var current_collision: StaticBody2D = null
var points: Array = []

var orb: RigidBody2D = null
var spawn_position: Vector2 = Vector2(360, 150)

var max_ink: float = 800.0
var current_ink: float = 800.0
var ink_bar: ProgressBar = null
var level_label: Label = null
var score_label: Label = null
var is_game_over: bool = false
var is_paused: bool = false
var has_started_simulation: bool = false
var level_start_time: float = 0.0
var pause_canvas: CanvasLayer = null

var gravity_wells: Array = []
var sfx_player: AudioStreamPlayer = null

# Screen Shake Variables
var camera: Camera2D = null
var shake_timer: float = 0.0
var shake_intensity: float = 0.0

func _ready() -> void:
	DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	print("--- DEV CHEATS ACTIVE ---")
	print("[1-6]: Jump to Level | [N]: Skip Level | [R]: Restart | [ESC]: Pause")
	print("Orb Flow - Level " + str(current_level) + " Loaded (Juiced Mode)!")
	setup_audio_system()
	setup_camera()
	setup_game_elements()
	spawn_orb()

func setup_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(360, 640)
	camera.enabled = true
	add_child(camera)
	print("[Juice] Screen Shake Camera Initialized.")

func trigger_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration

func _process(delta: float) -> void:
	# Handle Screen Shake Offset translation
	if shake_timer > 0:
		shake_timer -= delta
		if camera and is_instance_valid(camera):
			camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		if camera and is_instance_valid(camera):
			camera.offset = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not has_started_simulation or is_game_over or is_paused:
		return
		
	var time_sec = Time.get_ticks_msec() * 0.001
	
	for i in range(gravity_wells.size()):
		var well = gravity_wells[i]
		if well != null and is_instance_valid(well):
			var phase = time_sec * 2.5 + (i * 1.5)
			var cycle = sin(phase)
			
			well.set_meta("cycle_value", cycle)
			
			var outer_ring = well.get_node_or_null("OuterRing") as Line2D
			if outer_ring:
				if cycle > 0.0:
					outer_ring.default_color = Color(0.0, 0.9, 1.0, 0.8)
					outer_ring.scale = Vector2.ONE * (1.0 + (cycle * 0.25))
				else:
					outer_ring.default_color = Color(1.0, 0.0, 0.6, 0.9)
					outer_ring.scale = Vector2.ONE * (1.0 + (cycle * 0.2))

			if orb != null and is_instance_valid(orb) and not is_game_over:
				var dir = well.global_position - orb.global_position
				var dist = dir.length()
				if dist < 400.0 and dist > 15.0:
					var force_magnitude = cycle * 22000.0 / (dist + 30.0)
					var force = dir.normalized() * force_magnitude
					orb.apply_central_force(force * delta * 60.0)

func setup_audio_system() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func play_cyber_sfx(sound_type: String) -> void:
	var sample_rate = 22050
	var duration = 0.1
	var freq = 440.0
	
	match sound_type:
		"draw":
			duration = 0.04
			freq = 880.0
		"bounce":
			duration = 0.08
			freq = 523.25
		"victory":
			duration = 0.3
			freq = 1046.50
		"hazard":
			duration = 0.2
			freq = 150.0

	var num_samples = int(sample_rate * duration)
	var buffer = PackedByteArray()
	buffer.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var wave = sin(t * freq * TAU)
		var val = int(wave * 12000)
		buffer.encode_s16(i * 2, val)

	var sample_stream = AudioStreamWAV.new()
	sample_stream.format = AudioStreamWAV.FORMAT_16_BITS
	sample_stream.mix_rate = sample_rate
	sample_stream.data = buffer

	sfx_player.stream = sample_stream
	sfx_player.play()

func setup_game_elements() -> void:
	setup_vaporwave_background()
	setup_screen_borders()

	var goal_area = Area2D.new()
	goal_area.name = "GoalArea"
	goal_area.position = Vector2(550, 1100)
	
	var goal_shape = CollisionShape2D.new()
	var goal_circle = CircleShape2D.new()
	goal_circle.radius = 55.0
	goal_shape.shape = goal_circle
	goal_area.add_child(goal_shape)
	
	var goal_visual = Line2D.new()
	goal_visual.width = 8.0
	goal_visual.default_color = Color(1.0, 0.7, 0.0)
	for i in range(33):
		var angle = i * (PI * 2 / 32)
		goal_visual.add_point(Vector2(cos(angle) * 50, sin(angle) * 50))
	goal_area.add_child(goal_visual)

	var inner_core = Line2D.new()
	inner_core.width = 4.0
	inner_core.default_color = Color(0.0, 1.0, 0.9)
	for i in range(17):
		var angle = i * (PI * 2 / 16)
		inner_core.add_point(Vector2(cos(angle) * 25, sin(angle) * 25))
	goal_area.add_child(inner_core)
	
	goal_area.body_entered.connect(_on_goal_entered)
	add_child(goal_area)

	setup_level_configuration()

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 5
	
	var reset_button = Button.new()
	reset_button.text = " ↺ "
	reset_button.position = Vector2(20, 40)
	reset_button.custom_minimum_size = Vector2(45, 40)
	reset_button.pressed.connect(reset_level)
	canvas_layer.add_child(reset_button)

	var pause_button = Button.new()
	pause_button.text = " ⏸ "
	pause_button.position = Vector2(70, 40)
	pause_button.custom_minimum_size = Vector2(45, 40)
	pause_button.pressed.connect(toggle_pause)
	canvas_layer.add_child(pause_button)

	var menu_button = Button.new()
	menu_button.text = " MENU "
	menu_button.position = Vector2(120, 40)
	menu_button.pressed.connect(func() -> void: 
		get_tree().paused = false
		current_level = 1 
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	canvas_layer.add_child(menu_button)

	level_label = Label.new()
	level_label.text = "LVL " + str(current_level)
	level_label.position = Vector2(210, 47)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))
	level_label.add_theme_font_size_override("font_size", 16)
	canvas_layer.add_child(level_label)

	score_label = Label.new()
	score_label.text = "PTS: " + str(total_score)
	score_label.position = Vector2(280, 47)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	score_label.add_theme_font_size_override("font_size", 16)
	canvas_layer.add_child(score_label)

	ink_bar = ProgressBar.new()
	ink_bar.position = Vector2(380, 48)
	ink_bar.custom_minimum_size = Vector2(300, 20)
	ink_bar.max_value = max_ink
	ink_bar.value = current_ink
	ink_bar.show_percentage = false
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.0, 0.9, 1.0)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	ink_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.18, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	ink_bar.add_theme_stylebox_override("background", bg_style)
	
	canvas_layer.add_child(ink_bar)
	add_child(canvas_layer)

func setup_vaporwave_background() -> void:
	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	
	var bg_node = VaporwaveBackground.new()
	bg_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_layer.add_child(bg_node)
	
	var particles = CPUParticles2D.new()
	particles.position = Vector2(360, 640)
	particles.amount = 45
	particles.lifetime = 5.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(360, 640)
	particles.direction = Vector2(0, -1)
	particles.spread = 40.0
	particles.gravity = Vector2(0, -15)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 45.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.0, 1.0, 0.9, 0.6)
	bg_layer.add_child(particles)
	
	add_child(bg_layer)

func setup_screen_borders() -> void:
	var left_wall = StaticBody2D.new()
	left_wall.position = Vector2(-10, 640)
	var left_shape = CollisionShape2D.new()
	var left_box = RectangleShape2D.new()
	left_box.size = Vector2(20, 1280)
	left_shape.shape = left_box
	left_wall.add_child(left_shape)
	add_child(left_wall)
	
	var right_wall = StaticBody2D.new()
	right_wall.position = Vector2(730, 640)
	var right_shape = CollisionShape2D.new()
	var right_box = RectangleShape2D.new()
	right_box.size = Vector2(20, 1280)
	right_shape.shape = right_box
	right_wall.add_child(right_shape)
	add_child(right_wall)
	
	var death_area = Area2D.new()
	death_area.position = Vector2(360, 1310)
	var death_shape = CollisionShape2D.new()
	var death_box = RectangleShape2D.new()
	death_box.size = Vector2(800, 50)
	death_shape.shape = death_box
	death_area.add_child(death_shape)
	death_area.body_entered.connect(_on_hazard_entered)
	add_child(death_area)

func setup_level_configuration() -> void:
	gravity_wells.clear()
	
	if current_level == 1:
		max_ink = 800.0
		setup_hazard(Vector2(360, 700), Vector2(300, 20))
	elif current_level == 2:
		max_ink = 650.0
		setup_hazard(Vector2(240, 600), Vector2(220, 20))
		setup_hazard(Vector2(480, 850), Vector2(220, 20))
	elif current_level == 3:
		max_ink = 500.0
		setup_hazard(Vector2(360, 550), Vector2(260, 18))
		setup_hazard(Vector2(200, 800), Vector2(180, 18))
		setup_hazard(Vector2(520, 950), Vector2(180, 18))
	elif current_level == 4:
		max_ink = 600.0
		setup_hazard(Vector2(360, 680), Vector2(320, 18))
		setup_gravity_well(Vector2(360, 450))
	elif current_level == 5:
		max_ink = 500.0
		setup_hazard(Vector2(240, 580), Vector2(200, 18))
		setup_hazard(Vector2(480, 820), Vector2(200, 18))
		setup_gravity_well(Vector2(360, 700))
	else:
		current_level = 6
		max_ink = 420.0
		setup_hazard(Vector2(360, 600), Vector2(260, 16))
		setup_gravity_well(Vector2(220, 420))
		setup_gravity_well(Vector2(500, 880))
		
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

func setup_gravity_well(pos: Vector2) -> void:
	var well_area = Area2D.new()
	well_area.position = pos
	well_area.set_meta("cycle_value", 0.0)
	gravity_wells.append(well_area)
	
	var core = Line2D.new()
	core.width = 4.0
	core.default_color = Color(1.0, 1.0, 1.0)
	for i in range(17):
		var angle = i * (PI * 2 / 16)
		core.add_point(Vector2(cos(angle) * 22, sin(angle) * 22))
	well_area.add_child(core)
	
	var outer_ring = Line2D.new()
	outer_ring.name = "OuterRing"
	outer_ring.width = 3.0
	outer_ring.default_color = Color(0.0, 0.9, 1.0, 0.8)
	for i in range(25):
		var angle = i * (PI * 2 / 24)
		outer_ring.add_point(Vector2(cos(angle) * 50, sin(angle) * 50))
	well_area.add_child(outer_ring)
	
	add_child(well_area)

func spawn_orb() -> void:
	if orb:
		orb.queue_free()
		
	has_started_simulation = false
	
	orb = RigidBody2D.new()
	orb.name = "Orb"
	orb.position = spawn_position
	orb.freeze = true
	orb.max_contacts_reported = 4
	orb.contact_monitor = true
	
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = 0.8
	phys_mat.friction = 0.1
	orb.physics_material_override = phys_mat
	
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 20.0
	collision.shape = circle
	orb.add_child(collision)
	
	var glow_visual = Line2D.new()
	glow_visual.width = 30.0
	glow_visual.default_color = Color(0.1, 0.8, 1.0, 0.3)
	glow_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	glow_visual.add_point(Vector2(-1, 0))
	glow_visual.add_point(Vector2(1, 0))
	orb.add_child(glow_visual)

	var orb_visual = Line2D.new()
	orb_visual.width = 20.0
	orb_visual.default_color = Color(0.2, 1.0, 0.6)
	orb_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	orb_visual.end_cap_mode = Line2D.LINE_CAP_ROUND
	orb_visual.add_point(Vector2(-1, 0))
	orb_visual.add_point(Vector2(1, 0))
	orb.add_child(orb_visual)
	
	# Neon Trail attached smoothly behind the moving orb
	var trail = Line2D.new()
	trail.name = "NeonTrail"
	trail.top_level = true
	trail.width = 10.0
	trail.default_color = Color(0.0, 0.9, 1.0, 0.7)
	trail.antialiased = true
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	orb.add_child(trail)
	
	var trail_script = GDScript.new()
	trail_script.source_code = """
extends Line2D
var target: Node2D = null
func _ready() -> void:
	target = get_parent()
func _process(_delta: float) -> void:
	if target and is_instance_valid(target):
		add_point(target.global_position)
		if get_point_count() > 25:
			remove_point(0)
"""
	
	# Trigger camera shake on high-velocity impact
	orb.body_entered.connect(func(_body): 
		play_cyber_sfx("bounce")
		if orb.linear_velocity.length() > 250.0:
			trigger_screen_shake(5.0, 0.15)
	)
	add_child(orb)

func spawn_success_burst(at_position: Vector2, parent_node: Node) -> void:
	var burst = CPUParticles2D.new()
	burst.global_position = at_position
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 50
	burst.lifetime = 0.8
	burst.explosiveness = 1.0
	
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.initial_velocity_min = 120.0
	burst.initial_velocity_max = 280.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 8.0
	burst.color = Color(1.0, 0.0, 0.6)
	
	parent_node.add_child(burst)
	burst.emitting = true
	
	_cleanup_node_after_delay(burst, 1.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			current_level = 1
			get_tree().reload_current_scene()
		elif event.keycode == KEY_2:
			current_level = 2
			get_tree().reload_current_scene()
		elif event.keycode == KEY_3:
			current_level = 3
			get_tree().reload_current_scene()
		elif event.keycode == KEY_4:
			current_level = 4
			get_tree().reload_current_scene()
		elif event.keycode == KEY_5:
			current_level = 5
			get_tree().reload_current_scene()
		elif event.keycode == KEY_6:
			current_level = 6
			get_tree().reload_current_scene()
		elif event.keycode == KEY_N:
			if orb and not is_game_over:
				var goal_node = get_node_or_null("GoalArea")
				if goal_node:
					_on_goal_entered(orb)
		elif event.keycode == KEY_R:
			reset_level()

	if event.is_action_pressed("ui_cancel") and not is_game_over:
		toggle_pause()
		return
		
	if is_game_over or is_paused:
		return
		
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.pressed:
			start_drawing(event.position)
		else:
			stop_drawing()
			
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_drawing:
			add_point_to_line(event.position)

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	play_cyber_sfx("bounce")
	
	if is_paused:
		show_pause_screen()
	else:
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()

func show_pause_screen() -> void:
	pause_canvas = CanvasLayer.new()
	pause_canvas.layer = 100
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_canvas.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)
	
	var resume_btn = Button.new()
	resume_btn.text = " RESUME "
	resume_btn.custom_minimum_size = Vector2(240, 50)
	resume_btn.pressed.connect(toggle_pause)
	vbox.add_child(resume_btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)
	
	var restart_btn = Button.new()
	restart_btn.text = " RESTART TERMINAL "
	restart_btn.custom_minimum_size = Vector2(240, 50)
	restart_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		reset_level()
	)
	vbox.add_child(restart_btn)
	
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer3)
	
	var menu_btn = Button.new()
	menu_btn.text = " MAIN MENU "
	menu_btn.custom_minimum_size = Vector2(240, 50)
	menu_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		current_level = 1
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(pause_canvas)

func start_drawing(pos: Vector2) -> void:
	if current_ink <= 0:
		return
		
	is_drawing = true
	points = [pos]
	
	current_line = Line2D.new()
	current_line.width = 12.0
	current_line.default_color = Color(0.0, 0.9, 1.0)
	current_line.joint_mode = Line2D.LINE_JOINT_ROUND
	current_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	current_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(current_line)
	current_line.add_point(pos)
	
	current_collision = StaticBody2D.new()
	add_child(current_collision)
	play_cyber_sfx("draw")

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
	
	spawn_spark(pos)
	
	if points.size() >= 2:
		var p1 = points[-2]
		var p2 = points[-1]
		
		var collision_shape = CollisionShape2D.new()
		var segment = SegmentShape2D.new()
		segment.a = p1
		segment.b = p2
		
		var line_mat = PhysicsMaterial.new()
		line_mat.bounce = 0.5
		collision_shape.material = line_mat
		
		collision_shape.shape = segment
		current_collision.add_child(collision_shape)
		
	if current_ink <= 0:
		stop_drawing()

func spawn_spark(pos: Vector2) -> void:
	var spark = CPUParticles2D.new()
	spark.position = pos
	spark.emitting = true
	spark.one_shot = true
	spark.amount = 6
	spark.lifetime = 0.4
	spark.initial_velocity_min = 40.0
	spark.initial_velocity_max = 90.0
	spark.scale_amount_min = 3.0
	spark.scale_amount_max = 7.0
	spark.color = Color(1.0, 0.0, 1.0)
	add_child(spark)
	
	_cleanup_node_after_delay(spark, 0.5)

func _cleanup_node_after_delay(node: Node, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if node != null and is_instance_valid(node):
		node.queue_free()

func stop_drawing() -> void:
	if is_drawing:
		is_drawing = false
		if not has_started_simulation:
			has_started_simulation = true
			level_start_time = Time.get_ticks_msec()
			if orb != null and is_instance_valid(orb):
				orb.freeze = false
			print("[Orb Flow] First line completed. Simulation initiated!")

func _on_goal_entered(body: Node2D) -> void:
	if body == orb and not is_game_over:
		is_game_over = true
		play_cyber_sfx("victory")
		trigger_screen_shake(10.0, 0.35)
		
		var goal_node = get_node_or_null("GoalArea")
		if goal_node:
			spawn_success_burst(goal_node.global_position, self)
		
		var elapsed_time = (Time.get_ticks_msec() - level_start_time) / 1000.0
		var time_bonus = max(0, int(100 - (elapsed_time * 2)))
		var ink_bonus = int(current_ink)
		var level_score = 500 + ink_bonus + time_bonus
		
		total_score += level_score
		print("VICTORY! Level score: ", level_score, " | Total Score: ", total_score)
		
		submit_score_to_huawei_leaderboard(total_score)
		show_victory_screen()

func _on_hazard_entered(body: Node2D) -> void:
	if body == orb and not is_game_over:
		is_game_over = true
		play_cyber_sfx("hazard")
		trigger_screen_shake(12.0, 0.4)
		print("OOF! Orb hit a hazard or went out of bounds!")
		call_deferred("reset_level")

func submit_score_to_huawei_leaderboard(score: int) -> void:
	print("[HMS SDK Hook] Submitting total score to Huawei Game Service Leaderboard: ", score)

func show_victory_screen() -> void:
	is_drawing = false
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
	# --- PERFECTLY CENTERED VICTORY PANEL ---
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center_container)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(450, 400)
	center_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "TERMINAL " + str(current_level) + " CLEARED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	vbox.add_child(title)
	
	var spacer_top = Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer_top)
	
	var score_display = Label.new()
	score_display.text = "TOTAL SYNC SCORE: " + str(total_score)
	score_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_display.add_theme_font_size_override("font_size", 18)
	score_display.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(score_display)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 35)
	vbox.add_child(spacer)
	
	var next_btn = Button.new()
	next_btn.text = " NEXT TERMINAL "
	next_btn.custom_minimum_size = Vector2(280, 50)
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_btn.pressed.connect(func() -> void:
		current_level += 1
		if current_level > 6:
			current_level = 1
		get_tree().reload_current_scene()
	)
	vbox.add_child(next_btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)
	
	var menu_btn = Button.new()
	menu_btn.text = " MENU "
	menu_btn.custom_minimum_size = Vector2(280, 50)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func() -> void:
		current_level = 1
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)

func reset_level() -> void:
	is_game_over = false
	is_paused = false
	has_started_simulation = false
	get_tree().paused = false
	get_tree().reload_current_scene()

class VaporwaveBackground extends Control:
	var scroll_offset: float = 0.0
	
	func _process(delta: float) -> void:
		scroll_offset += delta * 40.0
		if scroll_offset > 100.0:
			scroll_offset = 0.0
		queue_redraw()
		
	func _draw() -> void:
		var sz = size
		var horizon_y = sz.y * 0.50
		
		draw_rect(Rect2(0, 0, sz.x, horizon_y), Color(0.08, 0.02, 0.18))
		
		var sun_center = Vector2(sz.x * 0.5, horizon_y - 20)
		var sun_radius = 80.0
		for i in range(10):
			var r = sun_radius - (i * 5)
			var alpha = 0.15 + (i * 0.04)
			draw_circle(sun_center, r, Color(1.0, 0.3, 0.6, alpha))
		
		for y_off in range(-int(sun_radius), int(sun_radius), 12):
			if y_off > 0:
				var slice_y = sun_center.y + y_off
				var w = sqrt(sun_radius * sun_radius - y_off * y_off)
				draw_rect(Rect2(sun_center.x - w, slice_y, w * 2, 4), Color(0.08, 0.02, 0.18))

		var mountain_color = Color(0.05, 0.02, 0.12)
		var wire_color = Color(1.0, 0.0, 0.6, 0.4)
		
		var peaks = [
			Vector2(0, horizon_y),
			Vector2(120, horizon_y - 120),
			Vector2(260, horizon_y - 60),
			Vector2(400, horizon_y - 160),
			Vector2(560, horizon_y - 90),
			Vector2(720, horizon_y)
		]
		
		var poly_points = PackedVector2Array()
		poly_points.append(Vector2(0, horizon_y))
		for p in peaks: poly_points.append(p)
		poly_points.append(Vector2(sz.x, horizon_y))
		draw_polygon(poly_points, PackedColorArray([mountain_color]))
		
		for i in range(peaks.size() - 1):
			draw_line(peaks[i], peaks[i+1], wire_color, 2.0)

		draw_rect(Rect2(0, horizon_y, sz.x, sz.y - horizon_y), Color(0.02, 0.01, 0.06))
		draw_line(Vector2(0, horizon_y), Vector2(sz.x, horizon_y), Color(0.0, 1.0, 0.9), 3.0)
		
		var num_lines = 12
		for i in range(num_lines):
			var progress = fmod((float(i) + scroll_offset / 40.0), num_lines) / num_lines
			var y = horizon_y + pow(progress, 2.0) * (sz.y - horizon_y)
			var alpha = progress * 0.7
			draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.0, 0.9, 1.0, alpha), 1.5)
