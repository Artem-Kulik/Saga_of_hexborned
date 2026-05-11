extends Control

signal ward_clicked(ward)
signal skill_clicked(ward, skill_key: String)
signal ward_drag_started(ward)

@export var team: String = "ally"
@export var ward_index: int = 0
@export var max_hp: int = 100
@export var skill_damage: int = 50

@export var debug_draw_oval: bool = false
@export var debug_oval_color: Color = Color.RED
@export var debug_oval_width: float = 3.0

@export var oval_width: float = 315.0
@export var oval_height: float = 420.0
@export var oval_offset: Vector2 = Vector2(-60, -40)

@export var hover_scale: Vector2 = Vector2(1.015, 1.015)
@export var active_scale: Vector2 = Vector2(1.04, 1.04)
@export var scale_speed: float = 0.06

@onready var ward_visual: Control = $WardVisual
@onready var highlight: Control = $WardVisual/Highlight

@onready var hp_current = get_node_or_null("HPAnim/HP_current")
@onready var hp_delay = get_node_or_null("HPAnim/HP_delay")

@onready var skill_buttons = get_node_or_null("WardSkillButtons")
@onready var skill_q = get_node_or_null("WardSkillButtons/SkillButton_Q")
@onready var skill_w = get_node_or_null("WardSkillButtons/SkillButton_W")
@onready var skill_e = get_node_or_null("WardSkillButtons/SkillButton_E")

var current_hp: int
var is_dead: bool = false
var is_active_turn: bool = false

var hovering_oval: bool = false
var normal_scale: Vector2 = Vector2.ONE
var tween: Tween
var hp_tween: Tween


func _ready() -> void:
	current_hp = max_hp

	highlight.visible = false

	normal_scale = ward_visual.scale
	ward_visual.pivot_offset = ward_visual.size / 2.0

	mouse_filter = Control.MOUSE_FILTER_STOP
	ward_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in ward_visual.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_connect_skill_buttons()
	_setup_hp_bars()
	_update_hp_bar(false)

	if team == "enemy" and skill_buttons:
		skill_buttons.visible = false


func _process(_delta: float) -> void:
	if is_dead:
		return

	if hovering_oval:
		var local_mouse_pos: Vector2 = get_local_mouse_position()

		if !_is_inside_oval(local_mouse_pos):
			hovering_oval = false
			_on_oval_mouse_exited()


func _gui_input(event: InputEvent) -> void:
	if is_dead:
		return

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

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			ward_clicked.emit(self)
			ward_drag_started.emit(self)


func _connect_skill_buttons() -> void:
	if skill_q and skill_q.has_signal("skill_pressed"):
		skill_q.connect("skill_pressed", _on_skill_pressed)

	if skill_w and skill_w.has_signal("skill_pressed"):
		skill_w.connect("skill_pressed", _on_skill_pressed)

	if skill_e and skill_e.has_signal("skill_pressed"):
		skill_e.connect("skill_pressed", _on_skill_pressed)


func _setup_hp_bars() -> void:
	if hp_current:
		hp_current.min_value = 0
		hp_current.max_value = 100
		hp_current.value = 100

	if hp_delay:
		hp_delay.min_value = 0
		hp_delay.max_value = 100
		hp_delay.value = 100


func _update_hp_bar(animated: bool = true) -> void:
	var hp_percent: float = float(current_hp) / float(max_hp)
	var hp_value: float = hp_percent * 100.0

	if hp_current:
		hp_current.value = hp_value

	if hp_delay:
		if hp_tween:
			hp_tween.kill()

		if animated:
			hp_tween = create_tween()
			hp_tween.tween_property(hp_delay, "value", hp_value, 0.4)
		else:
			hp_delay.value = hp_value


func _is_inside_oval(local_mouse_pos: Vector2) -> bool:
	var center: Vector2 = size / 2.0 + oval_offset
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
	if is_dead:
		return

	highlight.visible = true
	_apply_visual_scale()

	var skill_panel = get_tree().get_first_node_in_group("skill_panel")
	if skill_panel and skill_panel.has_method("show_panel"):
		skill_panel.show_panel()


func _on_oval_mouse_exited() -> void:
	highlight.visible = false
	_apply_visual_scale()


func _apply_visual_scale() -> void:
	var target_scale: Vector2 = normal_scale

	if is_active_turn:
		target_scale = normal_scale * active_scale
	elif hovering_oval:
		target_scale = normal_scale * hover_scale

	_animate_scale(target_scale)


func _animate_scale(target_scale: Vector2) -> void:
	if tween:
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ward_visual, "scale", target_scale, scale_speed)


func _on_skill_pressed(skill_key: String) -> void:
	if is_dead:
		return

	if team != "ally":
		return

	skill_clicked.emit(self, skill_key)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0)

	_update_hp_bar(true)

	print(name, " отримав ", amount, " шкоди. HP: ", current_hp)

	if current_hp <= 0:
		die()


func die() -> void:
	is_dead = true
	is_active_turn = false
	hovering_oval = false

	highlight.visible = false
	ward_visual.modulate = Color(0.25, 0.25, 0.25, 0.55)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if skill_buttons:
		skill_buttons.visible = false

	print(name, " помер")


func set_active_turn(active: bool) -> void:
	if is_dead:
		is_active_turn = false
		return

	is_active_turn = active
	_apply_visual_scale()
