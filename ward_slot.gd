extends Control

@onready var highlight = $Highlight

func _ready():
	highlight.visible = false

func _on_mouse_entered():
	highlight.visible = true
	
	var skill_panel = get_tree().get_first_node_in_group("skill_panel")
	if skill_panel:
		skill_panel.show_panel()

func _on_mouse_exited():
	highlight.visible = false
