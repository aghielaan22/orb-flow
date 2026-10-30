extends Area2D

@export var speed: float = 900.0

func _ready() -> void:
	# Optional: ensure signal is connected via code if not done in the editor
	if not is_connected("area_entered", _on_area_entered):
		area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	position.y -= speed * delta
	if position.y < -50:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage()
		queue_free()
