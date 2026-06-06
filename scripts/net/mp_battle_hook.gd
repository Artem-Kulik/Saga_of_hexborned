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
	await battle._try_zhnets_harvest()
	await battle._try_adoneia_golem_tick()
	battle._turn_locked = false

	# Синкуємо стан до клієнта
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
	if battle.battle_log:
		battle.battle_log.add_info("⚔️ Ваш хід: " + ward_name + ". Оберіть скіл.", Color("#40b8e0"))

# ─── CLIENT: хост закінчив свій хід (отримали сигнал) ──────────────────────
func _on_host_turn_done_for_client(_ward_name: String) -> void:
	_client_turn_active = false
	if not battle.battle_finished:
		battle._next_turn()

# ─── CLIENT: перехоплення кліку скіла ──────────────────────────────────────
## Повертає true якщо дію перехоплено (не треба виконувати локально)
func intercept_skill_click(ward, skill_key: String, target_ward) -> bool:
	if not NetworkManager.is_multiplayer or NetworkManager.is_host:
		return false
	if not _client_turn_active:
		return false

	var attacker_idx := _find_ward_index(battle.ally_wards, ward)
	var target_idx := -1
	if target_ward != null:
		target_idx = _find_ward_index(battle.enemy_wards, target_ward)

	if attacker_idx < 0:
		return false

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

		# HP
		var new_hp: int = st.get("hp", w.current_hp)
		if new_hp != w.current_hp:
			w.health.heal(new_hp - w.current_hp) if new_hp > w.current_hp else w.health.take_damage(w.current_hp - new_hp)

		# Death
		w.is_dead = st.get("is_dead", w.is_dead)
		if w.is_dead and not w.has_meta("death_handled"):
			w.set_meta("death_handled", true)
			w.visible = false

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

# ─── End game від хоста ─────────────────────────────────────────────────────
func _on_battle_ended_from_host(result: String) -> void:
	if NetworkManager.is_host: return
	if result == "ПЕРЕМОГА":
		battle.show_victory_screen()
	else:
		battle.show_defeat_screen()
