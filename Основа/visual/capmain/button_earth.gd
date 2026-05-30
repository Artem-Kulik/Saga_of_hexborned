extends Button

@export var scene_path: String = "res://Основа/visual/capmain/campaing_map.tscn"

func pressed():
	get_tree().change_scene_to_file(scene_path)
