extends GPUParticles2D

@export var start_radius: float = 4.0
@export var end_radius: float = 80.0
@export var expand_time: float = 0.35

func burst_sparks() -> void:
	emitting = false
	restart()

	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process_material.emission_sphere_radius = start_radius

	emitting = true

	var tween := create_tween()
	tween.tween_property(
		process_material,
		"emission_sphere_radius",
		end_radius,
		expand_time
	)
