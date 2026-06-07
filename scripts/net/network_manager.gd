extends Node

# ─── Signals ───────────────────────────────────────────────────────────────
signal peer_connected
signal peer_disconnected
signal connection_failed
signal opponent_wards_ready          # обидва підтвердили варди
signal host_turn_started(ward_name: String)
signal host_ally_turn_active(ward_name: String)
signal client_turn_started(ward_name: String)
signal state_updated(state: Dictionary)
signal log_action_received(data: Dictionary)
signal battle_ended(result: String)
signal restart_requested             # хост попросив рестарт
signal ward_select_requested         # хост повернувся на вибір вардів
signal adoneia_golem_signal(ward_idx: int, is_golem: bool)

# ─── State ─────────────────────────────────────────────────────────────────
const PORT := 7777
const MAX_CLIENTS := 1

var is_multiplayer: bool = false
var is_host:        bool = false
var _client_peer_id: int = 0         # реальний ID клієнта (не завжди = 2)

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
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	return OK

func join_game(ip: String) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_multiplayer = true
	is_host = false
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed_cb):
		multiplayer.connection_failed.connect(_on_connection_failed_cb)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	return OK

func reset_ward_selection() -> void:
	_my_wards_sent = false
	_opp_wards_got = false
	my_ward_ids.clear()
	opponent_ward_ids.clear()

func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_multiplayer = false
	is_host = false
	_client_peer_id = 0
	_my_wards_sent = false
	_opp_wards_got = false
	my_ward_ids.clear()
	opponent_ward_ids.clear()

func get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		if addr.contains(":"):
			continue
		if addr.begins_with("127."):
			continue
		return addr
	return "127.0.0.1"

# ─── Ward selection sync ───────────────────────────────────────────────────
func send_my_wards(ward_ids: Array) -> void:
	my_ward_ids = ward_ids.duplicate()
	_my_wards_sent = true
	var target_id := _client_peer_id if is_host else 1
	if target_id > 0:
		_rpc_receive_wards.rpc_id(target_id, ward_ids)
	_check_both_wards_ready()

@rpc("any_peer", "call_remote", "reliable")
func _rpc_receive_wards(ward_ids: Array) -> void:
	opponent_ward_ids = ward_ids.duplicate()
	_opp_wards_got = true
	_check_both_wards_ready()

func resend_wards_rpc() -> void:
	if my_ward_ids.is_empty(): return
	var target_id := _client_peer_id if is_host else 1
	if target_id > 0:
		_rpc_receive_wards.rpc_id(target_id, my_ward_ids)

func _check_both_wards_ready() -> void:
	if _my_wards_sent and _opp_wards_got:
		opponent_wards_ready.emit()

# ─── Утиліта: клієнт підключений ──────────────────────────────────────────
func _client_connected() -> bool:
	return is_host and _client_peer_id > 0 and _client_peer_id in multiplayer.get_peers()

# ─── Battle: host → client state sync ─────────────────────────────────────
func broadcast_state(state: Dictionary) -> void:
	if not _client_connected(): return
	_rpc_apply_state.rpc_id(_client_peer_id, state)

@rpc("authority", "call_remote", "reliable")
func _rpc_apply_state(state: Dictionary) -> void:
	state_updated.emit(state)

# ─── Battle: host signals turns ────────────────────────────────────────────
func signal_client_turn(ward_name: String) -> void:
	if not _client_connected(): return
	_rpc_client_turn.rpc_id(_client_peer_id, ward_name)

@rpc("authority", "call_remote", "reliable")
func _rpc_client_turn(ward_name: String) -> void:
	client_turn_started.emit(ward_name)

func signal_host_turn_done(ward_name: String) -> void:
	if not _client_connected(): return
	_rpc_host_turn_done.rpc_id(_client_peer_id, ward_name)

@rpc("authority", "call_remote", "reliable")
func _rpc_host_turn_done(ward_name: String) -> void:
	host_turn_started.emit(ward_name)

func signal_host_ally_turn(ward_name: String) -> void:
	if not _client_connected(): return
	_rpc_host_ally_turn.rpc_id(_client_peer_id, ward_name)

@rpc("authority", "call_remote", "reliable")
func _rpc_host_ally_turn(ward_name: String) -> void:
	host_ally_turn_active.emit(ward_name)

# ─── Battle: client → host action ─────────────────────────────────────────
func client_send_action(skill_key: String, attacker_idx: int, target_idx: int) -> void:
	_rpc_client_action.rpc_id(1, skill_key, attacker_idx, target_idx)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_action(skill_key: String, attacker_idx: int, target_idx: int) -> void:
	var hook = get_tree().get_first_node_in_group("mp_battle_hook")
	if hook:
		hook.on_client_action_received(skill_key, attacker_idx, target_idx)

func client_send_etesena_w(attacker_idx: int, target_indices: Array) -> void:
	_rpc_client_etesena_w.rpc_id(1, attacker_idx, target_indices)

@rpc("any_peer", "call_remote", "reliable")
func _rpc_client_etesena_w(attacker_idx: int, target_indices: Array) -> void:
	var hook = get_tree().get_first_node_in_group("mp_battle_hook")
	if hook:
		hook.on_client_etesena_w_received(attacker_idx, target_indices)

# ─── Host: sync navigation ────────────────────────────────────────────────
func broadcast_restart() -> void:
	if not _client_connected(): return
	_rpc_do_restart.rpc_id(_client_peer_id)

@rpc("authority", "call_remote", "reliable")
func _rpc_do_restart() -> void:
	restart_requested.emit()

func broadcast_go_ward_select() -> void:
	if not _client_connected(): return
	_rpc_do_ward_select.rpc_id(_client_peer_id)

@rpc("authority", "call_remote", "reliable")
func _rpc_do_ward_select() -> void:
	ward_select_requested.emit()

# ─── Battle: Adoneia golem form sync ──────────────────────────────────────
func signal_adoneia_golem(ward_idx: int, is_golem: bool) -> void:
	if not _client_connected(): return
	_rpc_adoneia_golem.rpc_id(_client_peer_id, ward_idx, is_golem)

@rpc("authority", "call_remote", "reliable")
func _rpc_adoneia_golem(ward_idx: int, is_golem: bool) -> void:
	adoneia_golem_signal.emit(ward_idx, is_golem)

# ─── Battle: log sync ─────────────────────────────────────────────────────
func broadcast_log_action(data: Dictionary) -> void:
	if not _client_connected(): return
	_rpc_apply_log.rpc_id(_client_peer_id, data)

@rpc("authority", "call_remote", "reliable")
func _rpc_apply_log(data: Dictionary) -> void:
	log_action_received.emit(data)

# ─── Battle: end game ──────────────────────────────────────────────────────
func broadcast_battle_end(result: String) -> void:
	if not _client_connected(): return
	_rpc_battle_end.rpc_id(_client_peer_id, result)

@rpc("authority", "call_remote", "reliable")
func _rpc_battle_end(result: String) -> void:
	battle_ended.emit(result)

# ─── Connection callbacks ──────────────────────────────────────────────────
func _on_peer_connected(id: int) -> void:
	_client_peer_id = id
	peer_connected.emit()

func _on_peer_disconnected(id: int) -> void:
	if _client_peer_id == id:
		_client_peer_id = 0
	peer_disconnected.emit()

func _on_connected_to_server() -> void:
	peer_connected.emit()

func _on_connection_failed_cb() -> void:
	is_multiplayer = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	disconnect_game()
	peer_disconnected.emit()
