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

@onready var _tabs_menu: Control = $Wards_collection/chose_zone/TabsMenu

var _original_reverse_textures: Array = []
var _confirm_button: Button


func _ready() -> void:
	_setup_glow(glow_1)

	for r in _reverse_nodes:
		_original_reverse_textures.append(r.texture)

	for h in _highlight_nodes:
		h.visible = false

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


func _setup_confirm_button() -> void:
	_confirm_button = Button.new()
	_confirm_button.text = "▶  Підтвердити"
	_confirm_button.visible = false
	_confirm_button.custom_minimum_size = Vector2(260, 62)
	_confirm_button.position = Vector2(830, 345)
	_confirm_button.add_theme_font_size_override("font_size", 20)
	add_child(_confirm_button)
	_confirm_button.pressed.connect(_on_confirm_pressed)


# --- Card click handler ---

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


# --- Visual update ---

func _refresh_picked_slots() -> void:
	for i in range(3):
		if i < selected_ids.size():
			var data := WardDatabase.get_data(selected_ids[i])
			var portrait_path: String = data.get("portrait", "")
			if portrait_path != "" and ResourceLoader.exists(portrait_path):
				_reverse_nodes[i].texture = load(portrait_path)
				_reverse_nodes[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			_highlight_nodes[i].visible = true
		else:
			_reverse_nodes[i].texture = _original_reverse_textures[i]
			_reverse_nodes[i].stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_highlight_nodes[i].visible = false


func _refresh_confirm_button() -> void:
	_confirm_button.visible = selected_ids.size() == 3


# --- Confirm → Battle ---

func _on_confirm_pressed() -> void:
	GameState.ally_ward_ids = selected_ids.duplicate()
	get_tree().change_scene_to_file("res://battle_scene.tscn")
