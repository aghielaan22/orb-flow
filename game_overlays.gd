class_name GameOverlays
extends Node

signal retry_clicked
signal next_level_clicked
signal menu_clicked

var is_victory: bool = false
var terminal_num: int = 1
var score_val: int = 0

func _init(_is_victory: bool, _terminal_num: int, _score_val: int) -> void:
	is_victory = _is_victory
	terminal_num = _terminal_num
	score_val = _score_val

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 120
	add_child(canvas_layer)

	var dimmer = ColorRect.new()
	dimmer.color = Color(0.02, 0.01, 0.05, 0.85)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(dimmer)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(center)

	var overlay_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.14, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.0, 0.9, 1.0) if is_victory else Color(1.0, 0.0, 0.4)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 25
	style.content_margin_bottom = 25
	overlay_panel.add_theme_stylebox_override("panel", style)
	center.add_child(overlay_panel)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(380, 0)
	vbox.add_theme_constant_override("separation", 15)
	overlay_panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "TERMINAL DECRYPTED" if is_victory else "SYSTEM FAILURE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6) if is_victory else Color(1.0, 0.0, 0.5))
	vbox.add_child(title_label)

	var stats_label = Label.new()
	stats_label.text = "Terminal: %d\nFinal Score: %d" % [terminal_num, score_val]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 15)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	vbox.add_child(stats_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	if is_victory:
		var next_btn = create_overlay_button("PROCEED TO NEXT TERMINAL", Color(0.0, 0.9, 1.0))
		next_btn.pressed.connect(func(): emit_signal("next_level_clicked"); queue_free())
		vbox.add_child(next_btn)
	else:
		var retry_btn = create_overlay_button("RESTART TERMINAL", Color(1.0, 0.85, 0.0))
		retry_btn.pressed.connect(func(): emit_signal("retry_clicked"); queue_free())
		vbox.add_child(retry_btn)

	var menu_btn = create_overlay_button("RETURN TO MENU", Color(1.0, 0.0, 0.4))
	menu_btn.pressed.connect(func(): emit_signal("menu_clicked"); queue_free())
	vbox.add_child(menu_btn)

func create_overlay_button(text: String, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 48)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.05, 0.16, 0.9)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = border_col
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", normal_style)
	btn.add_theme_stylebox_override("pressed", normal_style)
	return btn
