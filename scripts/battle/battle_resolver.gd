extends Node

var battle_log = null


func setup(log_ref) -> void:
	battle_log = log_ref


func attack(attacker, target) -> void:
	_log(attacker.name + " атакує " + target.name)
	target.take_damage(attacker.skill_damage)


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
			ward.take_damage(ward.current_hp)


func _log(text: String) -> void:
	if battle_log:
		battle_log.add_entry(text)
	else:
		print(text)
