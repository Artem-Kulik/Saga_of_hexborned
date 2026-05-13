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

@onready var music_player: AudioStreamPlayer = $MusicPlayer

@onready var end_game_overlay: Control = $EndGameOverlay
@onready var background_overlay: TextureRect = $EndGameOverlay/BackGroundOverlay

@onready var win_title: Control = $EndGameOverlay/CenterContainer/WinTitle
@onready var loose_title: Control = $EndGameOverlay/CenterContainer/LooseTitle
@onready var victory_particles: GPUParticles2D = $EndGameOverlay/CenterContainer/VictoryParticles
@onready var defeat_particles: GPUParticles2D = $EndGameOverlay/CenterContainer/DefeatParticles
@onready var defeat_smoke: GPUParticles2D = $EndGameOverlay/CenterContainer/DefeatSmoke
@onready var defeat_ash: GPUParticles2D = $EndGameOverlay/CenterContainer/DefeatAsh

var target_arrow = null
var target_arrow_scene := preload("res://Основа/animation/target_arrow.tscn")
var end_screen_tween: Tween
var overlay_tween: Tween

var music_tracks: Array[AudioStream] = [
	preload("res://Основа/audio/main_theme/sound_1.mp3"),
	preload("res://Основа/audio/main_theme/sound_2.mp3"),
	preload("res://Основа/audio/main_theme/sound_3.mp3")
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
	_setup_end_game_overlay()
	_roll_first_turn()
	play_random_track()
	music_player.finished.connect(_on_music_finished)
func _fade_in_end_screen() -> void:
	end_game_overlay.visible = true
	end_game_overlay.modulate.a = 0.0

	if end_screen_tween:
		end_screen_tween.kill()

	end_screen_tween = create_tween()
	end_screen_tween.tween_property(
		end_game_overlay,
		"modulate:a",
		1.0,
		0.45
	)

func _setup_end_game_overlay() -> void:
	end_game_overlay.visible = false

	win_title.visible = false
	loose_title.visible = false

	victory_particles.emitting = false
	defeat_particles.emitting = false
	defeat_smoke.emitting = false
	defeat_ash.emitting = false


func show_victory_screen() -> void:
	print("SHOW VICTORY SCREEN")

	_fade_in_end_screen()
	background_overlay.visible = true
	win_title.visible = true
	loose_title.visible = false

	victory_particles.visible = true
	victory_particles.emitting = true

	defeat_particles.visible = false
	defeat_particles.emitting = false
	defeat_smoke.visible = false
	defeat_smoke.emitting = false
	defeat_ash.visible = false
	defeat_ash.emitting = false

func show_defeat_screen() -> void:
	print("SHOW DEFEAT SCREEN")

	_fade_in_end_screen()
	background_overlay.visible = true
	win_title.visible = false
	loose_title.visible = true

	victory_particles.visible = false
	victory_particles.emitting = false

	defeat_particles.visible = true
	defeat_particles.emitting = true
	defeat_smoke.visible = true
	defeat_smoke.emitting = true
	defeat_ash.visible = true
	defeat_ash.emitting = true

	background_overlay.modulate.a = 0.9


func play_random_track() -> void:
	if music_tracks.is_empty():
		return

	var random_track = music_tracks.pick_random()
	music_player.stream = random_track
	music_player.play()


func _on_music_finished() -> void:
	play_random_track()


func _process(_delta: float) -> void:
	reorder_manager.process_drag()


func show_target_arrow(from_position: Vector2) -> void:
	hide_target_arrow()

	target_arrow = target_arrow_scene.instantiate()
	add_child(target_arrow)

	if target_arrow.has_method("setup"):
		target_arrow.setup(from_position)


func hide_target_arrow() -> void:
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null


func _get_skill_button(ward, skill_key: String):
	if ward == null:
		return null

	match skill_key:
		"Q":
			return ward.skill_q
		"W":
			return ward.skill_w
		"E":
			return ward.skill_e

	return null


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

	hide_target_arrow()

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

	if current_ward.is_dead:
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

		if current_ward == null or current_ward.is_dead:
			_next_turn()
			return

		await _enemy_attack(current_ward)
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

	var pressed_button = _get_skill_button(ward, skill_key)

	if pressed_button:
		show_target_arrow(
			pressed_button.global_position + pressed_button.size * 0.5
		)

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

	hide_target_arrow()

	waiting_for_target = false

	await battle_resolver.attack(
		selected_attacker,
		ward,
		selected_skill
	)

	if battle_resolver.is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return

	if battle_resolver.is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return

	_next_turn()


func _on_ward_drag_started(ward) -> void:
	if battle_started:
		return

	reorder_manager.start_drag_ward(ward)


func _enemy_attack(enemy_ward) -> void:
	if battle_finished:
		return

	if enemy_ward == null or enemy_ward.is_dead:
		_next_turn()
		return

	hide_target_arrow()

	var alive_targets: Array = battle_resolver.get_alive_wards(ally_wards)

	if alive_targets.is_empty():
		_finish_battle("ПОРАЗКА")
		return

	var target = alive_targets.pick_random()
	var random_skill: String = ["Q", "W", "E"].pick_random()

	await battle_resolver.attack(
		enemy_ward,
		target,
		random_skill
	)

	if battle_finished:
		return

	if battle_resolver.is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return

	if battle_resolver.is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return

	_next_turn()


func _next_turn() -> void:
	if battle_finished:
		return

	hide_target_arrow()

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

	hide_target_arrow()
	_clear_active_ward_visual()
	_show_battle_result(result_text)

	if result_text == "ПЕРЕМОГА":
		show_victory_screen()
	elif result_text == "ПОРАЗКА":
		show_defeat_screen()


func _show_battle_result(result_text: String) -> void:
	battle_log.add_entry("Результат бою: " + result_text)
