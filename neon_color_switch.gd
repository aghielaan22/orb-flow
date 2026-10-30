extends Control

var player_color_index: int = 0
var available_colors = [
	Color(1.0, 0.0, 0.4), # Neon Pink
	Color(0.0, 0.9, 1.0), # Cyber Cyan
	Color(1.0, 0.85, 0.0) # Electric Yellow
]

var score: int = 0
var target_score: int = 25
var obstacles: Array = []
var game_timer: Timer = null

var player_visual: ColorRect = null
var score_label: Label = null
var arena_control: Control = null
var is_paused: bool = false
var game_active: bool = false # Ensures game doesn't run in background until start button is clicked
var pause_canvas: CanvasLayer = null
var start_canvas: CanvasLayer = null

var screen_size: Vector2 = Vector2(720, 1280)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	setup_matrix_background()
	setup_ui()
	setup_game_loop()

	# --- SHOW READY START PROMPT & HALT GAMEPLAY ---
	game_active = false
	show_start_prompt()

	# --- ADD LEVEL INTRO POPUP FOR TERMINAL 6 ---
	if ResourceLoader.exists("res://level_intro.gd"):
		var intro = load("res://level_intro.gd").new(6)
		get_tree().root.add_child(intro)

func setup_matrix_background() -> void:
	var bg = MatrixRainBackground.new()
	bg.name = "MatrixRainBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func setup_ui() -> void:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(720, 1280)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 0)
	center.add_child(vbox)
	
	# --- TOP HUD AREA ---
	var top_bar = MarginContainer.new()
	top_bar.custom_minimum_size = Vector2(720, 120)
	top_bar.add_theme_constant_override("margin_left", 35)
	top_bar.add_theme_constant_override("margin_right", 35)
	top_bar.add_theme_constant_override("margin_top", 40)
	vbox.add_child(top_bar)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_child(top_hbox)
	
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title = Label.new()
	title.text = "TERMINAL 6: COLOR SWITCH"
	title.add_theme_font_size_override("font_size", 24)
	title_box.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	title_box.add_child(title)
	
	score_label = Label.new()
	score_label.text = "SYNC PROGRESS: 0 / " + str(target_score)
	score_label.add_theme_font_size_override("font_size", 15)
	score_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	title_box.add_child(score_label)
	top_hbox.add_child(title_box)
	
	var pause_btn = Button.new()
	pause_btn.text = "❚❚"
	pause_btn.custom_minimum_size = Vector2(55, 55)
	pause_btn.add_theme_font_size_override("font_size", 20)
	pause_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.0, 0.9, 1.0)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	pause_btn.add_theme_stylebox_override("normal", btn_style)
	pause_btn.add_theme_stylebox_override("hover", btn_style)
	pause_btn.add_theme_stylebox_override("pressed", btn_style)
	pause_btn.pressed.connect(toggle_pause_menu)
	top_hbox.add_child(pause_btn)

	# --- MIDDLE FULL-SCREEN DROP ARENA ---
	var arena_wrapper = Control.new()
	arena_wrapper.custom_minimum_size = Vector2(720, 840)
	arena_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arena_wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(arena_wrapper)
	
	arena_control = Control.new()
	arena_control.name = "Arena"
	arena_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arena_wrapper.add_child(arena_control)
	
	# Target Barrier Zone Background Glow
	var barrier_zone = ColorRect.new()
	barrier_zone.custom_minimum_size = Vector2(720, 14)
	barrier_zone.size = Vector2(720, 14)
	barrier_zone.position = Vector2(0, 720)
	barrier_zone.color = Color(1.0, 0.1, 0.2, 0.2)
	arena_control.add_child(barrier_zone)
	
	# Full-Width Stationary Line
	player_visual = ColorRect.new()
	player_visual.custom_minimum_size = Vector2(720, 12)
	player_visual.size = Vector2(720, 12)
	player_visual.position = Vector2(0, 720)
	player_visual.color = available_colors[player_color_index]
	arena_control.add_child(player_visual)

	# --- BOTTOM CONTROLS AREA ---
	var bottom_bar = MarginContainer.new()
	bottom_bar.custom_minimum_size = Vector2(720, 220)
	bottom_bar.add_theme_constant_override("margin_bottom", 45)
	bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bottom_bar)
	
	var color_switch_btn = Button.new()
	color_switch_btn.text = "⚡ SWITCH FREQUENCY COLOR ⚡"
	color_switch_btn.custom_minimum_size = Vector2(560, 110)
	color_switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	color_switch_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	color_switch_btn.add_theme_font_size_override("font_size", 22)
	color_switch_btn.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0))
	
	var yellow_btn_style = StyleBoxFlat.new()
	yellow_btn_style.bg_color = Color(1.0, 0.85, 0.0)
	yellow_btn_style.border_width_left = 3
	yellow_btn_style.border_width_top = 3
	yellow_btn_style.border_width_right = 3
	yellow_btn_style.border_width_bottom = 3
	yellow_btn_style.border_color = Color(1.0, 1.0, 1.0)
	yellow_btn_style.corner_radius_top_left = 25
	yellow_btn_style.corner_radius_top_right = 25
	yellow_btn_style.corner_radius_bottom_left = 25
	yellow_btn_style.corner_radius_bottom_right = 25
	
	color_switch_btn.add_theme_stylebox_override("normal", yellow_btn_style)
	color_switch_btn.add_theme_stylebox_override("hover", yellow_btn_style)
	color_switch_btn.add_theme_stylebox_override("pressed", yellow_btn_style)
	color_switch_btn.pressed.connect(switch_color)
	bottom_bar.add_child(color_switch_btn)

func show_start_prompt() -> void:
	start_canvas = CanvasLayer.new()
	start_canvas.name = "StartPromptCanvas"
	start_canvas.layer = 120
	start_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.06, 0.90)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 300)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	p_style.border_width_left = 3
	p_style.border_width_top = 3
	p_style.border_width_right = 3
	p_style.border_width_bottom = 3
	p_style.border_color = Color(0.0, 0.9, 1.0)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_left = 14
	p_style.corner_radius_bottom_right = 14
	p_style.content_margin_left = 30
	p_style.content_margin_right = 30
	p_style.content_margin_top = 30
	p_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "READY TO SYNCHRONIZE?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "// Match dropping pulses with your frequency line //"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	vbox.add_child(desc)
	
	var start_btn = Button.new()
	start_btn.text = "▶ CLICK HERE TO START"
	start_btn.custom_minimum_size = Vector2(360, 55)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.add_theme_font_size_override("font_size", 16)
	start_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.0, 0.7, 0.5, 0.9)
	b_style.border_width_left = 2
	b_style.border_width_top = 2
	b_style.border_width_right = 2
	b_style.border_width_bottom = 2
	b_style.border_color = Color(0.0, 1.0, 0.8)
	b_style.corner_radius_top_left = 8
	b_style.corner_radius_top_right = 8
	b_style.corner_radius_bottom_left = 8
	b_style.corner_radius_bottom_right = 8
	start_btn.add_theme_stylebox_override("normal", b_style)
	start_btn.add_theme_stylebox_override("hover", b_style)
	start_btn.add_theme_stylebox_override("pressed", b_style)
	
	start_btn.pressed.connect(func():
		game_active = true
		if is_instance_valid(start_canvas):
			start_canvas.queue_free()
	)
	vbox.add_child(start_btn)
	
	get_tree().root.add_child(start_canvas)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = not is_paused
	game_active = not is_paused
	if is_paused:
		show_pause_overlay()
	else:
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()

func show_pause_overlay() -> void:
	pause_canvas = CanvasLayer.new()
	pause_canvas.name = "PauseOverlay"
	pause_canvas.layer = 100
	pause_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.05, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_canvas.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	create_menu_btn(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func(): toggle_pause_menu())
	create_menu_btn(vbox, "↺ RESTART TERMINAL", Color(1.0, 0.0, 0.6), func():
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()
		get_tree().reload_current_scene()
	)
	create_menu_btn(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	add_child(pause_canvas)

func create_menu_btn(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
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

func switch_color() -> void:
	player_color_index = (player_color_index + 1) % available_colors.size()
	player_visual.color = available_colors[player_color_index]

func setup_game_loop() -> void:
	game_timer = Timer.new()
	game_timer.wait_time = 1.25
	game_timer.autostart = true
	game_timer.timeout.connect(spawn_incoming_pulse)
	add_child(game_timer)

func spawn_incoming_pulse() -> void:
	if not game_active or score >= target_score or not arena_control:
		return
	
	var pulse = ColorRect.new()
	pulse.custom_minimum_size = Vector2(720, 14)
	pulse.size = Vector2(720, 14)
	pulse.position = Vector2(0, 0)
	
	var rand_color_idx = randi() % available_colors.size()
	pulse.color = available_colors[rand_color_idx]
	arena_control.add_child(pulse)
	obstacles.append({"node": pulse, "color_idx": rand_color_idx})

func _process(delta: float) -> void:
	if not game_active:
		return

	for i in range(obstacles.size() - 1, -1, -1):
		var obs = obstacles[i]
		var node = obs["node"]
		if not is_instance_valid(node):
			obstacles.remove_at(i)
			continue
			
		node.position.y += delta * 220.0
		
		if node.position.y >= 710 and node.position.y <= 735:
			if obs["color_idx"] == player_color_index:
				spawn_particle_burst(Vector2(360, node.position.y + 7), available_colors[obs["color_idx"]])
				node.queue_free()
				obstacles.remove_at(i)
				score += 1
				score_label.text = "SYNC PROGRESS: " + str(score) + " / " + str(target_score)
				if score >= target_score:
					trigger_victory()
			else:
				trigger_game_over()
		elif node.position.y > 840:
			node.queue_free()
			obstacles.remove_at(i)

func spawn_particle_burst(pos: Vector2, col: Color) -> void:
	if not arena_control: return
	var p_manager = ParticleManager.new()
	p_manager.burst_position = pos
	p_manager.burst_color = col
	arena_control.add_child(p_manager)

class ParticleManager extends Control:
	var burst_position: Vector2
	var burst_color: Color
	var particles: Array = []
	
	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		randomize()
		for i in range(18):
			var angle = randf() * TAU
			var speed = randf_range(80.0, 220.0)
			particles.append({
				"pos": burst_position,
				"vel": Vector2(cos(angle), sin(angle)) * speed,
				"life": 1.0
			})
			
	func _process(delta: float) -> void:
		var active = false
		for p in particles:
			if p["life"] > 0:
				p["pos"] += p["vel"] * delta
				p["life"] -= delta * 2.2
				active = true
		queue_redraw()
		if not active:
			queue_free()
			
	func _draw() -> void:
		for p in particles:
			if p["life"] > 0:
				draw_circle(p["pos"], 4.0 * p["life"], Color(burst_color.r, burst_color.g, burst_color.b, p["life"]))

class MatrixRainBackground extends Control:
	var drops: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = MOUSE_FILTER_IGNORE
		randomize()
		for i in range(45):
			drops.append({
				"x": randf_range(0, 720),
				"y": randf_range(-1280, 0),
				"speed": randf_range(200, 450),
				"length": randf_range(80, 220)
			})

	func _process(delta: float) -> void:
		for drop in drops:
			drop["y"] += drop["speed"] * delta
			if drop["y"] > 1280:
				drop["y"] = randf_range(-400, -50)
				drop["x"] = randf_range(0, 720)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 720, 1280), Color(0.0, 0.0, 0.0, 1.0))
		
		for drop in drops:
			var start_pos = Vector2(drop["x"], drop["y"] - drop["length"])
			var end_pos = Vector2(drop["x"], drop["y"])
			draw_line(start_pos, end_pos, Color(0.0, 0.3, 0.1, 0.35), 2.0)
			draw_line(end_pos - Vector2(0, 20), end_pos, Color(0.2, 1.0, 0.4, 0.85), 3.0)

func trigger_victory() -> void:
	game_active = false
	if game_timer: game_timer.stop()
	var canvas = CanvasLayer.new()
	canvas.name = "VictoryCanvas"
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var rect = ColorRect.new()
	rect.color = Color(0.02, 0.01, 0.06, 0.94)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(450, 350)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "FREQUENCY SYNCED!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.text = "▶ PROCEED TO TERMINAL 7"
	btn.custom_minimum_size = Vector2(360, 52)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		if is_instance_valid(canvas): canvas.queue_free()
		var main_script = load("res://main.gd")
		if main_script:
			main_script.current_level = 7
		get_tree().change_scene_to_file("res://main.tscn")
	)
	vbox.add_child(btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "⌂ RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(360, 52)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func():
		if is_instance_valid(canvas): canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)

func trigger_game_over() -> void:
	game_active = false
	if game_timer: game_timer.stop()
	var canvas = CanvasLayer.new()
	canvas.name = "GameOverCanvas"
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var rect = ColorRect.new()
	rect.color = Color(0.06, 0.01, 0.02, 0.94)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 380)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(1.0, 0.1, 0.2)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "SIGNAL DESYNCED!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
	vbox.add_child(lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "// FREQUENCY MISMATCH DETECTED //"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 12)
	sub_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(sub_lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	var retry_btn = Button.new()
	retry_btn.text = "↺ RETRY FREQUENCY SWITCH"
	retry_btn.custom_minimum_size = Vector2(360, 50)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_btn.add_theme_font_size_override("font_size", 15)
	retry_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(1.0, 0.1, 0.2)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	retry_btn.add_theme_stylebox_override("normal", btn_style)
	retry_btn.add_theme_stylebox_override("hover", btn_style)
	retry_btn.add_theme_stylebox_override("pressed", btn_style)
	
	retry_btn.pressed.connect(func():
		if is_instance_valid(canvas): canvas.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(retry_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "⌂ RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(360, 50)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.add_theme_font_size_override("font_size", 15)
	menu_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var menu_style = StyleBoxFlat.new()
	menu_style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	menu_style.border_width_left = 2
	menu_style.border_width_top = 2
	menu_style.border_width_right = 2
	menu_style.border_width_bottom = 2
	menu_style.border_color = Color(0.0, 0.9, 1.0)
	menu_style.corner_radius_top_left = 6
	menu_style.corner_radius_top_right = 6
	menu_style.corner_radius_bottom_left = 6
	menu_style.corner_radius_bottom_right = 6
	menu_btn.add_theme_stylebox_override("normal", menu_style)
	menu_btn.add_theme_stylebox_override("hover", menu_style)
	menu_btn.add_theme_stylebox_override("pressed", menu_style)
	
	menu_btn.pressed.connect(func():
		if is_instance_valid(canvas): canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)
