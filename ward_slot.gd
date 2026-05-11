extends Control

@onready var ward_visual: Control = $WardVisual
@onready var highlight: Control = $WardVisual/Highlight

@export var debug_draw_oval: bool = true
@export var debug_oval_color: Color = Color.RED
@export var debug_oval_width: float = 3.0

@export var oval_width: float = 315.0
@export var oval_height: float = 420.0
@export var oval_offset: Vector2 = Vector2(-60, -40)

@export var hover_scale: Vector2 = Vector2(1.015, 1.015)
@export var scale_speed: float = 0.06

var hovering_oval: bool = false
var normal_scale: Vector2
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
		var mouse_event: InputEventMouseMotion = event
		var inside_oval: bool = _is_inside_oval(mouse_event.position)

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

	return (
		(p.x * p.x) / (rx * rx) +
		(p.y * p.y) / (ry * ry)
	) <= 1.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and hovering_oval:
		hovering_oval = false
		_on_oval_mouse_exited()


func _draw() -> void:
	if !debug_draw_oval:
		return

	var points: PackedVector2Array = PackedVector2Array()

	var center: Vector2 = size / 2.0 + oval_offset
	var rx: float = oval_width / 2.0
	var ry: float = oval_height / 2.0
	var steps: int = 96

	for i in range(steps + 1):
		var t: float = (float(i) / float(steps)) * TAU
		var x: float = center.x + cos(t) * rx
		var y: float = center.y + sin(t) * ry

		points.append(Vector2(x, y))

	draw_polyline(points, debug_oval_color, debug_oval_width)


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
