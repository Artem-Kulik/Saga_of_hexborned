extends Control

@export_file("*.tscn") var scene_to_load: String = ""

@export var hover_time := 0.2
@export var hover_alpha := 1.0

@export var screen_position := Vector2(40, 40)

@onready var highlight: CanvasItem = $highlight
@onready var texture: CanvasItem = $texture
@onready var button: Button = $Button
@onready var label: CanvasItem = $name

var hover_tween: Tween


func _ready() -> void:
	# Позиція саме на екрані, бо вузол лежить у CanvasLayer
	position = screen_position
	set_anchors_preset(Control.PRESET_TOP_LEFT)

	highlight.visible = true
	highlight.modulate.a = 0.0

	button.flat = true
	button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Щоб декоративні елементи не перекривали Button
	_set_ignore_mouse(texture)
	_set_ignore_mouse(highlight)
	_set_ignore_mouse(label)

	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	button.pressed.connect(_on_pressed)


func _set_ignore_mouse(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in node.get_children():
		_set_ignore_mouse(child)


func _on_mouse_entered() -> void:
	if hover_tween:
		hover_tween.kill()

	highlight.visible = true

	hover_tween = create_tween()
	hover_tween.tween_property(
		highlight,
		"modulate:a",
		hover_alpha,
		hover_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_mouse_exited() -> void:
	if hover_tween:
		hover_tween.kill()

	hover_tween = create_tween()
	hover_tween.tween_property(
		highlight,
		"modulate:a",
		0.0,
		hover_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await hover_tween.finished

	highlight.visible = false


func _on_pressed() -> void:
	if scene_to_load == "":
		push_warning("Не вказано сцену для завантаження в back_button.")
		return

	SceneLoader.change_scene(scene_to_load)
