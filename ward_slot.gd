extends Control

const WardHealthScript = preload("res://scripts/wards/ward_health.gd")
const WardVisualScript = preload("res://scripts/wards/ward_visual.gd")
const WardInputScript = preload("res://scripts/wards/ward_input.gd")
const WardSkillControllerScript = preload("res://scripts/wards/ward_skill_controller.gd")

const _STATUS_TYPES = preload("res://Основа/visual/status/status_types.tscn")

# Відповідність ключа статусу → імені вузла в status_types.tscn
const _STATUS_NODE: Dictionary = {
	"burning":     "burning",
	"taunt":       "taunted",
	"rage":        "razh",
	"armor":       "armor",
	"stun":        "stunned",
	"regen":       "regeneration",
	"fire_shield": "oichi_flame_shield",
}

signal ward_clicked(ward)
signal skill_clicked(ward, skill_key: String)
signal ward_drag_started(ward)

@export var team: String = "ally"
@export var ward_index: int = 0
@export var max_hp: int = 250
@export var start_hp: int = 250
@export var skill_damage: int = 50

@export var ward_id: String = ""

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

# ====== STATUS SYSTEM ======
var status_effects: Dictionary = {}
var taunted_by: String = "" # ID варда, який спровокував

# ====== COOLDOWN SYSTEM ======
var _current_cd: Dictionary = {"Q": 0, "W": 0, "E": 0}
var _max_cd: Dictionary = {"Q": 0, "W": 0, "E": 0}

# Скидається на початку власного ходу — захист від двох стаків ражу за хід
var _rage_gained_this_turn: bool = false

var _status_tooltip: PanelContainer = null
var _status_container_top: GridContainer = null


func _ready() -> void:
	current_hp = clamp(start_hp, 0, max_hp)
	is_dead = false

	if highlight:
		highlight.visible = false

	if crack_overlay:
		crack_overlay.visible = false

	var status_container = get_node_or_null("StatusContainer")
	if status_container:
		for child in status_container.get_children():
			child.queue_free()

	_setup_mouse_filters()
	_create_systems()
	_create_status_tooltip()
	_create_status_container_top()

	base_ward_modulate = ward_visual.modulate
	base_ward_scale = ward_visual.scale


func _exit_tree() -> void:
	if _status_tooltip and is_instance_valid(_status_tooltip):
		_status_tooltip.queue_free()


func _create_status_tooltip() -> void:
	_status_tooltip = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#120d08", 0.96)
	style.border_color = Color("#9b6a35", 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_status_tooltip.add_theme_stylebox_override("panel", style)

	var lbl := Label.new()
	lbl.name = "Lbl"
	lbl.add_theme_color_override("font_color", Color("#d8caa0"))
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_ONLY
	lbl.custom_minimum_size = Vector2(200, 0)
	_status_tooltip.add_child(lbl)

	_status_tooltip.visible = false
	_status_tooltip.z_index = 300
	_status_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().add_child(_status_tooltip)


func _create_status_container_top() -> void:
	_status_container_top = GridContainer.new()
	_status_container_top.columns = 4
	_status_container_top.add_theme_constant_override("h_separation", 11)
	_status_container_top.add_theme_constant_override("v_separation", 8)
	_status_container_top.layout_mode = 0
	_status_container_top.offset_left = -17.5
	_status_container_top.offset_top = 18.0
	_status_container_top.offset_right = 250.5
	_status_container_top.offset_bottom = 120.0
	add_child(_status_container_top)


func _show_status_tooltip(text: String, icon: Control) -> void:
	if _status_tooltip == null or not is_instance_valid(_status_tooltip):
		return
	_status_tooltip.get_node("Lbl").text = text
	_status_tooltip.visible = true
	await get_tree().process_frame
	var icon_rect := icon.get_global_rect()
	_status_tooltip.global_position = Vector2(
		icon_rect.position.x,
		icon_rect.position.y - _status_tooltip.size.y - 6
	)


func _hide_status_tooltip() -> void:
	if _status_tooltip and is_instance_valid(_status_tooltip):
		_status_tooltip.visible = false


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


func _on_hp_changed(new_hp: int, _max_hp: int = 0) -> void:
	current_hp = new_hp


# ====== STATUS EFFECTS ======
func add_status(effect_name: String, count: int = 1) -> void:
	if not status_effects.has(effect_name):
		status_effects[effect_name] = 0
	status_effects[effect_name] += count
	_update_status_visuals()

func remove_status(effect_name: String, count: int = 1) -> void:
	if status_effects.has(effect_name):
		status_effects[effect_name] -= count
		if status_effects[effect_name] <= 0:
			status_effects.erase(effect_name)
	_update_status_visuals()

func get_status(effect_name: String) -> int:
	return status_effects.get(effect_name, 0)

func clear_statuses() -> void:
	status_effects.clear()
	taunted_by = ""
	_update_status_visuals()

func update_armor_status(armor_value: int) -> void:
	if armor_value > 0:
		status_effects["armor"] = 1
	else:
		if status_effects.has("armor"):
			status_effects.erase("armor")
	_update_status_visuals()

func _update_status_visuals() -> void:
	var container := get_node_or_null("StatusContainer")
	if container == null:
		return

	for child in container.get_children():
		child.queue_free()
	if _status_container_top:
		for child in _status_container_top.get_children():
			child.queue_free()

	var lib := _STATUS_TYPES.instantiate()

	for effect in status_effects.keys():
		var count: int = status_effects[effect]
		var draw_count: int = 1 if effect == "armor" else count
		var node_name: String = _STATUS_NODE.get(effect, "")
		if node_name == "":
			continue
		for i in range(draw_count):
			_add_status_icon(container, lib, node_name, effect, count)
			if _status_container_top:
				_add_status_icon(_status_container_top, lib, node_name, effect, count)

	if has_meta("fire_shield") and get_meta("fire_shield"):
		_add_status_icon(container, lib, "oichi_flame_shield", "fire_shield", 1)
		if _status_container_top:
			_add_status_icon(_status_container_top, lib, "oichi_flame_shield", "fire_shield", 1)

	lib.queue_free()


func _add_status_icon(container: Node, lib: Node, node_name: String, effect: String, count: int) -> void:
	var source := lib.get_node_or_null(node_name)
	if source == null:
		return
	var icon := source.duplicate()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	var tooltip_text := _get_status_tooltip(effect, count)
	icon.mouse_entered.connect(func(): _show_status_tooltip(tooltip_text, icon))
	icon.mouse_exited.connect(_hide_status_tooltip)
	container.add_child(icon)


func _get_status_tooltip(effect: String, count: int) -> String:
	match effect:
		"burning":
			return "Горіння (%d стаків)\nНа початку ходу: %d вогняної шкоди." % [count, 50 * count]
		"taunt":
			return "Провокація\nМусить атакувати того, хто спровокував.\nЗабороняє AoE та self-скіли."
		"rage":
			return "Раж (%d стаків)\nQ Оічі: +%d вогню за стак." % [count, 15 * count]
		"armor":
			var val: int = health.current_armor if health else 0
			return "Броня: %d HP\nПоглинає шкоду до HP." % val
		"stun":
			return "Оглушення (%d ходів)\nПропускає хід." % count
		"regen":
			return "Регенерація (%d ходів)" % count
		"fire_shield":
			return "Вогняний щит\nАтакуючий отримує 2 стаки горіння, щит зникає."
	return ""


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
	if skill_panel and skill_panel.has_method("populate") and ward_id != "":
		skill_panel.populate(ward_id)
	elif skill_panel and skill_panel.has_method("show_panel"):
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

func setup_ward(id: String) -> void:
	ward_id = id
	var data := WardDatabase.get_data(id)
	if data.is_empty():
		return

	name = data["name"]

	var portrait_node := get_node_or_null("WardVisual/Portrait") as TextureRect
	if portrait_node != null:
		var path: String = data.get("portrait", "")
		if path != "" and ResourceLoader.exists(path):
			portrait_node.texture = load(path)

	var skills: Dictionary = data.get("skills", {})
	var portrait_path: String = data.get("portrait", "")
	
	if skill_q: skill_q.skill_key = "Q"
	if skill_w: skill_w.skill_key = "W"
	if skill_e: skill_e.skill_key = "E"
	
	_set_skill_icon(skill_q, skills.get("Q", {}), portrait_path)
	_set_skill_icon(skill_w, skills.get("W", {}), portrait_path)
	_set_skill_icon(skill_e, skills.get("E", {}), portrait_path)

	# Ініціалізуємо максимальні значення КД з БД
	for key in ["Q", "W", "E"]:
		var skill_data: Dictionary = skills.get(key, {})
		var cd_val: int = int(skill_data.get("cd", 0))
		_max_cd[key] = cd_val
		_current_cd[key] = 0  # Спочатку всі скіли готові

	_sync_cd_buttons()


func _set_skill_icon(skill_button, skill: Dictionary, fallback: String) -> void:
	if skill_button == null or skill.is_empty():
		return
	var icon_node := skill_button.get_node_or_null("Icon") as TextureRect
	if icon_node == null:
		return
	var icon_path: String = skill.get("icon", "")
	if icon_path == "":
		icon_path = fallback
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_node.texture = load(icon_path)


func take_damage(amount: int, attacker = null, skill_key: String = "") -> void:
	if is_dead:
		return

	health.take_damage(amount)

	if skill_key == "Q" and attacker != null:
		AnimationCode.play_glass_hit_on_target(attacker, self)

	await AnimationCode.animation_take_damage(portrait)


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


# ====== COOLDOWN METHODS ======

## Зменшує всі КД на 1 — викликати на початку ходу цього варда
func tick_cooldowns() -> void:
	for key in _current_cd:
		if _current_cd[key] > 0:
			_current_cd[key] -= 1
	_rage_gained_this_turn = false
	_sync_cd_buttons()


## Застосовує КД після використання скілу
func apply_skill_cooldown(skill_key: String) -> void:
	if skill_key in _max_cd:
		_current_cd[skill_key] = _max_cd[skill_key]
	_sync_cd_buttons()


## Повертає true якщо скіл готовий до використання
func is_skill_ready(skill_key: String) -> bool:
	return _current_cd.get(skill_key, 0) == 0


## Оновлює візуальний стан кнопок відповідно до поточного КД
func _sync_cd_buttons() -> void:
	_apply_cd_to_button(skill_q, "Q")
	_apply_cd_to_button(skill_w, "W")
	_apply_cd_to_button(skill_e, "E")


func _apply_cd_to_button(btn, skill_key: String) -> void:
	if btn == null:
		return
	if btn.has_method("set_cooldown"):
		btn.set_cooldown(_current_cd.get(skill_key, 0))
