extends Control

@export var anim_time := 0.18
@export var delay_between_items := 0.04
@export var closed_scale := 0.85
@export var frame_rotate_time := 0.45

@onready var profile_button: Button = $profile/profile_button
@onready var profile_frame: Node2D = $profile/profile_frame

@onready var items: Array[Control] = [
	$VBoxContainer/Control,
	$VBoxContainer/Control5,
	$VBoxContainer/Control2,
	$VBoxContainer/Control3,
]

var opened := false
var item_heights: Array[float] = []


func _ready() -> void:
	profile_button.flat = true
	profile_button.mouse_filter = Control.MOUSE_FILTER_STOP
	profile_button.pressed.connect(_toggle_settings)

	for item in items:
		item_heights.append(item.size.y)

		item.visible = false
		item.modulate.a = 0.0
		item.scale = Vector2(closed_scale, closed_scale)
		item.custom_minimum_size.y = 0.0


func _toggle_settings() -> void:
	_rotate_frame_once()

	if opened:
		_close_settings()
	else:
		_open_settings()

	opened = !opened


func _rotate_frame_once() -> void:
	var tween := create_tween()

	tween.tween_property(
		profile_frame,
		"rotation",
		profile_frame.rotation + TAU,
		frame_rotate_time
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _open_settings() -> void:
	for i in items.size():
		var item := items[i]
		item.visible = true

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			item,
			"custom_minimum_size:y",
			item_heights[i],
			anim_time
		).set_delay(i * delay_between_items)

		tween.tween_property(
			item,
			"modulate:a",
			1.0,
			anim_time
		).set_delay(i * delay_between_items)

		tween.tween_property(
			item,
			"scale",
			Vector2.ONE,
			anim_time
		).set_delay(i * delay_between_items)


func _close_settings() -> void:
	for i in items.size():
		var item := items[i]

		var tween := create_tween()
		tween.set_parallel(true)

		tween.tween_property(
			item,
			"custom_minimum_size:y",
			0.0,
			anim_time
		).set_delay(i * delay_between_items)

		tween.tween_property(
			item,
			"modulate:a",
			0.0,
			anim_time
		).set_delay(i * delay_between_items)

		tween.tween_property(
			item,
			"scale",
			Vector2(closed_scale, closed_scale),
			anim_time
		).set_delay(i * delay_between_items)

		tween.finished.connect(_hide_item.bind(item))


func _hide_item(item: Control) -> void:
	item.visible = false
