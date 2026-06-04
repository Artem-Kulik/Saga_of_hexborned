extends Node2D

signal hit_moment

@onready var visual_root: Node2D = $visual_root
@onready var sprite: AnimatedSprite2D = $visual_root/liah_q_animation


func set_direction(direction: Vector2) -> void:
	visual_root.rotation = direction.angle()


func play() -> void:
	sprite.stop()
	sprite.frame = 0
	sprite.play("default")


func _on_animated_sprite_2d_animation_finished() -> void:
	hit_moment.emit()

	var particles := get_node_or_null("visual_root/water_drop") as GPUParticles2D
	if particles == null:
		print("water_drop не знайдено")
		queue_free()
		return

	particles.one_shot = true
	particles.emitting = false

	await get_tree().process_frame

	particles.restart()
	particles.emitting = true

	await get_tree().create_timer(
		particles.lifetime + particles.preprocess
	).timeout

	queue_free()
