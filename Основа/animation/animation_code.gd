extends Node

const LIAH_Q = preload("res://Основа/char/water/Liah/q_anim/liah_q.tscn")


func animation_take_damage(node: CanvasItem):
	if node == null:
		return

	var start_color: Color = node.modulate
	var start_pos: Vector2 = node.global_position

	var knockback_pos: Vector2 = start_pos + Vector2(18, 0)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		node,
		"modulate",
		Color(1, 0.25, 0.25, 1),
		0.08
	)

	tween.tween_property(
		node,
		"global_position",
		knockback_pos,
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.set_parallel(false)

	tween.tween_property(
		node,
		"global_position",
		start_pos,
		0.13
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		node,
		"modulate",
		start_color,
		0.13
	)

	await tween.finished
func skill_pressed_animation(node: CanvasItem):
	if node == null:
		return
	
	var tween := create_tween()
	
	tween.tween_property(node,
	"modulate",
	Color(0.0, 1.0, 0.055, 0.886),
	0.1
	)
func skill_used_animation(node):
	if node == null:
		return
	
	var tween := create_tween()
	
	tween.tween_property(node,
	"modulate",
	node.base_modulate,
	0.1
	)
	
	await tween.finished
func skill_qwe_animation(pressed_button):
	var skill_name = pressed_button
	print (skill_name)
func skill_hit_animation(attacker, target, on_hit: Callable) -> void:
	if attacker == null or target == null:
		return

	var attacker_visual: Control = attacker.get_node_or_null("WardVisual")
	var target_visual: Control = target.get_node_or_null("WardVisual")

	if attacker_visual == null or target_visual == null:
		return

	var start_local_pos: Vector2 = attacker_visual.position
	var start_global_pos: Vector2 = attacker_visual.global_position
	var start_scale: Vector2 = attacker_visual.scale
	var start_rotation: float = attacker_visual.rotation

	var attacker_hitbox: Control = attacker_visual.get_node_or_null("Portrait")
	var target_hitbox: Control = target_visual.get_node_or_null("Portrait")

	if attacker_hitbox == null:
		attacker_hitbox = attacker_visual

	if target_hitbox == null:
		target_hitbox = target_visual

	var attacker_center: Vector2 = attacker_hitbox.get_global_rect().get_center()
	var target_center: Vector2 = target_hitbox.get_global_rect().get_center()

	var direction: Vector2 = target_center - attacker_center

	if direction.length() <= 0.01:
		return

	direction = direction.normalized()

	var attacker_radius: float = min(
		attacker_hitbox.get_global_rect().size.x,
		attacker_hitbox.get_global_rect().size.y
	) * 0.5

	var target_radius: float = min(
		target_hitbox.get_global_rect().size.x,
		target_hitbox.get_global_rect().size.y
	) * 0.5

	# менше число overlap = слабше заходить у ворога
	# більше число overlap = глибше врізається
	var overlap: float = 3.0

	var contact_center: Vector2 = target_center - direction * (attacker_radius + target_radius - overlap)

	var lift_global: Vector2 = start_global_pos + Vector2(0, -45)
	var prepare_global: Vector2 = lift_global - direction * 35.0
	var hit_global: Vector2 = start_global_pos + (contact_center - attacker_center)

	var rebound_global: Vector2 = hit_global - direction * 45.0
	var push_global: Vector2 = hit_global + direction * 3.0
	var hover_home_global: Vector2 = start_global_pos + Vector2(0, -35)

	var old_z_index: int = attacker.z_index
	var old_z_as_relative: bool = attacker.z_as_relative

	attacker.z_as_relative = false
	attacker.z_index = 4000

	var tween := create_tween()

	tween.tween_property(
		attacker_visual,
		"global_position",
		lift_global,
		0.30
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_interval(0.08)

	tween.tween_property(
		attacker_visual,
		"global_position",
		prepare_global,
		0.22
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(0.06)

	tween.tween_property(
		attacker_visual,
		"global_position",
		hit_global,
		0.28
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	tween.tween_callback(func():
		play_hit_sound()

		if on_hit.is_valid():
			on_hit.call()
)

	tween.tween_property(
		attacker_visual,
		"global_position",
		rebound_global,
		0.18
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		attacker_visual,
		"global_position",
		push_global,
		0.14
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_interval(0.08)

	tween.tween_property(
		attacker_visual,
		"global_position",
		hover_home_global,
		0.35
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(0.10)

	tween.tween_property(
		attacker_visual,
		"global_position",
		start_global_pos,
		0.16
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tween.finished

	attacker_visual.position = start_local_pos
	attacker_visual.scale = start_scale
	attacker_visual.rotation = start_rotation

	attacker.z_index = old_z_index
	attacker.z_as_relative = old_z_as_relative
	
func play_hit_sound() -> void:
	var player := AudioStreamPlayer.new()
	player.stream = preload("res://Основа/audio/audio_effects/hit_audio.mp3")
	player.volume_db = -4.0
	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(func():
		player.queue_free()
	)
func skill_return_animation(attacker: CanvasItem) -> void:
	if attacker == null:
		return

	var tween := create_tween()

	tween.tween_property(
		attacker,
		"global_position",
		attacker.start_position,
		0.22
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tween.finished
func play_glass_hit_on_target(attacker, target) -> void:
	if attacker == null or target == null:
		return

	var hit_pos: Vector2

	if target.has_node("WardVisual/Portrait"):
		hit_pos = target.get_node("WardVisual/Portrait").get_global_rect().get_center()
	elif "portrait" in target and target.portrait != null:
		hit_pos = target.portrait.get_global_rect().get_center()
	else:
		hit_pos = target.global_position

	var dir: Vector2 = (target.global_position - attacker.global_position).normalized()

	play_glass_hit(hit_pos, dir)
func play_glass_hit(pos: Vector2, dir: Vector2) -> void:
	var glass = preload("res://Основа/animation/particles/glass_impact.tscn").instantiate()

	get_tree().current_scene.add_child(glass)
	glass.global_position = pos

	if glass.has_method("play"):
		glass.play(dir)
func animation_dmg_number(value: int, pos: Vector2) -> void:
	var label := Label.new()

	get_tree().current_scene.add_child(label)

	label.text = "-" + str(value)
	label.z_index = 999
	label.global_position = pos
	label.modulate = Color(1, 0.25, 0.25, 1)
	label.add_theme_font_size_override("font_size", 42)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(label, "global_position", pos + Vector2(0, -120), 0.8)
	tween.tween_property(label, "scale", Vector2(1.35, 1.35), 0.12)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.1)

	await tween.finished

	if is_instance_valid(label):
		label.queue_free()



func liah_q_animation(attacker, target, on_hit: Callable) -> void:
	if attacker == null or target == null:
		return

	var effect = LIAH_Q.instantiate()
	get_tree().current_scene.add_child(effect)

	effect.global_position = attacker.global_position

	effect.set_direction(target.global_position - attacker.global_position)

	effect.hit_moment.connect(func():
		if on_hit.is_valid():
			on_hit.call()
	)

	effect.play()
