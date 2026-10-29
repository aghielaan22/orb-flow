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
var pause_canvas: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	setup_neon_grid_background()
	setup_ui()
	setup_game_loop()

	# --- ADD LEVEL INTRO POPUP FOR TERMINAL 6 ---
	if ResourceLoader.exists("res://level_intro.gd"):
		var intro = load("res://level_intro.gd").new(6)
		get_tree().root.add_child(intro)

func setup_neon_grid_background() -> void:
	var bg = NeonGridBackground.new()
	bg.name = "NeonGridBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func setup_ui() -> void:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var outer_panel = PanelContainer.new()
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.04, 0.02, 0.1, 0.92)
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = Color(0.0, 0.9, 1.0)
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.content_margin_left = 25
	card_style.content_margin_right = 25
	card_style.content_margin_top = 20
	card_style.content_margin_bottom = 20
	outer_panel.add_theme_stylebox_override("panel", card_style)
	center.add_child(outer_panel)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(520, 780)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	outer_panel.add_child(vbox)
	
	var top_bar = HBoxContainer.new()
	top_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(top_bar)
	
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title = Label.new()
	title.text = "TERMINAL 6: COLOR SWITCH"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	title_box.add_child(title)
	
	var instructions = Label.new()
	instructions.text = "// MATCH YOUR FREQUENCY COLOR //"
	instructions.add_theme_font_size_override("font_size", 11)
	instructions.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	title_box.add_child(instructions)
	top_bar.add_child(title_box)
	
	var pause_btn = Button.new()
	pause_btn.text = "❚❚"
	pause_btn.custom_minimum_size = Vector2(45, 45)
	pause_btn.add_theme_font_size_override("font_size", 16)
	pause_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.0, 0.9, 1.0)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	pause_btn.add_theme_stylebox_override("normal", btn_style)
	pause_btn.add_theme_stylebox_override("hover", btn_style)
	pause_btn.add_theme_stylebox_override("pressed", btn_style)
	pause_btn.pressed.connect(toggle_pause_menu)
	top_bar.add_child(pause_btn)
	
	score_label = Label.new()
	score_label.text = "SYNC PROGRESS: 0 / " + str(target_score)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 14)
	score_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	vbox.add_child(score_label)
	
	var arena_panel = PanelContainer.new()
	arena_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.05, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.0, 0.6)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	arena_panel.add_theme_stylebox_override("panel", style)
	arena_panel.custom_minimum_size = Vector2(440, 320)
	vbox.add_child(arena_panel)
	
	arena_control = Control.new()
	arena_control.name = "Arena"
	arena_panel.add_child(arena_control)
	
	player_visual = ColorRect.new()
	player_visual.custom_minimum_size = Vector2(40, 40)
	player_visual.size = Vector2(40, 40)
	player_visual.position = Vector2(200, 250)
	player_visual.color = available_colors[player_color_index]
	arena_control.add_child(player_visual)
	
	var color_switch_btn = Button.new()
	color_switch_btn.text = "⚡ SWITCH FREQUENCY COLOR ⚡"
	color_switch_btn.custom_minimum_size = Vector2(360, 50)
	color_switch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	color_switch_btn.add_theme_font_size_override("font_size", 15)
	color_switch_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_s = StyleBoxFlat.new()
	btn_s.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	btn_s.border_width_left = 2
	btn_s.border_width_top = 2
	btn_s.border_width_right = 2
	btn_s.border_width_bottom = 2
	btn_s.border_color = Color(0.0, 0.9, 1.0)
	btn_s.corner_radius_top_left = 6
	btn_s.corner_radius_top_right = 6
	btn_s.corner_radius_bottom_left = 6
	btn_s.corner_radius_bottom_right = 6
	color_switch_btn.add_theme_stylebox_override("normal", btn_s)
	color_switch_btn.add_theme_stylebox_override("hover", btn_s)
	color_switch_btn.add_theme_stylebox_override("pressed", btn_s)
	color_switch_btn.pressed.connect(switch_color)
	vbox.add_child(color_switch_btn)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	if is_paused:
		show_pause_overlay()
	else:
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()

func show_pause_overlay() -> void:
	pause_canvas = CanvasLayer.new()
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
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.add_theme_constant_override("separation", 18)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	create_menu_btn(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func(): toggle_pause_menu())
	create_menu_btn(vbox, "↺ RESTART TERMINAL", Color(1.0, 0.0, 0.6), func():
		get_tree().paused = false
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()
		get_tree().reload_current_scene()
	)
	create_menu_btn(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		get_tree().paused = false
		if pause_canvas and is_instance_valid(pause_canvas):
			pause_canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	add_child(pause_canvas)

func create_menu_btn(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 50)
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
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
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
	game_timer.wait_time = 0.85
	game_timer.autostart = true
	game_timer.timeout.connect(spawn_incoming_pulse)
	add_child(game_timer)

func spawn_incoming_pulse() -> void:
	if score >= target_score or not arena_control:
		return
	
	var pulse = ColorRect.new()
	pulse.custom_minimum_size = Vector2(440, 14)
	pulse.size = Vector2(440, 14)
	pulse.position = Vector2(0, 0)
	
	var rand_color_idx = randi() % available_colors.size()
	pulse.color = available_colors[rand_color_idx]
	arena_control.add_child(pulse)
	obstacles.append({"node": pulse, "color_idx": rand_color_idx})

func _process(delta: float) -> void:
	for i in range(obstacles.size() - 1, -1, -1):
		var obs = obstacles[i]
		var node = obs["node"]
		if not is_instance_valid(node):
			obstacles.remove_at(i)
			continue
			
		node.position.y += delta * 260.0
		
		if node.position.y >= 235 and node.position.y <= 275:
			if obs["color_idx"] == player_color_index:
				spawn_particle_burst(Vector2(220, node.position.y + 7), available_colors[obs["color_idx"]])
				node.queue_free()
				obstacles.remove_at(i)
				score += 1
				score_label.text = "SYNC PROGRESS: " + str(score) + " / " + str(target_score)
				if score >= target_score:
					trigger_victory()
			else:
				trigger_game_over()
		elif node.position.y > 320:
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
		for i in range(16):
			var angle = randf() * TAU
			var speed = randf_range(60.0, 180.0)
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
				draw_circle(p["pos"], 3.5 * p["life"], Color(burst_color.r, burst_color.g, burst_color.b, p["life"]))

class NeonGridBackground extends Control:
	var scroll_offset: float = 0.0
	
	func _process(delta: float) -> void:
		scroll_offset += delta * 50.0
		if scroll_offset > 40.0:
			scroll_offset = 0.0
		queue_redraw()
		
	func _draw() -> void:
		var sz = get_viewport_rect().size
		var horizon_y = sz.y * 0.42
		
		draw_rect(Rect2(0, 0, sz.x, horizon_y), Color(0.06, 0.02, 0.16))
		
		var sun_center = Vector2(sz.x * 0.5, horizon_y - 25)
		var sun_radius = 80.0
		for i in range(10):
			var r = sun_radius - (i * 6)
			var alpha = 0.15 + (i * 0.03)
			draw_circle(sun_center, r, Color(1.0, 0.3, 0.5, alpha))
			
		draw_rect(Rect2(0, horizon_y, sz.x, sz.y - horizon_y), Color(0.02, 0.01, 0.06))
		draw_line(Vector2(0, horizon_y), Vector2(sz.x, horizon_y), Color(0.0, 0.9, 1.0), 3.0)
		
		var grid_step = 40.0
		for i in range(int(sz.x / grid_step) + 5):
			var x_pos = (i * grid_step) - fmod(scroll_offset * 2.0, grid_step)
			draw_line(Vector2(x_pos, horizon_y), Vector2((x_pos - sz.x * 0.5) * 1.8 + sz.x * 0.5, sz.y), Color(1.0, 0.0, 0.6, 0.18), 1.5)

func trigger_victory() -> void:
	if game_timer: game_timer.stop()
	get_tree().paused = true
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
	vbox.custom_minimum_size = Vector2(400, 300)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "FREQUENCY SYNCED!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	vbox.add_child(lbl)
	
	var btn = Button.new()
	btn.text = "▶ PROCEED TO TERMINAL 7"
	btn.custom_minimum_size = Vector2(320, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func():
		get_tree().paused = false
		if is_instance_valid(canvas): canvas.queue_free()
		var main_script = load("res://main.gd")
		if main_script:
			main_script.current_level = 7
		get_tree().change_scene_to_file("res://main.tscn")
	)
	vbox.add_child(btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "⌂ RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(320, 50)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		if is_instance_valid(canvas): canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)

func trigger_game_over() -> void:
	if game_timer: game_timer.stop()
	get_tree().paused = true
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
	panel.custom_minimum_size = Vector2(420, 360)
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
	panel_style.content_margin_left = 25
	panel_style.content_margin_right = 25
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "SIGNAL DESYNCED!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.1, 0.1))
	vbox.add_child(lbl)
	
	var sub_lbl = Label.new()
	sub_lbl.text = "// FREQUENCY MISMATCH DETECTED //"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 11)
	sub_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(sub_lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	var retry_btn = Button.new()
	retry_btn.text = "↺ RETRY FREQUENCY SWITCH"
	retry_btn.custom_minimum_size = Vector2(340, 48)
	retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	retry_btn.add_theme_font_size_override("font_size", 14)
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
		get_tree().paused = false
		if is_instance_valid(canvas): canvas.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(retry_btn)
	
	var menu_btn = Button.new()
	menu_btn.text = "⌂ RETURN TO MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(340, 48)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.add_theme_font_size_override("font_size", 14)
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
		get_tree().paused = false
		if is_instance_valid(canvas): canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(menu_btn)
	
	add_child(canvas)
