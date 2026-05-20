extends Control

@onready var hl: CanvasItem = $hl

var is_selected: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hl.visible = false


func _on_mouse_entered() -> void:
	hl.visible = true


func _on_mouse_exited() -> void:
	if not is_selected:
		hl.visible = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_selected = !is_selected
			hl.visible = is_selected
