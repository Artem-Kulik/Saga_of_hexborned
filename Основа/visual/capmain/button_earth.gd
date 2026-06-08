extends Button

@export var scene_path: String = "res://Основа/visual/capmain/campaing_map.tscn"

func pressed():
	SceneLoader.change_scene(scene_path)
