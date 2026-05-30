extends Node

signal ward_clicked
signal ward_drag_started
signal hover_entered
signal hover_exited

var owner_control: Control
var skill_buttons: Control
var hitbox_oval: Control

var hovering_oval: bool = false

var _is_pressed: bool = false
var _drag_started: bool = false
var _press_local_pos: Vector2 = Vector2.ZERO
const _DRAG_THRESHOLD: float = 10.0


func setup(
	owner_ref: Control,
	skill_buttons_ref: Control,
	hitbox_oval_ref: Control
) -> void:
	owner_control = owner_ref
	skill_buttons = skill_buttons_ref
	hitbox_oval = hitbox_oval_ref


func process_hover() -> void:
	if owner_control == null or hitbox_oval == null:
		return

	if hovering_oval and not _is_inside_hitbox():
		hovering_oval = false
		hover_exited.emit()


func handle_gui_input(event: InputEvent) -> void:
	if owner_control == null or hitbox_oval == null:
		return

	if event is InputEventMouseMotion:
		# Drag threshold: лише після реального руху мишки
		if _is_pressed and not _drag_started:
			if event.position.distance_to(_press_local_pos) >= _DRAG_THRESHOLD:
				_drag_started = true
				ward_drag_started.emit()

		if _is_mouse_over_skills():
			if hovering_oval:
				hovering_oval = false
				hover_exited.emit()
			return

		var inside := _is_inside_hitbox()
		if inside and not hovering_oval:
			hovering_oval = true
			hover_entered.emit()
		elif not inside and hovering_oval:
			hovering_oval = false
			hover_exited.emit()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_mouse_over_skills():
					return
				if not _is_inside_hitbox():
					return
				_is_pressed = true
				_drag_started = false
				_press_local_pos = event.position
				ward_clicked.emit()
			else:
				_is_pressed = false
				_drag_started = false


func handle_mouse_exit() -> void:
	if hovering_oval:
		hovering_oval = false
		hover_exited.emit()


func _is_inside_hitbox() -> bool:
	var local_mouse_pos: Vector2 = hitbox_oval.get_local_mouse_position()
	var center: Vector2 = hitbox_oval.size / 2.0
	var rx: float = hitbox_oval.size.x / 2.0
	var ry: float = hitbox_oval.size.y / 2.0

	if rx <= 0.0 or ry <= 0.0:
		return false

	var p: Vector2 = local_mouse_pos - center
	return ((p.x * p.x) / (rx * rx) + (p.y * p.y) / (ry * ry)) <= 1.0


func _is_mouse_over_skills() -> bool:
	if skill_buttons == null:
		return false
	return _is_mouse_over_control_children(skill_buttons)


func _is_mouse_over_control_children(node: Node) -> bool:
	if node == null:
		return false

	var mouse_global: Vector2 = owner_control.get_global_mouse_position()

	for child in node.get_children():
		if child is Control:
			if child.get_global_rect().has_point(mouse_global):
				return true
		if _is_mouse_over_control_children(child):
			return true

	return false
