extends Control

@export var empty_slot_scene: PackedScene
@export var slots_count: int = 24
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

var current_tab: int = 0


func _ready() -> void:
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_tab_pressed.bind(i))

	_create_slots_for_all_pages()
	_show_tab(0)


func _on_tab_pressed(tab_index: int) -> void:
	_show_tab(tab_index)


func _show_tab(tab_index: int) -> void:
	current_tab = tab_index

	for i in range(pages.size()):
		pages[i].visible = i == tab_index

	for i in range(buttons.size()):
		buttons[i].disabled = i == tab_index


func _create_slots_for_all_pages() -> void:
	if empty_slot_scene == null:
		push_error("Не вказана сцена empty_slots у Inspector")
		return

	for grid in grids:
		_clear_grid(grid)

		for i in range(slots_count):
			var slot = empty_slot_scene.instantiate()

			slot.custom_minimum_size = slot_size

			grid.add_child(slot)


func _clear_grid(grid: GridContainer) -> void:
	for child in grid.get_children():
		child.queue_free()
