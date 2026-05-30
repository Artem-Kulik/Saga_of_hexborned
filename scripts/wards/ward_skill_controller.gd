extends Node

signal skill_selected(skill_key: String)

var team: String = "ally"

var skill_buttons: Control
var skill_q = null
var skill_w = null
var skill_e = null

var target_arrow = null
var target_arrow_scene := preload("res://Основа/animation/target_arrow.tscn")


func setup(
	team_value: String,
	skill_buttons_ref,
	skill_q_ref,
	skill_w_ref,
	skill_e_ref
) -> void:
	team = team_value

	skill_buttons = skill_buttons_ref
	skill_q = skill_q_ref
	skill_w = skill_w_ref
	skill_e = skill_e_ref

	_connect_skill_buttons()
	_update_visibility()


func set_team(value: String) -> void:
	team = value
	_update_visibility()


func hide_buttons() -> void:
	if skill_buttons:
		skill_buttons.visible = false


func _connect_skill_buttons() -> void:
	if skill_q and skill_q.has_signal("skill_pressed"):
		skill_q.connect("skill_pressed", Callable(self, "_on_skill_pressed"))

	if skill_w and skill_w.has_signal("skill_pressed"):
		skill_w.connect("skill_pressed", Callable(self, "_on_skill_pressed"))

	if skill_e and skill_e.has_signal("skill_pressed"):
		skill_e.connect("skill_pressed", Callable(self, "_on_skill_pressed"))


func _update_visibility() -> void:
	if skill_buttons == null:
		return

	skill_buttons.visible = true


func show_target_arrow(from_position: Vector2) -> void:
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null

	target_arrow = target_arrow_scene.instantiate()

	get_tree().current_scene.add_child(target_arrow)

	if target_arrow.has_method("setup"):
		target_arrow.setup(from_position)


func hide_target_arrow() -> void:
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null


func _on_skill_pressed(skill_key: String) -> void:
	if team != "ally":
		return

	skill_selected.emit(skill_key)
