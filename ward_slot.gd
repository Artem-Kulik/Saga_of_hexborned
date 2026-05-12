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
@export var start_hp: int = 80
@export var skill_damage: int = 50

@export var debug_draw_oval: bool = false
@export var debug_oval_color: Color = Color.RED
@export var debug_oval_width: float = 3.0

@onready var death_sound: AudioStreamPlayer = $DeathSound


@export var hover_scale: Vector2 = Vector2(1.015, 1.015)
@export var active_scale: Vector2 = Vector2(1.04, 1.04)
@export var scale_speed: float = 0.06

@onready var hitbox_oval: Control = $WardVisual/HitboxOval
@onready var portrait = $WardVisual


@export var death_frames: Array[Texture2D] = []
@export var death_shake_strength: float = 6.0
@export var death_frame_speed: float = 0.12
@export var death_dissolve_time: float = 0.35

@onready var ward_visual: Control = $WardVisual
@onready var highlight: Control = $WardVisual/Highlight
@onready var crack_overlay: TextureRect = get_node_or_null("WardVisual/CrackOverlay")

@onready var hp_bar = get_node_or_null("WardVisual/Circle_hp_bar")
@onready var skill_buttons = get_node_or_null("WardSkillButtons")
@onready var skill_q = get_node_or_null("WardSkillButtons/SkillButton_Q")
@onready var skill_w = get_node_or_null("WardSkillButtons/SkillButton_W")
@onready var skill_e = get_node_or_null("WardSkillButtons/SkillButton_E")

@export var show_oval_preview: bool = true
@export var preview_color: Color = Color(1, 0, 0, 0.25)

var current_hp: int
var is_dead: bool = false

var health
var visual
var input_controller
var skill_controller

var active_turn_tween: Tween
var base_ward_modulate: Color
var base_ward_scale: Vector2


func _ready() -> void:
	current_hp = clamp(start_hp, 0, max_hp)
	is_dead = false

	if highlight:
		highlight.visible = false

	if crack_overlay:
		crack_overlay.visible = false

	_setup_mouse_filters()
	_create_systems()

	base_ward_modulate = ward_visual.modulate
	base_ward_scale = ward_visual.scale


func _process(_delta: float) -> void:
	if is_dead:
		return

	if input_controller:
		input_controller.process_hover()

	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if is_dead:
		return

	if input_controller:
		input_controller.handle_gui_input(event)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT and input_controller:
		input_controller.handle_mouse_exit()

func _setup_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	if ward_visual:
		ward_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

		for child in ward_visual.get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _create_systems() -> void:
	health = WardHealthScript.new()
	add_child(health)
	health.setup(max_hp, start_hp, hp_bar)
	health.hp_changed.connect(_on_hp_changed)
	health.died.connect(_on_died)

	current_hp = health.current_hp

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
	hitbox_oval
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


func _on_hover_entered() -> void:
	if visual:
		visual.set_hovered(true)

	var skill_panel = get_tree().get_first_node_in_group("skill_panel")
	if skill_panel and skill_panel.has_method("show_panel"):
		skill_panel.show_panel()


func _on_hover_exited() -> void:
	if visual:
		visual.set_hovered(false)


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
	AnimationCode.animation_take_damage(portrait)


	print(name, " отримав ", amount, " шкоди. HP: ", current_hp)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	if death_sound:
		death_sound.play()
	current_hp = 0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_active_turn(false)

	if highlight:
		highlight.visible = false

	if hp_bar and hp_bar.has_method("set_hp"):
		hp_bar.set_hp(0, true)
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
	if active_turn_tween:
		active_turn_tween.kill()
		active_turn_tween = null

	if is_dead:
		if highlight:
			highlight.visible = false
		return

	if active:
		if highlight:
			highlight.visible = true
			highlight.modulate = Color(1.0, 0.85, 0.35, 0.45)

		ward_visual.modulate = Color(1.25, 1.25, 1.25, 1.0)

		active_turn_tween = create_tween()
		active_turn_tween.set_loops()

		active_turn_tween.tween_property(
			ward_visual,
			"scale",
			base_ward_scale * 1.045,
			0.45
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		active_turn_tween.tween_property(
			ward_visual,
			"scale",
			base_ward_scale,
			0.45
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	else:
		if highlight:
			highlight.visible = false

		ward_visual.modulate = base_ward_modulate
		ward_visual.scale = base_ward_scale
