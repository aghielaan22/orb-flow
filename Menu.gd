extends Control

var sfx_player: AudioStreamPlayer = null

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	# Canvas styling to expand properly on mobile
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
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
	center_container.name = "MenuCenter"
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(520, 840)
	center_container.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "ORB FLOW"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 84)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	title_label.add_theme_color_override("font_outline_color", Color(1.0, 0.0, 0.5))
	title_label.add_theme_constant_override("outline_size", 16)
	vbox.add_child(title_label)

	var subtitle_label = Label.new()
	subtitle_label.text = "// VAPORWAVE GRAVITY PROTOCOL //"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	vbox.add_child(subtitle_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 25)
	vbox.add_child(spacer)

	create_cyber_button(vbox, "▶ INITIATE GAME", Color(0.0, 0.9, 1.0), func():
		play_menu_click_sfx()
		var main_script = load("res://main.gd")
		if main_script:
			main_script.current_level = 1
		get_tree().change_scene_to_file("res://main.tscn")
	)

	add_menu_spacer(vbox)

	# --- LEVEL SELECT TERMINALS OVERLAY ---
	create_cyber_button(vbox, "⚙ SELECT TERMINAL", Color(0.0, 1.0, 0.5), func():
		play_menu_click_sfx()
		show_terminal_selector(center_container)
	)

	add_menu_spacer(vbox)

	# --- HOW TO PLAY OVERLAY ---
	create_cyber_button(vbox, "❓ HOW TO PLAY", Color(1.0, 0.85, 0.0), func():
		play_menu_click_sfx()
		show_how_to_play()
	)

	add_menu_spacer(vbox)

	# --- SPICED UP SETTINGS OVERLAY ---
	create_cyber_button(vbox, "🛠 SYSTEM SETTINGS", Color(1.0, 0.0, 0.5), func():
		play_menu_click_sfx()
		show_settings_overlay()
	)

	add_menu_spacer(vbox)

	# --- HMS LEADERBOARD BUTTON ---
	create_cyber_button(vbox, "HMS LEADERBOARD", Color(1.0, 0.7, 0.0), func():
		play_menu_click_sfx()
		if ResourceLoader.exists("res://leaderboard.tscn"):
			get_tree().change_scene_to_file("res://leaderboard.tscn")
		else:
			print("[Menu] leaderboard.tscn not found yet.")
	)

	add_menu_spacer(vbox)

	create_cyber_button(vbox, "SYSTEM EXIT", Color(1.0, 0.0, 0.4), func():
		play_menu_click_sfx()
		get_tree().quit()
	)

func show_how_to_play() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "HowToPlayOverlay"
	canvas.layer = 100
	
	var dark_rect = ColorRect.new()
	dark_rect.color = Color(0.02, 0.01, 0.05, 0.96)
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(dark_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 880)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(1.0, 0.85, 0.0)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "⚡ OPERATIONAL MANUAL ⚡"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "// MAINFRAME PROTOCOL REFERENCE //"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 15)
	sub.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))
	vbox.add_child(sub)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 580)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(scroll)
	
	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(scroll_vbox)
	
	var instructions = [
		{"title": "◆ MODE 1: PUZZLE ORB FLOW", "color": Color(0.0, 0.9, 1.0), "desc": "• Draw vector lines with your finger or mouse to guide the energy Orb.\n• Collect all glowing data stars and hit the destination core.\n• Avoid active red ICE firewalls and bottom hazards!"},
		{"title": "◆ MODE 2: CYBER HANGMAN (Terminals 3 & 7)", "color": Color(1.0, 0.7, 0.0), "desc": "• Tap the enlarged virtual keyboard to decrypt hidden keys.\n• Beat the time-bomb countdown or risk byte corruption!\n• Use the Context Hint button if you hit a deadlock."},
		{"title": "◆ MODE 3: NEON COLOR SWITCH (Terminal 6)", "color": Color(1.0, 0.85, 0.0), "desc": "• Switch your frequency color to match incoming pulse waves.\n• Clear all synchronization checkpoints to bypass the firewall."},
		{"title": "◆ MODE 4: ICE BREAKER (Terminal 8)", "color": Color(0.0, 1.0, 0.9), "desc": "• Navigate through static and sweeping laser grids.\n• Manage your generous ink juice meter carefully."},
		{"title": "◆ MODE 5: SPACE SHOOTER (Terminals 2, 4, 9)", "color": Color(1.0, 0.4, 0.2), "desc": "• Pilot your starfighter and blast incoming cyber threats.\n• Survive enemy fighter waves to clear defense protocols."},
		{"title": "◆ MODE 6: DATA UNBLOCK (Terminal 10)", "color": Color(1.0, 0.1, 0.5), "desc": "• Slide firewall blocks across the grid matrix.\n• Clear a direct path for the Red Key Node to escape!"}
	]
	
	for item in instructions:
		var section_box = VBoxContainer.new()
		section_box.add_theme_constant_override("separation", 6)
		
		var head = Label.new()
		head.text = item["title"]
		head.add_theme_font_size_override("font_size", 22)
		head.add_theme_color_override("font_color", item["color"])
		section_box.add_child(head)
		
		var desc = Label.new()
		desc.text = item["desc"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 18)
		desc.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
		section_box.add_child(desc)
		
		scroll_vbox.add_child(section_box)
		
		var sep = ColorRect.new()
		sep.custom_minimum_size = Vector2(0, 2)
		sep.color = Color(1.0, 0.0, 0.5, 0.4)
		scroll_vbox.add_child(sep)

	create_cyber_button(vbox, "✖ CLOSE MANUAL", Color(1.0, 0.0, 0.5), func():
		play_menu_click_sfx()
		canvas.queue_free()
	)
	
	add_child(canvas)

# --- EXPANDED, FEATURE-RICH CYBERPUNK SETTINGS MENU ---
func show_settings_overlay() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "SettingsOverlay"
	canvas.layer = 100
	
	var dark_rect = ColorRect.new()
	dark_rect.color = Color(0.02, 0.01, 0.05, 0.96)
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(dark_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	# Cyber Panel Container
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(580, 740)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(1.0, 0.0, 0.5)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 30
	panel_style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "🛠 SYSTEM CONFIG 🛠"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.0, 0.5))
	vbox.add_child(title)
	
	var sub = Label.new()
	sub.text = "// MAINFRAME PREFERENCES & TOGGLES //"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(sub)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	vbox.add_child(spacer)
	
	# --- 1. MASTER VOLUME ---
	var vol_label = Label.new()
	vol_label.text = "MASTER AUDIO VOLUME"
	vol_label.add_theme_font_size_override("font_size", 16)
	vol_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(vol_label)
	
	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(0, 35)
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider.value_changed.connect(func(val: float):
		AudioServer.set_bus_volume_db(0, linear_to_db(val))
	)
	vbox.add_child(slider)

	# --- 2. SFX VOLUME ---
	var sfx_label = Label.new()
	sfx_label.text = "SFX PULSE FREQUENCY"
	sfx_label.add_theme_font_size_override("font_size", 16)
	sfx_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	vbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.custom_minimum_size = Vector2(0, 35)
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	sfx_slider.value = 0.8
	sfx_slider.value_changed.connect(func(_val: float):
		play_menu_click_sfx()
	)
	vbox.add_child(sfx_slider)

	# --- 3. CRT SCANLINE TOGGLE ---
	var crt_toggle_box = HBoxContainer.new()
	vbox.add_child(crt_toggle_box)
	
	var crt_label = Label.new()
	crt_label.text = "RETRO CRT SCANLINE FILTER"
	crt_label.add_theme_font_size_override("font_size", 16)
	crt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	crt_toggle_box.add_child(crt_label)
	
	var crt_spacer = Control.new()
	crt_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	crt_toggle_box.add_child(crt_spacer)
	
	var crt_check = CheckBox.new()
	crt_check.button_pressed = true
	crt_toggle_box.add_child(crt_check)

	# --- 4. SCREEN SHAKE TOGGLE ---
	var shake_toggle_box = HBoxContainer.new()
	vbox.add_child(shake_toggle_box)
	
	var shake_label = Label.new()
	shake_label.text = "IMPACT SCREEN SHAKE"
	shake_label.add_theme_font_size_override("font_size", 16)
	shake_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	shake_toggle_box.add_child(shake_label)
	
	var shake_spacer = Control.new()
	shake_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shake_toggle_box.add_child(shake_spacer)
	
	var shake_check = CheckBox.new()
	shake_check.button_pressed = true
	shake_toggle_box.add_child(shake_check)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)

	create_cyber_button(vbox, "✔ SAVE & CLOSE CONFIG", Color(0.0, 0.9, 1.0), func():
		play_menu_click_sfx()
		canvas.queue_free()
	)
	
	add_child(canvas)

func show_terminal_selector(container: CenterContainer) -> void:
	for child in container.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(500, 900)
	container.add_child(vbox)

	var title = Label.new()
	title.text = "SELECT TERMINAL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	vbox.add_child(title)

	var sub = Label.new()
	sub.text = "CHOOSE MAINFRAME DECRYPTION TARGET (1 - 10)"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(sub)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(480, 640)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(scroll)

	var scroll_vbox = VBoxContainer.new()
	scroll_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(scroll_vbox)

	var terminal_data = [
		{"name": "System Calibration", "type": "PUZZLE"},
		{"name": "Neon Interceptor", "type": "SHOOTER"},
		{"name": "Security Bypass", "type": "HANGMAN"},
		{"name": "Sector Breach", "type": "SHOOTER"},
		{"name": "Quantum Well", "type": "PUZZLE"},
		{"name": "Frequency Switch", "type": "SWITCH"},
		{"name": "Data Matrix", "type": "HANGMAN"},
		{"name": "ICE Breaker", "type": "CIRCUIT"},
		{"name": "Overdrive Protocol", "type": "SHOOTER"},
		{"name": "Data Unblock", "type": "UNBLOCK"}
	]

	for i in range(terminal_data.size()):
		var lvl = i + 1
		var info = terminal_data[i]
		var btn_text = ""
		var btn_color = Color.WHITE
		
		match info["type"]:
			"HANGMAN":
				btn_text = "🔒 TERM " + ("0" + str(lvl) if lvl < 10 else str(lvl)) + " — " + info["name"]
				btn_color = Color(1.0, 0.7, 0.0)
			"SHOOTER":
				btn_text = "🚀 TERM " + ("0" + str(lvl) if lvl < 10 else str(lvl)) + " — " + info["name"]
				btn_color = Color(1.0, 0.4, 0.2)
			"SWITCH":
				btn_text = "⚡ TERM 06 — " + info["name"]
				btn_color = Color(1.0, 0.85, 0.0)
			"CIRCUIT":
				btn_text = "🛡 TERM 08 — " + info["name"]
				btn_color = Color(0.0, 1.0, 0.9)
			"UNBLOCK":
				btn_text = "🔓 TERM 10 — " + info["name"]
				btn_color = Color(1.0, 0.1, 0.5)
			_:
				btn_text = "🔵 TERM " + ("0" + str(lvl) if lvl < 10 else str(lvl)) + " — " + info["name"]
				btn_color = Color(0.2, 1.0, 0.8)

		create_cyber_button(scroll_vbox, btn_text, btn_color, func():
			play_menu_click_sfx()
			launch_level(lvl)
		)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer2)

	create_cyber_button(vbox, "« BACK TO MAIN MENU", Color(1.0, 0.0, 0.4), func():
		play_menu_click_sfx()
		container.queue_free()
		setup_cyber_menu()
	)

func launch_level(lvl: int) -> void:
	print("[Menu] Launching Terminal: ", lvl)
	var main_script = load("res://main.gd")
	if main_script:
		main_script.current_level = lvl

	if lvl == 3 or lvl == 7:
		get_tree().change_scene_to_file("res://cyber_hangman.tscn")
	elif lvl == 6:
		get_tree().change_scene_to_file("res://neon_color_switch.tscn")
	elif lvl in [2, 4, 9]:
		get_tree().change_scene_to_file("res://space_shooter.tscn")
	elif lvl == 10:
		get_tree().change_scene_to_file("res://unblock_puzzle.tscn")
	else:
		get_tree().change_scene_to_file("res://main.tscn")

func create_cyber_button(parent: Node, text: String, accent_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(420, 62)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.06, 0.04, 0.12, 0.92)
	style_normal.border_width_left = 2
	style_normal.border_width_top = 2
	style_normal.border_width_right = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = accent_color
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_normal)
	btn.add_theme_stylebox_override("pressed", style_normal)
	
	btn.pressed.connect(callback)
	parent.add_child(btn)

func add_menu_spacer(parent: Node) -> void:
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, 12)
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
