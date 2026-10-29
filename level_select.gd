extends Control

var sfx_player: AudioStreamPlayer = null

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	setup_vaporwave_background()
	setup_level_select_ui()

func play_click_sfx() -> void:
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

func setup_level_select_ui() -> void:
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(480, 920)
	center_container.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "MAINFRAME SELECT"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	vbox.add_child(title_label)

	var subtitle_label = Label.new()
	subtitle_label.text = "// CHOOSE DECRYPTION TARGET (1 - 10) //"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	vbox.add_child(subtitle_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer)

	# Scrollable container so 10 terminals fit nicely on any screen height
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 650)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(scroll)

	var grid_center = CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_center)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid_center.add_child(grid)

	var level_data = [
		{"name": "Calibration", "type": "PUZZLE", "scene": "res://main.tscn"},
		{"name": "Interceptor", "type": "ARCADE", "scene": "res://space_shooter.tscn"},
		{"name": "Security Bypass", "type": "HANGMAN", "scene": "res://cyber_hangman.tscn"},
		{"name": "Sector Breach", "type": "ARCADE", "scene": "res://space_shooter.tscn"},
		{"name": "Quantum Well", "type": "PUZZLE", "scene": "res://main.tscn"},
		{"name": "Frequency Switch", "type": "SWITCH", "scene": "res://cyber_color_switch.tscn"},
		{"name": "Data Matrix", "type": "MEMORY", "scene": "res://memory_matrix.tscn"},
		{"name": "ICE Breaker", "type": "CIRCUIT", "scene": "res://laser_puzzle.tscn"},
		{"name": "Overdrive", "type": "BOSS", "scene": "res://boss_shooter.tscn"},
		{"name": "Core Mainframe", "type": "FINALE", "scene": "res://main_core.tscn"}
	]

	for i in range(level_data.size()):
		var lvl_info = level_data[i]
		var target_lvl = i + 1
		
		var lvl_btn = Button.new()
		var prefix = "⚡ " if lvl_info["type"] == "SWITCH" else ("🚀 " if lvl_info["type"] == "ARCADE" else "🔵 ")
		lvl_btn.text = prefix + "TERM " + ("0" + str(target_lvl) if target_lvl < 10 else str(target_lvl)) + "\n" + lvl_info["name"]
		lvl_btn.custom_minimum_size = Vector2(215, 75)
		lvl_btn.add_theme_font_size_override("font_size", 13)
		lvl_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.04, 0.12, 0.9)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		
		# Color coding per game type
		match lvl_info["type"]:
			"ARCADE", "BOSS":
				style.border_color = Color(1.0, 0.5, 0.0) # Orange
			"SWITCH":
				style.border_color = Color(1.0, 0.85, 0.0) # Electric Yellow
			"HANGMAN", "MEMORY":
				style.border_color = Color(1.0, 0.0, 0.6) # Neon Pink
			_:
				style.border_color = Color(0.0, 0.9, 1.0) # Cyber Cyan
				
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		
		lvl_btn.add_theme_stylebox_override("normal", style)
		lvl_btn.add_theme_stylebox_override("hover", style)
		lvl_btn.add_theme_stylebox_override("pressed", style)
		
		lvl_btn.pressed.connect(func():
			play_click_sfx()
			var main_script = load("res://main.gd")
			if main_script:
				main_script.current_level = target_lvl
				
			var scene_path = lvl_info["scene"]
			if ResourceLoader.exists(scene_path):
				get_tree().change_scene_to_file(scene_path)
			else:
				# Fallback if new mini-game scene isn't created yet
				get_tree().change_scene_to_file("res://cyber_color_switch.tscn" if target_lvl == 6 else "res://main.tscn")
		)
		grid.add_child(lvl_btn)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)

	var back_btn = Button.new()
	back_btn.text = " BACK TO MAIN MENU "
	back_btn.custom_minimum_size = Vector2(320, 48)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 15)
	back_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.06, 0.04, 0.12, 0.9)
	back_style.border_width_left = 2
	back_style.border_width_top = 2
	back_style.border_width_right = 2
	back_style.border_width_bottom = 2
	back_style.border_color = Color(1.0, 0.85, 0.0)
	back_style.corner_radius_top_left = 6
	back_style.corner_radius_top_right = 6
	back_style.corner_radius_bottom_left = 6
	back_style.corner_radius_bottom_right = 6
	
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_stylebox_override("hover", back_style)
	back_btn.add_theme_stylebox_override("pressed", back_style)
	
	back_btn.pressed.connect(func():
		play_click_sfx()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	vbox.add_child(back_btn)

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
