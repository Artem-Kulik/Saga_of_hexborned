extends Control

@export_file("*.tscn") var target_scene_path: String

@onready var animated_sprite: AnimatedSprite2D = $TextureRect/AnimatedSprite2D


func _ready() -> void:
	modulate.a = 0.0

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 1.0, 0.25)

	animated_sprite.play()

	if target_scene_path == "":
		print("LoadingScreen: target_scene_path порожній")
		return

	ResourceLoader.load_threaded_request(target_scene_path)


func _process(_delta: float) -> void:
	if target_scene_path == "":
		return

	var status := ResourceLoader.load_threaded_get_status(target_scene_path)

	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene := ResourceLoader.load_threaded_get(target_scene_path)
		get_tree().change_scene_to_packed(packed_scene)
