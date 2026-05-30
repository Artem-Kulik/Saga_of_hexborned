extends Control

signal ward_card_clicked(ward_id: String)

@export var slot_size: Vector2 = Vector2(120, 170)

@onready var buttons: Array[Button] = [
	$Buttons/but_earth,
	$Buttons/but_water,
	$Buttons/but_fire,
	$Buttons/but_air
]

@onready var pages: Array[Control] = [
	$Pages/page_earth,
	$Pages/page_water,
	$Pages/page_fire,
	$Pages/page_air
]

@onready var grids: Array[GridContainer] = [
	$Pages/page_earth/ScrollContainer/GridContainer,
	$Pages/page_water/ScrollContainer/GridContainer,
	$Pages/page_fire/ScrollContainer/GridContainer,
	$Pages/page_air/ScrollContainer/GridContainer
]

const ELEMENT_BY_INDEX: Array = ["earth", "water", "fire", "air"]

var current_tab: int = 0
var _cards: Dictionary = {}


func _ready() -> void:
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_tab_pressed.bind(i))

	_populate_ward_cards()
	_show_tab(0)


func _on_tab_pressed(tab_index: int) -> void:
	_show_tab(tab_index)


func _show_tab(tab_index: int) -> void:
	current_tab = tab_index

	for i in range(pages.size()):
		pages[i].visible = i == tab_index

	for i in range(buttons.size()):
		buttons[i].disabled = i == tab_index


func set_card_selected(ward_id: String, selected: bool) -> void:
	if ward_id not in _cards:
		return
	var overlay = _cards[ward_id].get_node_or_null("SelectionOverlay")
	if overlay:
		overlay.visible = selected


func _populate_ward_cards() -> void:
	_cards.clear()

	for i in range(grids.size()):
		_clear_grid(grids[i])
		var element: String = ELEMENT_BY_INDEX[i]
		for ward_id in WardDatabase.get_by_element(element):
			var card := _create_ward_card(ward_id)
			_cards[ward_id] = card
			grids[i].add_child(card)


func _create_ward_card(ward_id: String) -> Control:
	var data: Dictionary = WardDatabase.get_data(ward_id)

	var card := Control.new()
	card.custom_minimum_size = slot_size
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = true

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.04, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg)

	var portrait_rect := TextureRect.new()
	portrait_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_rect.offset_bottom = -26.0
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_path: String = data.get("portrait", "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait_rect.texture = load(portrait_path)
	card.add_child(portrait_rect)

	var label := Label.new()
	label.text = data.get("name", ward_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	label.offset_top = -26.0
	label.add_theme_font_size_override("font_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)

	var sel_overlay := ColorRect.new()
	sel_overlay.name = "SelectionOverlay"
	sel_overlay.color = Color(1.0, 0.85, 0.15, 0.38)
	sel_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sel_overlay.visible = false
	sel_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sel_overlay)

	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton \
				and event.button_index == MOUSE_BUTTON_LEFT \
				and event.pressed:
			ward_card_clicked.emit(ward_id)
	)

	return card


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()
