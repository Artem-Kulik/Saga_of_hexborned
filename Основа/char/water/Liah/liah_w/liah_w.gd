extends Node2D

signal finished

@onready var sprite: AnimatedSprite2D = $liah_w

func play_once() -> void:
	for child in get_children():
		if child is GPUParticles2D:
			child.one_shot = false
			child.emitting = true

	if sprite.sprite_frames != null:
		var frames := sprite.sprite_frames.duplicate() as SpriteFrames
		for anim_name in frames.get_animation_names():
			frames.set_animation_loop(anim_name, false)
		sprite.sprite_frames = frames

	sprite.play("default")

	await sprite.animation_finished

	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = false

	await get_tree().create_timer(0.25).timeout

	finished.emit()
	queue_free()
