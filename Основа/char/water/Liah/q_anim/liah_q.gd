extends Control

signal hit_moment

@onready var visual_root: Node2D = $visual_root
@onready var sprite: AnimatedSprite2D = $visual_root/liah_q_animation
@onready var particles: GPUParticles2D = $visual_root/water_drop


func set_direction(direction: Vector2) -> void:
	visual_root.rotation = direction.angle()


func play() -> void:
	particles.emitting = false
	sprite.play("default")


func _on_animated_sprite_2d_animation_finished() -> void:
	hit_moment.emit()

	particles.restart()
	particles.emitting = true

	var timer := get_tree().create_timer(particles.lifetime)
	timer.timeout.connect(queue_free)
