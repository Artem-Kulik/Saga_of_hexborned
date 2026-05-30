extends Button

@onready var camera: Camera2D = $"../../../camera"

@export var focus_zoom := Vector2(0.1, 0.1)


func _pressed() -> void:
	var target_pos := global_position + size / 2.0

	var tween := create_tween()

	tween.parallel().tween_property(
		camera,
		"global_position",
		target_pos,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(
		camera,
		"zoom",
		focus_zoom,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
