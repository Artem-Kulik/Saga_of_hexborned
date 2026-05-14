extends Node2D

@onready var particles: GPUParticles2D = $GPUParticles2D


func play(dir: Vector2) -> void:
	if particles == null:
		queue_free()
		return

	dir = dir.normalized()

	var mat := particles.process_material.duplicate() as ParticleProcessMaterial
	particles.process_material = mat

	if mat != null:
		mat.direction = Vector3(dir.x, dir.y, 0.0)
		mat.spread = 12.0

	particles.restart()
	particles.emitting = true

	await get_tree().create_timer(particles.lifetime + 0.3).timeout
	queue_free()
