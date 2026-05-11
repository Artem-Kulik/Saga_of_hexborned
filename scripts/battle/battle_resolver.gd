extends Node

var battle_log = null


func setup(log_ref) -> void:
	battle_log = log_ref


func attack(attacker, target, skill_key: String = "Q") -> void:
	var damage: int = attacker.skill_damage

	apply_damage(
		attacker.name,
		attacker.team,
		target,
		damage,
		skill_key,
		"-",
		"skill"
	)


func apply_damage(
	source_name: String,
	source_team: String,
	target,
	damage: int,
	skill_name: String = "-",
	status_text: String = "-",
	damage_source: String = "effect"
) -> void:
	var hp_before: int = target.current_hp
	var max_hp: int = target.max_hp

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
			apply_damage(
				"Здатися",
				"ally",
				ward,
				ward.current_hp,
				"-",
				"-",
				"surrender"
			)
