## Додається як дочірній вузол до battle_scene у мультиплеєрному режимі.
## Хост: перехоплює enemy-хід, чекає RPC від клієнта, виконує, синкає стан.
## Клієнт: перехоплює skill-кліки, надсилає RPC хосту, застосовує state updates.
extends Node

var battle: Node  # посилання на battle_scene

# Клієнт чекає на хід
var _client_turn_active: bool = false
var _client_pending_skill: String = ""
var _client_pending_target_idx: int = -1

# Хост чекає RPC від клієнта
var _host_waiting_client: bool = false

func _ready() -> void:
	battle = get_parent()
	add_to_group("mp_battle_hook")

	NetworkManager.state_updated.connect(_on_state_updated)
	NetworkManager.client_turn_started.connect(_on_client_turn_started)
	NetworkManager.host_turn_started.connect(_on_host_turn_done_for_client)
	NetworkManager.battle_ended.connect(_on_battle_ended_from_host)
	NetworkManager.peer_disconnected.connect(_on_peer_disconnected)

	if NetworkManager.is_host:
		battle.battle_log.log_action.connect(_on_log_action_from_battle)
	else:
		NetworkManager.log_action_received.connect(_apply_log_action)
		NetworkManager.host_ally_turn_active.connect(_on_host_ally_turn_active)
		NetworkManager.adoneia_golem_signal.connect(_on_adoneia_golem)

# ─── HOST: клієнт надіслав дію ─────────────────────────────────────────────
func on_client_action_received(skill_key: String, attacker_idx: int, target_idx: int) -> void:
	if not NetworkManager.is_host: return
	_host_waiting_client = false

	var enemy_wards: Array = battle.enemy_wards
	var ally_wards:  Array = battle.ally_wards

	if attacker_idx < 0 or attacker_idx >= enemy_wards.size():
		return
	var attacker = enemy_wards[attacker_idx]
	if attacker == null or attacker.is_dead:
		battle._next_turn()
		return

	var target = null
	if target_idx >= 0 and target_idx < ally_wards.size():
		target = ally_wards[target_idx]   # HOST's ward (ворог для клієнта)
	elif target_idx <= -10:
		var _ai := -(target_idx + 10)
		if _ai >= 0 and _ai < enemy_wards.size():
			target = enemy_wards[_ai]     # CLIENT's own ward (союзник для клієнта)

	# Виконуємо скіл як ворожу атаку
	battle._turn_locked = true
	await battle.battle_resolver.attack(attacker, target, skill_key)
	battle._apply_and_log_cd(attacker, skill_key)
	battle._clear_taunt_after_attack(attacker)
	battle._turn_locked = false

	# Адонея E: встановлюємо форму Голема та повертаємо хід клієнту
	if attacker.ward_id == "adoneia" and skill_key == "E" and not attacker.is_dead:
		battle._adoneia_set_form(attacker, true)
		# golem-сигнал надходить ДО state push — клієнт зберігає в мету оригінальні max_cd
		NetworkManager.signal_adoneia_golem(attacker_idx, true)
		_push_state_to_client()
		NetworkManager.signal_client_turn(attacker.name)
		return

	# Астея W: self-buff, не закінчує хід — повертаємо хід клієнту
	if attacker.ward_id == "asteyah" and skill_key == "W" and not attacker.is_dead:
		_push_state_to_client()
		NetworkManager.signal_client_turn(attacker.name)
		return

	await battle._try_zhnets_harvest()

	# Відстежуємо чи завершилась форма Голема після цього ходу
	var _golem_was: bool = attacker.ward_id == "adoneia" and attacker.has_meta("golem_form")
	await battle._try_adoneia_golem_tick()
	var _golem_ended: bool = _golem_was and not attacker.has_meta("golem_form")

	if _golem_ended:
		NetworkManager.signal_adoneia_golem(attacker_idx, false)

	_push_state_to_client()

	if battle.battle_resolver.is_team_dead(enemy_wards):
		battle._finish_battle("ПЕРЕМОГА")
		NetworkManager.broadcast_battle_end("ПОРАЗКА")  # клієнт програв
		return
	if battle.battle_resolver.is_team_dead(ally_wards):
		battle._finish_battle("ПОРАЗКА")
		NetworkManager.broadcast_battle_end("ПЕРЕМОГА")  # клієнт виграв
		return

	battle._next_turn()

# ─── HOST: очікуємо дії клієнта (викликається з battle_scene) ──────────────
func host_wait_for_client(current_ward) -> void:
	_host_waiting_client = true
	var ward_name: String = current_ward.name if current_ward else "?"
	NetworkManager.signal_client_turn(ward_name)

# ─── CLIENT: отримали сигнал "ваш хід" ─────────────────────────────────────
func _on_client_turn_started(ward_name: String) -> void:
	_client_turn_active = true
	# Знаходимо правильний вард серед союзників клієнта і підсвічуємо його
	for w in battle.ally_wards:
		if w.name == ward_name and not w.is_dead:
			battle.current_ward = w
			battle._update_active_ward_visual()
			break
	if battle.battle_log:
		battle.battle_log.add_info("⚔️ Ваш хід: " + ward_name + ". Оберіть скіл.", Color("#40b8e0"))

# ─── CLIENT: хост почав ХІД СВОГО варда ────────────────────────────────────
func _on_host_ally_turn_active(ward_name: String) -> void:
	_client_turn_active = false
	if battle.battle_finished:
		return
	for w in battle.enemy_wards:
		if w.name == ward_name and not w.is_dead:
			battle.current_ward = w
			battle._update_active_ward_visual()
			break

# ─── CLIENT: Адонея змінює форму ────────────────────────────────────────────
func _on_adoneia_golem(ward_idx: int, is_golem: bool) -> void:
	if ward_idx >= 0 and ward_idx < battle.ally_wards.size():
		var ward = battle.ally_wards[ward_idx]
		if ward and not ward.is_dead:
			battle._adoneia_set_form(ward, is_golem)

# ─── CLIENT: хост закінчив свій хід (отримали сигнал) ──────────────────────
func _on_host_turn_done_for_client(_ward_name: String) -> void:
	_client_turn_active = false
	if battle.battle_finished:
		return
	# Знімаємо підсвітку — чекаємо наступного сигналу
	battle.current_ward = null
	battle._update_active_ward_visual()

# ─── CLIENT: перехоплення кліку скіла ──────────────────────────────────────
## Повертає true якщо дію перехоплено (не треба виконувати локально)
func intercept_skill_click(ward, skill_key: String, target_ward) -> bool:
	if not NetworkManager.is_multiplayer or NetworkManager.is_host:
		return false
	if not _client_turn_active:
		return false

	var attacker_idx := _find_ward_index(battle.ally_wards, ward)
	if attacker_idx < 0:
		return false

	var target_idx := -1
	if target_ward != null:
		# Спочатку шукаємо серед ворогів (позитивний індекс)
		var ei := _find_ward_index(battle.enemy_wards, target_ward)
		if ei >= 0:
			target_idx = ei
		else:
			# Союзник клієнта — негативне кодування: -(ally_idx + 10)
			var ai := _find_ward_index(battle.ally_wards, target_ward)
			if ai >= 0:
				target_idx = -(ai + 10)
			else:
				# Ціль не знайдена — повертаємо без відправки
				return true  # intercept = true, але без відправки = повторна спроба

	NetworkManager.client_send_action(skill_key, attacker_idx, target_idx)
	_client_turn_active = false

	# Блокуємо UI поки хост не надішле стан
	battle._turn_locked = true
	if battle.battle_log:
		battle.battle_log.add_info("⏳ Очікуємо відповідь від хоста...", Color("#888888"))
	return true

# ─── Sync: застосовуємо стан від хоста ─────────────────────────────────────
func _on_state_updated(state: Dictionary) -> void:
	if NetworkManager.is_host: return

	# На клієнті: ally = мої варди, enemy = варди хоста
	# Хост надсилає: "ally" = його варди, "enemy" = мої варди
	# Тому клієнт застосовує "enemy" до своїх ally і "ally" до своїх enemy
	_apply_ward_states(battle.ally_wards, state.get("enemy", []))
	_apply_ward_states(battle.enemy_wards, state.get("ally", []))

	battle._turn_locked = false

func _apply_ward_states(wards: Array, states: Array) -> void:
	for i in range(mini(wards.size(), states.size())):
		var w  = wards[i]
		var st: Dictionary = states[i]
		if w == null: continue

		# Death — обробляємо ПЕРШИМ до будь-яких HP змін
		var now_dead: bool = st.get("is_dead", false)
		if now_dead and not w.is_dead and not w.has_meta("death_handled"):
			w.set_meta("death_handled", true)
			# Встановлюємо ward_health в dead-стан ПЕРШ ніж die() — щоб die() не re-trigger
			w.health.current_hp = 0
			w.health.is_dead = true
			if w.health.hp_bar and w.health.hp_bar.has_method("set_hp"):
				w.health.hp_bar.set_hp(0, true)
			w.health.hp_changed.emit(0, w.health.max_hp)
			# ward_slot.is_dead ще false — die() запуститься з анімацією
			if w.has_method("die"):
				w.die()
			continue  # мертвий вард — пропускаємо решту

		if w.is_dead:
			continue  # вже мертвий — нічого не змінюємо

		# HP (тільки для живих вардів; прямий set щоб обійти броню)
		var new_hp: int = st.get("hp", w.current_hp)
		if new_hp != w.current_hp:
			if new_hp > w.current_hp:
				w.health.heal(new_hp - w.current_hp)
			else:
				w.health.current_hp = new_hp
				if w.health.hp_bar and w.health.hp_bar.has_method("set_hp"):
					w.health.hp_bar.set_hp(new_hp, false)
				w.health.hp_changed.emit(new_hp, w.health.max_hp)

		# Статуси (burning, stun, armor, regen тощо)
		w.status_effects       = st.get("status_effects", {}).duplicate()
		w.burning_applications = st.get("burning_applications", []).duplicate(true)
		w.regen_applications   = st.get("regen_applications", []).duplicate(true)
		if w.has_method("_sync_burning_to_status"):
			w._sync_burning_to_status()
		if w.has_method("_update_status_visuals"):
			w._update_status_visuals()

		# Кулдауни скілів
		var synced_cd: Dictionary = st.get("cd", {})
		if not synced_cd.is_empty():
			w._current_cd = synced_cd.duplicate()
		var synced_max_cd: Dictionary = st.get("max_cd", {})
		if not synced_max_cd.is_empty():
			w._max_cd = synced_max_cd.duplicate()
			if w.has_method("_sync_cd_buttons"):
				w._sync_cd_buttons()

		# Провокація (taunt)
		w.taunted_by = st.get("taunted_by", "")

# ─── HOST: серіалізуємо та надсилаємо стан ─────────────────────────────────
func _push_state_to_client() -> void:
	var state := {
		"ally":  _serialize_wards(battle.ally_wards),
		"enemy": _serialize_wards(battle.enemy_wards),
	}
	NetworkManager.broadcast_state(state)

func _serialize_wards(wards: Array) -> Array:
	var result := []
	for w in wards:
		result.append({
			"hp":                   w.current_hp,
			"max_hp":               w.max_hp,
			"is_dead":              w.is_dead,
			"status_effects":       w.status_effects.duplicate(),
			"burning_applications": w.burning_applications.duplicate(true),
			"regen_applications":   w.regen_applications.duplicate(true),
			"cd":                   w._current_cd.duplicate(),
			"max_cd":               w._max_cd.duplicate(),
			"taunted_by":           w.taunted_by,
		})
	return result

# ─── Утиліти ────────────────────────────────────────────────────────────────
func _find_ward_index(wards: Array, ward) -> int:
	for i in range(wards.size()):
		if wards[i] == ward:
			return i
	return -1

# ─── Disconnect ─────────────────────────────────────────────────────────────
func _on_peer_disconnected() -> void:
	if battle.battle_finished:
		return
	if battle.battle_log:
		battle.battle_log.add_info("❌ Суперник відключився!", Color("#ff4040"))
	battle._finish_battle("ПОРАЗКА")

# ─── Log sync: HOST → CLIENT ─────────────────────────────────────────────────
func _on_log_action_from_battle(data: Dictionary) -> void:
	NetworkManager.broadcast_log_action(data)

func _apply_log_action(data: Dictionary) -> void:
	var log = battle.battle_log
	match data.get("t", ""):
		"turn":
			log.start_turn(data["n"], data.get("wn", ""), _flip(data.get("wt", "")))
		"info":
			var col := Color("#" + data["c"]) if data.has("c") else Color("#a09070")
			log.add_info(data["tx"], col)
		"atk":
			log.add_attack(data["an"], _flip(data["at"]), data["sn"], data["d"], data["st"],
				data["tn"], _flip(data["tt"]), data["hb"], data["ha"], data["mh"],
				data.get("ds", "skill"), data.get("bd", 0), data.get("m", 1.0))
		"eff":
			log.add_effect(data["tn"], _flip(data["tt"]), data["et"])
		"heal":
			log.add_heal(data["wn"], _flip(data["wt"]), data["hb"], data["ha"], data["mh"])
		"die":
			log.add_death(data["wn"], _flip(data["wt"]))
		"round":
			log.update_round(data["n"])

func _flip(team: String) -> String:
	return "enemy" if team == "ally" else "ally"

# ─── End game від хоста ─────────────────────────────────────────────────────
func _on_battle_ended_from_host(result: String) -> void:
	if NetworkManager.is_host: return
	if result == "ПЕРЕМОГА":
		battle.show_victory_screen()
	else:
		battle.show_defeat_screen()
