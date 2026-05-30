extends Control

@onready var glow_1: TextureRect = $Background_box/glow

@export var glow_1_min := 0.15
@export var glow_1_max := 0.75
@export var glow_1_speed := 0.35

var t := 0.0

# --- Selection state ---
var selected_ids: Array[String] = []

# --- PickedWards refs ---
@onready var _picked_wards: Array[Control] = [
	$PickedWards/ward_1,
	$PickedWards/ward_2,
	$PickedWards/ward_3,
]
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

@onready var _tabs_menu: Control = $Wards_collection/chose_zone/TabsMenu

var _original_reverse_textures: Array = []
var _slot_borders: Array = []
var _confirm_button: Button


func _ready() -> void:
	_setup_glow(glow_1)

	# Зберігаємо оригінальні текстури карток-рубашок
	for r in _reverse_nodes:
		_original_reverse_textures.append(r.texture)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ховаємо вбудовану підсвітку — використовуємо власну рамку
	for h in _highlight_nodes:
		h.visible = false

	# Створюємо золоті рамки для кожного слоту
	for i in range(3):
		_slot_borders.append(_create_slot_border(i))

	# Підключаємо кліки на верхні слоти для скидання вибору
	for i in range(3):
		var idx := i
		_reverse_nodes[i].gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton \
					and event.button_index == MOUSE_BUTTON_LEFT \
					and event.pressed \
					and idx < selected_ids.size():
				_deselect_ward(selected_ids[idx])
		)

	_tabs_menu.ward_card_clicked.connect(_on_ward_card_clicked)
	_setup_confirm_button()


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
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	border.add_theme_stylebox_override("panel", style)

	border.layout_mode = 1
	border.anchor_left = r.anchor_left
	border.anchor_right = r.anchor_right
	border.offset_left = r.offset_left - 4
	border.offset_top = r.offset_top - 4
	border.offset_right = r.offset_right + 4
	border.offset_bottom = r.offset_bottom + 4
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.visible = false

	ward_node.add_child(border)
	ward_node.move_child(border, 0)
	return border


# --- Кнопка підтвердження ---

func _setup_confirm_button() -> void:
	_confirm_button = Button.new()
	_confirm_button.text = "▶  Підтвердити"
	_confirm_button.visible = false
	_confirm_button.custom_minimum_size = Vector2(240, 58)
	# Праворуч від 3-го слоту, по центру висоти карток
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


# --- Логіка вибору ---

func _on_ward_card_clicked(ward_id: String) -> void:
	if selected_ids.has(ward_id):
		_deselect_ward(ward_id)
	elif selected_ids.size() < 3:
		_select_ward(ward_id)


func _select_ward(ward_id: String) -> void:
	selected_ids.append(ward_id)
	_tabs_menu.set_card_selected(ward_id, true)
	_refresh_picked_slots()
	_refresh_confirm_button()


func _deselect_ward(ward_id: String) -> void:
	selected_ids.erase(ward_id)
	_tabs_menu.set_card_selected(ward_id, false)
	_refresh_picked_slots()
	_refresh_confirm_button()


# --- Оновлення верхніх слотів ---

func _refresh_picked_slots() -> void:
	for i in range(3):
		if i < selected_ids.size():
			var data := WardDatabase.get_data(selected_ids[i])
			var portrait_path: String = data.get("portrait", "")
			if portrait_path != "" and ResourceLoader.exists(portrait_path):
				_reverse_nodes[i].texture = load(portrait_path)
				_reverse_nodes[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_reverse_nodes[i].mouse_filter = Control.MOUSE_FILTER_STOP
			_slot_borders[i].visible = true
		else:
			_reverse_nodes[i].texture = _original_reverse_textures[i]
			_reverse_nodes[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_reverse_nodes[i].mouse_filter = Control.MOUSE_FILTER_IGNORE
			_slot_borders[i].visible = false


func _refresh_confirm_button() -> void:
	_confirm_button.visible = selected_ids.size() == 3


# --- Перехід до бою ---

func _on_confirm_pressed() -> void:
	GameState.ally_ward_ids = selected_ids.duplicate()
	get_tree().change_scene_to_file("res://battle_scene.tscn")
