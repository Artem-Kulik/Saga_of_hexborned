extends Control

@onready var glow_1: TextureRect = $Background_box/glow

@export var glow_1_min := 0.15
@export var glow_1_max := 0.75
@export var glow_1_speed := 0.35

var t := 0.0

# --- Selection state ---
var selected_ids: Array[String] = []

# --- PickedWards refs ---
@onready var _reverse_nodes: Array[TextureRect] = [
	$PickedWards/ward_1/reverse1,
	$PickedWards/ward_2/reverse2,
	$PickedWards/ward_3/reverse3,
]
@onready var _highlight_nodes: Array[TextureRect] = [
	$PickedWards/ward_1/highlight_1,
	$PickedWards/ward_2/highlight_2,
	$PickedWards/ward_3/highlight_3,
]
@onready var _picked_wards: Array[Control] = [
	$PickedWards/ward_1,
	$PickedWards/ward_2,
	$PickedWards/ward_3,
]

@onready var _tabs_menu: Control = $Wards_collection/chose_zone/TabsMenu

# --- Skill panel refs ---
@onready var _sp_q_icon: TextureRect    = $Skill_panel/Skills/q_back/q_icon
@onready var _sp_q_text: RichTextLabel  = $Skill_panel/Skills/q_back/RichTextLabel
@onready var _sp_w_icon: TextureRect    = $Skill_panel/Skills/w_back/q_icon
@onready var _sp_w_text: RichTextLabel  = $Skill_panel/Skills/w_back/RichTextLabel
@onready var _sp_e_icon: TextureRect    = $Skill_panel/Skills/e_back/q_icon
@onready var _sp_e_text: RichTextLabel  = $Skill_panel/Skills/e_back/RichTextLabel
@onready var _sp_p_icon: TextureRect    = $Skill_panel/Skills/p_back/q_icon
@onready var _sp_p_text: RichTextLabel  = $Skill_panel/Skills/p_back/RichTextLabel
@onready var _sp_portrait: TextureRect  = $Skill_panel/lore/ward_portrait
@onready var _sp_name: Label            = $Skill_panel/lore/ward_portrait/name

var _original_reverse_textures: Array = []
var _slot_borders: Array = []
var _slot_frames: Array = []
var _slot_elem_bgs: Array = []
var _slot_click_overlays: Array = []
var _confirm_button: Button

const SLOT_FRAME_TEXTURE = "res://Основа/visual/choose_stage/epmty_slot_frame.png"
const CARD_ANIM_SCENE = preload("res://Основа/animation/particles/fire_card_start.tscn")

const ELEMENT_CARD_TEXTURES: Dictionary = {
	"fire":  "res://Основа/visual/element_cards/card_fire.png",
	"water": "res://Основа/visual/element_cards/card_water.png",
	"earth": "res://Основа/visual/element_cards/card_earth.png",
	"air":   "res://Основа/visual/element_cards/card_air.png",
}

const _ELEMENT_CARD_NODE: Dictionary = {
	"fire":  "Fire_card",
	"water": "Water_card",
	"air":   "Air_card",
	"earth": "Earth_card",
}
const _ELEMENT_SPRITE_PATH: Dictionary = {
	"fire":  "Fire_card/elemental_card_fire",
	"water": "Water_card/water_card_start_animation",
	"air":   "Air_card/air_card_start_animation",
	"earth": "Earth_card/AnimatedSprite2D",
}

# Точні екранні позиції верхніх слотів (розраховані з tscn)
# reverse_N: anchor 0.5 на ward (40px) → base 20px + offset
const SLOT_RECTS: Array = [
	[645.0, 50.0, 200.0, 275.0],
	[862.0, 50.0, 200.0, 275.0],
	[1079.0, 50.0, 200.0, 275.0],
]


func _ready() -> void:
	_setup_glow(glow_1)

	for r in _reverse_nodes:
		_original_reverse_textures.append(r.texture)

	for h in _highlight_nodes:
		h.visible = false

	for i in range(3):
		_slot_borders.append(_create_slot_border(i))
		_slot_elem_bgs.append(_create_slot_elem_bg(i))
		_slot_frames.append(_create_slot_frame(i))

	# Click overlays додаємо на ROOT (вище за Wards_collection) —
	# це єдиний надійний спосіб перехопити кліки поверх full-screen Control
	for i in range(3):
		var idx := i
		var r: Array = SLOT_RECTS[i]
		var overlay := Control.new()
		overlay.position = Vector2(r[0], r[1])
		overlay.size     = Vector2(r[2], r[3])
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton \
					and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed \
					and idx < selected_ids.size():
				_deselect_ward(selected_ids[idx])
		)
		add_child(overlay)
		_slot_click_overlays.append(overlay)

	_tabs_menu.ward_card_clicked.connect(_on_ward_card_clicked)
	_setup_confirm_button()
	_clear_skill_panel()


func _process(delta: float) -> void:
	t += delta
	var wave_1 := (sin(t * glow_1_speed) + 1.0) * 0.5
	glow_1.modulate.a = lerp(glow_1_min, glow_1_max, wave_1)


func _setup_glow(glow: TextureRect) -> void:
	glow.visible = true
	glow.modulate = Color(1, 1, 1, 1)
	glow.self_modulate = Color(1, 1, 1, 1)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE


# --- Золота рамка навколо слоту ---

func _create_slot_border(slot_idx: int) -> Panel:
	var r := _reverse_nodes[slot_idx]
	var ward_node := _picked_wards[slot_idx]

	var border := Panel.new()
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = Color(0.92, 0.72, 0.18, 1.0)
	style.border_width_left   = 3
	style.border_width_right  = 3
	style.border_width_top    = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	border.add_theme_stylebox_override("panel", style)

	border.layout_mode = 1
	border.anchor_left  = r.anchor_left
	border.anchor_right = r.anchor_right
	border.offset_left   = r.offset_left   - 4
	border.offset_top    = r.offset_top    - 4
	border.offset_right  = r.offset_right  + 4
	border.offset_bottom = r.offset_bottom + 4
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.visible = false

	ward_node.add_child(border)
	ward_node.move_child(border, 0)
	return border


# --- Фон стихійної картки (за портретом) ---

func _create_slot_elem_bg(slot_idx: int) -> TextureRect:
	var r := _reverse_nodes[slot_idx]
	var ward_node := _picked_wards[slot_idx]

	var bg := TextureRect.new()
	bg.layout_mode = 1
	bg.anchor_left  = r.anchor_left
	bg.anchor_right = r.anchor_right
	bg.offset_left   = r.offset_left
	bg.offset_top    = r.offset_top
	bg.offset_right  = r.offset_right
	bg.offset_bottom = r.offset_bottom
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.visible = false

	ward_node.add_child(bg)
	# Вставляємо перед reverseN (портретом) щоб бути за ним
	# Поточний порядок після border: [border(0), highlight(1), reverseN(2)]
	ward_node.move_child(bg, 2)
	return bg


# --- Рамка з empty_slots поверх портрету ---

func _create_slot_frame(slot_idx: int) -> TextureRect:
	var r := _reverse_nodes[slot_idx]
	var ward_node := _picked_wards[slot_idx]

	var frame := TextureRect.new()
	frame.layout_mode = 1
	frame.anchor_left  = r.anchor_left
	frame.anchor_right = r.anchor_right
	# Рамка рівно по розміру слоту, без виходу за межі
	frame.offset_left   = r.offset_left
	frame.offset_top    = r.offset_top
	frame.offset_right  = r.offset_right
	frame.offset_bottom = r.offset_bottom
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = false

	if ResourceLoader.exists(SLOT_FRAME_TEXTURE):
		frame.texture = load(SLOT_FRAME_TEXTURE)

	ward_node.add_child(frame)
	return frame


# --- Кнопка підтвердження ---

func _setup_confirm_button() -> void:
	_confirm_button = Button.new()
	_confirm_button.text = "▶  Підтвердити"
	_confirm_button.visible = false
	_confirm_button.custom_minimum_size = Vector2(240, 58)
	_confirm_button.position = Vector2(1340, 158)
	_confirm_button.add_theme_font_size_override("font_size", 17)

	var s_normal := _make_button_style(Color(0.06, 0.04, 0.02, 0.93), Color(0.75, 0.56, 0.17, 1.0))
	var s_hover  := _make_button_style(Color(0.14, 0.10, 0.03, 0.97), Color(1.00, 0.83, 0.26, 1.0))
	var s_press  := _make_button_style(Color(0.22, 0.16, 0.04, 1.00), Color(1.00, 0.83, 0.26, 1.0))

	_confirm_button.add_theme_stylebox_override("normal",  s_normal)
	_confirm_button.add_theme_stylebox_override("hover",   s_hover)
	_confirm_button.add_theme_stylebox_override("pressed", s_press)
	_confirm_button.add_theme_stylebox_override("focus",   s_normal)
	_confirm_button.add_theme_color_override("font_color",       Color(0.95, 0.82, 0.42, 1.0))
	_confirm_button.add_theme_color_override("font_hover_color", Color(1.00, 0.95, 0.60, 1.0))

	add_child(_confirm_button)
	_confirm_button.pressed.connect(_on_confirm_pressed)


func _make_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left   = 2
	s.border_width_right  = 2
	s.border_width_top    = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 5
	s.corner_radius_top_right    = 5
	s.corner_radius_bottom_left  = 5
	s.corner_radius_bottom_right = 5
	s.content_margin_left  = 14
	s.content_margin_right = 14
	return s


# --- Очищення панелі скілів при старті ---

func _clear_skill_panel() -> void:
	_sp_name.text = ""
	_sp_portrait.texture = null

	for node in [_sp_q_text, _sp_w_text, _sp_e_text, _sp_p_text]:
		node.text = ""

	for node in [_sp_q_icon, _sp_w_icon, _sp_e_icon, _sp_p_icon]:
		node.texture = null


# --- Логіка вибору ---

func _on_ward_card_clicked(ward_id: String) -> void:
	_show_skill_panel(ward_id)
	if selected_ids.has(ward_id):
		_deselect_ward(ward_id)
	elif selected_ids.size() < 3:
		_select_ward(ward_id)


# --- Skill panel ---

func _show_skill_panel(ward_id: String) -> void:
	var data := WardDatabase.get_data(ward_id)
	if data.is_empty():
		return

	# Портрет і ім'я
	var portrait_path: String = data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		_sp_portrait.texture = load(portrait_path)
	_sp_name.text = data.get("name", "")

	# Скіли
	var skills: Dictionary = data.get("skills", {})
	_fill_skill_row(_sp_p_icon, _sp_p_text, skills.get("P", {}), portrait_path)
	_fill_skill_row(_sp_q_icon, _sp_q_text, skills.get("Q", {}), portrait_path)
	_fill_skill_row(_sp_w_icon, _sp_w_text, skills.get("W", {}), portrait_path)
	_fill_skill_row(_sp_e_icon, _sp_e_text, skills.get("E", {}), portrait_path)


func _fill_skill_row(
	icon_node: TextureRect,
	text_node: RichTextLabel,
	skill: Dictionary,
	fallback_portrait: String
) -> void:
	if skill.is_empty():
		text_node.text = ""
		return

	var icon_path: String = skill.get("icon", "")
	if icon_path == "":
		icon_path = fallback_portrait
	if icon_path != "" and ResourceLoader.exists(icon_path):
		icon_node.texture = load(icon_path)

	var skill_name: String = skill.get("name", "")
	var skill_desc: String = skill.get("desc", "")
	text_node.text = skill_name + "\n" + skill_desc


func _select_ward(ward_id: String) -> void:
	selected_ids.append(ward_id)
	_tabs_menu.set_card_selected(ward_id, true)
	_refresh_picked_slots()
	_refresh_confirm_button()

	var slot_idx := selected_ids.size() - 1
	var element: String = WardDatabase.get_data(ward_id).get("element", "")
	_play_card_anim(slot_idx, element)


func _deselect_ward(ward_id: String) -> void:
	selected_ids.erase(ward_id)
	_tabs_menu.set_card_selected(ward_id, false)
	_refresh_picked_slots()
	_refresh_confirm_button()


# --- Анімація появи картки ---

func _play_card_anim(slot_idx: int, element: String) -> void:
	if not element in _ELEMENT_CARD_NODE:
		return

	var anim = CARD_ANIM_SCENE.instantiate()
	anim.scale = Vector2(0.32, 0.32)

	var r: Array = SLOT_RECTS[slot_idx]
	anim.position = Vector2(r[0], r[1])

	add_child(anim)

	# Показуємо лише потрібну стихію
	for elem in _ELEMENT_CARD_NODE:
		var card = anim.get_node_or_null(_ELEMENT_CARD_NODE[elem])
		if card:
			card.visible = (elem == element)

	# Запускаємо анімацію та видаляємо після завершення
	var sprite_path: String = _ELEMENT_SPRITE_PATH.get(element, "")
	var sprite := anim.get_node_or_null(sprite_path) as AnimatedSprite2D

	if sprite:
		# Дублюємо SpriteFrames щоб не чіпати shared ресурс
		if sprite.sprite_frames != null:
			var frames := sprite.sprite_frames.duplicate() as SpriteFrames
			frames.set_animation_loop(sprite.animation, false)
			sprite.sprite_frames = frames
		sprite.play()
		sprite.animation_finished.connect(anim.queue_free)
	else:
		get_tree().create_timer(2.0).timeout.connect(anim.queue_free)


# --- Оновлення верхніх слотів ---

func _refresh_picked_slots() -> void:
	for i in range(3):
		if i < selected_ids.size():
			var data := WardDatabase.get_data(selected_ids[i])
			var portrait_path: String = data.get("portrait", "")
			if portrait_path != "" and ResourceLoader.exists(portrait_path):
				_reverse_nodes[i].texture = load(portrait_path)
			_reverse_nodes[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_reverse_nodes[i].expand_mode  = TextureRect.EXPAND_IGNORE_SIZE

			# Стихійний фон карти
			var element: String = data.get("element", "")
			var card_path: String = ELEMENT_CARD_TEXTURES.get(element, "")
			if card_path != "" and ResourceLoader.exists(card_path):
				_slot_elem_bgs[i].texture = load(card_path)
			_slot_elem_bgs[i].visible = true

			_slot_borders[i].visible = true
			_slot_frames[i].visible = false   # картка стихії має власну рамку
			_slot_click_overlays[i].mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			_reverse_nodes[i].texture = _original_reverse_textures[i]
			_reverse_nodes[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_reverse_nodes[i].expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			_slot_elem_bgs[i].visible = false
			_slot_borders[i].visible = false
			_slot_frames[i].visible = false
			_slot_click_overlays[i].mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refresh_confirm_button() -> void:
	_confirm_button.visible = selected_ids.size() == 3


# --- Перехід до бою ---

func _on_confirm_pressed() -> void:
	GameState.ally_ward_ids = selected_ids.duplicate()
	get_tree().change_scene_to_file("res://battle_scene.tscn")
