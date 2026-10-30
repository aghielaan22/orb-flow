extends CanvasLayer

signal name_submitted(entered_name: String)

var final_score: int = 0
var line_edit: LineEdit = null

func _init(score: int) -> void:
	final_score = score
	layer = 150
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	setup_ui()

func setup_ui() -> void:
	var dark_rect = ColorRect.new()
	dark_rect.color = Color(0.02, 0.01, 0.05, 0.92)
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(450, 350)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "NEW HIGH SCORE!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var score_info = Label.new()
	score_info.text = "FINAL SCORE: " + str(final_score)
	score_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_info.add_theme_font_size_override("font_size", 20)
	score_info.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(score_info)
	
	var prompt = Label.new()
	prompt.text = "ENTER 3-LETTER INITIALS:"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	vbox.add_child(prompt)
	
	# LineEdit for name entry
	line_edit = LineEdit.new()
	line_edit.text = "AAA"
	line_edit.max_length = 3
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_edit.custom_minimum_size = Vector2(200, 50)
	line_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line_edit.add_theme_font_size_override("font_size", 28)
	vbox.add_child(line_edit)
	
	# Automatically grab focus so player can type immediately
	line_edit.grab_focus()
	line_edit.select_all()
	
	# Submit Button
	var btn = Button.new()
	btn.text = "✔ SAVE TO LEADERBOARD"
	btn.custom_minimum_size = Vector2(280, 50)
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
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	
	btn.pressed.connect(func():
		var entered_name = line_edit.text if line_edit.text != "" else "AAA"
		ScoreManager.save_score(entered_name, final_score)
		emit_signal("name_submitted", entered_name)
		queue_free()
	)
	vbox.add_child(btn)
