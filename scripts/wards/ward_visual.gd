extends Node

var ward_visual: Control
var highlight: Control

var hover_scale: Vector2 = Vector2(1.015, 1.015)
var active_scale: Vector2 = Vector2(1.04, 1.04)
var scale_speed: float = 0.06

var normal_scale: Vector2 = Vector2.ONE
var tween: Tween

var is_hovered: bool = false
var is_active_turn: bool = false
var is_dead: bool = false


func setup(
	ward_visual_ref: Control,
	highlight_ref: Control,
	hover_scale_value: Vector2,
	active_scale_value: Vector2,
	scale_speed_value: float
) -> void:
	ward_visual = ward_visual_ref
	highlight = highlight_ref

	hover_scale = hover_scale_value
	active_scale = active_scale_value
	scale_speed = scale_speed_value

	highlight.visible = false

	normal_scale = ward_visual.scale
	ward_visual.pivot_offset = ward_visual.size / 2.0


func set_hovered(value: bool) -> void:
	if is_dead:
		return

	is_hovered = value
	highlight.visible = value

	_apply_scale()


func set_active_turn(value: bool) -> void:
	if is_dead:
		is_active_turn = false
		return

	is_active_turn = value
	_apply_scale()


func play_death_visual() -> void:
	is_dead = true
	is_hovered = false
	is_active_turn = false

	if highlight:
		highlight.visible = false

	if ward_visual:
		ward_visual.modulate = Color(0.25, 0.25, 0.25, 0.55)


func _apply_scale() -> void:
	var target_scale: Vector2 = normal_scale

	if is_active_turn:
		target_scale = normal_scale * active_scale
	elif is_hovered:
		target_scale = normal_scale * hover_scale

	_animate_scale(target_scale)


func _animate_scale(target_scale: Vector2) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ward_visual, "scale", target_scale, scale_speed)
