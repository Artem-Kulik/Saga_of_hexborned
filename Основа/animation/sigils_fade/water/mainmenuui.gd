extends Control

@export var hover_time := 0.12
@export var hover_scale := 1.03
@export_file("*.tscn") var earth_scene_path: String
@export_file("*.tscn") var air_scene_path: String
@export_file("*.tscn") var water_scene_path: String
@export_file("*.tscn") var fire_scene_path: String

@onready var earth_root: Control = $earth
@onready var earth_visual: Control = $earth/earth_but
@onready var earth_hl: CanvasItem = $earth/earth_hl
@onready var button_earth: Button = $earth/button_earth
@onready var button_effect: AudioStreamPlayer2D = $button_effect

@onready var air_root: Control = $air
@onready var air_visual: Control = $air/air_but
@onready var air_hl: CanvasItem = $air/air_hl
@onready var button_air: Button = $air/button_air

@onready var water_root: Control = $water
@onready var water_visual: Control = $water/water_but
@onready var water_hl: CanvasItem = $water/water_hl
@onready var button_water: Button = $water/button_water

@onready var fire_root: Control = $fire
@onready var fire_visual: Control = $fire/fire_but
@onready var fire_hl: CanvasItem = $fire/fire_hl
@onready var button_fire: Button = $fire/button_fire


func _ready() -> void:
	_setup_menu_button(earth_root, earth_visual, earth_hl, button_earth, "earth")
	_setup_menu_button(air_root, air_visual, air_hl, button_air, "air")
	_setup_menu_button(water_root, water_visual, water_hl, button_water, "water")
	_setup_menu_button(fire_root, fire_visual, fire_hl, button_fire, "fire")


func _setup_menu_button(
	root: Control,
	visual: Control,
	highlight: CanvasItem,
	button: Button,
	button_name: String
) -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_make_children_ignore_mouse(visual)
	_make_children_ignore_mouse(highlight)

	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.flat = true
	button.pivot_offset = button.size / 2.0

	highlight.visible = false
	highlight.modulate.a = 0.0

	button.mouse_entered.connect(
		_on_button_mouse_entered.bind(button, highlight)
	)

	button.mouse_exited.connect(
		_on_button_mouse_exited.bind(button, highlight)
	)

	button.pressed.connect(
		_on_button_pressed.bind(button_name)
	)


func _make_children_ignore_mouse(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_make_children_ignore_mouse(child)


func _on_button_mouse_entered(button: Button, highlight: CanvasItem) -> void:
	highlight.visible = true

	button_effect.stop()
	button_effect.play()

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		Vector2.ONE * hover_scale,
		hover_time
	)

	tween.tween_property(
		highlight,
		"modulate:a",
		1.0,
		hover_time
	)


func _on_button_mouse_exited(button: Button, highlight: CanvasItem) -> void:
	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		button,
		"scale",
		Vector2.ONE,
		hover_time
	)

	tween.tween_property(
		highlight,
		"modulate:a",
		0.0,
		hover_time
	)

	await tween.finished

	highlight.visible = false


func _on_button_pressed(button_name: String) -> void:
	print("Натиснута кнопка: ", button_name)

	# COLLECTION (air) → екран вибору вардів (офлайн, боти)
	if button_name == "air":
		get_tree().change_scene_to_file("res://choose_wards_stage.tscn")
		return

	# DUEL (fire) → лобі мультиплеєра
	if button_name == "fire":
		get_tree().change_scene_to_file("res://scripts/net/mp_lobby.tscn")
		return

	var scene_path := ""

	match button_name:
		"earth":
			scene_path = earth_scene_path
		"water":
			scene_path = water_scene_path
		_:
			push_warning("Невідома кнопка: " + button_name)
			return

	if scene_path == "":
		push_warning("Для кнопки " + button_name + " не вказано сцену")
		return

	get_tree().change_scene_to_file(scene_path)
