extends Button

func _pressed() -> void:
	get_tree().current_scene.focus_stage_and_open_info(self)
