extends Control
# leaderboard.gd - Huawei Game Service Leaderboard Integration UI

var score_list: VBoxContainer = null
var back_button: Button = null

var sample_leaderboard_data = [
	{"rank": 1, "name": "Aghielaan22", "score": 9850},
	{"rank": 2, "name": "K-Corp_Agent", "score": 8720},
	{"rank": 3, "name": "CyberRunner", "score": 7400},
	{"rank": 4, "name": "NeonOrb", "score": 6150},
	{"rank": 5, "name": "Player_Zero", "score": 5200}
]

func _ready() -> void:
	# Force root control to cover full window bounds
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	setup_vaporwave_background()
	setup_leaderboard_ui()
	_populate_scores()

func setup_vaporwave_background() -> void:
	var bg_node = VaporwaveBackground.new()
	bg_node.name = "VaporwaveBG"
	bg_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg_node)
	move_child(bg_node, 0)
	
	var particles = CPUParticles2D.new()
	particles.name = "BGParticles"
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
	move_child(particles, 1)

func setup_leaderboard_ui() -> void:
	# CenterContainer locks everything dead-center on mobile screen viewports
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(500, 700)
	vbox.add_theme_constant_override("separation", 20)
	center_container.add_child(vbox)

	var title_label = Label.new()
	title_label.text = "GLOBAL LEADERBOARD"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	vbox.add_child(title_label)

	var subtitle_label = Label.new()
	subtitle_label.text = "// HUAWEI GAME SERVICE //"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.0, 0.6))
	vbox.add_child(subtitle_label)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer)

	# Panel container wrapper for the score list to give it a sleek cyber box look
	var panel_container = PanelContainer.new()
	panel_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.04, 0.12, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.0, 0.9, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 25
	panel_style.content_margin_right = 25
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel_container.add_theme_stylebox_override("panel", panel_style)
	vbox.add_child(panel_container)

	score_list = VBoxContainer.new()
	score_list.add_theme_constant_override("separation", 12)
	panel_container.add_child(score_list)

	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer2)

	back_button = Button.new()
	back_button.text = " BACK TO MENU "
	back_button.custom_minimum_size = Vector2(320, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 16)
	back_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
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
	
	back_button.add_theme_stylebox_override("normal", back_style)
	back_button.add_theme_stylebox_override("hover", back_style)
	back_button.add_theme_stylebox_override("pressed", back_style)
	
	back_button.pressed.connect(_on_back_pressed)
	vbox.add_child(back_button)

func _populate_scores() -> void:
	if not score_list:
		return
		
	for child in score_list.get_children():
		child.queue_free()
		
	for entry in sample_leaderboard_data:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(380, 30)
		row.add_theme_constant_override("separation", 20)
		
		var rank_lbl = Label.new()
		rank_lbl.text = "#%d" % entry["rank"]
		rank_lbl.custom_minimum_size = Vector2(60, 0)
		rank_lbl.add_theme_font_size_override("font_size", 16)
		rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0) if entry["rank"] <= 3 else Color(0.8, 0.8, 0.8))
		row.add_child(rank_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = entry["name"]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		row.add_child(name_lbl)
		
		var score_lbl = Label.new()
		score_lbl.text = str(entry["score"])
		score_lbl.add_theme_font_size_override("font_size", 16)
		score_lbl.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
		row.add_child(score_lbl)
		
		score_list.add_child(row)

func _on_back_pressed() -> void:
	var target_scene = "res://menu.tscn"
	if not ResourceLoader.exists(target_scene):
		target_scene = "res://Menu.tscn"
		
	get_tree().change_scene_to_file(target_scene)

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
