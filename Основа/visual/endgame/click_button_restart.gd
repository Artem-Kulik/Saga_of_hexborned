extends Button

@onready var glow = $"../Glow"

func _ready() -> void:
	disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	glow.modulate.a = 0.0

	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)


func _pressed() -> void:
	get_tree().reload_current_scene()


func _on_hover_enter() -> void:
	create_tween().tween_property(
		glow,
		"modulate:a",
		0.7,
		0.12
	)


func _on_hover_exit() -> void:
	create_tween().tween_property(
		glow,
		"modulate:a",
		0.0,
		0.12
	)
