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
@onready var result_player: AudioStreamPlayer2D = $ResultPlayer
var defeat_music := preload ("res://Основа/audio/audio_effects/defeat.mp3")
var victory_music := preload ("res://Основа/audio/audio_effects/victory.mp3")

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

# Блокує нові скіл-кліки під час анімації атаки — запобігає паралельним атакам
var _turn_locked: bool = false

# Стан для W Етесени — вибір цілей у порядку
var _etesena_w_active: bool = false
var _etesena_w_targets: Array = []
var _etesena_w_labels: Array = []
var _etesena_w_required: int = 0


func _ready() -> void:
	_apply_ward_data()
	_create_battle_systems()
	_connect_wards()
	_setup_end_game_overlay()
	_roll_first_turn()
	play_random_track()
	music_player.finished.connect(_on_music_finished)


func _apply_ward_data() -> void:
	if GameState.ally_ward_ids.is_empty():
		return

	for i in range(mini(GameState.ally_ward_ids.size(), ally_wards.size())):
		ally_wards[i].setup_ward(GameState.ally_ward_ids[i])

	var all_enemy_ids: Array = WardDatabase.get_all_ids().filter(
		func(id: String) -> bool: return not GameState.ally_ward_ids.has(id)
	)
	all_enemy_ids.shuffle()

	var final_enemy_pool: Array = []
	var used_elements: Array = []

	for id in all_enemy_ids:
		var ward_data = WardDatabase.get_data(id)
		var elem = ward_data.get("element", "none")
		if not used_elements.has(elem):
			used_elements.append(elem)
			final_enemy_pool.append(id)
		
		if final_enemy_pool.size() == 3:
			break
			
	# На випадок якщо 3 різних стихій не знайшлося (добираємо будь-яких)
	if final_enemy_pool.size() < 3:
		for id in all_enemy_ids:
			if not final_enemy_pool.has(id):
				final_enemy_pool.append(id)
			if final_enemy_pool.size() == 3:
				break

	for i in range(mini(enemy_wards.size(), final_enemy_pool.size())):
		enemy_wards[i].setup_ward(final_enemy_pool[i])
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
	result_player.stream = victory_music
	result_player.play()
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
	result_player.stream = defeat_music
	result_player.play()
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

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Z:
				_surrender()
			KEY_ESCAPE:
				_cancel_skill()
			KEY_Q:
				if current_ward != null and turn_manager.current_team == "ally" and not waiting_for_target:
					_on_skill_clicked(current_ward, "Q")
			KEY_W:
				if current_ward != null and turn_manager.current_team == "ally" and not waiting_for_target:
					_on_skill_clicked(current_ward, "W")
			KEY_E:
				if current_ward != null and turn_manager.current_team == "ally" and not waiting_for_target:
					_on_skill_clicked(current_ward, "E")

	# Drag-to-target: відпустив мишку → атакуємо або скасовуємо
	# Пропускаємо якщо активний multi-target вибір (Танець Етесени)
	if waiting_for_target \
			and not _etesena_w_active \
			and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		var enemy_target = _get_enemy_ward_at_mouse()
		if enemy_target != null:
			# Відпустив над живим ворогом → атака
			# Перевірка провокації (taunt)
			if selected_attacker.taunted_by != "":
				if enemy_target.ward_id != selected_attacker.taunted_by:
					var taunter = null
					for w in enemy_wards:
						if w.ward_id == selected_attacker.taunted_by and not w.is_dead:
							taunter = w
							break
					if taunter != null:
						battle_log.add_entry("Ви під дією Провокації! Потрібно атакувати " + taunter.name)
						return
					else:
						selected_attacker.remove_status("taunt", selected_attacker.get_status("taunt"))
						selected_attacker.taunted_by = ""
			hide_target_arrow()
			waiting_for_target = false
			_turn_locked = true
			await battle_resolver.attack(selected_attacker, enemy_target, selected_skill)
			# Застосовуємо КД + логуємо (drag-to-target шлях)
			_apply_and_log_cd(selected_attacker, selected_skill)
			if battle_resolver.is_team_dead(enemy_wards):
				_finish_battle("ПЕРЕМОГА")
				return
			if battle_resolver.is_team_dead(ally_wards):
				_finish_battle("ПОРАЗКА")
				return
			_next_turn()
		else:
			# Відпустив над кнопкою власного скілу — це просто клік (не скасовуємо)
			var pressed_button = _get_skill_button(selected_attacker, selected_skill)
			var mouse_pos := get_viewport().get_mouse_position()
			if pressed_button != null and pressed_button.get_global_rect().has_point(mouse_pos):
				pass  # звичайне завершення кліку по кнопці скілу
			else:
				_cancel_skill()


func _create_battle_systems() -> void:
	battle_log = BattleLogScript.new()
	add_child(battle_log)
	battle_log.setup_ui(get_node_or_null("BattleLog"))

	turn_manager = TurnManagerScript.new()
	add_child(turn_manager)

	battle_resolver = BattleResolverScript.new()
	add_child(battle_resolver)
	battle_resolver.setup(battle_log, self)

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

	_turn_locked = false
	if _etesena_w_active:
		_etesena_w_active = false
		_etesena_w_targets.clear()
		_etesena_w_clear_labels()
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

	if current_ward.has_meta("untargetable") and current_ward.get_meta("untargetable"):
		current_ward.set_meta("untargetable", false)
		current_ward.modulate.a = 1.0

	# Підсвічуємо поточний Вард ДО перевірки оглушення —
	# щоб гравець бачив іконку стану на ньому до моменту пропуску
	_update_active_ward_visual()

	# === ОБРОБКА ОГЛУШЕННЯ ===
	# Оглушений Вард пропускає хід; хід переходить до наступного Варда ТІЄї ж команди.
	# Жодна команда не може ходити двічі поспіль.
	if current_ward.get_status("stun") > 0:
		battle_log.add_entry(current_ward.name + " оглушений — пропускає хід!")
		await get_tree().create_timer(0.6).timeout
		current_ward.remove_status("stun", 1)
		if current_ward.has_method("tick_cooldowns"):
			current_ward.tick_cooldowns()
		_start_turn()  # Та ж команда — наступний Вард, без switch_team()
		return

	battle_log.add_empty_line()
	battle_log.add_entry("====== ХІД ======")
	battle_log.add_entry(current_ward.name)
	battle_log.add_entry(current_ward.team)
	
	# === ОБРОБКА ГОРІННЯ ===
	var burn_stacks = current_ward.get_status("burning")
	if burn_stacks > 0:
		battle_log.add_entry("Горіння! " + current_ward.name + " отримує шкоду.")
		var burn_dmg = 50 * burn_stacks
		await battle_resolver.deal_damage_with_modifiers(null, current_ward, burn_dmg, "burning", "fire")
		current_ward.remove_status("burning", burn_stacks)
		if current_ward.is_dead:
			_next_turn()
			return

	# Тікаємо КД на початку кожного ходу персонажа
	if current_ward.has_method("tick_cooldowns"):
		current_ward.tick_cooldowns()

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

	if _turn_locked:
		return

	if turn_manager.current_team != "ally":
		return

	if ward != current_ward:
		battle_log.add_entry("Зараз ходить інший Вард")
		return

	# Перевірка КД
	if ward.has_method("is_skill_ready") and not ward.is_skill_ready(skill_key):
		var cd_left: int = ward._current_cd.get(skill_key, 0)
		battle_log.add_entry("Скіл " + skill_key + " на КД ще " + str(cd_left) + " ход.")
		return

	# Рікер W: лише якщо попередній скіл був Q або E
	if ward.ward_id == "riker" and skill_key == "W":
		var last: String = ward.get_meta("riker_last_skill", "") if ward.has_meta("riker_last_skill") else ""
		if last != "Q" and last != "E":
			battle_log.add_entry("Стиль Доломедес: спочатку використайте Q або E!")
			return

	selected_attacker = ward
	selected_skill = skill_key
	waiting_for_target = false
	hide_target_arrow()

	var pressed_button = _get_skill_button(ward, skill_key)

	var SkillExecutor = preload("res://scripts/battle/skill_executor.gd")
	var target_type = SkillExecutor.get_skill_target_type(ward.ward_id, skill_key, ward)

	if target_type == "single_enemy":
		waiting_for_target = true
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
			show_target_arrow(
				pressed_button.global_position + pressed_button.size * 0.5
			)
		battle_log.add_entry("Обраний скіл: " + skill_key)
		battle_log.add_entry("Обери ворога")
	elif target_type == "etesena_w":
		var alive_count: int = battle_resolver.get_alive_wards(enemy_wards).size()
		if alive_count == 0: return
		# Якщо під провокацією — лише 1 ціль (тільки провокатор)
		if ward.taunted_by != "":
			var taunter_found = false
			for w in enemy_wards:
				if w.ward_id == ward.taunted_by and not w.is_dead:
					taunter_found = true
					break
			_etesena_w_required = 1 if taunter_found else mini(alive_count, 3)
		else:
			_etesena_w_required = mini(alive_count, 3)
		_etesena_w_targets = []
		_etesena_w_labels = []
		_etesena_w_active = true
		waiting_for_target = true
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
		battle_log.add_entry("Танець: обери %d ціль(і) у порядку атаки  (Escape — скасування)" % _etesena_w_required)
	elif target_type == "self" or target_type == "all_enemies":
		if ward.taunted_by != "":
			var taunter_alive = false
			for w in enemy_wards:
				if w.ward_id == ward.taunted_by and not w.is_dead:
					taunter_alive = true
					break
			if taunter_alive:
				battle_log.add_entry("Під Провокацією можна використовувати лише направлені атаки!")
				return
			else:
				ward.remove_status("taunt", ward.get_status("taunt"))
				ward.taunted_by = ""
				
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
		battle_log.add_entry("Обраний скіл: " + skill_key)
		_turn_locked = true
		await battle_resolver.attack(selected_attacker, null, selected_skill)
		_apply_and_log_cd(selected_attacker, selected_skill)
		if battle_resolver.is_team_dead(enemy_wards):
			_finish_battle("ПЕРЕМОГА")
			return
		if battle_resolver.is_team_dead(ally_wards):
			_finish_battle("ПОРАЗКА")
			return
		_next_turn()


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

	if ward.has_meta("untargetable") and ward.get_meta("untargetable"):
		battle_log.add_entry("Ця ціль наразі не вразлива!")
		return

	# Танець Етесени — multi-target вибір
	if _etesena_w_active:
		_etesena_w_add_target(ward)
		return

	if selected_attacker.taunted_by != "":
		if ward.ward_id != selected_attacker.taunted_by:
			# Перевіряємо чи живий той, хто спровокував
			var taunter = null
			for w in enemy_wards:
				if w.ward_id == selected_attacker.taunted_by and not w.is_dead:
					taunter = w
					break
			if taunter != null:
				battle_log.add_entry("Ви під дією Провокації! Потрібно атакувати " + taunter.name)
				return
			else:
				# Якщо він мертвий, знімаємо провокацію
				selected_attacker.remove_status("taunt", selected_attacker.get_status("taunt"))
				selected_attacker.taunted_by = ""

	hide_target_arrow()

	waiting_for_target = false
	_turn_locked = true

	await battle_resolver.attack(
		selected_attacker,
		ward,
		selected_skill
	)

	# Застосовуємо КД + логуємо
	_apply_and_log_cd(selected_attacker, selected_skill)

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

	var available_skills = []
	for sk in ["Q", "W", "E"]:
		if enemy_ward.has_method("is_skill_ready") and enemy_ward.is_skill_ready(sk):
			# Рікер W: тільки якщо попередній скіл Q або E
			if enemy_ward.ward_id == "riker" and sk == "W":
				var last: String = enemy_ward.get_meta("riker_last_skill", "") if enemy_ward.has_meta("riker_last_skill") else ""
				if last != "Q" and last != "E":
					continue
			available_skills.append(sk)
	if available_skills.is_empty():
		available_skills = ["Q"] # Fallback

	var SkillExecutor = preload("res://scripts/battle/skill_executor.gd")
	var forced_taunter = null
	
	if enemy_ward.taunted_by != "":
		for w in ally_wards:
			if w.ward_id == enemy_ward.taunted_by and not w.is_dead:
				forced_taunter = w
				break
		if forced_taunter == null:
			enemy_ward.remove_status("taunt", enemy_ward.get_status("taunt"))
			enemy_ward.taunted_by = ""
	if forced_taunter != null:
		var single_target_skills = available_skills.filter(func(sk): return SkillExecutor.get_skill_target_type(enemy_ward.ward_id, sk, enemy_ward) == "single_enemy")
		if not single_target_skills.is_empty():
			available_skills = single_target_skills

	var random_skill: String = available_skills.pick_random()
	var target_type = SkillExecutor.get_skill_target_type(enemy_ward.ward_id, random_skill, enemy_ward)
	var target = null

	if target_type == "single_enemy":
		if forced_taunter != null:
			target = forced_taunter
		else:
			var valid_targets = alive_targets.filter(func(w): return not (w.has_meta("untargetable") and w.get_meta("untargetable")))
			if valid_targets.is_empty():
				valid_targets = alive_targets # Fallback if all are untargetable
			target = valid_targets.pick_random()

	await battle_resolver.attack(
		enemy_ward,
		target,
		random_skill
	)

	# Застосовуємо КД + логуємо для ворога
	_apply_and_log_cd(enemy_ward, random_skill)

	if battle_finished:
		return

	if battle_resolver.is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return

	if battle_resolver.is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return

	_next_turn()


func _cancel_skill() -> void:
	if not waiting_for_target:
		return

	var pressed_button = _get_skill_button(selected_attacker, selected_skill)
	if pressed_button:
		AnimationCode.skill_used_animation(pressed_button)

	waiting_for_target = false
	selected_attacker = null
	selected_skill = ""
	hide_target_arrow()
	if _etesena_w_active:
		_etesena_w_active = false
		_etesena_w_targets.clear()
		_etesena_w_clear_labels()
	battle_log.add_entry("Скіл скасовано")


func _get_enemy_ward_at_mouse():
	var mouse_pos := get_viewport().get_mouse_position()
	for ward in enemy_wards:
		if ward.is_dead:
			continue
		if ward.has_meta("untargetable") and ward.get_meta("untargetable"):
			continue
		if ward.get_global_rect().has_point(mouse_pos):
			return ward
	return null


# ── Танець Етесени: multi-target ────────────────────────────────────────────

func _etesena_w_add_target(ward) -> void:
	# Перевірка провокації
	if selected_attacker.taunted_by != "" and ward.ward_id != selected_attacker.taunted_by:
		var taunter = null
		for w in enemy_wards:
			if w.ward_id == selected_attacker.taunted_by and not w.is_dead:
				taunter = w
				break
		if taunter != null:
			battle_log.add_entry("Під Провокацією! Потрібно атакувати " + taunter.name)
			return
		else:
			selected_attacker.remove_status("taunt", selected_attacker.get_status("taunt"))
			selected_attacker.taunted_by = ""

	_etesena_w_targets.append(ward)
	var order_num: int = _etesena_w_targets.size()

	# Лейбл з номером поверх картки варда
	var label := Label.new()
	label.text = str(order_num)
	label.z_index = 500
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.1, 1.0))
	var portrait_center: Vector2 = ward.portrait.get_global_rect().get_center()
	label.global_position = portrait_center - Vector2(11, 24)
	add_child(label)
	_etesena_w_labels.append(label)

	battle_log.add_entry("Танець: ціль %d — %s" % [order_num, ward.name])

	# Рахуємо required динамічно — захист від несинхронізованого стану
	var required: int = mini(battle_resolver.get_alive_wards(enemy_wards).size(), 3)
	if required <= 0: required = 1
	if _etesena_w_targets.size() >= required:
		await _etesena_w_execute()


func _etesena_w_execute() -> void:
	_etesena_w_active = false
	waiting_for_target = false
	hide_target_arrow()
	_etesena_w_clear_labels()

	selected_attacker.set_meta("etesena_w_targets", _etesena_w_targets.duplicate())
	_etesena_w_targets.clear()

	_turn_locked = true
	await battle_resolver.attack(selected_attacker, null, selected_skill)
	_apply_and_log_cd(selected_attacker, selected_skill)

	if battle_resolver.is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return
	if battle_resolver.is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return
	_next_turn()


func _etesena_w_clear_labels() -> void:
	for label in _etesena_w_labels:
		if is_instance_valid(label):
			label.queue_free()
	_etesena_w_labels.clear()


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


## Застосовує КД і логує його, якщо КД > 0
func _apply_and_log_cd(ward, skill_key: String) -> void:
	if ward == null:
		return
	if not ward.has_method("apply_skill_cooldown"):
		return

	ward.apply_skill_cooldown(skill_key)

	var cd_turns: int = ward._max_cd.get(skill_key, 0)
	if cd_turns > 0 and battle_log != null:
		battle_log.add_cooldown(ward.name, ward.team, skill_key, cd_turns)
