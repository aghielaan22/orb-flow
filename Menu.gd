extends Control

var sfx_player: AudioStreamPlayer = null

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	setup_vaporwave_background()
	setup_cyber_menu()

func play_menu_click_sfx() -> void:
	var sample_rate = 22050
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var buffer = PackedByteArray()
	buffer.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var wave = sin(t * 1200.0 * TAU)
		var val = int(wave * 10000)
		buffer.encode_s16(i * 2, val)

	var sample_stream = AudioStreamWAV.new()
	sample_stream.format = AudioStreamWAV.FORMAT_16_BITS
	sample_stream.mix_rate = sample_rate
	sample_stream.data = buffer

	sfx_player.stream = sample_stream
	sfx_player.play()

func setup_vaporwave_background() -> void:
	var bg_node = VaporwaveBackground.new()
	bg_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_node)
	
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
	add_child(particles)

func setup_cyber_menu() -> void:
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(450, 750)
	center_container.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "ORB FLOW"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	vbox.add_child(title_label)

	var subtitle_label = Label.new()
	subtitle_label.text = "// VAPORWAVE GRAVITY PROTOCOL //"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	vbox.add_child(subtitle_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	create_cyber_button(vbox, "INITIATE GAME", Color(0.0, 0.9, 1.0), func():
		play_menu_click_sfx()
		get_tree().change_scene_to_file("res://main.tscn")
	)

	add_menu_spacer(vbox)

	# --- LEVEL SELECT BUTTON ---
	create_cyber_button(vbox, "SELECT TERMINAL", Color(0.0, 1.0, 0.5), func():
		play_menu_click_sfx()
		get_tree().change_scene_to_file("res://level_select.tscn")
	)

	add_menu_spacer(vbox)

	# --- HMS LEADERBOARD BUTTON ---
	create_cyber_button(vbox, "HMS LEADERBOARD", Color(1.0, 0.7, 0.0), func():
		play_menu_click_sfx()
		get_tree().change_scene_to_file("res://leaderboard.tscn")
	)

	add_menu_spacer(vbox)

	create_cyber_button(vbox, "SYSTEM EXIT", Color(1.0, 0.0, 0.4), func():
		play_menu_click_sfx()
		get_tree().quit()
	)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)

	# --- DEVELOPER CHEATS DISPLAY PANEL ---
	var cheat_panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.02, 0.1, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1.0, 0.0, 0.8, 0.8)
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	cheat_panel.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(cheat_panel)

	var cheat_vbox = VBoxContainer.new()
	cheat_panel.add_child(cheat_vbox)

	var cheat_title = Label.new()
	cheat_title.text = "⚡ DEV TESTING SHORTCUTS ⚡"
	cheat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_title.add_theme_font_size_override("font_size", 13)
	cheat_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	cheat_vbox.add_child(cheat_title)

	var cheat_details = Label.new()
	cheat_details.text = "[1 - 6] : Jump to Level\n[ N ] : Instant Win / Skip Level\n[ R ] : Quick Restart Level"
	cheat_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cheat_details.add_theme_font_size_override("font_size", 12)
	cheat_details.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9, 0.9))
	cheat_vbox.add_child(cheat_details)

func create_cyber_button(parent: Node, text: String, accent_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 48)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.04, 0.12, 0.9)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = accent_color
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("pressed", style_normal)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func add_menu_spacer(parent: Node) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, 10)
	parent.add_child(s)

class VaporwaveBackground extends Control:
	var grid_offset: float = 0.0
	
	func _process(delta: float) -> void:
		grid_offset += delta * 60.0
		if grid_offset > 50.0:
			grid_offset = 0.0
		queue_redraw()
		
	func _draw() -> void:
		var sz = size
		var horizon_y = sz.y * 0.52
		draw_rect(Rect2(0, 0, sz.x, horizon_y), Color(0.07, 0.02, 0.14))
		
		var sun_center = Vector2(sz.x * 0.5, horizon_y - 30)
		var sun_radius = 85.0
		for i in range(12):
			var r = sun_radius - (i * 4)
			var alpha = 0.12 + (i * 0.04)
			draw_circle(sun_center, r, Color(1.0, 0.35, 0.65, alpha))
		
		for y_off in range(-int(sun_radius), int(sun_radius), 10):
			if y_off > 0:
				var slice_y = sun_center.y + y_off
				var w = sqrt(sun_radius * sun_radius - y_off * y_off)
				draw_rect(Rect2(sun_center.x - w, slice_y, w * 2, 3), Color(0.07, 0.02, 0.14))

		draw_rect(Rect2(0, horizon_y, sz.x, sz.y - horizon_y), Color(0.02, 0.01, 0.05))
		draw_line(Vector2(0, horizon_y), Vector2(sz.x, horizon_y), Color(1.0, 0.0, 0.7), 3.0)
		
		var vanishing_point = Vector2(sz.x * 0.5, horizon_y)
		var num_rays = 14
		for i in range(num_rays):
			var t = float(i) / (num_rays - 1)
			var bottom_x = (t * sz.x * 2.0) - (sz.x * 0.5)
			draw_line(vanishing_point, Vector2(bottom_x, sz.y), Color(0.0, 0.9, 1.0, 0.35), 1.5)
			
		var num_horizontal = 14
		for i in range(num_horizontal):
			var progress = fmod((float(i) + grid_offset / 50.0), num_horizontal) / num_horizontal
			var y = horizon_y + pow(progress, 2.2) * (sz.y - horizon_y)
			var alpha = progress * 0.65
			draw_line(Vector2(0, y), Vector2(sz.x, y), Color(1.0, 0.0, 0.65, alpha), 1.5)
