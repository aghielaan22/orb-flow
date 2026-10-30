extends Control
# unblock_puzzle_game.gd - Terminal 10 Sliding Block Puzzle Controller

const GRID_SIZE: int = 6
const CELL_SIZE: float = 90.0
const BOARD_ORIGIN: Vector2 = Vector2(90, 300)

var is_paused: bool = false
var game_active: bool = false
var pause_canvas: CanvasLayer = null
var start_canvas: CanvasLayer = null

var board_control: Control = null
var blocks: Array = []
var exit_gate_node: ColorRect = null

# Flawless, tightly packed classical layout with zero overlapping coordinates
var active_layout = {
	"exit_side": "right", "exit_pos": 2,
	"blocks": [
		{"x": 1, "y": 2, "w": 2, "h": 1, "is_target": true},  # Red Key Node (Safely isolated with open exit path)
		{"x": 0, "y": 0, "w": 2, "h": 1, "is_target": false}, # Top-left block
		{"x": 3, "y": 0, "w": 3, "h": 1, "is_target": false}, # Top-right block
		{"x": 0, "y": 1, "w": 1, "h": 2, "is_target": false}, # Left vertical blocker
		{"x": 3, "y": 1, "w": 2, "h": 1, "is_target": false}, # Upper middle block
		{"x": 5, "y": 1, "w": 1, "h": 2, "is_target": false}, # Right vertical wall block
		{"x": 0, "y": 3, "w": 1, "h": 2, "is_target": false}, # Lower-left vertical blocker
		{"x": 2, "y": 3, "w": 2, "h": 1, "is_target": false}, # Lower middle block
		{"x": 4, "y": 3, "w": 1, "h": 2, "is_target": false}, # Lower-right vertical blocker
		{"x": 0, "y": 5, "w": 3, "h": 1, "is_target": false}, # Bottom-left block
		{"x": 3, "y": 5, "w": 3, "h": 1, "is_target": false}  # Bottom-right block
	]
}

var active_block: Dictionary = {}
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	setup_matrix_background()
	setup_ui()
	setup_board()
	
	game_active = false
	show_start_prompt()

func setup_matrix_background() -> void:
	var bg = MatrixRainBackground.new()
	bg.name = "MatrixRainBackground"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

func setup_ui() -> void:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(720, 1280)
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	center.add_child(vbox)
	
	var top_bar = MarginContainer.new()
	top_bar.custom_minimum_size = Vector2(720, 130)
	top_bar.add_theme_constant_override("margin_left", 30)
	top_bar.add_theme_constant_override("margin_right", 30)
	top_bar.add_theme_constant_override("margin_top", 30)
	vbox.add_child(top_bar)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_hbox.add_theme_constant_override("separation", 15)
	top_bar.add_child(top_hbox)
	
	var title_box = VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title = Label.new()
	title.text = "TERMINAL 10: DATA UNBLOCK"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	title_box.add_child(title)
	
	var sub = Label.new()
	sub.text = "// SLIDE RED KEY NODE TO THE EXIT GATE //"
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	title_box.add_child(sub)
	top_hbox.add_child(title_box)
	
	var reset_btn = Button.new()
	reset_btn.text = "↺"
	reset_btn.custom_minimum_size = Vector2(60, 60)
	reset_btn.add_theme_font_size_override("font_size", 26)
	reset_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.08, 0.05, 0.18, 0.95)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(1.0, 0.0, 0.5)
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	reset_btn.add_theme_stylebox_override("normal", btn_style)
	reset_btn.add_theme_stylebox_override("hover", btn_style)
	reset_btn.add_theme_stylebox_override("pressed", btn_style)
	reset_btn.pressed.connect(func(): get_tree().reload_current_scene())
	top_hbox.add_child(reset_btn)

	var pause_btn = Button.new()
	pause_btn.text = "❚❚"
	pause_btn.custom_minimum_size = Vector2(60, 60)
	pause_btn.add_theme_font_size_override("font_size", 22)
	pause_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var pause_style = btn_style.duplicate()
	pause_style.border_color = Color(0.0, 0.9, 1.0)
	pause_btn.add_theme_stylebox_override("normal", pause_style)
	pause_btn.add_theme_stylebox_override("hover", pause_style)
	pause_btn.add_theme_stylebox_override("pressed", pause_style)
	pause_btn.pressed.connect(toggle_pause_menu)
	top_hbox.add_child(pause_btn)

func setup_board() -> void:
	var board_frame = PanelContainer.new()
	board_frame.custom_minimum_size = Vector2(560, 560)
	board_frame.position = BOARD_ORIGIN - Vector2(10, 10)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.01, 0.06, 0.95)
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.0, 0.9, 1.0)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	board_frame.add_theme_stylebox_override("panel", style)
	add_child(board_frame)
	
	exit_gate_node = ColorRect.new()
	exit_gate_node.color = Color(0.0, 1.0, 0.4)
	exit_gate_node.custom_minimum_size = Vector2(14, 90)
	exit_gate_node.size = Vector2(14, 90)
	exit_gate_node.position = BOARD_ORIGIN + Vector2(GRID_SIZE * CELL_SIZE + 2, 2 * CELL_SIZE)
	add_child(exit_gate_node)

	board_control = Control.new()
	board_control.name = "GridBoard"
	board_control.position = BOARD_ORIGIN
	board_control.custom_minimum_size = Vector2(540, 540)
	add_child(board_control)
	
	for r in range(GRID_SIZE):
		for c in range(GRID_SIZE):
			var cell_bg = ColorRect.new()
			cell_bg.size = Vector2(CELL_SIZE - 6, CELL_SIZE - 6)
			cell_bg.position = Vector2(c * CELL_SIZE + 3, r * CELL_SIZE + 3)
			cell_bg.color = Color(0.06, 0.04, 0.12, 0.6)
			board_control.add_child(cell_bg)

	blocks.clear()
	for data in active_layout["blocks"]:
		spawn_block(data)

func spawn_block(data: Dictionary) -> void:
	var b_node = PanelContainer.new()
	var is_target = data["is_target"]
	
	var style = StyleBoxFlat.new()
	if is_target:
		style.bg_color = Color(1.0, 0.1, 0.3, 0.95)
		style.border_color = Color(1.0, 0.85, 0.0)
	else:
		style.bg_color = Color(0.0, 0.7, 0.9, 0.85) if data["w"] > data["h"] else Color(0.9, 0.0, 0.6, 0.85)
		style.border_color = Color(1.0, 1.0, 1.0)
		
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	b_node.add_theme_stylebox_override("panel", style)
	
	var block_size = Vector2(data["w"] * CELL_SIZE - 6, data["h"] * CELL_SIZE - 6)
	b_node.custom_minimum_size = block_size
	b_node.size = block_size
	
	var pos = Vector2(data["x"] * CELL_SIZE + 3, data["y"] * CELL_SIZE + 3)
	b_node.position = pos
	
	board_control.add_child(b_node)
	
	var block_dict = {
		"node": b_node,
		"grid_x": data["x"],
		"grid_y": data["y"],
		"w": data["w"],
		"h": data["h"],
		"is_target": is_target,
		"is_horizontal": data["w"] > data["h"]
	}
	
	blocks.append(block_dict)
	
	b_node.gui_input.connect(func(event: InputEvent):
		_on_block_gui_input(event, block_dict)
	)

func _on_block_gui_input(event: InputEvent, b: Dictionary) -> void:
	if not game_active or is_paused:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			active_block = b
			drag_offset = event.position
		else:
			if is_dragging and active_block == b:
				is_dragging = false
				snap_block_to_grid(b)
				active_block = {}

	elif event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			active_block = b
			drag_offset = event.position
		else:
			if is_dragging and active_block == b:
				is_dragging = false
				snap_block_to_grid(b)
				active_block = {}

	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_dragging and active_block == b:
		move_block_constrained(b, event.position)

func move_block_constrained(b: Dictionary, event_pos: Vector2) -> void:
	var node = b["node"]
	var current_pos = node.position
	
	if b["is_horizontal"]:
		var new_x = current_pos.x + event_pos.x - drag_offset.x
		var min_x = get_min_slide_limit(b, true)
		var max_x = get_max_slide_limit(b, true)
		node.position.x = clamp(new_x, min_x, max_x)
	else:
		var new_y = current_pos.y + event_pos.y - drag_offset.y
		var min_y = get_min_slide_limit(b, false)
		var max_y = get_max_slide_limit(b, false)
		node.position.y = clamp(new_y, min_y, max_y)

func get_min_slide_limit(b: Dictionary, horizontal: bool) -> float:
	var limit = 3.0
	for other in blocks:
		if other == b: continue
		if horizontal and other["grid_y"] < b["grid_y"] + b["h"] and other["grid_y"] + other["h"] > b["grid_y"]:
			if other["grid_x"] < b["grid_x"]:
				var other_right = (other["grid_x"] + other["w"]) * CELL_SIZE + 3
				if other_right > limit:
					limit = other_right
		elif not horizontal and other["grid_x"] < b["grid_x"] + b["w"] and other["grid_x"] + other["w"] > b["grid_x"]:
			if other["grid_y"] < b["grid_y"]:
				var other_bottom = (other["grid_y"] + other["h"]) * CELL_SIZE + 3
				if other_bottom > limit:
					limit = other_bottom
	return limit

func get_max_slide_limit(b: Dictionary, horizontal: bool) -> float:
	var max_boundary = (GRID_SIZE - (b["w"] if horizontal else b["h"])) * CELL_SIZE + 3
	if b["is_target"]:
		max_boundary += CELL_SIZE * 2.0

	var limit = max_boundary
	for other in blocks:
		if other == b: continue
		if horizontal and other["grid_y"] < b["grid_y"] + b["h"] and other["grid_y"] + other["h"] > b["grid_y"]:
			if other["grid_x"] >= b["grid_x"] + b["w"]:
				var other_left = other["grid_x"] * CELL_SIZE - b["w"] * CELL_SIZE + 3
				if other_left < limit:
					limit = other_left
		elif not horizontal and other["grid_x"] < b["grid_x"] + b["w"] and other["grid_x"] + other["w"] > b["grid_x"]:
			if other["grid_y"] >= b["grid_y"] + b["h"]:
				var other_top = other["grid_y"] * CELL_SIZE - b["h"] * CELL_SIZE + 3
				if other_top < limit:
					limit = other_top
	return limit

func snap_block_to_grid(b: Dictionary) -> void:
	var node = b["node"]
	var gx = round((node.position.x - 3) / CELL_SIZE)
	var gy = round((node.position.y - 3) / CELL_SIZE)
	
	b["grid_x"] = gx
	b["grid_y"] = gy
	
	var final_pos = Vector2(gx * CELL_SIZE + 3, gy * CELL_SIZE + 3)
	
	var tween = create_tween()
	tween.tween_property(node, "position", final_pos, 0.12)
	
	if b["is_target"] and gy == 2 and gx >= 4:
		trigger_victory()

func show_start_prompt() -> void:
	start_canvas = CanvasLayer.new()
	start_canvas.layer = 120
	start_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.06, 0.90)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	start_canvas.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 320)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.04, 0.02, 0.12, 0.98)
	p_style.border_width_left = 3
	p_style.border_width_top = 3
	p_style.border_width_right = 3
	p_style.border_width_bottom = 3
	p_style.border_color = Color(0.0, 0.9, 1.0)
	p_style.corner_radius_top_left = 14
	p_style.corner_radius_top_right = 14
	p_style.corner_radius_bottom_left = 14
	p_style.corner_radius_bottom_right = 14
	p_style.content_margin_left = 35
	p_style.content_margin_right = 35
	p_style.content_margin_top = 35
	p_style.content_margin_bottom = 35
	panel.add_theme_stylebox_override("panel", p_style)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "READY TO UNBLOCK?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "// Slide blocks to clear a path\nfor the Red Key Node //"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.0, 1.0, 0.9))
	vbox.add_child(desc)
	
	var start_btn = Button.new()
	start_btn.text = "▶ CLICK HERE TO START"
	start_btn.custom_minimum_size = Vector2(380, 60)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.add_theme_font_size_override("font_size", 18)
	
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.0, 0.7, 0.5, 0.9)
	b_style.border_width_left = 2
	b_style.border_width_top = 2
	b_style.border_width_right = 2
	b_style.border_width_bottom = 2
	b_style.border_color = Color(0.0, 1.0, 0.8)
	b_style.corner_radius_top_left = 10
	b_style.corner_radius_top_right = 10
	b_style.corner_radius_bottom_left = 10
	b_style.corner_radius_bottom_right = 10
	start_btn.add_theme_stylebox_override("normal", b_style)
	start_btn.add_theme_stylebox_override("hover", b_style)
	start_btn.add_theme_stylebox_override("pressed", b_style)
	
	start_btn.pressed.connect(func():
		game_active = true
		if is_instance_valid(start_canvas):
			start_canvas.queue_free()
	)
	vbox.add_child(start_btn)
	
	get_tree().root.add_child(start_canvas)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = not is_paused
	game_active = not is_paused
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
	vbox.custom_minimum_size = Vector2(420, 0)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	create_menu_btn(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func(): toggle_pause_menu())
	create_menu_btn(vbox, "↺ RESTART TERMINAL", Color(1.0, 0.0, 0.6), func():
		if pause_canvas and is_instance_valid(pause_canvas): pause_canvas.queue_free()
		get_tree().reload_current_scene()
	)
	create_menu_btn(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		if pause_canvas and is_instance_valid(pause_canvas): pause_canvas.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	add_child(pause_canvas)

func create_menu_btn(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(360, 56)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.pressed.connect(callback)
	parent.add_child(btn)

func trigger_victory() -> void:
	game_active = false
	var victory_overlay = load("res://stage7_victory_overlay.gd").new(1000)
	get_tree().root.add_child(victory_overlay)

class MatrixRainBackground extends Control:
	var drops: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		randomize()
		for i in range(45):
			drops.append({
				"x": randf_range(0, 720),
				"y": randf_range(-1280, 0),
				"speed": randf_range(200, 450),
				"length": randf_range(80, 220)
			})

	func _process(delta: float) -> void:
		for drop in drops:
			drop["y"] += drop["speed"] * delta
			if drop["y"] > 1280:
				drop["y"] = randf_range(-400, -50)
				drop["x"] = randf_range(0, 720)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 720, 1280), Color(0.0, 0.0, 0.0, 1.0))
		for drop in drops:
			var start_pos = Vector2(drop["x"], drop["y"] - drop["length"])
			var end_pos = Vector2(drop["x"], drop["y"])
			draw_line(start_pos, end_pos, Color(0.0, 0.3, 0.1, 0.35), 2.0)
			draw_line(end_pos - Vector2(0, 20), end_pos, Color(0.2, 1.0, 0.4, 0.85), 3.0)
