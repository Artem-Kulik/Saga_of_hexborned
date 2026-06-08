## Autoload for MP bot stress-test mode.
## Activated via CLI args: --bot-host [n_battles]  or  --bot-client [host_ip]
extends Node

# ─── Config ─────────────────────────────────────────────────────────────────
var enabled:     bool   = false
var is_host:     bool   = false
var host_ip:     String = "127.0.0.1"
var max_battles: int    = 50

# ─── Runtime state ───────────────────────────────────────────────────────────
var battle_count: int = 0
var turn_count:   int = 0

# ─── Log storage ─────────────────────────────────────────────────────────────
var _errors:         Array[String] = []
var _battle_results: Array[String] = []
var _skill_stats:    Dictionary    = {}  # key → {ok, fail, reasons}
var _battle_log:     Array[String] = []

func _ready() -> void:
	var args: Array = OS.get_cmdline_user_args()
	for i in range(args.size()):
		match args[i]:
			"--bot-host":
				enabled = true
				is_host = true
				if i + 1 < args.size() and args[i + 1].is_valid_int():
					max_battles = args[i + 1].to_int()
			"--bot-client":
				enabled = true
				is_host = false
				if i + 1 < args.size() and not args[i + 1].begins_with("-"):
					host_ip = args[i + 1]
	if not enabled:
		return
	Engine.time_scale = 6.0
	msg("[BOT_INIT] role=%s max_battles=%d ip=%s" % [_role(), max_battles, host_ip])
	call_deferred("_navigate_to_lobby")

func _navigate_to_lobby() -> void:
	await get_tree().process_frame
	SceneLoader.change_scene("res://scripts/net/mp_lobby.tscn")

# ─── Logging ─────────────────────────────────────────────────────────────────
func _role() -> String:
	return "HOST" if is_host else "CLIENT"

func msg(text: String) -> void:
	var ts: int = Time.get_ticks_msec()
	var line: String = "[%07d][%s] %s" % [ts, _role(), text]
	_battle_log.append(line)
	print(line)

func log_error(context: String, detail: String) -> void:
	var ts: int = Time.get_ticks_msec()
	var line: String = "[%07d][%s][ERROR] ctx=%s | %s" % [ts, _role(), context, detail]
	_battle_log.append(line)
	_errors.append("[b=%d] %s" % [battle_count + 1, line])
	print(line)

func log_skill(ward_name: String, skill_key: String, success: bool, reason: String = "") -> void:
	var key: String = "%s_%s" % [ward_name, skill_key]
	if not _skill_stats.has(key):
		_skill_stats[key] = {"ok": 0, "fail": 0, "reasons": {}}
	if success:
		_skill_stats[key]["ok"] += 1
	else:
		_skill_stats[key]["fail"] += 1
		if not reason.is_empty():
			var reasons: Dictionary = _skill_stats[key]["reasons"]
			reasons[reason] = reasons.get(reason, 0) + 1
	var status_str: String = "OK" if success else ("FAIL:" + reason)
	msg("[SKILL] ward=%s sk=%s st=%s" % [ward_name, skill_key, status_str])

# ─── Battle lifecycle ─────────────────────────────────────────────────────────
func record_battle_end(result: String) -> void:
	battle_count += 1
	_battle_results.append(result)
	turn_count = 0
	msg("[BATTLE_END] battle=%d result=%s" % [battle_count, result])
	_battle_log.clear()

func should_stop() -> bool:
	return battle_count >= max_battles

# ─── Final report ─────────────────────────────────────────────────────────────
func print_final_report() -> void:
	var sep: String = "=".repeat(72)
	print("")
	print(sep)
	print("[FINAL_REPORT] role=%s" % _role())
	print("Battles played : %d / %d" % [battle_count, max_battles])
	if not _battle_results.is_empty():
		var wins:  int = _battle_results.count("WIN")
		var loses: int = _battle_results.count("LOSE")
		var stuck: int = _battle_results.count("STUCK")
		print("Results        : WIN=%d  LOSE=%d  STUCK=%d" % [wins, loses, stuck])
	print("")
	print("--- ERRORS (%d) ---" % _errors.size())
	if _errors.is_empty():
		print("  (none)")
	else:
		for e in _errors:
			print("  " + e)
	print("")
	print("--- SKILL FAILURES ---")
	var any_fail := false
	for key in _skill_stats:
		var s: Dictionary = _skill_stats[key]
		if s["fail"] > 0:
			any_fail = true
			print("  %s  ok=%d fail=%d" % [key, s["ok"], s["fail"]])
			for reason in s["reasons"]:
				print("    reason='%s'  x%d" % [reason, s["reasons"][reason]])
	if not any_fail:
		print("  (none)")
	print(sep)
	print("[BOT_DONE]")
