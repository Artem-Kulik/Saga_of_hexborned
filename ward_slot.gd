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
	"cuts":          "hiscoris_scares",
	"fire_circle":   "ocii_circle_flame",
	"barrier":       "armor",
	"fire_seventh":  "prayers_fire",
	"reaping":       "znec_znyva",
	"parasitism":    "parazyte_assim",
}

const NEGATIVE_EFFECTS: Array = ["burning", "taunt", "stun", "cuts", "fire_seventh"]

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

# Горіння: кожне накладення має власний таймер [{"count": N, "turns": T}, ...]
var burning_applications: Array = []

# ====== COOLDOWN SYSTEM ======
var _current_cd: Dictionary = {"Q": 0, "W": 0, "E": 0}
var _max_cd: Dictionary = {"Q": 0, "W": 0, "E": 0}

# Скидається на початку власного ходу — захист від двох стаків ражу за хід
var _rage_gained_this_turn: bool = false

var _status_tooltip: PanelContainer = null


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
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.custom_minimum_size = Vector2(200, 0)
	_status_tooltip.add_child(lbl)

	_status_tooltip.visible = false
	_status_tooltip.z_index = 300
	_status_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().add_child(_status_tooltip)



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
	if effect_name == "burning":
		add_burning(count, 1)
		return
	if not status_effects.has(effect_name):
		status_effects[effect_name] = 0
	status_effects[effect_name] += count
	_update_status_visuals()

func remove_status(effect_name: String, count: int = 1) -> void:
	if effect_name == "burning":
		var to_remove: int = count
		var i: int = burning_applications.size() - 1
		while i >= 0 and to_remove > 0:
			if burning_applications[i].count <= to_remove:
				to_remove -= burning_applications[i].count
				burning_applications.remove_at(i)
			else:
				burning_applications[i].count -= to_remove
				to_remove = 0
			i -= 1
		_sync_burning_to_status()
		_update_status_visuals()
		return
	if status_effects.has(effect_name):
		status_effects[effect_name] -= count
		if status_effects[effect_name] <= 0:
			status_effects.erase(effect_name)
	_update_status_visuals()

func get_status(effect_name: String) -> int:
	if effect_name == "burning":
		var total: int = 0
		for app in burning_applications:
			total += app.count
		return total
	return status_effects.get(effect_name, 0)

func clear_statuses() -> void:
	status_effects.clear()
	burning_applications.clear()
	taunted_by = ""
	_update_status_visuals()

func remove_negative_effects() -> void:
	for effect in NEGATIVE_EFFECTS:
		if status_effects.has(effect):
			status_effects.erase(effect)
	burning_applications.clear()
	taunted_by = ""
	if has_meta("fire_shield") and get_meta("fire_shield"):
		set_meta("fire_shield", false)
	_update_status_visuals()

# ====== BURNING SYSTEM ======
func add_burning(count: int, turns: int = 1) -> void:
	for i in range(burning_applications.size()):
		if burning_applications[i].turns == turns:
			burning_applications[i].count += count
			_sync_burning_to_status()
			_update_status_visuals()
			return
	burning_applications.append({"count": count, "turns": turns})
	_sync_burning_to_status()
	_update_status_visuals()

func tick_burning() -> int:
	var total_dmg: int = 0
	var remaining: Array = []
	for app in burning_applications:
		total_dmg += 50 * app.count
		if app.turns - 1 > 0:
			remaining.append({"count": app.count, "turns": app.turns - 1})
	burning_applications = remaining
	_sync_burning_to_status()
	_update_status_visuals()
	return total_dmg

func extend_burning(extra_turns: int = 1) -> void:
	for i in range(burning_applications.size()):
		burning_applications[i].turns += extra_turns
	_update_status_visuals()

func reduce_burning_turns(reduce_by: int = 1) -> void:
	var remaining: Array = []
	for app in burning_applications:
		var new_turns: int = app.turns - reduce_by
		if new_turns > 0:
			remaining.append({"count": app.count, "turns": new_turns})
	burning_applications = remaining
	_sync_burning_to_status()
	_update_status_visuals()

func consume_burning_stacks(count: int) -> void:
	burning_applications.sort_custom(func(a, b): return a.turns < b.turns)
	var to_consume: int = count
	var i: int = 0
	while i < burning_applications.size() and to_consume > 0:
		if burning_applications[i].count <= to_consume:
			to_consume -= burning_applications[i].count
			burning_applications.remove_at(i)
		else:
			burning_applications[i].count -= to_consume
			to_consume = 0
			i += 1
	_sync_burning_to_status()
	_update_status_visuals()

func activate_all_burning() -> int:
	var virtual_stacks: int = 0
	for app in burning_applications:
		virtual_stacks += app.count * app.turns
	burning_applications.clear()
	_sync_burning_to_status()
	_update_status_visuals()
	return virtual_stacks * 50

func _sync_burning_to_status() -> void:
	var total: int = 0
	for app in burning_applications:
		total += app.count
	if total > 0:
		status_effects["burning"] = total
	elif status_effects.has("burning"):
		status_effects.erase("burning")

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

	var lib := _STATUS_TYPES.instantiate()

	# Горіння: одна іконка на стак, всі мають однаковий тултіп з усіма групами
	if not burning_applications.is_empty():
		var lines: Array = []
		for app in burning_applications:
			lines.append("%d стак(и) діють %d хід(ів)" % [app.count, app.turns])
		var shared_tooltip: String = "Горіння:\n" + "\n".join(lines)
		var total_stacks: int = 0
		for app in burning_applications:
			total_stacks += app.count
		for _i in range(total_stacks):
			_add_status_icon(container, lib, "burning", shared_tooltip)

	for effect in status_effects.keys():
		if effect == "burning":
			continue
		var count: int = status_effects[effect]
		var draw_count: int = 1 if effect in ["armor", "fire_circle", "barrier", "regen", "parasitism", "reaping"] else count
		var node_name: String = _STATUS_NODE.get(effect, "")
		if node_name == "":
			continue
		for i in range(draw_count):
			_add_status_icon(container, lib, node_name, _get_status_tooltip(effect, count))

	if has_meta("fire_shield") and get_meta("fire_shield"):
		_add_status_icon(container, lib, "oichi_flame_shield",
			"Вогняний щит\nАктивна броня: поглинає наступний удар.")
		_add_status_icon(container, lib, "oichi_flame_shield",
			"Контратака вогнем\nАтакуючий отримує 2 стаки горіння, щит зникає.")

	lib.queue_free()


func _add_status_icon(container: Node, lib: Node, node_name: String, tooltip: String) -> void:
	var source := lib.get_node_or_null(node_name)
	if source == null:
		return
	var icon := source.duplicate()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	icon.mouse_entered.connect(func(): _show_status_tooltip(tooltip, icon))
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
			return "Регенерація (%d ход(и))\n+100 HP на початку кожного ходу." % count
		"fire_shield":
			return "Вогняний щит\nАтакуючий отримує 2 стаки горіння, щит зникає."
		"cuts":
			return "Тисяча Порізів (%d стак(и))\nНаступна атака Іскоріса: +%d до скіла + 20 повітря пасивки." % [count, 10 * count]
		"fire_circle":
			return "Коло пекельного вогню (%d ход(и))\nАтакуючий отримує 2 стаки горіння." % count
		"barrier":
			return "Бар'єр (%d ход(и))\nПоглинає до 30 шкоди від наступного удару.\nАтакуючий отримує 1 стак горіння." % count
		"fire_seventh":
			return "Вогонь сьомого (%d стак(и))\nНа початку ходу: %d вогняної шкоди усій команді." % [count, 150 * count]
		"reaping":
			return "Жнива\nЖнець атакує на початку свого наступного ходу.\nАктивує всі стаки горіння."
		"parasitism":
			return "Паразитування (%d хід)\nНа початку ходу — б'є випадкового союзника випадковим скілом." % count
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

	var hp_override: int = int(data.get("hp", 0))
	if hp_override > 0:
		max_hp    = hp_override
		start_hp  = hp_override
		current_hp = hp_override
		if health:
			health.setup(max_hp, start_hp, hp_bar)

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
