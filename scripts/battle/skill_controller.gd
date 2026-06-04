class_name SkillController
extends RefCounted

var active_skill_id: String = ""
var active_ward_id: String = ""
var active_skill_key: String = ""
var active_attacker = null


func activate(ward_id: String, skill_key: String, attacker) -> void:
	active_ward_id = ward_id
	active_skill_key = skill_key
	active_skill_id = ward_id + "_" + skill_key.to_lower()
	active_attacker = attacker
	print("[SKILL] id: %s  |  ward: %s  |  key: %s" % [active_skill_id, ward_id, skill_key])


func clear() -> void:
	print("[SKILL] %s — завершено" % active_skill_id)
	active_skill_id = ""
	active_ward_id = ""
	active_skill_key = ""
	active_attacker = null


func is_active() -> bool:
	return active_skill_id != ""
