extends Line2D
# ship_visual.gd - Procedural vector starfighter graphic for the player ship

func _ready() -> void:
	width = 3.5
	default_color = Color(0.0, 0.95, 1.0) # Electric Cyan
	closed = true
	
	clear_points()
	add_point(Vector2(0, -28))    # Nose tip
	add_point(Vector2(-10, -10))  # Left cockpit taper
	add_point(Vector2(-24, 22))   # Left wing tip
	add_point(Vector2(-8, 14))    # Left engine recess
	add_point(Vector2(0, 20))     # Center tail notch
	add_point(Vector2(8, 14))     # Right engine recess
	add_point(Vector2(24, 22))    # Right wing tip
	add_point(Vector2(10, -10))   # Right cockpit taper
