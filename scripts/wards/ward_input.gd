extends Node

signal ward_clicked
signal ward_drag_started
signal hover_entered
signal hover_exited

var owner_control: Control
var skill_buttons: Control

var oval_width: float = 315.0
var oval_height: float = 420.0
var oval_offset: Vector2 = Vector2(-60, -40)

var hovering_oval: bool = false


func setup(
	owner_ref: Control,
	skill_buttons_ref: Control,
	oval_width_value: float,
	oval_height_value: float,
	oval_offset_value: Vector2
) -> void:
	owner_control = owner_ref
	skill_buttons = skill_buttons_ref

	oval_width = oval_width_value
	oval_height = oval_height_value
	oval_offset = oval_offset_value


func process_hover() -> void:
	if owner_control == null:
		return

	if hovering_oval:
		var local_mouse_pos: Vector2 = owner_control.get_local_mouse_position()

		if not _is_inside_oval(local_mouse_pos):
			hovering_oval = false
			hover_exited.emit()


func handle_gui_input(event: InputEvent) -> void:
	if owner_control == null:
		return

	if event is InputEventMouseMotion:
		if _is_mouse_over_skills():
			if hovering_oval:
				hovering_oval = false
				hover_exited.emit()
			return

		var inside_oval: bool = _is_inside_oval(event.position)

		if inside_oval and not hovering_oval:
			hovering_oval = true
			hover_entered.emit()
		elif not inside_oval and hovering_oval:
			hovering_oval = false
			hover_exited.emit()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _is_mouse_over_skills():
				return

			ward_clicked.emit()
			ward_drag_started.emit()


func handle_mouse_exit() -> void:
	if hovering_oval:
		hovering_oval = false
		hover_exited.emit()


func _is_inside_oval(local_mouse_pos: Vector2) -> bool:
	var center: Vector2 = owner_control.size / 2.0 + oval_offset
	var p: Vector2 = local_mouse_pos - center

	var rx: float = oval_width / 2.0
	var ry: float = oval_height / 2.0

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
