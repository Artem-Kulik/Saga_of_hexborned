extends Control

@export_file("*.tscn") var scene_to_load: String = ""

@export var hover_scale := 1.04
@export var hover_time := 0.15
@export var highlight_alpha := 1.0

@onready var button: Button = $play
@onready var highlight: CanvasItem = $highlight

var hover_tween: Tween


func _ready() -> void:
	pivot_offset = size / 2.0

	highlight.visible = true
	highlight.modulate.a = 0.0

	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_on_button_pressed)
	button.mouse_entered.connect(_on_button_mouse_entered)
	button.mouse_exited.connect(_on_button_mouse_exited)


func _on_button_mouse_entered() -> void:
	if hover_tween:
		hover_tween.kill()

	highlight.visible = true

	hover_tween = create_tween()
	hover_tween.set_parallel(true)

	hover_tween.tween_property(
		self,
		"scale",
		Vector2.ONE * hover_scale,
		hover_time
	)

	hover_tween.tween_property(
		highlight,
		"modulate:a",
		highlight_alpha,
		hover_time
	)


func _on_button_mouse_exited() -> void:
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.set_parallel(true)

	hover_tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		hover_time
	)

	hover_tween.tween_property(
		highlight,
		"modulate:a",
		0.0,
		hover_time
	)


func _on_button_pressed() -> void:
	print("Кнопка натиснута")

	if scene_to_load.is_empty():
		push_warning("Не вказана сцена")
		return

	get_tree().change_scene_to_file(scene_to_load)
