extends Control

@onready var camera: Camera2D = $camera
@onready var stage_1: Control = $stages/stage_1

@onready var main_overlay: CanvasLayer = $main_overlay
@onready var lvl_info: CanvasLayer = $lvl_info
@onready var info_page: Control = $lvl_info/info_page

@export var map_size := Vector2(1920, 1080)

@export var target_zoom := Vector2(3.0, 3.0)
@export var focus_zoom := Vector2(5.0, 5.0)
@export var focus_time := 1.2

@export var lvl_info_fade_time := 0.35

@export var edge_size := 80.0
@export var edge_move_speed := 500.0

# Кнопка після фокусу буде зліва.
@export var focused_stage_screen_pos := Vector2(0.15, 0.5)

var dragging := false
var camera_locked := false

var focus_tween: Tween
var info_tween: Tween


func _ready() -> void:
	camera.enabled = true
	camera.zoom = target_zoom

	main_overlay.visible = true
	main_overlay.process_mode = Node.PROCESS_MODE_INHERIT

	lvl_info.visible = false
	lvl_info.process_mode = Node.PROCESS_MODE_DISABLED

	info_page.modulate.a = 0.0

	_center_camera_on(stage_1)


func _process(delta: float) -> void:
	if camera_locked:
		return

	_move_camera_by_screen_edge(delta)
	_clamp_camera_to_map()


func _center_camera_on(target: Control) -> void:
	camera.global_position = target.global_position + target.size / 2.0
	_clamp_camera_to_map()


func focus_stage_and_open_info(stage_button: Control) -> void:
	if camera_locked:
		return

	camera_locked = true
	dragging = false

	if focus_tween:
		focus_tween.kill()

	if info_tween:
		info_tween.kill()

	main_overlay.visible = false
	main_overlay.process_mode = Node.PROCESS_MODE_DISABLED

	lvl_info.visible = true
	lvl_info.process_mode = Node.PROCESS_MODE_INHERIT

	info_page.modulate.a = 0.0

	info_tween = create_tween()
	info_tween.tween_property(
		info_page,
		"modulate:a",
		1.0,
		lvl_info_fade_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var stage_world_pos := stage_button.global_position + stage_button.size / 2.0
	var viewport_size := get_viewport_rect().size
	var screen_center := viewport_size / 2.0

	var desired_screen_pos := Vector2(
		viewport_size.x * focused_stage_screen_pos.x,
		viewport_size.y * focused_stage_screen_pos.y
	)

	var final_camera_pos := stage_world_pos - (desired_screen_pos - screen_center) / focus_zoom

	focus_tween = create_tween()
	focus_tween.set_parallel(true)

	focus_tween.tween_property(
		camera,
		"global_position",
		final_camera_pos,
		focus_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	focus_tween.tween_property(
		camera,
		"zoom",
		focus_zoom,
		focus_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await focus_tween.finished

	camera_locked = true


func close_level_info() -> void:
	if focus_tween:
		focus_tween.kill()

	if info_tween:
		info_tween.kill()

	info_tween = create_tween()
	info_tween.tween_property(
		info_page,
		"modulate:a",
		0.0,
		lvl_info_fade_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await info_tween.finished

	lvl_info.visible = false
	lvl_info.process_mode = Node.PROCESS_MODE_DISABLED

	main_overlay.visible = true
	main_overlay.process_mode = Node.PROCESS_MODE_INHERIT

	camera_locked = false


func _move_camera_by_screen_edge(delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := get_viewport_rect().size
	var direction := Vector2.ZERO

	if mouse_pos.x <= edge_size:
		direction.x -= 1.0
	elif mouse_pos.x >= screen_size.x - edge_size:
		direction.x += 1.0

	if mouse_pos.y <= edge_size:
		direction.y -= 1.0
	elif mouse_pos.y >= screen_size.y - edge_size:
		direction.y += 1.0

	if direction != Vector2.ZERO:
		direction = direction.normalized()
		camera.global_position += direction * edge_move_speed * delta / camera.zoom.x


func _clamp_camera_to_map() -> void:
	var viewport_size := get_viewport_rect().size
	var visible_size := viewport_size / camera.zoom
	var half_visible := visible_size / 2.0

	camera.global_position.x = clamp(
		camera.global_position.x,
		half_visible.x,
		map_size.x - half_visible.x
	)

	camera.global_position.y = clamp(
		camera.global_position.y,
		half_visible.y,
		map_size.y - half_visible.y
	)


func _unhandled_input(event: InputEvent) -> void:
	if camera_locked:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed

	if event is InputEventMouseMotion and dragging:
		camera.global_position -= event.relative / camera.zoom
		_clamp_camera_to_map()
