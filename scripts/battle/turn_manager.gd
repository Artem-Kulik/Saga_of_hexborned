extends Node

var current_team: String = "ally"

var ally_turn_index: int = 0
var enemy_turn_index: int = 0


func roll_first_team() -> String:
	randomize()

	if randi() % 2 == 0:
		current_team = "ally"
	else:
		current_team = "enemy"

	return current_team


func reset_turn_indices() -> void:
	ally_turn_index = 0
	enemy_turn_index = 0


func switch_team() -> void:
	if current_team == "ally":
		current_team = "enemy"
	else:
		current_team = "ally"


func get_next_alive_ward(ally_wards: Array, enemy_wards: Array):
	if current_team == "ally":
		return _get_next_alive_from_team(ally_wards, true)

	return _get_next_alive_from_team(enemy_wards, false)


func _get_next_alive_from_team(wards: Array, is_ally: bool):
	var start_index: int

	if is_ally:
		start_index = ally_turn_index
	else:
		start_index = enemy_turn_index

	for i in range(wards.size()):
		var check_index: int = (start_index + i) % wards.size()
		var ward = wards[check_index]

		if not ward.is_dead:
			if is_ally:
				ally_turn_index = (check_index + 1) % wards.size()
			else:
				enemy_turn_index = (check_index + 1) % wards.size()

			return ward

	return null
