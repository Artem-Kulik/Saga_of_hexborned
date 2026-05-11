extends Control

@onready var ally_container = $arena/BackGround/"Wards Ally"
@onready var confirm_order_button = get_node_or_null("ConfirmOrderButton")

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

var reorder_phase: bool = false
var dragging_ward = null
var dragged_from_index: int = -1
var drag_mouse_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	randomize()

	for ward in ally_wards:
		ward.connect("ward_clicked", _on_ward_clicked)
		ward.connect("skill_clicked", _on_skill_clicked)
		ward.connect("ward_drag_started", _start_drag_ward)

	for ward in enemy_wards:
		ward.connect("ward_clicked", _on_ward_clicked)

	if confirm_order_button:
		confirm_order_button.visible = false
		confirm_order_button.pressed.connect(_on_confirm_order_pressed)

	_roll_first_turn()


func _process(_delta: float) -> void:
	if dragging_ward == null:
		return

	dragging_ward.global_position = get_global_mouse_position() - drag_mouse_offset


func _input(event: InputEvent) -> void:
	if dragging_ward != null:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_drop_dragged_ward()
				return

	if battle_finished:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Z:
				_surrender()


func _roll_first_turn() -> void:
	if randi() % 2 == 0:
		current_team = "ally"
	else:
		current_team = "enemy"

	print("Першим ходить: ", current_team)

	if current_team == "enemy":
		_start_reorder_phase()
	else:
		_start_battle()


func _start_reorder_phase() -> void:
	reorder_phase = true

	if confirm_order_button:
		confirm_order_button.visible = true

	print("Ти ходиш другим. Можеш переставити Вардів і натиснути Готово.")


func _on_confirm_order_pressed() -> void:
	if not reorder_phase:
		return

	if dragging_ward != null:
		_drop_dragged_ward()

	reorder_phase = false

	if confirm_order_button:
		confirm_order_button.visible = false

	_start_battle()


func _start_battle() -> void:
	reorder_phase = false
	ally_turn_index = 0
	enemy_turn_index = 0

	print("Бій почався")
	_start_turn()


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
	if reorder_phase:
		return

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
	if reorder_phase:
		return

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


func _start_drag_ward(ward) -> void:
	if not reorder_phase:
		return

	if ward.team != "ally":
		return

	if dragging_ward != null:
		return

	dragging_ward = ward
	dragged_from_index = ally_wards.find(ward)

	if dragged_from_index == -1:
		dragging_ward = null
		return

	drag_mouse_offset = get_global_mouse_position() - ward.global_position
	ward.z_index = 100

	print("Рухаємо Варда: ", ward.name)


func _drop_dragged_ward() -> void:
	if dragging_ward == null:
		return

	var nearest_index: int = _get_nearest_ally_slot_index(get_global_mouse_position())

	if nearest_index == -1:
		nearest_index = dragged_from_index

	dragging_ward.z_index = 0

	if nearest_index != dragged_from_index:
		_swap_ally_wards(dragged_from_index, nearest_index)

	await get_tree().process_frame

	_refresh_ally_wards_order()

	print("Новий порядок Вардів:")
	for ward in ally_wards:
		print(ward.name)

	dragging_ward = null
	dragged_from_index = -1
	drag_mouse_offset = Vector2.ZERO


func _swap_ally_wards(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_b < 0:
		return

	if index_a >= ally_wards.size() or index_b >= ally_wards.size():
		return

	var new_order = ally_wards.duplicate()

	var temp = new_order[index_a]
	new_order[index_a] = new_order[index_b]
	new_order[index_b] = temp

	for i in range(new_order.size()):
		ally_container.move_child(new_order[i], i)

	ally_wards = new_order


func _get_nearest_ally_slot_index(mouse_global_pos: Vector2) -> int:
	var nearest_index: int = -1
	var nearest_distance: float = INF

	for i in range(ally_wards.size()):
		var ward = ally_wards[i]

		if ward == dragging_ward:
			continue

		var ward_center: Vector2 = ward.global_position + ward.size / 2.0
		var distance: float = mouse_global_pos.distance_to(ward_center)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i

	if nearest_index == -1:
		return dragged_from_index

	return nearest_index


func _refresh_ally_wards_order() -> void:
	ally_wards.clear()

	for child in ally_container.get_children():
		if child.has_method("take_damage"):
			ally_wards.append(child)


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
