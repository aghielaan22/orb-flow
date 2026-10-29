extends Node2D

static var current_level: int = 1
static var total_score: int = 0

var stars: Array = []
var total_level_stars: int = 0
var collected_stars: int = 0
var stars_label: Label = null

# Keep track of active hazards spawned via code
var code_hazards: Array = []

var is_drawing: bool = false
var current_line: Line2D = null
var current_collision: StaticBody2D = null
var points: Array = []

var orb: RigidBody2D = null
var spawn_position: Vector2 = Vector2(360, 150)

var level_label: Label = null
var score_label: Label = null
var is_game_over: bool = false
var is_paused: bool = false
var has_started_simulation: bool = false
var level_start_time: float = 0.0
var pause_canvas: CanvasLayer = null

var sfx_player: AudioStreamPlayer = null

# Screen Shake Variables
var camera: Camera2D = null
var shake_timer: float = 0.0
var shake_intensity: float = 0.0

func _ready() -> void:
	print("--- DEV CHEATS ACTIVE ---")
	print("[1-7]: Jump to Level | [N]: Skip Level | [R]: Restart | [ESC]: Pause")
	print("Orb Flow - Level " + str(current_level) + " Loaded (Streamlined Mode)!")
	setup_audio_system()
	setup_camera()
	setup_game_elements()
	spawn_orb()
	# Example 1: A hazard starting at X: 360, Y: 400, moving at speed 180, spanning 200 pixels right/left
	spawn_code_hazard(Vector2(360, 400), 180.0, 200.0, Vector2.RIGHT)
	# Example 2: Another hazard lower down on the screen moving left
	spawn_code_hazard(Vector2(360, 700), 220.0, 150.0, Vector2.LEFT)

func setup_camera() -> void:
	camera = Camera2D.new()
	camera.position = Vector2(360, 640)
	camera.enabled = true
	add_child(camera)
	print("[Juice] Screen Shake Camera Initialized.")

func trigger_screen_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_timer = duration
	
func trigger_screen_flash(flash_color: Color, duration: float = 0.2) -> void:
	var flash = ColorRect.new()
	flash.color = flash_color
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Put it on a high canvas layer so it overlays everything
	var canvas = CanvasLayer.new()
	canvas.layer = 150
	canvas.add_child(flash)
	
	# Attach to self so it clears automatically when the level reloads
	add_child(canvas)
	
	# Tween to fade out and free
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration)
	await tween.finished
	if is_instance_valid(canvas):
		canvas.queue_free()

func _process(delta: float) -> void:
	if shake_timer > 0:
		shake_timer -= delta
		if camera and is_instance_valid(camera):
			camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
	else:
		if camera and is_instance_valid(camera):
			camera.offset = Vector2.ZERO

func setup_audio_system() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

func play_cyber_sfx(sound_type: String) -> void:
	var sample_rate = 22050
	var duration = 0.1
	var freq = 440.0
	
	match sound_type:
		"draw":
			duration = 0.03
			freq = 920.0
		"bounce":
			duration = 0.06
			freq = 587.33 # D5 note for crisp bounce
		"star":
			duration = 0.25
			freq = 1318.51 # E6 high chime for star collection
		"victory":
			duration = 0.35
			freq = 1046.50
		"hazard":
			duration = 0.25
			freq = 110.0 # Low sci-fi sub buzz for danger

	var num_samples = int(sample_rate * duration)
	var buffer = PackedByteArray()
	buffer.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var envelope = 1.0 - (float(i) / num_samples) # Fade out smoothly
		var wave = sin(t * freq * TAU) * envelope
		var val = int(wave * 14000)
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
	
	# Helper styling function for top bar buttons
	var top_btn_style = StyleBoxFlat.new()
	top_btn_style.bg_color = Color(0.06, 0.04, 0.12, 0.9)
	top_btn_style.border_width_left = 2
	top_btn_style.border_width_top = 2
	top_btn_style.border_width_right = 2
	top_btn_style.border_width_bottom = 2
	top_btn_style.border_color = Color(0.0, 0.9, 1.0)
	top_btn_style.corner_radius_top_left = 6
	top_btn_style.corner_radius_top_right = 6
	top_btn_style.corner_radius_bottom_left = 6
	top_btn_style.corner_radius_bottom_right = 6

	var reset_button = Button.new()
	reset_button.text = "↺"
	reset_button.position = Vector2(25, 30)
	reset_button.custom_minimum_size = Vector2(50, 50)
	reset_button.add_theme_font_size_override("font_size", 22)
	reset_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	reset_button.add_theme_stylebox_override("normal", top_btn_style)
	reset_button.add_theme_stylebox_override("hover", top_btn_style)
	reset_button.add_theme_stylebox_override("pressed", top_btn_style)
	reset_button.pressed.connect(reset_level)
	canvas_layer.add_child(reset_button)

	var pause_button = Button.new()
	pause_button.text = "❚❚"
	pause_button.position = Vector2(85, 30)
	pause_button.custom_minimum_size = Vector2(50, 50)
	pause_button.add_theme_font_size_override("font_size", 20)
	pause_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	pause_button.add_theme_stylebox_override("normal", top_btn_style)
	pause_button.add_theme_stylebox_override("hover", top_btn_style)
	pause_button.add_theme_stylebox_override("pressed", top_btn_style)
	pause_button.pressed.connect(toggle_pause)
	canvas_layer.add_child(pause_button)

	var menu_button = Button.new()
	menu_button.text = "MENU"
	menu_button.position = Vector2(145, 30)
	menu_button.custom_minimum_size = Vector2(85, 50)
	menu_button.add_theme_font_size_override("font_size", 16)
	menu_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var menu_style = top_btn_style.duplicate()
	menu_style.border_color = Color(1.0, 0.0, 0.4)
	menu_button.add_theme_stylebox_override("normal", menu_style)
	menu_button.add_theme_stylebox_override("hover", menu_style)
	menu_button.add_theme_stylebox_override("pressed", menu_style)
	
	menu_button.pressed.connect(func() -> void: 
		get_tree().paused = false
		current_level = 1 
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	canvas_layer.add_child(menu_button)

	level_label = Label.new()
	level_label.text = "LVL " + str(current_level)
	level_label.position = Vector2(250, 42)
	level_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))
	level_label.add_theme_font_size_override("font_size", 20)
	canvas_layer.add_child(level_label)

	score_label = Label.new()
	score_label.text = "PTS: " + str(total_score)
	score_label.position = Vector2(350, 42)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	score_label.add_theme_font_size_override("font_size", 20)
	canvas_layer.add_child(score_label)

	stars_label = Label.new()
	stars_label.text = "★ 0/0"
	stars_label.position = Vector2(560, 42)
	stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	stars_label.add_theme_font_size_override("font_size", 20)
	canvas_layer.add_child(stars_label)

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
	stars.clear()
	collected_stars = 0
	
	match current_level:
		1:
			setup_hazard(Vector2(360, 650), Vector2(260, 24))
			setup_star(Vector2(260, 500))
		3:
			setup_hazard(Vector2(200, 500), Vector2(240, 20))
			setup_hazard(Vector2(520, 800), Vector2(240, 20))
			setup_star(Vector2(180, 450))
			setup_star(Vector2(560, 950))
		5:
			setup_hazard(Vector2(360, 620), Vector2(320, 20))
			setup_star(Vector2(180, 350))
			setup_star(Vector2(540, 950))
		7:
			setup_hazard(Vector2(240, 500), Vector2(200, 20))
			setup_hazard(Vector2(480, 820), Vector2(200, 20))
			setup_star(Vector2(120, 320))
			setup_star(Vector2(600, 600))
			setup_star(Vector2(360, 1020))
		_:
			setup_hazard(Vector2(360, 700), Vector2(300, 20))
			setup_star(Vector2(260, 500))
		
	total_level_stars = stars.size()
	update_stars_ui()

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

func setup_star(pos: Vector2) -> void:
	var star_area = Area2D.new()
	star_area.position = pos
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 25.0
	shape.shape = circle
	star_area.add_child(shape)
	
	var visual = Line2D.new()
	visual.width = 4.0
	visual.default_color = Color(1.0, 0.85, 0.0)
	for i in range(11):
		var angle = i * (PI * 2 / 10)
		var r = 20.0 if i % 2 == 0 else 10.0
		visual.add_point(Vector2(cos(angle) * r, sin(angle) * r))
	star_area.add_child(visual)
	
	star_area.body_entered.connect(func(body):
		if body == orb and star_area in stars:
			stars.erase(star_area)
			collected_stars += 1
			play_cyber_sfx("bounce")
			play_cyber_sfx("star")
			trigger_screen_flash(Color(1.0, 0.85, 0.0, 0.4), 0.15) # Gold flash
			spawn_success_burst(star_area.global_position, self)
			star_area.queue_free()
			update_stars_ui()
			print("Star collected! ", collected_stars, "/", total_level_stars)
	)
	
	add_child(star_area)
	stars.append(star_area)

func update_stars_ui() -> void:
	if stars_label:
		stars_label.text = "★ " + str(collected_stars) + " / " + str(total_level_stars)

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
	
	var trail = Line2D.new()
	trail.name = "NeonTrail"
	trail.top_level = true
	trail.width = 10.0
	trail.default_color = Color(0.0, 0.9, 1.0, 0.7)
	trail.antialiased = true
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	orb.add_child(trail)
	
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
		if event.keycode >= KEY_1 and event.keycode <= KEY_7:
			current_level = event.keycode - KEY_0
			if current_level in [2, 4, 6]:
				get_tree().change_scene_to_file("res://space_shooter.tscn")
			else:
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
			# Transform local position to canvas coordinates to match scaled viewports
			var pos = get_canvas_transform().affine_inverse() * event.position
			if event.pressed:
				start_drawing(pos)
			else:
				stop_drawing()
			
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		if is_drawing:
			var pos = get_canvas_transform().affine_inverse() * event.position
			add_point_to_line(pos)

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	play_cyber_sfx("bounce")
	
	if is_paused:
		show_pause_screen()
	else:
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()

func create_pause_button(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.05, 0.16, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func show_pause_screen() -> void:
	pause_canvas = CanvasLayer.new()
	pause_canvas.layer = 100
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Dim backdrop
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.05, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(center)
	
	# Styled Panel Container for perfect centering & cyberpunk border matching overlays
	var overlay_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.0, 0.9, 1.0) # Cyberpunk Cyan
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 35
	style.content_margin_right = 35
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	overlay_panel.add_theme_stylebox_override("panel", style)
	center.add_child(overlay_panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.add_theme_constant_override("separation", 18)
	overlay_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer)
	
	# Resume Button
	create_pause_button(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func():
		toggle_pause()
	)
	
	# Restart Button
	create_pause_button(vbox, "↺ RESTART TERMINAL", Color(1.0, 0.0, 0.6), func():
		get_tree().paused = false
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()
		reset_level()
	)
	
	# Menu Button
	create_pause_button(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		get_tree().paused = false
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()
		current_level = 1
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	
	add_child(pause_canvas)

# --- RESTORED ORIGINAL VICTORY SCREEN ---
func show_victory_screen() -> void:
	is_drawing = false
	
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
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
	var next_target_level = current_level + 1
	
	if next_target_level in [2, 4, 6]:
		next_btn.text = " ▶ LAUNCH SPACE SHOOTER (LEVEL " + str(next_target_level) + ") "
	elif next_target_level > 7:
		next_btn.text = " GAME COMPLETED! RESTART "
	else:
		next_btn.text = " NEXT TERMINAL (LEVEL " + str(next_target_level) + ") "
		
	next_btn.custom_minimum_size = Vector2(320, 50)
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_btn.pressed.connect(func() -> void:
		current_level += 1
		if current_level > 7:
			current_level = 1
			total_score = 0
			get_tree().change_scene_to_file("res://menu.tscn")
		elif current_level in [2, 4, 6]:
			get_tree().change_scene_to_file("res://space_shooter.tscn")
		else:
			get_tree().reload_current_scene()
	)
	vbox.add_child(next_btn)
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)
	
	var menu_btn = Button.new()
	menu_btn.text = " MENU "
	menu_btn.custom_minimum_size = Vector2(320, 50)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func() -> void:
		current_level = 1
		total_score = 0
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)

func start_drawing(pos: Vector2) -> void:
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
	if points.size() > 0 and pos.distance_to(points[-1]) < 10.0:
		return
		
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
		if collected_stars < total_level_stars:
			print("Goal locked! Collect all stars first: ", collected_stars, "/", total_level_stars)
			play_cyber_sfx("hazard")
			return
			
		is_game_over = true
		play_cyber_sfx("victory")
		trigger_screen_flash(Color(0.0, 1.0, 0.9, 0.5), 0.4) # Cyan cyber flash
		trigger_screen_shake(10.0, 0.35)
		
		var goal_node = get_node_or_null("GoalArea")
		if goal_node:
			spawn_success_burst(goal_node.global_position, self)
		
		var elapsed_time = (Time.get_ticks_msec() - level_start_time) / 1000.0
		var time_bonus = max(0, int(100 - (elapsed_time * 2)))
		var star_bonus = collected_stars * 200
		var level_score = 500 + time_bonus + star_bonus
		
		total_score += level_score
		print("VICTORY! Level score: ", level_score, " | Total Score: ", total_score)
		
		submit_score_to_huawei_leaderboard(total_score)
		call_deferred("show_victory_screen")

func _on_hazard_entered(body: Node2D) -> void:
	if body == orb and not is_game_over:
		is_game_over = true
		play_cyber_sfx("hazard")
		trigger_screen_flash(Color(1.0, 0.0, 0.4, 0.6), 0.3) # Crimson
		trigger_screen_shake(12.0, 0.4)
		print("OOF! Orb hit a hazard or went out of bounds!")
		
		# Safely defer the reset to prevent physics callback crashes
		call_deferred("reset_level")

func submit_score_to_huawei_leaderboard(score: int) -> void:
	print("[HMS SDK Hook] Submitting total score to Huawei Game Service Leaderboard: ", score)

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

func spawn_code_hazard(spawn_pos: Vector2, speed: float, limit: float, direction: Vector2) -> void:
	var hazard = Area2D.new()
	# Load and attach your moving_hazard.gd script
	hazard.set_script(load("res://moving_hazard.gd"))
	hazard.position = spawn_pos
	
	# Pass the custom parameters into the hazard script variables
	hazard.move_speed = speed
	hazard.travel_limit = limit
	hazard.move_direction = direction
	
	# Add it to the scene tree
	add_child(hazard)
	
	# Call the visual setup function inside the hazard script
	if hazard.has_method("setup_visual"):
		hazard.setup_visual()
		
	# Track it in our array
	code_hazards.append(hazard)

func start_bonus_minigame() -> void:
	get_tree().change_scene_to_file("res://space_shooter.tscn")

func complete_level_one() -> void:
	print("Level 1 Complete! Launching Space Shooter (Level 2)")
	get_tree().change_scene_to_file("res://space_shooter.tscn")
