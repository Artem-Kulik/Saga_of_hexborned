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
			_clear_taunt_after_attack(selected_attacker)
			await _try_zhnets_harvest()
			await _try_adoneia_golem_tick()
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
	for _w in ally_wards + enemy_wards:
		if _w.has_meta("countered_this_turn"):
			_w.remove_meta("countered_this_turn")
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
		battle_log.add_entry("%s: Загороджуючий водопад спав — знову доступний як ціль." % current_ward.name)

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

	# === ПАСИВКА СЬОМОГО: 2 стаки горіння рандомному варду ===
	if current_ward.ward_id == "siomyi":
		var all_active: Array = []
		for w in ally_wards + enemy_wards:
			if not w.is_dead and w != current_ward:
				all_active.append(w)
		if not all_active.is_empty():
			var lucky = all_active[randi() % all_active.size()]
			lucky.add_status("burning", 2)
			lucky._update_status_visuals()
			battle_log.add_entry("З пилу жару: %s отримує 2 стаки горіння!" % lucky.name)
			battle_log.add_effect(lucky.name, lucky.team, "Горіння +2 стаки (пасивка Сьомого)")

	# === ВОГОНЬ СЬОМОГО: шкода всій команді ===
	var fs_stacks: int = current_ward.get_status("fire_seventh")
	if fs_stacks > 0:
		var fs_team: Array = ally_wards if current_ward.team == "ally" else enemy_wards
		battle_log.add_entry("Вогонь сьомого спалахує! %d стак(и) → %d вогняної шкоди кожному!" % [fs_stacks, 150 * fs_stacks])
		for w in fs_team:
			if not w.is_dead:
				await battle_resolver.deal_damage_with_modifiers(null, w, 150 * fs_stacks, "fire_seventh", "fire")
		current_ward.remove_status("fire_seventh", fs_stacks)
		current_ward._update_status_visuals()
		if battle_resolver.is_team_dead(ally_wards):
			_finish_battle("ПОРАЗКА")
			return
		if battle_resolver.is_team_dead(enemy_wards):
			_finish_battle("ПЕРЕМОГА")
			return
		if current_ward.is_dead:
			_next_turn()
			return

	# === ОБРОБКА ГОРІННЯ ===
	if current_ward.get_status("burning") > 0:
		var burn_dmg: int = current_ward.tick_burning()
		battle_log.add_entry("Горіння! " + current_ward.name + " отримує %d вогняної шкоди." % burn_dmg)
		await battle_resolver.deal_damage_with_modifiers(null, current_ward, burn_dmg, "burning", "fire")
		if current_ward.is_dead:
			_next_turn()
			return

	# Тікаємо КД на початку кожного ходу персонажа
	if current_ward.has_method("tick_cooldowns"):
		current_ward.tick_cooldowns()

	# === РЕГЕНЕРАЦІЯ ===
	if current_ward.get_status("regen") > 0:
		var regen_hp_before: int = current_ward.current_hp
		current_ward.health.heal(100)
		current_ward.remove_status("regen", 1)
		battle_log.add_heal(current_ward.name, current_ward.team, regen_hp_before, current_ward.current_hp, current_ward.max_hp)
		if current_ward.get_status("regen") == 0:
			battle_log.add_entry(current_ward.name + ": регенерація завершилась.")

	# Тік кола пекельного вогню та бар'єру
	if current_ward.get_status("fire_circle") > 0:
		current_ward.remove_status("fire_circle", 1)
		if current_ward.get_status("fire_circle") == 0:
			battle_log.add_entry(current_ward.name + ": Коло пекельного вогню згасло.")
	if current_ward.get_status("barrier") > 0:
		current_ward.remove_status("barrier", 1)
		if current_ward.get_status("barrier") == 0:
			battle_log.add_entry(current_ward.name + ": Бар'єр згас.")

	# === ПАРАЗИТУВАННЯ: авто-атака союзника ===
	if current_ward.get_status("parasitism") > 0:
		current_ward.remove_status("parasitism", current_ward.get_status("parasitism"))
		battle_log.add_entry("Паразитування! %s атакує свого союзника!" % current_ward.name)
		var SkillExecP = preload("res://scripts/battle/skill_executor.gd")
		var same_team: Array = ally_wards if current_ward.team == "ally" else enemy_wards
		var alive_allies: Array = battle_resolver.get_alive_wards(same_team).filter(
			func(w): return w != current_ward
		)
		var available_skills: Array = []
		for sk in ["Q", "W", "E"]:
			if current_ward._current_cd.get(sk, 0) == 0:
				var tt: String = SkillExecP.get_skill_target_type(current_ward.ward_id, sk, current_ward)
				if tt == "single_enemy":
					available_skills.append(sk)
		if not available_skills.is_empty() and not alive_allies.is_empty():
			var chosen_sk: String = available_skills[randi() % available_skills.size()]
			var target_ally = alive_allies[randi() % alive_allies.size()]
			battle_log.add_entry("%s застосовує %s проти %s!" % [current_ward.name, chosen_sk, target_ally.name])
			_turn_locked = true
			await battle_resolver.attack(current_ward, target_ally, chosen_sk)
		else:
			battle_log.add_entry("Паразитування: немає доступних скілів або союзників.")
		if battle_resolver.is_team_dead(enemy_wards): _finish_battle("ПЕРЕМОГА"); return
		if battle_resolver.is_team_dead(ally_wards):  _finish_battle("ПОРАЗКА");  return
		_next_turn()
		return

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
		AnimationCode.skill_blocked_animation(_get_skill_button(ward, skill_key))
		return

	# Перевірка КД
	if ward.has_method("is_skill_ready") and not ward.is_skill_ready(skill_key):
		var cd_left: int = ward._current_cd.get(skill_key, 0)
		battle_log.add_entry("Скіл " + skill_key + " на КД ще " + str(cd_left) + " ход.")
		AnimationCode.skill_blocked_animation(_get_skill_button(ward, skill_key))
		return

	# Сьомий E: блок якщо жоден ворог не має 5+ стаків горіння
	if ward.ward_id == "siomyi" and skill_key == "E":
		var has_valid_target: bool = false
		for w in enemy_wards:
			if not w.is_dead and w.get_status("burning") >= 5:
				has_valid_target = true
				break
		if not has_valid_target:
			battle_log.add_entry("Вогонь сьомого: жоден ворог не має мінімум 5 стаків горіння!")
			AnimationCode.skill_blocked_animation(_get_skill_button(ward, skill_key))
			return

	# Рікер W: лише якщо попередній скіл був Q або E
	if ward.ward_id == "riker" and skill_key == "W":
		var last: String = ward.get_meta("riker_last_skill", "") if ward.has_meta("riker_last_skill") else ""
		if last != "Q" and last != "E":
			battle_log.add_entry("Стиль Доломедес: спочатку використайте Q або E!")
			AnimationCode.skill_blocked_animation(_get_skill_button(ward, skill_key))
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
	elif target_type == "single_ally":
		waiting_for_target = true
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
		battle_log.add_entry("Обраний скіл: " + skill_key)
		battle_log.add_entry("Обери союзника (або себе)")
	elif target_type == "single_any":
		waiting_for_target = true
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
		battle_log.add_entry("Обраний скіл: " + skill_key)
		battle_log.add_entry("Обери будь-яку ціль")
	elif target_type == "etesena_w":
		var alive_count: int = battle_resolver.get_alive_wards(enemy_wards).size()
		if alive_count == 0:
			battle_log.add_entry("Немає живих цілей!")
			AnimationCode.skill_blocked_animation(pressed_button)
			return
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
				AnimationCode.skill_blocked_animation(pressed_button)
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
		_clear_taunt_after_attack(selected_attacker)
		# Адонея E: не закінчує хід — гравець обирає Q/W у формі Голема
		if ward.ward_id == "adoneia" and skill_key == "E":
			_adoneia_set_form(ward, true)
			_turn_locked = false
			return
		await _try_zhnets_harvest()
		await _try_adoneia_golem_tick()
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

	# Скіли на союзника (single_ally / single_any)
	if ward.team == "ally" and selected_attacker != null:
		var SkillExecW = preload("res://scripts/battle/skill_executor.gd")
		var w_type = SkillExecW.get_skill_target_type(selected_attacker.ward_id, selected_skill, selected_attacker)
		if w_type == "single_ally" or w_type == "single_any":
			if ward.is_dead: return
			hide_target_arrow()
			waiting_for_target = false
			_turn_locked = true
			await battle_resolver.attack(selected_attacker, ward, selected_skill)
			_apply_and_log_cd(selected_attacker, selected_skill)
			_clear_taunt_after_attack(selected_attacker)
			await _try_zhnets_harvest()
			await _try_adoneia_golem_tick()
			if battle_resolver.is_team_dead(enemy_wards): _finish_battle("ПЕРЕМОГА"); return
			if battle_resolver.is_team_dead(ally_wards):  _finish_battle("ПОРАЗКА"); return
			_next_turn()
			return

	if ward.team != "enemy":
		battle_log.add_entry("Це не ворог")
		return

	# Блок single_ally скілів від вибору ворога (наприклад, Сьомий W)
	if selected_attacker != null:
		var SkillExecBlock = preload("res://scripts/battle/skill_executor.gd")
		var bl_type = SkillExecBlock.get_skill_target_type(selected_attacker.ward_id, selected_skill, selected_attacker)
		if bl_type == "single_ally":
			battle_log.add_entry("Цей скіл застосовується лише на союзника!")
			AnimationCode.skill_blocked_animation(_get_skill_button(selected_attacker, selected_skill))
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

	# Сьомий E: ціль повинна мати мінімум 5 стаків горіння
	if selected_attacker.ward_id == "siomyi" and selected_skill == "E":
		if ward.get_status("burning") < 5:
			battle_log.add_entry("Вогонь сьомого: у %s лише %d стаків горіння (мінімум 5)!" % [ward.name, ward.get_status("burning")])
			AnimationCode.skill_blocked_animation(_get_skill_button(selected_attacker, selected_skill))
			return

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
	_clear_taunt_after_attack(selected_attacker)

	await _try_zhnets_harvest()
	await _try_adoneia_golem_tick()

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
				valid_targets = alive_targets
			target = valid_targets.pick_random()
	elif target_type == "single_ally":
		var alive_allies = battle_resolver.get_alive_wards(enemy_wards)
		target = alive_allies.pick_random() if not alive_allies.is_empty() else enemy_ward
	elif target_type == "single_any":
		# AI: атакує ворога (пріоритет — ті з горінням)
		var burn_targets = alive_targets.filter(func(w): return w.get_status("burning") > 0)
		target = burn_targets.pick_random() if not burn_targets.is_empty() else alive_targets.pick_random()
	elif target_type == "etesena_w":
		# AI Єтесени: W атакує 3 рандомних живих вороги (союзників гравця)
		var w_pool: Array = alive_targets.duplicate()
		w_pool.shuffle()
		enemy_ward.set_meta("etesena_w_targets", w_pool.slice(0, mini(3, w_pool.size())))
		# target залишається null — execute_skill читає з meta

	await battle_resolver.attack(
		enemy_ward,
		target,
		random_skill
	)

	# Застосовуємо КД + логуємо для ворога
	_apply_and_log_cd(enemy_ward, random_skill)
	_clear_taunt_after_attack(enemy_ward)

	# Адонея E (ворог): не закінчує хід — бот одразу вибирає Q/W у формі Голема
	if enemy_ward.ward_id == "adoneia" and random_skill == "E" and not enemy_ward.is_dead:
		_adoneia_set_form(enemy_ward, true)
		var golem_skills: Array = []
		for sk in ["Q", "W"]:
			if enemy_ward.is_skill_ready(sk):
				golem_skills.append(sk)
		if golem_skills.is_empty():
			golem_skills = ["Q"]
		var golem_skill: String = golem_skills.pick_random()
		await battle_resolver.attack(enemy_ward, null, golem_skill)
		_apply_and_log_cd(enemy_ward, golem_skill)
		_clear_taunt_after_attack(enemy_ward)

	if battle_finished:
		return

	await _try_zhnets_harvest()
	await _try_adoneia_golem_tick()

	if battle_resolver.is_team_dead(ally_wards):
		_finish_battle("ПОРАЗКА")
		return

	if battle_resolver.is_team_dead(enemy_wards):
		_finish_battle("ПЕРЕМОГА")
		return

	_next_turn()


func _try_zhnets_harvest() -> void:
	if current_ward == null or current_ward.ward_id != "zhnets": return
	if not current_ward.has_meta("zhnets_e_target"): return
	var harvest_target = current_ward.get_meta("zhnets_e_target")
	current_ward.remove_meta("zhnets_e_target")
	if is_instance_valid(harvest_target) and not harvest_target.is_dead:
		var burn_total_before: int = harvest_target.get_status("burning")
		harvest_target.remove_status("reaping", harvest_target.get_status("reaping"))
		harvest_target._update_status_visuals()
		battle_log.add_entry("Жнива! Жнець атакує %s! Знімає ефект Жнива." % harvest_target.name)
		var burn_dmg: int = harvest_target.activate_all_burning()
		if burn_dmg > 0:
			battle_log.add_entry("Жнива: активує %d стаків горіння — %d вогняної шкоди! Горіння знято." % [burn_total_before, burn_dmg])
			await battle_resolver.deal_damage_with_modifiers(current_ward, harvest_target, burn_dmg, "burning", "fire")
		if is_instance_valid(harvest_target) and not harvest_target.is_dead:
			await battle_resolver.deal_damage_with_modifiers(current_ward, harvest_target, 80, "zhnets_e", "phys")
	else:
		if is_instance_valid(harvest_target):
			harvest_target.remove_status("reaping", harvest_target.get_status("reaping"))
		battle_log.add_entry("Жнива: ціль вже мертва.")


func _adoneia_set_form(ward, is_golem: bool) -> void:
	var portrait_node := ward.get_node_or_null("WardVisual/Portrait") as TextureRect
	if is_golem:
		# Портрет і іконки скілів
		if portrait_node:
			portrait_node.texture = load("res://Основа/char/earth/Adoneya/form_golem.png")
		var q_icon := ward.skill_q.get_node_or_null("Icon") as TextureRect
		if q_icon:
			q_icon.texture = load("res://Основа/char/earth/Adoneya/golem_q.png")
		var w_icon := ward.skill_w.get_node_or_null("Icon") as TextureRect
		if w_icon:
			w_icon.texture = load("res://Основа/char/earth/Adoneya/golem_w.png")
		# Ліва панель — override на golem запис
		ward.set_meta("skill_panel_override", "adoneia_golem")
		# Незалежні КД: зберігаємо звичайні, ставимо голем КД
		ward.set_meta("normal_q_max_cd", ward._max_cd.get("Q", 0))
		ward.set_meta("normal_w_max_cd", ward._max_cd.get("W", 0))
		ward.set_meta("normal_q_cd",     ward._current_cd.get("Q", 0))
		ward.set_meta("normal_w_cd",     ward._current_cd.get("W", 0))
		ward._max_cd["Q"] = 0
		ward._max_cd["W"] = 2
		ward._current_cd["Q"] = 0
		ward._current_cd["W"] = 0
		ward._sync_cd_buttons()
	else:
		var ward_data = WardDatabase.get_data("adoneia")
		# Портрет і іконки скілів
		if portrait_node:
			var base_portrait: String = ward_data.get("portrait", "")
			if base_portrait != "" and ResourceLoader.exists(base_portrait):
				portrait_node.texture = load(base_portrait)
		var skills: Dictionary = ward_data.get("skills", {})
		var q_icon := ward.skill_q.get_node_or_null("Icon") as TextureRect
		if q_icon:
			var p: String = skills.get("Q", {}).get("icon", "")
			if p != "" and ResourceLoader.exists(p):
				q_icon.texture = load(p)
		var w_icon := ward.skill_w.get_node_or_null("Icon") as TextureRect
		if w_icon:
			var p: String = skills.get("W", {}).get("icon", "")
			if p != "" and ResourceLoader.exists(p):
				w_icon.texture = load(p)
		# Ліва панель — скидаємо override
		if ward.has_meta("skill_panel_override"):
			ward.remove_meta("skill_panel_override")
		# Незалежні КД: відновлюємо звичайні
		ward._max_cd["Q"]     = ward.get_meta("normal_q_max_cd", 0)
		ward._max_cd["W"]     = ward.get_meta("normal_w_max_cd", 4)
		ward._current_cd["Q"] = ward.get_meta("normal_q_cd",     0)
		ward._current_cd["W"] = ward.get_meta("normal_w_cd",     0)
		for _key in ["normal_q_max_cd", "normal_w_max_cd", "normal_q_cd", "normal_w_cd"]:
			if ward.has_meta(_key):
				ward.remove_meta(_key)
		ward._sync_cd_buttons()


func _try_adoneia_golem_tick() -> void:
	if current_ward == null or current_ward.ward_id != "adoneia": return
	if not current_ward.has_meta("golem_form"): return
	var turns_left: int = current_ward.get_meta("golem_form") - 1
	if turns_left > 0:
		current_ward.set_meta("golem_form", turns_left)
		if battle_log:
			battle_log.add_entry("Форма Голема (%s): залишився %d хід(и)." % [current_ward.name, turns_left])
		return
	# Форма Голема завершується
	current_ward.remove_meta("golem_form")
	var base_max: int = current_ward.get_meta("golem_base_max_hp", current_ward.max_hp - 100)
	if current_ward.has_meta("golem_base_max_hp"):
		current_ward.remove_meta("golem_base_max_hp")
	var hp_was: int = current_ward.current_hp
	var max_was: int = current_ward.max_hp
	current_ward.max_hp = base_max
	current_ward.current_hp = mini(current_ward.current_hp, base_max)
	if current_ward.get("health") != null:
		current_ward.health.setup(current_ward.max_hp, current_ward.current_hp, current_ward.hp_bar)
	_adoneia_set_form(current_ward, false)
	current_ward.add_status("stun", 2)
	current_ward._update_status_visuals()
	if battle_log:
		battle_log.add_entry("Форма Голема завершена! %s повертається до звичайної форми." % current_ward.name)
		battle_log.add_entry("HP: %d → %d | Макс. HP: %d → %d" % [hp_was, current_ward.current_hp, max_was, current_ward.max_hp])
		battle_log.add_entry("Оглушення: %s на 2 ходи!" % current_ward.name)
		battle_log.add_effect(current_ward.name, current_ward.team, "Оглушення 2 ходи (завершення Голема)")


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
	_clear_taunt_after_attack(selected_attacker)

	await _try_zhnets_harvest()
	await _try_adoneia_golem_tick()

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


# ── Taunt helpers ────────────────────────────────────────────────────────────

func _clear_taunt_after_attack(attacker) -> void:
	if attacker == null: return
	if attacker.taunted_by != "":
		attacker.remove_status("taunt", attacker.get_status("taunt"))
		attacker.taunted_by = ""
		battle_log.add_entry(attacker.name + ": провокацію знято.")

func clear_taunt_on_death(dead_ward) -> void:
	var all_wards: Array = ally_wards + enemy_wards
	for w in all_wards:
		if not w.is_dead and w.taunted_by == dead_ward.ward_id:
			w.remove_status("taunt", w.get_status("taunt"))
			w.taunted_by = ""
			battle_log.add_entry(w.name + ": провокацію знято (провокатор загинув).")



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
