extends Control

const TurnManagerScript = preload("res://scripts/battle/turn_manager.gd")
const BattleLogScript = preload("res://scripts/battle/battle_log.gd")
const BattleResolverScript = preload("res://scripts/battle/battle_resolver.gd")
const BattleReorderManagerScript = preload("res://scripts/battle/battle_reorder_manager.gd")

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
var turn_number: int = 0
var turn_manager
var battle_log
var battle_resolver
var reorder_manager

var current_ward = null

var selected_attacker = null
var selected_skill: String = ""
var waiting_for_target: bool = false

var battle_finished: bool = false
var battle_started: bool = false


func _ready() -> void:
	_create_battle_systems()
	_connect_wards()
	_roll_first_turn()


func _process(_delta: float) -> void:
	reorder_manager.process_drag()


func _input(event: InputEvent) -> void:
	if reorder_manager.handle_input(event):
		return

	if battle_finished:
		return

	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_Z:
				_surrender()


func _create_battle_systems() -> void:
	battle_log = BattleLogScript.new()
	add_child(battle_log)
	battle_log.setup_ui(get_node_or_null("BattleLog"))

	turn_manager = TurnManagerScript.new()
	add_child(turn_manager)

	battle_resolver = BattleResolverScript.new()
	add_child(battle_resolver)
	battle_resolver.setup(battle_log)

	reorder_manager = BattleReorderManagerScript.new()
	add_child(reorder_manager)
	reorder_manager.setup(
		ally_container,
		ally_wards,
		confirm_order_button,
		battle_log
	)
	reorder_manager.reorder_confirmed.connect(_on_reorder_confirmed)


func _connect_wards() -> void:
	for ward in ally_wards:
		ward.connect("ward_clicked", _on_ward_clicked)
		ward.connect("skill_clicked", _on_skill_clicked)
		ward.connect("ward_drag_started", _on_ward_drag_started)

	for ward in enemy_wards:
		ward.connect("ward_clicked", _on_ward_clicked)


func _roll_first_turn() -> void:
	var first_team: String = turn_manager.roll_first_team()

	battle_log.add_entry("Першим ходить: " + first_team)

	if first_team == "enemy":
		reorder_manager.start_reorder_phase()
	else:
		_start_battle()


func _on_reorder_confirmed() -> void:
	ally_wards = reorder_manager.get_ally_wards()
	_start_battle()


func _start_battle() -> void:
	turn_number = 0
	battle_started = true
	turn_manager.reset_turn_indices()

	battle_log.add_entry("Бій почався")
	_start_turn()


func _start_turn() -> void:
	if battle_finished:
		return

	if battle_resolver.is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return

	if battle_resolver.is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return
	
	turn_number += 1
	battle_log.start_turn(turn_number)
	selected_attacker = null
	selected_skill = ""
	waiting_for_target = false

	current_ward = turn_manager.get_next_alive_ward(ally_wards, enemy_wards)

	if current_ward == null:
		_next_turn()
		return

	_update_active_ward_visual()

	battle_log.add_empty_line()
	battle_log.add_entry("====== ХІД ======")
	battle_log.add_entry(current_ward.name)
	battle_log.add_entry(current_ward.team)

	if turn_manager.current_team == "enemy":
		await get_tree().create_timer(0.8).timeout

		if battle_finished:
			return

		_enemy_attack(current_ward)
	else:
		battle_log.add_entry("Обери Q/W/E")


func _on_skill_clicked(ward, skill_key: String) -> void:
	if not battle_started:
		return

	if battle_finished:
		return

	if turn_manager.current_team != "ally":
		return

	if ward != current_ward:
		battle_log.add_entry("Зараз ходить інший Вард")
		return

	selected_attacker = ward
	selected_skill = skill_key
	waiting_for_target = true

	battle_log.add_entry("Обраний скіл: " + skill_key)
	battle_log.add_entry("Обери ворога")


func _on_ward_clicked(ward) -> void:
	if not battle_started:
		return

	if battle_finished:
		return

	if not waiting_for_target:
		return

	if ward.team != "enemy":
		battle_log.add_entry("Це не ворог")
		return

	if ward.is_dead:
		battle_log.add_entry("Ціль вже мертва")
		return
	battle_resolver.attack(selected_attacker, ward, selected_skill)
	_next_turn()


func _on_ward_drag_started(ward) -> void:
	if battle_started:
		return

	reorder_manager.start_drag_ward(ward)


func _enemy_attack(enemy_ward) -> void:
	if battle_finished:
		return

	var alive_targets: Array = battle_resolver.get_alive_wards(ally_wards)

	if alive_targets.is_empty():
		_finish_battle("ПОРАЗКА")
		return

	var target = alive_targets.pick_random()
	var random_skill: String = ["Q", "W", "E"].pick_random()

	battle_resolver.attack(enemy_ward, target, random_skill)
	_next_turn()


func _next_turn() -> void:
	if battle_finished:
		return

	turn_manager.switch_team()
	_start_turn()


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
	battle_log.add_entry("Ти здався")

	battle_resolver.kill_team(ally_wards)
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
	battle_log.add_entry("Результат бою: " + result_text)
