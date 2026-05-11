extends Control

@onready var content = $Content

func _ready():
	visible = true
	clear_panel()

func show_panel():
	content.visible = true

func clear_panel():
	content.visible = false
