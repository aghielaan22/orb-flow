extends CanvasLayer

var level_num: int = 1

# Static tracker to ensure the intro only pops up once per level session, not on retries
static var seen_levels: Array = []

func _init(lvl: int) -> void:
	level_num = lvl
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	# If we already saw this level intro in this session, destroy it immediately
	if level_num in seen_levels:
		queue_free()
		return
		
	# Otherwise, mark it as seen and pause to show the briefing
	seen_levels.append(level_num)
	get_tree().paused = true
	setup_intro_ui()

func setup_intro_ui() -> void:
	var dark_rect = ColorRect.new()
	dark_rect.color = Color(0.02, 0.01, 0.05, 0.92)
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(450, 420)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "TERMINAL SECTOR " + ("0" + str(level_num) if level_num < 10 else str(level_num))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var objective_desc = ""
	
	if level_num == 3 or level_num == 7:
		objective_desc = """
		[ CYBER HANGMAN PROTOCOL ]
		• Objective: Decrypt the hidden security passphrase.
		• Control: Tap virtual keys to guess letters.
		• Warning: Too many trace breaches triggers system lock!
		"""
	elif level_num == 6:
		objective_desc = """
		[ NEON COLOR SWITCH PROTOCOL ]
		• Objective: Match frequency pulses.
		• Control: Tap to shift your core filter color.
		• Warning: Mismatched frequencies cause destabilization!
		"""
	elif level_num in [2, 4, 9]:
		objective_desc = """
		[ ARCADE COMBAT PROTOCOL ]
		• Objective: Eliminate incoming malware targets.
		• Defense Rule: Do not let enemies cross the red perimeter!
		• Controls: Drag to glide, automatic firing engaged.
		"""
	elif level_num == 8:
		objective_desc = """
		[ ICE BREAKER PROTOCOL ]
		• Objective: Navigate past sweeping security firewalls.
		• Control: Draw lines carefully with limited ink supply.
		• Warning: Touching active ICE lasers wipes the session!
		"""
	else:
		objective_desc = """
		[ PHYSICS PUZZLE PROTOCOL ]
		• Objective: Collect all stars & reach the core goal.
		• Control: Draw guide paths for the energy orb.
		• Warning: Avoid static red hazards and dead zones!
		"""
		
	var desc_label = Label.new()
	desc_label.text = objective_desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(desc_label)
	
	var btn = Button.new()
	btn.text = "▶ BEGIN PROTOCOL"
	btn.custom_minimum_size = Vector2(300, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.9, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	
	btn.pressed.connect(func():
		get_tree().paused = false
		queue_free()
	)
	vbox.add_child(btn)
