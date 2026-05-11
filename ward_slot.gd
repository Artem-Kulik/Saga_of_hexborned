extends Control

const WardHealthScript = preload("res://scripts/wards/ward_health.gd")
const WardVisualScript = preload("res://scripts/wards/ward_visual.gd")
const WardInputScript = preload("res://scripts/wards/ward_input.gd")
const WardSkillControllerScript = preload("res://scripts/wards/ward_skill_controller.gd")

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

@export var death_frames: Array[Texture2D] = []
@export var death_shake_strength: float = 6.0
@export var death_frame_speed: float = 0.12
@export var death_dissolve_time: float = 0.35

@onready var ward_visual: Control = $WardVisual
@onready var highlight: Control = $WardVisual/Highlight
@onready var crack_overlay: TextureRect = get_node_or_null("WardVisual/CrackOverlay")

@onready var hp_current = get_node_or_null("HPAnim/HP_current")
@onready var hp_delay = get_node_or_null("HPAnim/HP_delay")

@onready var skill_buttons = get_node_or_null("WardSkillButtons")
@onready var skill_q = get_node_or_null("WardSkillButtons/SkillButton_Q")
@onready var skill_w = get_node_or_null("WardSkillButtons/SkillButton_W")
@onready var skill_e = get_node_or_null("WardSkillButtons/SkillButton_E")

var current_hp: int
var is_dead: bool = false

var health
var visual
var input_controller
var skill_controller


func _ready() -> void:
	current_hp = max_hp
	is_dead = false

	if highlight:
		highlight.visible = false

	if crack_overlay:
		crack_overlay.visible = false

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

	input_controller.process_hover()


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


func _on_input_ward_clicked() -> void:
	ward_clicked.emit(self)


func _setup_hp_bars() -> void:
	if hp_current:
		hp_current.min_value = 0
		hp_current.max_value = 100
		hp_current.value = 100

	if hp_delay:
		hp_delay.min_value = 0
		hp_delay.max_value = 100
		hp_delay.value = 100



func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		input_controller.handle_mouse_exit()


func _draw() -> void:
	if not debug_draw_oval:
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


func _setup_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	ward_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child in ward_visual.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _create_systems() -> void:
	health = WardHealthScript.new()
	add_child(health)
	health.setup(max_hp, hp_current, hp_delay)
	health.hp_changed.connect(_on_hp_changed)
	health.died.connect(_on_died)

	visual = WardVisualScript.new()
	add_child(visual)
	visual.setup(
		ward_visual,
		highlight,
		hover_scale,
		active_scale,
		scale_speed
	)

	input_controller = WardInputScript.new()
	add_child(input_controller)
	input_controller.setup(
		self,
		skill_buttons,
		oval_width,
		oval_height,
		oval_offset
	)
	input_controller.ward_clicked.connect(_on_input_ward_clicked)
	input_controller.ward_drag_started.connect(_on_input_ward_drag_started)
	input_controller.hover_entered.connect(_on_hover_entered)
	input_controller.hover_exited.connect(_on_hover_exited)

	skill_controller = WardSkillControllerScript.new()
	add_child(skill_controller)
	skill_controller.setup(
		team,
		skill_buttons,
		skill_q,
		skill_w,
		skill_e
	)
	skill_controller.skill_selected.connect(_on_skill_selected)


func _on_hp_changed(new_current_hp: int, _max_hp: int) -> void:
	current_hp = new_current_hp


func _on_died() -> void:
	die()


func _on_input_ward_clicked() -> void:
	ward_clicked.emit(self)


func _on_input_ward_drag_started() -> void:
	ward_drag_started.emit(self)

	if highlight:
		highlight.visible = true

	_apply_visual_scale()

	var skill_panel = get_tree().get_first_node_in_group("skill_panel")
	if skill_panel and skill_panel.has_method("show_panel"):
		skill_panel.show_panel()


func _on_oval_mouse_exited() -> void:
	if highlight:
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


func _on_skill_selected(skill_key: String) -> void:
	if is_dead:
		return

	if team != "ally":
		return

	skill_clicked.emit(self, skill_key)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	health.take_damage(amount)

	print(name, " отримав ", amount, " шкоди. HP: ", current_hp)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	current_hp = 0
	hovering_oval = false
	is_active_turn = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if highlight:
		highlight.visible = false

	if skill_buttons:
		skill_buttons.visible = false

	await play_anim_death()
	await dissolve_death()

	print(name, " помер")


func play_anim_death() -> void:
	if crack_overlay == null:
		return

	if death_frames.is_empty():
		return

	crack_overlay.visible = true

	var start_pos: Vector2 = ward_visual.position

	for frame in death_frames:
		crack_overlay.texture = frame

		ward_visual.position = start_pos + Vector2(
			randf_range(-death_shake_strength, death_shake_strength),
			randf_range(-death_shake_strength, death_shake_strength)
		)

		await get_tree().create_timer(death_frame_speed).timeout

	ward_visual.position = start_pos

	for child in ward_visual.get_children():
		if child != crack_overlay and child is CanvasItem:
			child.visible = false


func dissolve_death() -> void:
	if ward_visual == null:
		return

	var dissolve_tween := create_tween()
	dissolve_tween.tween_property(ward_visual, "modulate:a", 0.0, death_dissolve_time)

	await dissolve_tween.finished


func set_active_turn(active: bool) -> void:
	if is_dead:
		return

	visual.set_active_turn(active)
