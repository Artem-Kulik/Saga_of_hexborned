extends Node2D

@onready var visual_root: Node2D = $VisualRoot

func set_direction(direction: Vector2) -> void:
	visual_root.rotation = direction.angle()
