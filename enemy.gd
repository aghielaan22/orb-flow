extends Area2D

@export var speed: float = 200.0

func _physics_process(delta: float) -> void:
	position.y += speed * delta
	if position.y > get_viewport_rect().size.y + 50:
		queue_free()

func take_damage() -> void:
	# Find the space shooter scene and add score
	var space_shooter = get_tree().root.get_node_or_null("SpaceShooter")
	if space_shooter and space_shooter.has_method("add_score"):
		space_shooter.add_score(1)
		
	queue_free()
