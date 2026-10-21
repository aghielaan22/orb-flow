extends Control

func _ready() -> void:
	# 1. Dark Cyberpunk Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1) # Deep dark charcoal/blue
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 2. Container for UI elements (centered on screen)
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	# 3. Game Title Label
	var title = Label.new()
	title.text = "ORB FLOW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0)) # Neon Cyan
	vbox.add_child(title)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# 4. Cyberpunk Play Button
	var play_btn = Button.new()
	play_btn.text = " INITIALIZE GAME "
	play_btn.custom_minimum_size = Vector2(220, 60)
	play_btn.pressed.connect(_on_play_pressed)
	vbox.add_child(play_btn)

func _on_play_pressed() -> void:
	# Fixed to lowercase 'main.tscn' to match file system and mobile export standards
	get_tree().change_scene_to_file("res://main.tscn")
