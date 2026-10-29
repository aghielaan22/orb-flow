extends Node2D

static var input_dir: float = 0.0
static var firing_pressed: bool = false

static var current_level: int = 2
var score: int = 0
var target_score: int = 15

var screen_size: Vector2 = Vector2(720, 1280)

var player_ship: Node = null
var enemies: Array = []
var enemy_bullets: Array = []
var green_obstacles: Array = [] # Terminal 9 Green Entities

var spawn_timer: float = 0.0
var enemy_fire_timer: float = 0.0
var obstacle_spawn_timer: float = 0.0

var score_label: Label = null
var target_label: Label = null
var defense_label: Label = null

var escaped_enemies: int = 0
var max_escaped_allowed: int = 3

var is_game_over: bool = false
var is_paused: bool = false

# Touch dragging state for smooth single-finger glide steering
var is_dragging_player: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Fix stretch/window aspect ratio to eliminate grey side bars on mobile
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	match main_game_level():
		2: target_score = 15
		4: target_score = 25
		9: target_score = 40  # Terminal 9 Overdrive Target
		_: target_score = 20

	setup_matrix_background()
	setup_ui()
	
	# Locate the PlayerShip node already placed in your scene tree
	player_ship = get_node_or_null("PlayerShip")
	
	print("[Space Shooter] Initialized Level ", main_game_level(), " | Target Score: ", target_score)
	
	# Add Level Intro Popup for Space Shooter (using main_game_level())
	if ResourceLoader.exists("res://level_intro.gd"):
		var current_lvl = main_game_level()
		var intro = load("res://level_intro.gd").new(current_lvl)
		get_tree().root.add_child(intro)
	
func main_game_level() -> int:
	var main_script = load("res://main.gd")
	if main_script and "current_level" in main_script:
		return main_script.current_level
	return current_level

func _process(delta: float) -> void:
	if is_game_over or is_paused:
		return

	handle_spawning(delta)
	update_projectiles_and_enemies(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			toggle_pause_menu()
		elif not is_paused:
			if event.keycode == KEY_R:
				get_tree().reload_current_scene()
			elif event.keycode == KEY_N:
				on_victory()
	
	# Handle single-finger drag / glide steering in the upper game area
	elif event is InputEventScreenTouch:
		if event.pressed:
			if event.position.y < screen_size.y - 220:
				is_dragging_player = true
				update_glide_position(event.position.x)
		else:
			is_dragging_player = false
			input_dir = 0.0
	elif event is InputEventScreenDrag and is_dragging_player:
		if event.position.y < screen_size.y - 220:
			update_glide_position(event.position.x)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.y < screen_size.y - 220:
			is_dragging_player = true
			update_glide_position(event.position.x)
		elif not event.pressed:
			is_dragging_player = false
			input_dir = 0.0
	elif event is InputEventMouseMotion and is_dragging_player:
		if event.position.y < screen_size.y - 220:
			update_glide_position(event.position.x)

func update_glide_position(touch_x: float) -> void:
	if not is_instance_valid(player_ship):
		return
	var diff = touch_x - player_ship.position.x
	if abs(diff) > 5.0:
		input_dir = sign(diff) * min(abs(diff) / 30.0, 1.5)
	else:
		input_dir = 0.0

func toggle_pause_menu() -> void:
	if is_game_over:
		return
		
	is_paused = not is_paused
	get_tree().paused = is_paused
	
	if is_paused:
		show_pause_overlay()
	else:
		var overlay = get_tree().root.get_node_or_null("PauseOverlay")
		if overlay:
			overlay.queue_free()

func show_pause_overlay() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "PauseOverlay"
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var dark_rect = ColorRect.new()
	dark_rect.color = Color(0.02, 0.01, 0.05, 0.85)
	dark_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(dark_rect)
	
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(400, 500)
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "SYSTEM PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	vbox.add_child(title)
	
	create_overlay_button(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func():
		toggle_pause_menu()
	)
	create_overlay_button(vbox, "↺ RESTART LEVEL", Color(1.0, 0.0, 0.6), func():
		get_tree().paused = false
		var overlay = get_tree().root.get_node_or_null("PauseOverlay")
		if overlay: overlay.queue_free()
		get_tree().reload_current_scene()
	)
	create_overlay_button(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		get_tree().paused = false
		var overlay = get_tree().root.get_node_or_null("PauseOverlay")
		if overlay: overlay.queue_free()
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	
	get_tree().root.add_child(canvas)

func create_overlay_button(parent: Node, text: String, border_color: Color, callback: Callable) -> void:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(320, 50)
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

var level_time_elapsed: float = 0.0

func handle_spawning(delta: float) -> void:
	level_time_elapsed += delta
	
	# Progressive spawn rates based on stage difficulty
	var base_spawn_rate = 1.2
	if main_game_level() == 4:
		base_spawn_rate = 0.85
	elif main_game_level() == 9:
		base_spawn_rate = 0.45 # High-intensity Overdrive spawn rate
	elif main_game_level() >= 6:
		base_spawn_rate = 0.55
		
	spawn_timer += delta
	if spawn_timer >= base_spawn_rate:
		spawn_timer = 0.0
		spawn_enemy()

	# Terminal 9: Spawn Green Obstacles / Entities
	if main_game_level() == 9:
		obstacle_spawn_timer += delta
		if obstacle_spawn_timer >= 1.8:
			obstacle_spawn_timer = 0.0
			spawn_green_obstacle()

	# Enemy firing frequency scales up in higher terminals
	if main_game_level() >= 4:
		var fire_interval = 1.4 if main_game_level() == 4 else (0.7 if main_game_level() == 9 else 1.0)
		enemy_fire_timer += delta
		if enemy_fire_timer >= fire_interval:
			enemy_fire_timer = 0.0
			enemy_shoot_bullet()

func spawn_enemy() -> void:
	var enemy = Area2D.new()
	enemy.name = "Enemy"
	
	var enemy_script = load("res://enemy.gd")
	if enemy_script:
		enemy.set_script(enemy_script)
		
	var spawn_x = randf_range(60, screen_size.x - 60)
	enemy.position = Vector2(spawn_x, -40)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 35.0
	shape.shape = circle
	enemy.add_child(shape)

	var visual = Line2D.new()
	visual.width = 3.5
	visual.default_color = Color(1.0, 0.0, 0.6)
	var points_arr = [
		Vector2(0, 25), Vector2(-8, 10), Vector2(-25, -15),
		Vector2(-10, -8), Vector2(0, -18), Vector2(10, -8),
		Vector2(25, -15), Vector2(8, 10), Vector2(0, 25)
	]
	for p in points_arr:
		visual.add_point(p)
	enemy.add_child(visual)

	enemy.body_entered.connect(_on_enemy_body_entered.bind(enemy))
	enemy.area_entered.connect(_on_enemy_area_entered.bind(enemy))

	add_child(enemy)
	enemies.append(enemy)

func spawn_green_obstacle() -> void:
	var obstacle = Area2D.new()
	obstacle.name = "GreenObstacle"
	
	var spawn_x = randf_range(80, screen_size.x - 80)
	obstacle.position = Vector2(spawn_x, -50)

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(50, 50)
	shape.shape = rect
	obstacle.add_child(shape)

	var visual = Line2D.new()
	visual.width = 4.0
	visual.default_color = Color(0.0, 1.0, 0.4) # Glowing green entity obstacle
	var box_points = [
		Vector2(-25, -25), Vector2(25, -25),
		Vector2(25, 25), Vector2(-25, 25), Vector2(-25, -25)
	]
	for p in box_points:
		visual.add_point(p)
	obstacle.add_child(visual)

	obstacle.body_entered.connect(func(body):
		if is_game_over: return
		if body.name == "PlayerShip" or "Player" in body.name or body is CharacterBody2D:
			on_player_hit()
	)
	obstacle.area_entered.connect(func(area):
		if "Bullet" in area.name or area.is_in_group("bullets"):
			if is_instance_valid(area): area.queue_free()
	)

	add_child(obstacle)
	green_obstacles.append(obstacle)

func _on_enemy_body_entered(body: Node, _enemy: Area2D) -> void:
	if is_game_over:
		return
	if body.name == "PlayerShip" or "Player" in body.name or body is CharacterBody2D:
		on_player_hit()

func _on_enemy_area_entered(area: Area2D, enemy: Area2D) -> void:
	if is_game_over or not is_instance_valid(enemy):
		return
		
	if "Enemy" in area.name:
		return

	if area.is_in_group("bullets") or "Bullet" in area.name or "bullet" in area.name:
		if is_instance_valid(area):
			area.queue_free()
			
		score += 1
		update_ui()
		
		spawn_hit_spark(enemy.global_position, Color(1.0, 0.0, 0.5))
		
		if enemy in enemies:
			enemies.erase(enemy)
		enemy.queue_free()
		
		if score >= target_score and not is_game_over:
			on_victory()

func enemy_shoot_bullet() -> void:
	if enemies.size() == 0:
		return

	var shooter = enemies.pick_random()
	if not is_instance_valid(shooter):
		return

	var bullet = Area2D.new()
	bullet.name = "EnemyBullet"
	bullet.position = shooter.position + Vector2(0, 25)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 16.0 
	shape.shape = circle
	bullet.add_child(shape)

	var visual = Line2D.new()
	visual.width = 14.0
	visual.default_color = Color(1.0, 0.8, 0.0) 
	visual.add_point(Vector2(0, -8))
	visual.add_point(Vector2(0, 8))
	bullet.add_child(visual)

	add_child(bullet)
	enemy_bullets.append(bullet)

func spawn_hit_spark(pos: Vector2, spark_color: Color) -> void:
	var spark = CPUParticles2D.new()
	spark.global_position = pos
	spark.emitting = true
	spark.one_shot = true
	spark.amount = 16
	spark.lifetime = 0.4
	spark.explosiveness = 1.0
	spark.initial_velocity_min = 100.0
	spark.initial_velocity_max = 220.0
	spark.scale_amount_min = 4.0
	spark.scale_amount_max = 7.0
	spark.color = spark_color
	spark.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(spark)
	
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(_on_spark_timeout.bind(spark))

func _on_spark_timeout(spark: CPUParticles2D) -> void:
	if is_instance_valid(spark):
		spark.queue_free()

func update_projectiles_and_enemies(delta: float) -> void:
	var red_line_y = screen_size.y - 190.0

	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if is_instance_valid(e):
			if e.position.y >= red_line_y:
				escaped_enemies += 1
				update_ui()
				spawn_hit_spark(e.global_position, Color(1.0, 0.1, 0.1))
				
				enemies.remove_at(i)
				e.queue_free()
				
				if escaped_enemies >= max_escaped_allowed and not is_game_over:
					on_player_hit()
		else:
			enemies.remove_at(i)

	# Update Terminal 9 Green Obstacles movement
	for i in range(green_obstacles.size() - 1, -1, -1):
		var obs = green_obstacles[i]
		if is_instance_valid(obs):
			obs.position.y += 280.0 * delta
			if is_instance_valid(player_ship):
				if obs.global_position.distance_to(player_ship.global_position) < 40.0:
					obs.queue_free()
					green_obstacles.remove_at(i)
					on_player_hit()
					continue
			if obs.position.y > screen_size.y + 100:
				obs.queue_free()
				green_obstacles.remove_at(i)
		else:
			green_obstacles.remove_at(i)

	for i in range(enemy_bullets.size() - 1, -1, -1):
		var b = enemy_bullets[i]
		if is_instance_valid(b):
			b.position.y += 480.0 * delta
			
			if is_instance_valid(player_ship):
				if b.global_position.distance_to(player_ship.global_position) < 38.0:
					b.queue_free()
					enemy_bullets.remove_at(i)
					on_player_hit()
					continue

			if b.position.y > screen_size.y + 100:
				b.queue_free()
				enemy_bullets.remove_at(i)
		else:
			enemy_bullets.remove_at(i)

func on_player_hit() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	if is_instance_valid(player_ship):
		spawn_hit_spark(player_ship.global_position, Color(0.0, 0.9, 1.0))
		player_ship.queue_free()
	
	get_tree().paused = true
	
	var name_popup = load("res://name_entry_overlay.gd").new(score)
	name_popup.name_submitted.connect(func(_name):
		var gameover_overlay = load("res://game_overlays.gd").new(false, main_game_level(), score)
		gameover_overlay.retry_clicked.connect(func(): 
			get_tree().paused = false
			get_tree().reload_current_scene()
		)
		gameover_overlay.menu_clicked.connect(func(): 
			get_tree().paused = false
			get_tree().change_scene_to_file("res://menu.tscn")
		)
		get_tree().root.add_child(gameover_overlay)
	)
	get_tree().root.add_child(name_popup)

func on_victory() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	get_tree().paused = true
	var victory_overlay = load("res://game_overlays.gd").new(true, main_game_level(), score)
	
	victory_overlay.retry_clicked.connect(func(): 
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	victory_overlay.next_level_clicked.connect(func(): 
		get_tree().paused = false
		var next_lvl = main_game_level() + 1
		var main_script = load("res://main.gd")
		if main_script:
			main_script.current_level = next_lvl
		
		if next_lvl == 3:
			get_tree().change_scene_to_file("res://cyber_hangman.tscn")
		elif next_lvl == 6:
			get_tree().change_scene_to_file("res://neon_color_switch.tscn")
		elif next_lvl in [2, 4, 9]:
			get_tree().change_scene_to_file("res://space_shooter.tscn")
		else:
			get_tree().change_scene_to_file("res://main.tscn")
	)
	victory_overlay.menu_clicked.connect(func(): 
		get_tree().paused = false
		get_tree().change_scene_to_file("res://menu.tscn")
	)
	get_tree().root.add_child(victory_overlay)

func setup_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 5

	score_label = Label.new()
	score_label.position = Vector2(35, 35)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	canvas.add_child(score_label)

	target_label = Label.new()
	target_label.position = Vector2(35, 75)
	target_label.add_theme_font_size_override("font_size", 18)
	target_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	canvas.add_child(target_label)

	defense_label = Label.new()
	defense_label.position = Vector2(35, 110)
	defense_label.add_theme_font_size_override("font_size", 16)
	defense_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	canvas.add_child(defense_label)

	var pause_btn = Button.new()
	pause_btn.text = "❚❚"
	pause_btn.custom_minimum_size = Vector2(50, 50)
	pause_btn.position = Vector2(screen_size.x - 85, 35)
	pause_btn.add_theme_font_size_override("font_size", 20)
	pause_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var pause_style = create_arcade_button_style(Color(0.0, 0.9, 1.0))
	pause_btn.add_theme_stylebox_override("normal", pause_style)
	pause_btn.add_theme_stylebox_override("hover", pause_style)
	pause_btn.add_theme_stylebox_override("pressed", pause_style)
	pause_btn.pressed.connect(func(): toggle_pause_menu())
	canvas.add_child(pause_btn)

	var red_line_y = screen_size.y - 190.0
	var red_line = Line2D.new()
	red_line.width = 10.0
	red_line.default_color = Color(1.0, 0.1, 0.1, 0.95)
	red_line.add_point(Vector2(0, red_line_y))
	red_line.add_point(Vector2(screen_size.x, red_line_y))
	canvas.add_child(red_line)

	var shoot_btn = create_control_button("FIRE", Vector2(screen_size.x - 180, screen_size.y - 145), Vector2(160, 85), Color(1.0, 0.0, 0.5))
	shoot_btn.add_theme_font_size_override("font_size", 28)
	shoot_btn.button_down.connect(func(): firing_pressed = true)
	shoot_btn.button_up.connect(func(): firing_pressed = false)
	canvas.add_child(shoot_btn)

	update_ui()
	add_child(canvas)

func update_ui() -> void:
	if score_label:
		score_label.text = "SCORE: " + str(score)
	if target_label:
		target_label.text = "TARGET: " + str(target_score) + " [STAGE " + str(main_game_level()) + "]"
	if defense_label:
		defense_label.text = "ESCAPED: " + str(escaped_enemies) + " / " + str(max_escaped_allowed)

func create_control_button(txt: String, pos: Vector2, min_size: Vector2, border_color: Color) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = min_size
	btn.position = pos
	btn.add_theme_font_size_override("font_size", 26)
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return btn

func create_arcade_button_style(border_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.04, 0.12, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func setup_matrix_background() -> void:
	var matrix_bg = MatrixBackground.new()
	matrix_bg.name = "MatrixBackground"
	matrix_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	matrix_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(matrix_bg)
	move_child(matrix_bg, 0)

class MatrixBackground extends Control:
	var drops: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		randomize()
		for i in range(40):
			drops.append({
				"x": randf_range(0, 720),
				"y": randf_range(-1280, 0),
				"speed": randf_range(300, 600),
				"length": randf_range(80, 200)
			})

	func _process(delta: float) -> void:
		for drop in drops:
			drop["y"] += drop["speed"] * delta
			if drop["y"] > 1280:
				drop["y"] = randf_range(-400, -50)
				drop["x"] = randf_range(0, 720)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 720, 1280), Color(0.02, 0.03, 0.05, 1.0))
		
		for drop in drops:
			var start_pos = Vector2(drop["x"], drop["y"] - drop["length"])
			var end_pos = Vector2(drop["x"], drop["y"])
			draw_line(start_pos, end_pos, Color(0.0, 0.3, 0.1, 0.4), 2.0)
			draw_line(end_pos - Vector2(0, 15), end_pos, Color(0.2, 1.0, 0.4, 0.9), 3.0)
