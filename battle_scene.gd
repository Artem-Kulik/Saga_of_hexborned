extends Control

@onready var ally_wards = [
	$arena/BackGround/"Wards Ally"/WardSlot,
	$arena/BackGround/"Wards Ally"/WardSlot2,
	$arena/BackGround/"Wards Ally"/WardSlot3
]

@onready var enemy_wards = [
	$arena/BackGround/"Wards Enemy"/WardSlot_enemy,
	$arena/BackGround/"Wards Enemy"/WardSlot_enemy2,
	$arena/BackGround/"Wards Enemy"/WardSlot_enemy3
]

var current_team: String = "ally"

var ally_turn_index: int = 0
var enemy_turn_index: int = 0

var current_ward = null

var selected_attacker = null
var selected_skill: String = ""
var waiting_for_target: bool = false

var battle_finished: bool = false


func _ready() -> void:
	for ward in ally_wards:
		ward.connect("ward_clicked", _on_ward_clicked)
		ward.connect("skill_clicked", _on_skill_clicked)

	for ward in enemy_wards:
		ward.connect("ward_clicked", _on_ward_clicked)

	_start_turn()


func _input(event: InputEvent) -> void:
	if battle_finished:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Z:
				_surrender()


func _start_turn() -> void:
	if battle_finished:
		return

	if _is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return

	if _is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return

	selected_attacker = null
	selected_skill = ""
	waiting_for_target = false

	if current_team == "ally":
		current_ward = _get_next_alive_ward(ally_wards, true)
	else:
		current_ward = _get_next_alive_ward(enemy_wards, false)

	if current_ward == null:
		_next_turn()
		return

	_update_active_ward_visual()

	print("")
	print("====== ХІД ======")
	print(current_ward.name)
	print(current_ward.team)

	if current_team == "enemy":
		await get_tree().create_timer(0.8).timeout

		if battle_finished:
			return

		_enemy_attack(current_ward)
	else:
		print("Обери Q/W/E")


func _get_next_alive_ward(wards: Array, is_ally: bool):
	var start_index: int

	if is_ally:
		start_index = ally_turn_index
	else:
		start_index = enemy_turn_index

	for i in range(wards.size()):
		var check_index = (start_index + i) % wards.size()
		var ward = wards[check_index]

		if not ward.is_dead:
			if is_ally:
				ally_turn_index = (check_index + 1) % wards.size()
			else:
				enemy_turn_index = (check_index + 1) % wards.size()

			return ward

	return null


func _on_skill_clicked(ward, skill_key: String) -> void:
	if battle_finished:
		return

	if current_team != "ally":
		return

	if ward != current_ward:
		print("Зараз ходить інший Вард")
		return

	selected_attacker = ward
	selected_skill = skill_key
	waiting_for_target = true

	print("Обраний скіл: ", skill_key)
	print("Обери ворога")


func _on_ward_clicked(ward) -> void:
	if battle_finished:
		return

	if not waiting_for_target:
		return

	if ward.team != "enemy":
		print("Це не ворог")
		return

	if ward.is_dead:
		print("Ціль вже мертва")
		return

	_attack(selected_attacker, ward)
	_next_turn()


func _enemy_attack(enemy_ward) -> void:
	if battle_finished:
		return

	var alive_targets = _get_alive_wards(ally_wards)

	if alive_targets.is_empty():
		_finish_battle("ПОРАЗКА")
		return

	var target = alive_targets.pick_random()

	_attack(enemy_ward, target)
	_next_turn()


func _attack(attacker, target) -> void:
	print(attacker.name, " атакує ", target.name)

	target.take_damage(attacker.skill_damage)


func _next_turn() -> void:
	if battle_finished:
		return

	if current_team == "ally":
		current_team = "enemy"
	else:
		current_team = "ally"

	_start_turn()


func _get_alive_wards(wards: Array) -> Array:
	var result = []

	for ward in wards:
		if not ward.is_dead:
			result.append(ward)

	return result


func _is_team_dead(wards: Array) -> bool:
	for ward in wards:
		if not ward.is_dead:
			return false

	return true


func _update_active_ward_visual() -> void:
	for ward in ally_wards:
		ward.set_active_turn(ward == current_ward)

	for ward in enemy_wards:
		ward.set_active_turn(ward == current_ward)


func _clear_active_ward_visual() -> void:
	for ward in ally_wards:
		ward.set_active_turn(false)

	for ward in enemy_wards:
		ward.set_active_turn(false)


func _surrender() -> void:
	print("Ти здався")

	for ward in ally_wards:
		if not ward.is_dead:
			ward.take_damage(ward.current_hp)

	_finish_battle("ПОРАЗКА")


func _finish_battle(result_text: String) -> void:
	if battle_finished:
		return

	battle_finished = true
	waiting_for_target = false
	selected_attacker = null
	selected_skill = ""

	_clear_active_ward_visual()
	_show_battle_result(result_text)


func _show_battle_result(result_text: String) -> void:
	print("Результат бою: ", result_text)
