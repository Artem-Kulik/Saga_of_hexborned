extends Control

@onready var camera: Camera2D = $camera
@onready var stage_1: Control = $stages/stage_1

@export var target_zoom := Vector2(0.2, 0.2)

@export var drag_speed := 1.0

var dragging := false


func _ready() -> void:
	camera.enabled = true
	camera.zoom = target_zoom

	_center_camera_on(stage_1)


func _center_camera_on(target: Control) -> void:
	camera.global_position = target.global_position + target.size / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed

	if event is InputEventMouseMotion and dragging:
		camera.global_position -= event.relative / camera.zoom
