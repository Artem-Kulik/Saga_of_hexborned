extends Control

signal skill_pressed(skill_key: String)

@export var skill_key: String = "Q"
@export var cooldown: int = 0

@export var oval_width: float = 49.0
@export var oval_height: float = 54.0
@export var oval_offset: Vector2 = Vector2.ZERO

@export var debug_draw_oval: bool = false
@export var debug_oval_color: Color = Color.RED
@export var debug_oval_width: float = 2.0

@export var hover_scale_multiplier: float = 1.12
@export var scale_speed: float = 0.12

@onready var highlight: Control = $Highlight
@onready var key_label: Label = $Key

var base_scale: Vector2
var tween: Tween
var hovering_oval: bool = false
var base_modulate: Color


func _ready() -> void:
	base_scale = scale
	pivot_offset = size / 2.0

	highlight.modulate.a = 0.0
	key_label.text = skill_key

	mouse_filter = Control.MOUSE_FILTER_STOP

	for child in get_children():
		if child is Control and child != highlight:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	base_modulate = modulate


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

	elif event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event

		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if _is_inside_oval(mouse_button.position):
				try_press()
				accept_event()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("skill_" + skill_key.to_lower()):
		try_press()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		if hovering_oval:
			hovering_oval = false
			_on_oval_mouse_exited()


func _draw() -> void:
	if !debug_draw_oval:
		return

	var points: PackedVector2Array = PackedVector2Array()

	var center: Vector2 = size / 2.0 + oval_offset
	var rx: float = oval_width / 2.0
	var ry: float = oval_height / 2.0
	var steps: int = 64

	for i in range(steps + 1):
		var t: float = (float(i) / float(steps)) * TAU
		var x: float = center.x + cos(t) * rx
		var y: float = center.y + sin(t) * ry
		points.append(Vector2(x, y))

	draw_polyline(points, debug_oval_color, debug_oval_width)


func _is_inside_oval(local_mouse_pos: Vector2) -> bool:
	var center: Vector2 = size / 2.0 + oval_offset
	var p: Vector2 = local_mouse_pos - center

	var rx: float = oval_width / 2.0
	var ry: float = oval_height / 2.0

	return (
		(p.x * p.x) / (rx * rx) +
		(p.y * p.y) / (ry * ry)
	) <= 1.0


func try_press() -> void:
	if cooldown > 0:
		return

	skill_pressed.emit(skill_key)


func _on_oval_mouse_entered() -> void:
	highlight.modulate.a = 1.0
	animate_scale(base_scale * hover_scale_multiplier)


func _on_oval_mouse_exited() -> void:
	highlight.modulate.a = 0.0
	animate_scale(base_scale)


func animate_scale(target_scale: Vector2) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, scale_speed)


func set_cooldown(value: int) -> void:
	cooldown = value
