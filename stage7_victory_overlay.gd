extends CanvasLayer

var final_score: int = 0

func _init(score: int) -> void:
	final_score = score
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	get_tree().paused = true
	setup_victory_ui()

func setup_victory_ui() -> void:
	# Dark vaporwave backing overlay
	var dark_rect = ColorRect.new()
	dark_rect.color = Color(0.02, 0.01, 0.06, 0.95)
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dark_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 600)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "★ MISSION COMPLETE ★"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "ORB FLOW PROTOCOL FULLY RESTORED"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	subtitle.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	vbox.add_child(subtitle)
	
	# Stats panel container
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.9)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 0.9, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 25
	style.content_margin_right = 25
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", style)
	vbox.add_child(panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 12)
	panel.add_child(stats_vbox)
	
	var stats_title = Label.new()
	stats_title.text = "― DEPLOYMENT SUMMARY ―"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 15)
	stats_title.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	stats_vbox.add_child(stats_title)
	
	var score_lbl = Label.new()
	score_lbl.text = "FINAL SCORE: " + str(final_score)
	score_lbl.add_theme_font_size_override("font_size", 18)
	score_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	stats_vbox.add_child(score_lbl)
	
	var status_lbl = Label.new()
	status_lbl.text = "SYSTEM INTEGRITY: 100% (OPTIMAL)"
	status_lbl.add_theme_font_size_override("font_size", 15)
	status_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	stats_vbox.add_child(status_lbl)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Action Buttons with explicit unpause and queue_free()
	create_victory_button(vbox, "↺ PLAY AGAIN", Color(0.0, 0.9, 1.0), func():
		get_tree().paused = false
		var main_script = load("res://main.gd")
		if main_script:
			main_script.current_level = 1
		queue_free()
		get_tree().change_scene_to_file("res://main.tscn")
	)
	
	create_victory_button(vbox, "⌂ RETURN TO MAIN MENU", Color(1.0, 0.7, 0.0), func():
		get_tree().paused = false
		queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)

func create_victory_button(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(340, 50)
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
