extends Control

@onready var tabs: Array[Control] = [
	$but_earth,
	$but_water,
	$but_fire,
	$but_air,
	$but_radiance
]

@onready var highlights: Array[Control] = [
	$"../../buttons/HBoxContainer/Earth/earth_hl",
	$"../../buttons/HBoxContainer/Water/water_hl",
	$"../../buttons/HBoxContainer/Fire/fire_hl",
	$"../../buttons/HBoxContainer/Air/air_hl",
	$"../../buttons/HBoxContainer/Radiance/radiance_hl"
]


func _ready() -> void:

	for highlight in highlights:
		highlight.visible = false


	for i in range(tabs.size()):

		tabs[i].mouse_filter = Control.MOUSE_FILTER_STOP

		tabs[i].gui_input.connect(
			func(event): _on_tab_input(i, event)
		)


func _on_tab_input(index: int, event: InputEvent) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			for highlight in highlights:
				highlight.visible = false

			highlights[index].visible = true
