extends Node

const LOADING_SCREEN := preload("res://Основа/load_screen/load_screen.tscn")

var scene_to_load: String = ""


func change_scene(path: String) -> void:
	scene_to_load = path

	var loading_screen := LOADING_SCREEN.instantiate()
	loading_screen.target_scene_path = path

	get_tree().root.add_child(loading_screen)

	var current_scene := get_tree().current_scene
	if current_scene:
		current_scene.queue_free()

	get_tree().current_scene = loading_screen
