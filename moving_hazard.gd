extends Area2D

var move_speed: float = 180.0
var move_direction: Vector2 = Vector2.RIGHT
var travel_limit: float = 200.0
var distance_traveled: float = 0.0

func setup_visual() -> void:
	# Add collision shape
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(80, 10)
	col.shape = rect
	add_child(col)

	# Add neon vector visual
	var visual = Line2D.new()
	visual.width = 4.0
	visual.default_color = Color(1.0, 0.0, 0.4) # Magenta hazard bar
	visual.add_point(Vector2(-40, 0))
	visual.add_point(Vector2(40, 0))
	add_child(visual)
	
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Move back and forth purely through code math
	var step = move_speed * delta
	position += move_direction * step
	distance_traveled += step
	
	# Reverse direction when reaching the travel limit
	if distance_traveled >= travel_limit:
		move_direction = -move_direction
		distance_traveled = 0.0

func _on_body_entered(body: Node) -> void:
	# Check if the body entering is the orb or any physics body we care about
	if body.name == "Orb" or body.name == "Player" or "Ball" in body.name:
		print("[Hazard] Hit by code-driven barrier: ", body.name)
		var main_node = get_tree().current_scene
		if main_node and main_node.has_method("reset_level"):
			# Safely defer the reset to avoid physics callback errors
			main_node.call_deferred("reset_level")
		else:
			get_tree().reload_current_scene()
	else:
		print("[Hazard] Collided with unknown body: ", body.name)
