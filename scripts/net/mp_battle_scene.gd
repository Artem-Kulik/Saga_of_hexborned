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
@onready var error_sound: AudioStreamPlayer2D = $error

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
var round_number: int = 0
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

var _turn_timeout_timer: Timer = null
var _turn_tick_timer: Timer = null
var _turn_timer_secs: int = 30

# Блокує нові скіл-кліки під час анімації атаки — запобігає паралельним атакам
var _turn_locked: bool = false

# Стан для W Етесени — вибір цілей у порядку
var _etesena_w_active: bool = false
var _etesena_w_targets: Array = []
var _etesena_w_labels: Array = []
var _etesena_w_required: int = 0

# Клятва рицаря дощу Арная (E Велодія)
var _oath_active: bool = false
var _oath_carrier = null
var _oath_caster_team: String = ""
var _oath_rounds_left: int = 0
var _oath_triggered_this_round: bool = false
var _oath_skip_next_carrier_trigger: bool = false



func _ready() -> void:
	_apply_ward_data()
	_create_battle_systems()
	if NetworkManager.is_multiplayer:
		var hook = preload("res://scripts/net/mp_battle_hook.gd").new()
		hook.name = "MPBattleHook"
		add_child(hook)
	_connect_wards()
	_setup_end_game_overlay()
	_roll_first_turn()
	play_random_track()
	music_player.finished.connect(_on_music_finished)


func _apply_ward_data() -> void:
	if GameState.ally_ward_ids.is_empty():
		return

	# Власні варди
	for i in range(mini(GameState.ally_ward_ids.size(), ally_wards.size())):
		ally_wards[i].setup_ward(GameState.ally_ward_ids[i])

	# Мультиплеєр: ворог — це реальні варди суперника (отримані через мережу)
	if NetworkManager.is_multiplayer:
		for i in range(mini(NetworkManager.opponent_ward_ids.size(), enemy_wards.size())):
			enemy_wards[i].setup_ward(NetworkManager.opponent_ward_ids[i])
		return

	# Офлайн: рандомні вороги з різних стихій
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

	_turn_timeout_timer = Timer.new()
	_turn_timeout_timer.one_shot = true
	_turn_timeout_timer.wait_time = 45.0
	_turn_timeout_timer.timeout.connect(_on_turn_timeout)
	add_child(_turn_timeout_timer)

	_turn_tick_timer = Timer.new()
	_turn_tick_timer.one_shot = false
	_turn_tick_timer.wait_time = 1.0
	_turn_tick_timer.timeout.connect(_on_turn_tick)
	add_child(_turn_tick_timer)

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
	var first_team: String
	if NetworkManager.is_multiplayer:
		# Завжди починає хост ("ally") — однаково для обох гравців, без рандому
		first_team = "ally"
	else:
		first_team = turn_manager.roll_first_team()

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

	battle_log.add_info("⚔ Бій почався!")

	# Фізіта отримує 2 початкових стеки Тяжіння (одноразово на старті)
	for w in ally_wards + enemy_wards:
		if w.ward_id == "fizita" and not w.is_dead:
			w.add_status("gravity", 2)
			w._update_status_visuals()
			battle_log.add_info("Тяжіння: %s отримує 2 початкових стеки" % w.name)

	# Шусіма E: стартує на перезарядці 3
	for w in ally_wards + enemy_wards:
		if w.ward_id == "shusima":
			w._current_cd["E"] = 3
			w._sync_cd_buttons()

	_start_turn()


func _start_turn() -> void:
	if battle_finished:
		return

	# CLIENT ніколи не запускає логіку ходу сам — лише через сигнали від хоста
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
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
	
	# Лічильник раунду: інкремент коли союзники повертаються до першого варда
	if turn_manager.current_team == "ally" and turn_manager.ally_turn_index == 0:
		round_number += 1
		battle_log.update_round(round_number)

	turn_number += 1
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

	battle_log.start_turn(turn_number, current_ward.name, current_ward.team)

	if current_ward.has_meta("untargetable") and current_ward.get_meta("untargetable"):
		current_ward.set_meta("untargetable", false)
		current_ward.modulate.a = 1.0
		battle_log.add_info("Загороджуючий водопад спав — %s знову вразливий." % current_ward.name)

	_update_active_ward_visual()

	# === ТАЙМЕР ХОДУ ===
	_turn_timeout_timer.stop()
	_turn_tick_timer.stop()
	if turn_manager.current_team == "ally":
		_turn_timer_secs = 45
		battle_log.update_timer(_turn_timer_secs)
		_turn_timeout_timer.start(45.0)
		_turn_tick_timer.start(1.0)
	else:
		battle_log.update_timer(-1)

	# === ОБРОБКА ОГЛУШЕННЯ ===
	# Оглушений Вард пропускає хід; хід переходить до наступного Варда ТІЄї ж команди.
	# Жодна команда не може ходити двічі поспіль.
	if current_ward.get_status("stun") > 0:
		battle_log.add_info("⚡ " + current_ward.name + " оглушений — пропускає хід!", Color("#c88020"))
		await get_tree().create_timer(0.6).timeout
		current_ward.remove_status("stun", 1)
		# Провокація спадає разом з оглушенням
		if current_ward.taunted_by != "":
			current_ward.remove_status("taunt", current_ward.get_status("taunt"))
			current_ward.taunted_by = ""
			battle_log.add_info("  Провокація спала — %s не міг атакувати." % current_ward.name, Color("#c88020"))
		if current_ward.has_method("tick_cooldowns"):
			current_ward.tick_cooldowns()
		# Якщо більше немає живих вардів на цій команді — передаємо хід суперникам
		var stunned_team_wards: Array = ally_wards if turn_manager.current_team == "ally" else enemy_wards
		var has_other_alive: bool = false
		for w in stunned_team_wards:
			if w != current_ward and not w.is_dead:
				has_other_alive = true
				break
		if not has_other_alive:
			turn_manager.switch_team()
		_start_turn()
		return

	# === ПАСИВКА ФІЗІТИ: Тяжіння — +2 стаки на початку ходу ===
	if current_ward.ward_id == "fizita" and not current_ward.is_dead:
		var fizita_turns: int = current_ward.get_meta("fizita_gravity_turns", 0)
		var stacks_to_add: int = fizita_turns + 2  # хід 1: +2, хід 2: +3, хід 3: +4…
		var grav_cap: int = 4 + 2 * fizita_turns
		var current_grav: int = current_ward.get_status("gravity")
		var actual_add: int = mini(stacks_to_add, grav_cap - current_grav)
		if actual_add > 0:
			current_ward.add_status("gravity", actual_add)
			current_ward._update_status_visuals()
			battle_log.add_info("Тяжіння: %s +%d стак(и) (разом: %d, макс: %d)" % [
				current_ward.name, actual_add, current_ward.get_status("gravity"), grav_cap
			])
			battle_log.add_effect(current_ward.name, current_ward.team, "Тяжіння +%d (всього: %d)" % [actual_add, current_ward.get_status("gravity")])
		current_ward.set_meta("fizita_gravity_turns", fizita_turns + 1)

	# === ПАСИВКА ШУСІМИ: Розсипання — 90 фіз шкоди собі ===
	if current_ward.ward_id == "shusima" and not current_ward.is_dead:
		battle_log.add_info("💀 Розсипання: %s — 90 фіз шкоди собі!" % current_ward.name, Color("#c84030"))
		battle_log.add_effect(current_ward.name, current_ward.team, "Розсипання (пасивка)")
		await battle_resolver.deal_damage_with_modifiers(current_ward, current_ward, 90, "P", "phys")
		if current_ward.is_dead:
			_next_turn()
			return

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
			battle_log.add_info("🔥 З пилу жару: %s отримує 2 стаки горіння!" % lucky.name, Color("#c86030"))
			battle_log.add_effect(lucky.name, lucky.team, "Горіння +2 стаки (пасивка Сьомого)")

	# === ПАСИВКА АСТЕЇ: Пам'ять — показуємо що скопійовано в E ===
	if current_ward.ward_id == "asteyah" and not current_ward.is_dead:
		if current_ward.has_meta("asteyah_memory"):
			var _mem: Dictionary = current_ward.get_meta("asteyah_memory")
			battle_log.add_info("🧠 Пам'ять: E = [%s] від %s" % [_mem.get("skill_key", "?"), _mem.get("ward_id", "?")])
		else:
			battle_log.add_info("🧠 Пам'ять: E порожня")

	# === ПАСИВКА INFECTED_1: Реген від кількості сяйво-вардів ===
	if current_ward.ward_id in ["infected_1_a", "infected_1_b", "infected_1_c"] and not current_ward.is_dead:
		var own_team: Array = ally_wards if current_ward.team == "ally" else enemy_wards
		var radiance_count: int = 0
		for w in own_team:
			if not w.is_dead and WardDatabase.get_data(w.ward_id).get("element", "") == "light":
				radiance_count += 1
		if radiance_count > 0:
			var heal_amount: int = 50 * radiance_count
			var hp_before: int = current_ward.current_hp
			current_ward.health.heal(heal_amount)
			battle_log.add_heal(current_ward.name, current_ward.team, hp_before, current_ward.current_hp, current_ward.max_hp)
			battle_log.add_info("💫 Зараза: %s +%d HP (×%d сяйво-вардів)." % [current_ward.name, heal_amount, radiance_count], Color("#e0e040"))

	# === ВОГОНЬ СЬОМОГО: шкода всій команді ===
	var fs_stacks: int = current_ward.get_status("fire_seventh")
	if fs_stacks > 0:
		var fs_team: Array = ally_wards if current_ward.team == "ally" else enemy_wards
		battle_log.add_info("🔥 Вогонь сьомого спалахує! %d стак(и) → %d вогняного кожному!" % [fs_stacks, 150 * fs_stacks], Color("#c86030"))
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
		battle_log.add_info("🔥 Горіння: %s отримує %d вогню." % [current_ward.name, burn_dmg], Color("#c86030"))
		await battle_resolver.deal_damage_with_modifiers(null, current_ward, burn_dmg, "burning", "fire")
		if current_ward.is_dead:
			_next_turn()
			return

	# === ТІК ЧУМИ (infected_1 W) ===
	if current_ward.get_status("plague") > 0:
		battle_log.add_info("☠️ Чума: %s отримує 15 сяйво шкоди!" % current_ward.name, Color("#90d060"))
		await battle_resolver.deal_damage_with_modifiers(null, current_ward, 15, "plague", "light")
		current_ward.remove_status("plague", 1)
		current_ward._update_status_visuals()
		if current_ward.is_dead:
			_next_turn()
			return

	# === ТІК КОНТРАТАКИ ===
	if current_ward.get_status("counterattack") > 0:
		current_ward.remove_status("counterattack", 1)
		current_ward._update_status_visuals()
		if current_ward.get_status("counterattack") == 0:
			battle_log.add_info("Контратака (%s): вичерпалась." % current_ward.name)
		else:
			battle_log.add_info("Контратака (%s): ще %d хід(и)." % [current_ward.name, current_ward.get_status("counterattack")])

	# === ТІК ФАЛАНГИ ВЕЛОДІЯ ===
	if current_ward.get_status("phalanx") > 0:
		current_ward.remove_status("phalanx", 1)
		current_ward._update_status_visuals()
		if current_ward.get_status("phalanx") == 0:
			battle_log.add_info("Фаланга (%s): вичерпалась." % current_ward.name)
		else:
			battle_log.add_info("Фаланга (%s): ще %d хід(и)." % [current_ward.name, current_ward.get_status("phalanx")])

	# === ТІК ПАСИВКИ ВЕЛОДІЯ (Захисний рефлекс) ===
	if current_ward.ward_id == "velodiy" and current_ward.has_meta("velodiy_p_cd"):
		var _p_cd: int = current_ward.get_meta("velodiy_p_cd") - 1
		if _p_cd <= 0:
			current_ward.remove_meta("velodiy_p_cd")
			battle_log.add_info("Захисний рефлекс (%s): пасивка знову готова!" % current_ward.name)
		else:
			current_ward.set_meta("velodiy_p_cd", _p_cd)

	# Тікаємо КД на початку кожного ходу персонажа
	if current_ward.has_method("tick_cooldowns"):
		current_ward.tick_cooldowns()

	# === РЕГЕНЕРАЦІЯ ===
	if not current_ward.regen_applications.is_empty():
		var regen_hp: int = current_ward.tick_regen()
		var regen_hp_before: int = current_ward.current_hp
		current_ward.health.heal(regen_hp)
		battle_log.add_heal(current_ward.name, current_ward.team, regen_hp_before, current_ward.current_hp, current_ward.max_hp)
		battle_log.add_info("💚 Реген: %s +%d HP." % [current_ward.name, regen_hp], Color("#40b050"))
		if current_ward.regen_applications.is_empty():
			battle_log.add_info(current_ward.name + ": регенерація завершилась.")

	# Тік кола пекельного вогню та бар'єру
	if current_ward.get_status("fire_circle") > 0:
		current_ward.remove_status("fire_circle", 1)
		if current_ward.get_status("fire_circle") == 0:
			battle_log.add_info(current_ward.name + ": Коло пекельного вогню згасло.")
	if current_ward.get_status("barrier") > 0:
		current_ward.remove_status("barrier", 1)
		if current_ward.get_status("barrier") == 0:
			battle_log.add_info(current_ward.name + ": Бар'єр згас.")

	# === КЛЯТВА РИЦАРЯ ДОЩУ АРНАЯ (E Велодія) ===
	if _oath_active:
		# Передача клятви якщо носій мертвий
		if _oath_carrier != null and _oath_carrier.is_dead:
			_transfer_oath_of_rain()

		# Клятва спрацьовує ЛИШЕ на початку ходу носія
		if _oath_active and current_ward == _oath_carrier and not current_ward.is_dead:
			if _oath_skip_next_carrier_trigger:
				_oath_skip_next_carrier_trigger = false
				_oath_triggered_this_round = false
			else:
				_oath_triggered_this_round = false
				# Хіл ВСІМ водяним союзникам одразу
				var carrier_team_wards: Array = ally_wards if _oath_caster_team == "ally" else enemy_wards
				for _w in carrier_team_wards:
					if not _w.is_dead and WardDatabase.get_data(_w.ward_id).get("element", "") == "water":
						var _ohp: int = _w.current_hp
						_w.health.heal(75)
						battle_log.add_heal(_w.name, _w.team, _ohp, _w.current_hp, _w.max_hp)
						battle_log.add_info("💧 Клятва дощу: %s +75 HP." % _w.name, Color("#4090c0"))
				# Броня носієві: Велодій або Ошая (якщо вкрала Клятву)
				if current_ward.ward_id == "velodiy" or current_ward.ward_id == "ashayah":
					current_ward.health.add_armor(75)
					current_ward._update_status_visuals()
					battle_log.add_info("💧 Клятва дощу: %s +75 броні!" % current_ward.name, Color("#4090c0"))
				_oath_rounds_left -= 1
				_oath_triggered_this_round = true
				_oath_carrier.remove_status("velodiy_oath", _oath_carrier.get_status("velodiy_oath"))
				if _oath_rounds_left > 0:
					_oath_carrier.add_status("velodiy_oath", _oath_rounds_left)
				_oath_carrier._update_status_visuals()
				if _oath_rounds_left <= 0:
					_oath_active = false
					_oath_carrier = null
					battle_log.add_info("Клятва рицаря дощу завершилась!")
				else:
					battle_log.add_info("Клятва дощу: ще %d раунд(и)." % _oath_rounds_left)

	# === ПАРАЗИТУВАННЯ: авто-атака союзника ===
	if current_ward.get_status("parasitism") > 0:
		current_ward.remove_status("parasitism", current_ward.get_status("parasitism"))
		battle_log.add_info("🦠 Паразитування! %s атакує свого союзника!" % current_ward.name, Color("#a060d0"))
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
			battle_log.add_info("%s застосовує %s проти %s!" % [current_ward.name, chosen_sk, target_ally.name], Color("#a060d0"))
			_turn_locked = true
			await battle_resolver.attack(current_ward, target_ally, chosen_sk)
		else:
			battle_log.add_info("Паразитування: немає доступних скілів або союзників.")
		if battle_resolver.is_team_dead(enemy_wards): _finish_battle("ПЕРЕМОГА"); return
		if battle_resolver.is_team_dead(ally_wards):  _finish_battle("ПОРАЗКА");  return
		_next_turn()
		return

	# Всі пасивні ефекти застосовано — синкуємо стан до клієнта
	if NetworkManager.is_multiplayer and NetworkManager.is_host:
		var _st_hook = get_tree().get_first_node_in_group("mp_battle_hook")
		if _st_hook:
			_st_hook._push_state_to_client()
		# Якщо йде хід союзника HOST — показуємо клієнту який ворожий вард пульсує
		if turn_manager.current_team == "ally" and current_ward != null:
			NetworkManager.signal_host_ally_turn(current_ward.name)

	if turn_manager.current_team == "enemy":
		# HOST у мультиплеєрі: "enemy" = клієнтські варди — чекаємо RPC замість AI
		if NetworkManager.is_multiplayer and NetworkManager.is_host:
			var hook = get_tree().get_first_node_in_group("mp_battle_hook")
			if hook:
				hook.host_wait_for_client(current_ward)
				return

		# CLIENT у мультиплеєрі: заблокуємо AI — клієнт лише реагує на сигнали хоста
		if NetworkManager.is_multiplayer and not NetworkManager.is_host:
			return

		await get_tree().create_timer(2.0).timeout

		if battle_finished:
			return

		if current_ward == null or current_ward.is_dead:
			_next_turn()
			return

		await _enemy_attack(current_ward)


func _on_skill_clicked(ward, skill_key: String) -> void:
	if not battle_started:
		return

	if battle_finished:
		return

	if _turn_locked:
		return

	# CLIENT: перевіряємо через hook, а не через локальний turn_manager
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
		var _hk = get_tree().get_first_node_in_group("mp_battle_hook")
		if not _hk or not _hk._client_turn_active:
			battle_log.add_entry("⏳ Не ваш хід")
			AnimationCode.skill_blocked_animation(_get_skill_button(ward, skill_key))
			return
	else:
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

	# Клієнт у мультиплеєрі: no-target скіли одразу надсилаємо хосту
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
		var _SkillExecutorMP = preload("res://scripts/battle/skill_executor.gd")
		var _ttype = _SkillExecutorMP.get_skill_target_type(ward.ward_id, skill_key, ward)
		if _ttype not in ["single_enemy", "single_ally", "single_any", "etesena_w"]:
			_turn_locked = true  # блокуємо до підтвердження від хоста
			var _hook = get_tree().get_first_node_in_group("mp_battle_hook")
			if _hook and _hook.intercept_skill_click(ward, skill_key, null):
				return
			_turn_locked = false  # intercept не відпрацював — скасовуємо блок

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
	elif target_type == "single_ally":
		waiting_for_target = true
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
	elif target_type == "single_any":
		waiting_for_target = true
		if pressed_button:
			AnimationCode.skill_pressed_animation(pressed_button)
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
		_turn_locked = true
		await battle_resolver.attack(selected_attacker, null, selected_skill)
		_apply_and_log_cd(selected_attacker, selected_skill)
		_clear_taunt_after_attack(selected_attacker)
		# Адонея E: не закінчує хід — гравець обирає Q/W у формі Голема
		if ward.ward_id == "adoneia" and skill_key == "E":
			_adoneia_set_form(ward, true)
			_turn_locked = false
			return
		# Астея W: не закінчує хід — гравець обирає Q або E ще раз
		if ward.ward_id == "asteyah" and skill_key == "W":
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

	# CLIENT у мультиплеєрі: надсилаємо ціль хосту замість локального виконання
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
		var _mp_h = get_tree().get_first_node_in_group("mp_battle_hook")
		if _mp_h and selected_attacker != null:
			# Валідуємо тип цілі так само як офлайн (перед відправкою)
			var _SkillExecMP2 = preload("res://scripts/battle/skill_executor.gd")
			var _tt2 = _SkillExecMP2.get_skill_target_type(selected_attacker.ward_id, selected_skill, selected_attacker)
			if _tt2 == "single_ally" and ward.team == "enemy":
				battle_log.add_entry("Цей скіл застосовується лише на союзника!")
				AnimationCode.skill_blocked_animation(_get_skill_button(selected_attacker, selected_skill))
				return
			if _tt2 in ["single_enemy", "etesena_w"] and ward.team == "ally":
				battle_log.add_entry("Це не ворог")
				return
			if ward.is_dead:
				battle_log.add_entry("Ціль вже мертва")
				return
			var _atk_i: int = ally_wards.find(selected_attacker)
			var _tgt_i: int
			if ward.team == "enemy":
				_tgt_i = enemy_wards.find(ward)       # >= 0: ворожий вард хоста
			else:
				_tgt_i = -10 - ally_wards.find(ward)  # <= -10: власний союзник клієнта
			_turn_locked = true  # блокуємо до підтвердження від хоста
			_mp_h._client_turn_active = false
			waiting_for_target = false
			hide_target_arrow()
			NetworkManager.client_send_action(selected_skill, _atk_i, _tgt_i)
			battle_log.add_info("⏳ Очікуємо відповідь від хоста...", Color("#888888"))
		return

	# Скіли на союзника (single_ally / single_any)
	if ward.team == "ally" and selected_attacker != null:
		var SkillExecW = preload("res://scripts/battle/skill_executor.gd")
		var w_type = SkillExecW.get_skill_target_type(selected_attacker.ward_id, selected_skill, selected_attacker)
		if w_type == "single_ally" or w_type == "single_any":
			if ward.is_dead: return
			if ward.has_meta("untargetable") and ward.get_meta("untargetable"):
				battle_log.add_entry("Ця ціль наразі не вразлива!")
				return
			# Фізіта W: не можна застосувати на себе
			if selected_attacker.ward_id == "fizita" and selected_skill == "W" and ward == selected_attacker:
				battle_log.add_entry("Стіна: не можна застосувати на себе!")
				AnimationCode.skill_blocked_animation(_get_skill_button(selected_attacker, selected_skill))
				return
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
		# Фізіта W: не може таргетити себе
		if enemy_ward.ward_id == "fizita" and random_skill == "W":
			alive_allies = alive_allies.filter(func(w): return w != enemy_ward)
		target = alive_allies.pick_random() if not alive_allies.is_empty() else enemy_ward
	elif target_type == "single_any":
		var valid_any = alive_targets.filter(func(w): return not (w.has_meta("untargetable") and w.get_meta("untargetable")))
		if valid_any.is_empty(): valid_any = alive_targets
		var burn_targets = valid_any.filter(func(w): return w.get_status("burning") > 0)
		target = burn_targets.pick_random() if not burn_targets.is_empty() else valid_any.pick_random()
	elif target_type == "etesena_w":
		# AI Єтесени: W атакує 3 рандомних живих вороги (союзників гравця)
		var w_pool: Array = alive_targets.duplicate()
		w_pool.shuffle()
		enemy_ward.set_meta("etesena_w_targets", w_pool.slice(0, mini(3, w_pool.size())))
		# target залишається null — execute_skill читає з meta

	if battle_log:
		var _tname: String = target.name if target != null else "всіх"
		battle_log.add_info("▶ %s [%s] → %s" % [enemy_ward.name, random_skill, _tname], Color("#d06040"))

	await battle_resolver.attack(
		enemy_ward,
		target,
		random_skill
	)

	# Застосовуємо КД + логуємо для ворога
	_apply_and_log_cd(enemy_ward, random_skill)
	_clear_taunt_after_attack(enemy_ward)

	# Астея W (ворог): не закінчує хід — бот одразу обирає Q або E
	if enemy_ward.ward_id == "asteyah" and random_skill == "W" and not enemy_ward.is_dead:
		var bonus_pool: Array = []
		for sk in ["Q", "E"]:
			if enemy_ward.is_skill_ready(sk):
				bonus_pool.append(sk)
		if bonus_pool.is_empty():
			bonus_pool = ["Q"]
		var bonus_sk: String = bonus_pool.pick_random()
		var bonus_tt: String = SkillExecutor.get_skill_target_type(enemy_ward.ward_id, bonus_sk, enemy_ward)
		var bonus_target = null
		if bonus_tt == "single_enemy":
			var valid_b: Array = battle_resolver.get_alive_wards(ally_wards).filter(
				func(w): return not (w.has_meta("untargetable") and w.get_meta("untargetable"))
			)
			if valid_b.is_empty(): valid_b = battle_resolver.get_alive_wards(ally_wards)
			if not valid_b.is_empty():
				bonus_target = valid_b.pick_random()
		await battle_resolver.attack(enemy_ward, bonus_target, bonus_sk)
		_apply_and_log_cd(enemy_ward, bonus_sk)
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
	# Пропускаємо хід коли E щойно використали — запускаємо лише на НАСТУПНОМУ ході
	if current_ward.has_meta("zhnets_e_just_used"):
		current_ward.remove_meta("zhnets_e_just_used")
		return
	var harvest_target = current_ward.get_meta("zhnets_e_target")
	current_ward.remove_meta("zhnets_e_target")
	if is_instance_valid(harvest_target) and not harvest_target.is_dead:
		var burn_total_before: int = harvest_target.get_status("burning")
		harvest_target.remove_status("reaping", harvest_target.get_status("reaping"))
		harvest_target._update_status_visuals()
		battle_log.add_info("🔥 Жнива! Жнець атакує %s!" % harvest_target.name, Color("#c86030"))
		var burn_dmg: int = harvest_target.activate_all_burning()
		if burn_dmg > 0:
			battle_log.add_info("Жнива: %d стаків горіння → %d вогняної шкоди!" % [burn_total_before, burn_dmg], Color("#c86030"))
			await battle_resolver.deal_damage_with_modifiers(current_ward, harvest_target, burn_dmg, "burning", "fire")
		if is_instance_valid(harvest_target) and not harvest_target.is_dead:
			await battle_resolver.deal_damage_with_modifiers(current_ward, harvest_target, 80, "zhnets_e", "phys")
	else:
		if is_instance_valid(harvest_target):
			harvest_target.remove_status("reaping", harvest_target.get_status("reaping"))
		battle_log.add_info("Жнива: ціль вже мертва.")


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
		current_ward._sync_cd_buttons()
		if battle_log:
			battle_log.add_info("⚙ Форма Голема (%s): ще %d хід(и)." % [current_ward.name, turns_left])
		return
	# Форма Голема завершується
	current_ward.remove_meta("golem_form")
	current_ward._current_cd["E"] = max(0, current_ward._max_cd.get("E", 8) - 2)
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
		battle_log.add_info("⚙ Форма Голема завершена! %s повертається + оглушення 2 ходи." % current_ward.name)
		battle_log.add_info("HP: %d → %d | Макс: %d → %d" % [hp_was, current_ward.current_hp, max_was, current_ward.max_hp])
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


func _activate_oath_of_rain(caster) -> void:
	_oath_active = true
	_oath_carrier = caster
	_oath_caster_team = caster.team
	_oath_rounds_left = 4
	_oath_triggered_this_round = false
	_oath_skip_next_carrier_trigger = false
	caster.add_status("velodiy_oath", 4)
	caster._update_status_visuals()


func _steal_oath_as_carrier(new_carrier, rounds: int) -> void:
	# Знімаємо статус зі старого носія якщо є
	if _oath_carrier != null and not _oath_carrier.is_dead:
		_oath_carrier.remove_status("velodiy_oath", _oath_carrier.get_status("velodiy_oath"))
		_oath_carrier._update_status_visuals()
	_oath_active = true
	_oath_carrier = new_carrier
	_oath_caster_team = new_carrier.team  # Клятва тепер служить команді Ашани
	_oath_rounds_left = rounds
	_oath_triggered_this_round = false
	_oath_skip_next_carrier_trigger = true  # Не тригерить у цьому ж ході
	new_carrier.add_status("velodiy_oath", rounds)
	new_carrier._update_status_visuals()
	if battle_log:
		battle_log.add_info("💧 Крилатий трофей: %s перехопила Клятву дощу (%d раунд(и))!" % [new_carrier.name, rounds], Color("#4090c0"))


func _transfer_oath_of_rain() -> void:
	var team_wards: Array = ally_wards if _oath_caster_team == "ally" else enemy_wards
	var candidates: Array = team_wards.filter(
		func(w): return not w.is_dead and WardDatabase.get_data(w.ward_id).get("element", "") == "water" and w != _oath_carrier
	)
	if candidates.is_empty():
		_oath_active = false
		if _oath_carrier != null:
			_oath_carrier.remove_status("velodiy_oath", _oath_carrier.get_status("velodiy_oath"))
			_oath_carrier._update_status_visuals()
		_oath_carrier = null
		battle_log.add_info("💧 Клятва рицаря дощу згасла — немає водяних союзників.", Color("#4090c0"))
		return
	# Знімаємо статус зі старого носія
	var old_carrier = _oath_carrier
	if old_carrier != null:
		old_carrier.remove_status("velodiy_oath", old_carrier.get_status("velodiy_oath"))
		old_carrier._update_status_visuals()
	var new_carrier = candidates.pick_random()
	_oath_skip_next_carrier_trigger = _oath_triggered_this_round
	_oath_carrier = new_carrier
	new_carrier.add_status("velodiy_oath", _oath_rounds_left)
	new_carrier._update_status_visuals()
	battle_log.add_info("💧 Клятва передана → %s (%d раунд(и))." % [new_carrier.name, _oath_rounds_left], Color("#4090c0"))


func _next_turn() -> void:
	if battle_finished:
		return

	_turn_timeout_timer.stop()
	_turn_tick_timer.stop()
	battle_log.update_timer(-1)

	hide_target_arrow()

	turn_manager.switch_team()

	# Хост: пушимо стан ПЕРЕД сигналом щоб клієнт бачив HP/ефекти одразу
	if NetworkManager.is_multiplayer and NetworkManager.is_host:
		var _nt_hook = get_tree().get_first_node_in_group("mp_battle_hook")
		if _nt_hook:
			_nt_hook._push_state_to_client()
		NetworkManager.signal_host_turn_done(current_ward.name if current_ward else "")

	_start_turn()


func _on_turn_tick() -> void:
	_turn_timer_secs = max(0, _turn_timer_secs - 1)
	battle_log.update_timer(_turn_timer_secs)


func _on_turn_timeout() -> void:
	if battle_finished or current_ward == null or current_ward.is_dead:
		return
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
		# Клієнт: перевіряємо через хук — turn_manager може бути не синхронізований
		var _hk_t = get_tree().get_first_node_in_group("mp_battle_hook")
		if not _hk_t or not _hk_t._client_turn_active:
			return
	else:
		if turn_manager.current_team != "ally":
			return
	_turn_tick_timer.stop()
	battle_log.update_timer(0)
	waiting_for_target = false
	selected_skill = ""
	selected_attacker = null
	battle_log.add_info("⏱ Час вийшов! Автоматичне Q: %s" % current_ward.name, Color("#c88020"))
	var valid := _get_auto_q_targets()
	if valid.is_empty():
		_next_turn()
		return
	var auto_target = valid[randi() % valid.size()]
	_turn_locked = true
	await battle_resolver.attack(current_ward, auto_target, "Q")
	await _try_zhnets_harvest()
	await _try_adoneia_golem_tick()
	_turn_locked = false
	_next_turn()


func _get_auto_q_targets() -> Array:
	var all_enemies: Array = battle_resolver.get_alive_wards(enemy_wards)
	var valid: Array = all_enemies.filter(func(w): return not (w.has_meta("untargetable") and w.get_meta("untargetable")))
	if valid.is_empty():
		valid = all_enemies
	if current_ward.has_meta("taunted_by"):
		var tb: String = current_ward.get_meta("taunted_by", "")
		if tb != "":
			var taunters: Array = valid.filter(func(w): return w.ward_id == tb)
			if not taunters.is_empty():
				return taunters
	return valid


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


func play_error_sound():
	error_sound.stop()
	error_sound.play()
	
	
	
## Застосовує КД і логує його, якщо КД > 0
func _apply_and_log_cd(ward, skill_key: String) -> void:
	if ward == null:
		return
	if not ward.has_method("apply_skill_cooldown"):
		return

	ward.apply_skill_cooldown(skill_key)
