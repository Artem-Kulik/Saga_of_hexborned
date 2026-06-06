extends Node

# ─── Signals ───────────────────────────────────────────────────────────────
signal peer_connected
signal peer_disconnected
signal connection_failed
signal opponent_wards_ready          # обидва підтвердили варди
signal host_turn_started(ward_name: String)
signal client_turn_started(ward_name: String)
signal state_updated(state: Dictionary)
signal battle_ended(result: String)
signal restart_requested             # хост попросив рестарт
signal ward_select_requested         # хост повернувся на вибір вардів

# ─── State ─────────────────────────────────────────────────────────────────
const PORT := 7777
const MAX_CLIENTS := 1

var is_multiplayer: bool = false
var is_host:        bool = false

var my_ward_ids:        Array = []
var opponent_ward_ids:  Array = []
var _my_wards_sent:     bool  = false
var _opp_wards_got:     bool  = false

# ─── Connection ────────────────────────────────────────────────────────────
func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	is_host = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[NET] Сервер запущено на порту ", PORT)
	return OK

func join_game(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	is_host = false
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed_cb)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("[NET] Підключаємося до ", ip, ":", PORT)
	return OK

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_multiplayer = false
	is_host = false
	_my_wards_sent = false
	_opp_wards_got = false
	my_ward_ids.clear()
	opponent_ward_ids.clear()

func get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	return "127.0.0.1"

# ─── Ward selection sync ───────────────────────────────────────────────────
func send_my_wards(ward_ids: Array) -> void:
	my_ward_ids = ward_ids.duplicate()
	_my_wards_sent = true
	# Надсилаємо супернику
	if is_host:
		_rpc_receive_wards.rpc_id(2, ward_ids)
	else:
		_rpc_receive_wards.rpc_id(1, ward_ids)
	_check_both_wards_ready()

@rpc("any_peer", "call_remote", "reliable")
func _rpc_receive_wards(ward_ids: Array) -> void:
	opponent_ward_ids = ward_ids.duplicate()
	_opp_wards_got = true
	print("[NET] Отримано варди суперника: ", opponent_ward_ids)
	_check_both_wards_ready()

func _check_both_wards_ready() -> void:
	if _my_wards_sent and _opp_wards_got:
		opponent_wards_ready.emit()

# ─── Battle: host → client state sync ─────────────────────────────────────
func broadcast_state(state: Dictionary) -> void:
	if not is_host: return
	_rpc_apply_state.rpc_id(2, state)

@rpc("authority", "call_remote", "reliable")
func _rpc_apply_state(state: Dictionary) -> void:
	state_updated.emit(state)

# ─── Battle: host signals turns ────────────────────────────────────────────
func signal_client_turn(ward_name: String) -> void:
	if not is_host: return
	_rpc_client_turn.rpc_id(2, ward_name)

@rpc("authority", "call_remote", "reliable")
func _rpc_client_turn(ward_name: String) -> void:
	client_turn_started.emit(ward_name)

func signal_host_turn_done(ward_name: String) -> void:
	if not is_host: return
	_rpc_host_turn_done.rpc_id(2, ward_name)

@rpc("authority", "call_remote", "reliable")
func _rpc_host_turn_done(ward_name: String) -> void:
	host_turn_started.emit(ward_name)

# ─── Battle: client → host action ─────────────────────────────────────────
func client_send_action(skill_key: String, attacker_idx: int, target_idx: int) -> void:
	_rpc_client_action.rpc_id(1, skill_key, attacker_idx, target_idx)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_action(skill_key: String, attacker_idx: int, target_idx: int) -> void:
	var hook = get_tree().get_first_node_in_group("mp_battle_hook")
	if hook:
		hook.on_client_action_received(skill_key, attacker_idx, target_idx)

# ─── Host: sync navigation ────────────────────────────────────────────────
func broadcast_restart() -> void:
	if not is_host: return
	_rpc_do_restart.rpc_id(2)

@rpc("authority", "call_remote", "reliable")
func _rpc_do_restart() -> void:
	restart_requested.emit()

func broadcast_go_ward_select() -> void:
	if not is_host: return
	_rpc_do_ward_select.rpc_id(2)

@rpc("authority", "call_remote", "reliable")
func _rpc_do_ward_select() -> void:
	ward_select_requested.emit()

# ─── Battle: end game ──────────────────────────────────────────────────────
func broadcast_battle_end(result: String) -> void:
	if not is_host: return
	_rpc_battle_end.rpc_id(2, result)

@rpc("authority", "call_remote", "reliable")
func _rpc_battle_end(result: String) -> void:
	battle_ended.emit(result)

# ─── Connection callbacks ──────────────────────────────────────────────────
func _on_peer_connected(id: int) -> void:
	print("[NET] Peer підключився id=", id)
	peer_connected.emit()

func _on_peer_disconnected(id: int) -> void:
	print("[NET] Peer відключився id=", id)
	peer_disconnected.emit()

func _on_connected_to_server() -> void:
	print("[NET] Підключено до сервера")
	peer_connected.emit()

func _on_connection_failed_cb() -> void:
	print("[NET] Підключення не вдалося")
	is_multiplayer = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("[NET] Сервер відключився")
	disconnect_game()
	peer_disconnected.emit()
