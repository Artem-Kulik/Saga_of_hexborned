extends Node

var battle_log = null


func setup(log_ref) -> void:
	battle_log = log_ref


func attack(attacker, target, skill_key: String = "Q") -> void:
	if attacker == null or target == null:
		return

	var damage: int = attacker.skill_damage
	var pressed_button = null

	match skill_key:
		"Q":
			pressed_button = attacker.skill_q
		"W":
			pressed_button = attacker.skill_w
		"E":
			pressed_button = attacker.skill_e

	if pressed_button != null:
		await AnimationCode.skill_used_animation(pressed_button)
		AnimationCode.skill_qwe_animation(pressed_button)

	await apply_damage(
		attacker,
		target,
		damage,
		skill_key,
		"-",
		"skill"
	)


func apply_damage(
	source,
	target,
	damage: int,
	skill_name: String = "-",
	status_text: String = "-",
	damage_source: String = "effect"
) -> void:
	if target == null:
		return

	var source_name: String = "Невідомо"
	var source_team: String = "-"

	if source != null:
		source_name = source.name
		source_team = source.team

	var hp_before: int = target.current_hp
	var max_hp: int = target.max_hp

	if damage_source == "skill" and source != null:
		await AnimationCode.skill_hit_animation(
			source,
			target,
			func():
				target.take_damage(damage)
		)
	else:
		target.take_damage(damage)

	var hp_after: int = target.current_hp

	if battle_log:
		battle_log.add_attack(
			source_name,
			source_team,
			skill_name,
			damage,
			status_text,
			target.name,
			target.team,
			hp_before,
			hp_after,
			max_hp,
			damage_source
		)
	else:
		print(source_name, " завдав ", damage, " шкоди ", target.name)

	if target.is_dead and battle_log:
		battle_log.add_death(target.name, target.team)


func get_alive_wards(wards: Array) -> Array:
	var result: Array = []

	for ward in wards:
		if not ward.is_dead:
			result.append(ward)

	return result


func is_team_dead(wards: Array) -> bool:
	for ward in wards:
		if not ward.is_dead:
			return false

	return true


func kill_team(wards: Array) -> void:
	for ward in wards:
		if not ward.is_dead:
			await apply_damage(
				null,
				ward,
				ward.current_hp,
				"-",
				"-",
				"surrender"
			)
