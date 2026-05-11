extends Control

@onready var ward_visual: Control = $WardVisual
@onready var highlight: Control = $WardVisual/Highlight
@onready var ward_skill_buttons: Control = get_node_or_null("WardSkillButtons")

@export var oval_width: float = 150
@export var oval_height: float = 420
@export var oval_offset: Vector2 = Vector2(-1, -170)

@export var hover_scale: Vector2 = Vector2(1.015, 1.015)
@export var scale_speed: float = 0.06

var hovering_oval: bool = false
var normal_scale: Vector2 = Vector2.ONE
var tween: Tween


func _ready() -> void:
	highlight.visible = false

	normal_scale = ward_visual.scale
	ward_visual.pivot_offset = ward_visual.size / 2.0

	mouse_filter = Control.MOUSE_FILTER_STOP
	ward_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in ward_visual.get_children():
		if child is Control and child != highlight:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if hovering_oval:
		var local_mouse_pos: Vector2 = get_local_mouse_position()

		if !_is_inside_oval(local_mouse_pos):
			hovering_oval = false
			_on_oval_mouse_exited()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _is_mouse_over_skills():
			if hovering_oval:
				hovering_oval = false
				_on_oval_mouse_exited()
			return

		var inside_oval: bool = _is_inside_oval(event.position)

		if inside_oval and !hovering_oval:
			hovering_oval = true
			_on_oval_mouse_entered()
		elif !inside_oval and hovering_oval:
			hovering_oval = false
			_on_oval_mouse_exited()


func _is_inside_oval(local_mouse_pos: Vector2) -> bool:
	var center: Vector2 = size / 2.0 + oval_offset
	var p: Vector2 = local_mouse_pos - center

	var rx: float = oval_width / 2.0
	var ry: float = oval_height / 2.0

	return ((p.x * p.x) / (rx * rx) + (p.y * p.y) / (ry * ry)) <= 1.0


func _is_mouse_over_skills() -> bool:
	if ward_skill_buttons == null:
		return false

	return _is_mouse_over_control_children(ward_skill_buttons)


func _is_mouse_over_control_children(node: Node) -> bool:
	if node == null:
		return false

	var mouse_global: Vector2 = get_global_mouse_position()

	for child in node.get_children():
		if child is Control:
			if child.get_global_rect().has_point(mouse_global):
				return true

		if _is_mouse_over_control_children(child):
			return true

	return false


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hovering_oval:
		hovering_oval = false
		_on_oval_mouse_exited()


func _on_oval_mouse_entered() -> void:
	highlight.visible = true
	_animate_scale(normal_scale * hover_scale)

	var skill_panel = get_tree().get_first_node_in_group("skill_panel")
	if skill_panel:
		skill_panel.show_panel()


func _on_oval_mouse_exited() -> void:
	highlight.visible = false
	_animate_scale(normal_scale)


func _animate_scale(target_scale: Vector2) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ward_visual, "scale", target_scale, scale_speed)
