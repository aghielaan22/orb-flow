extends Line2D
# neon_trail.gd - Smooth fading neon trail for the physics orb

@export var max_points: int = 25
@export var target_path: NodePath
var target: Node2D = null

func _ready() -> void:
	top_level = true
	if not target_path.is_empty():
		target = get_node(target_path)
	
	# Cyberpunk neon glow styling
	width = 12.0
	default_color = Color(0.0, 0.9, 1.0, 0.8) # Cyan glow
	
	# Add a soft neon additive blend effect if desired
	antialiased = true

func _process(_delta: float) -> void:
	if not target:
		# If no target path is set, fallback to following parent
		if get_parent() is Node2D:
			target = get_parent()
		else:
			return

	add_point(target.global_position)
	
	if get_point_count() > max_points:
		remove_point(0)
