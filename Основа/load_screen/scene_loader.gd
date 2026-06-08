extends Node

const LOAD_SCREEN := preload("res://Основа/load_screen/load_screen.tscn")


func change_scene(scene_path: String) -> void:
	var load_screen := LOAD_SCREEN.instantiate()
	load_screen.target_scene_path = scene_path

	get_tree().root.add_child(load_screen)

	var old_scene := get_tree().current_scene
	if old_scene:
		old_scene.queue_free()

	get_tree().current_scene = load_screen
