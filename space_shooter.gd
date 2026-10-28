extends Node2D

static var current_level: int = 2
var score: int = 0
var target_score: int = 15

var screen_size: Vector2 = Vector2(720, 1280)

var enemies: Array = []
var enemy_bullets: Array = []
var hazards: Array = []

var spawn_timer: float = 0.0
var enemy_fire_timer: float = 0.0
var hazard_timer: float = 0.0

var score_label: Label = null
var target_label: Label = null
var is_game_over: bool = false
var is_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	match main_game_level():
		2: target_score = 15
		4: target_score = 25
		6: target_score = 35
		_: target_score = 20

	setup_matrix_background()
	setup_ui()
	print("[Space Shooter] Initialized Level ", main_game_level(), " | Target Score: ", target_score)

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
			if event.keycode == KEY_R or event.keycode == KEY_R:
				get_tree().reload_current_scene()
			elif event.keycode == KEY_N:
				on_victory()

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
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS # Keeps the menu running while paused
	
	# Dim backdrop
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
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Resume Button
	create_overlay_button(vbox, "▶ RESUME PROTOCOL", Color(0.0, 0.9, 1.0), func():
		toggle_pause_menu()
	)
	
	# Restart Button
	create_overlay_button(vbox, "↺ RESTART LEVEL", Color(1.0, 0.0, 0.6), func():
		get_tree().paused = false
		var overlay = get_tree().root.get_node_or_null("PauseOverlay")
		if overlay:
			overlay.queue_free()
		get_tree().reload_current_scene()
	)
	
	# Menu Button
	create_overlay_button(vbox, "⌂ MAIN MENU", Color(1.0, 0.0, 0.4), func():
		get_tree().paused = false
		var overlay = get_tree().root.get_node_or_null("PauseOverlay")
		if overlay:
			overlay.queue_free()
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

func handle_spawning(delta: float) -> void:
	var spawn_rate = 1.2 if main_game_level() == 2 else (0.9 if main_game_level() == 4 else 0.6)
	spawn_timer += delta
	if spawn_timer >= spawn_rate:
		spawn_timer = 0.0
		spawn_enemy()

	if main_game_level() >= 4:
		enemy_fire_timer += delta
		if enemy_fire_timer >= 1.5:
			enemy_fire_timer = 0.0
			enemy_shoot_bullet()

	if main_game_level() == 6:
		hazard_timer += delta
		if hazard_timer >= 2.5:
			hazard_timer = 0.0
			spawn_green_hazard()

func spawn_enemy() -> void:
	var enemy = Area2D.new()
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

func _on_enemy_body_entered(body: Node, _enemy: Area2D) -> void:
	if is_game_over:
		return
	if body.name == "PlayerShip" or "Player" in body.name:
		on_player_hit()

func _on_enemy_area_entered(area: Area2D, enemy: Area2D) -> void:
	if is_game_over or not is_instance_valid(enemy):
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
	bullet.position = shooter.position + Vector2(0, 25)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	bullet.add_child(shape)

	var visual = Line2D.new()
	visual.width = 10.0
	visual.default_color = Color(1.0, 0.5, 0.0)
	visual.add_point(Vector2(0, -5))
	visual.add_point(Vector2(0, 5))
	bullet.add_child(visual)

	bullet.body_entered.connect(_on_bullet_body_entered.bind(bullet))

	add_child(bullet)
	enemy_bullets.append(bullet)

func _on_bullet_body_entered(body: Node, bullet: Area2D) -> void:
	if is_game_over:
		return
	if body.name == "PlayerShip" or "Player" in body.name:
		on_player_hit()
		if is_instance_valid(bullet):
			bullet.queue_free()

func spawn_green_hazard() -> void:
	var hazard = Area2D.new()
	hazard.name = "GreenHazard"
	var spawn_x = randf_range(80, screen_size.x - 80)
	hazard.position = Vector2(spawn_x, -40)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	hazard.add_child(shape)

	var visual = Line2D.new()
	visual.width = 5.0
	visual.default_color = Color(0.2, 1.0, 0.2)
	for i in range(9):
		var angle = i * (PI * 2 / 8)
		visual.add_point(Vector2(cos(angle) * 18, sin(angle) * 18))
	hazard.add_child(visual)

	hazard.body_entered.connect(_on_hazard_body_entered.bind(hazard))
	hazard.area_entered.connect(_on_hazard_area_entered.bind(hazard))

	add_child(hazard)
	hazards.append(hazard)

func _on_hazard_body_entered(body: Node, _hazard: Area2D) -> void:
	if is_game_over:
		return
	if body.name == "PlayerShip" or "Player" in body.name:
		on_player_hit()

func _on_hazard_area_entered(area: Area2D, hazard: Area2D) -> void:
	if is_game_over or not is_instance_valid(hazard):
		return
	if area.is_in_group("bullets") or "Bullet" in area.name or "bullet" in area.name:
		if is_instance_valid(area):
			area.queue_free()
		score = max(0, score - 3)
		update_ui()
		spawn_hit_spark(hazard.global_position, Color(0.2, 1.0, 0.2))
		if hazard in hazards:
			hazards.erase(hazard)
		hazard.queue_free()

func spawn_hit_spark(pos: Vector2, spark_color: Color) -> void:
	var spark = CPUParticles2D.new()
	spark.global_position = pos
	spark.emitting = true
	spark.one_shot = true
	spark.amount = 12
	spark.lifetime = 0.3
	spark.explosiveness = 1.0
	spark.initial_velocity_min = 80.0
	spark.initial_velocity_max = 180.0
	spark.scale_amount_min = 3.0
	spark.scale_amount_max = 6.0
	spark.color = spark_color
	add_child(spark)
	
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(_on_spark_timeout.bind(spark))

func _on_spark_timeout(spark: CPUParticles2D) -> void:
	if is_instance_valid(spark):
		spark.queue_free()

func update_projectiles_and_enemies(delta: float) -> void:
	var speed = 220.0 if main_game_level() == 2 else 300.0
	for i in range(enemies.size() - 1, -1, -1):
		var e = enemies[i]
		if is_instance_valid(e):
			e.position.y += speed * delta
			if e.position.y > screen_size.y + 50:
				e.queue_free()
				enemies.remove_at(i)

	for i in range(enemy_bullets.size() - 1, -1, -1):
		var b = enemy_bullets[i]
		if is_instance_valid(b):
			b.position.y += 420.0 * delta
			if b.position.y > screen_size.y + 50:
				b.queue_free()
				enemy_bullets.remove_at(i)

	for i in range(hazards.size() - 1, -1, -1):
		var h = hazards[i]
		if is_instance_valid(h):
			h.position.y += 180.0 * delta
			if h.position.y > screen_size.y + 50:
				h.queue_free()
				hazards.remove_at(i)

func on_player_hit() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	get_tree().paused = true
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
		
		if next_lvl in [2, 4, 6]:
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

	# Score Label
	score_label = Label.new()
	score_label.position = Vector2(35, 35)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	canvas.add_child(score_label)

	# Target Label
	target_label = Label.new()
	target_label.position = Vector2(35, 75)
	target_label.add_theme_font_size_override("font_size", 18)
	target_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	canvas.add_child(target_label)

	# --- TOP-RIGHT PAUSE BUTTON ---
	var pause_btn = Button.new()
	pause_btn.text = "❚❚" # Pause icon symbol
	pause_btn.custom_minimum_size = Vector2(50, 50)
	
	# Anchor to top right with some padding (screen_size.x is 720)
	pause_btn.position = Vector2(screen_size.x - 85, 35)
	pause_btn.add_theme_font_size_override("font_size", 20)
	pause_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	# Cyberpunk style matching your theme
	var pause_style = StyleBoxFlat.new()
	pause_style.bg_color = Color(0.06, 0.04, 0.12, 0.9)
	pause_style.border_width_left = 2
	pause_style.border_width_top = 2
	pause_style.border_width_right = 2
	pause_style.border_width_bottom = 2
	pause_style.border_color = Color(0.0, 0.9, 1.0) # Cyan border
	pause_style.corner_radius_top_left = 6
	pause_style.corner_radius_top_right = 6
	pause_style.corner_radius_bottom_left = 6
	pause_style.corner_radius_bottom_right = 6
	
	pause_btn.add_theme_stylebox_override("normal", pause_style)
	pause_btn.add_theme_stylebox_override("hover", pause_style)
	pause_btn.add_theme_stylebox_override("pressed", pause_style)
	
	# Connect click event to toggle your pause menu
	pause_btn.pressed.connect(func():
		toggle_pause_menu()
	)
	canvas.add_child(pause_btn)

	update_ui()
	add_child(canvas)

func update_ui() -> void:
	if score_label:
		score_label.text = "SCORE: " + str(score)
	if target_label:
		target_label.text = "TARGET: " + str(target_score) + " [STAGE " + str(main_game_level()) + "]"

func setup_matrix_background() -> void:
	var matrix_bg = MatrixBackground.new()
	matrix_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(matrix_bg)
	move_child(matrix_bg, 0)

class MatrixBackground extends Control:
	var drops: Array = []

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		randomize()
		for i in range(35):
			drops.append({
				"x": randf_range(20, 700),
				"y": randf_range(-1280, 0),
				"speed": randf_range(300, 600),
				"length": randf_range(80, 200)
			})

	func _process(delta: float) -> void:
		for drop in drops:
			drop["y"] += drop["speed"] * delta
			if drop["y"] > 1280:
				drop["y"] = randf_range(-400, -50)
				drop["x"] = randf_range(20, 700)
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, size.x, size.y), Color(0.02, 0.05, 0.03, 1.0))
		
		for drop in drops:
			var start_pos = Vector2(drop["x"], drop["y"] - drop["length"])
			var end_pos = Vector2(drop["x"], drop["y"])
			draw_line(start_pos, end_pos, Color(0.0, 0.3, 0.1, 0.4), 2.0)
			draw_line(end_pos - Vector2(0, 15), end_pos, Color(0.2, 1.0, 0.4, 0.9), 3.0)
