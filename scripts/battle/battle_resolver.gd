extends Node

const SkillExecutor = preload("res://scripts/battle/skill_executor.gd")

var battle_log      = null
var battle_scene    = null
var skill_controller: SkillController = SkillController.new()

const ELEMENT_MULTIPLIERS = {
	"fire": {"fire": 1.0, "water": 2.0, "air": 0.5, "earth": 1.0, "light": 2.0},
	"water": {"fire": 0.5, "water": 1.0, "air": 2.0, "earth": 1.0, "light": 2.0},
	"air": {"fire": 2.0, "water": 0.5, "air": 1.0, "earth": 1.0, "light": 2.0},
	"earth": {"fire": 1.0, "water": 1.0, "air": 1.0, "earth": 1.0, "light": 2.0},
	"light": {"fire": 2.0, "water": 2.0, "air": 2.0, "earth": 2.0, "light": 4.0}
}

func setup(log_ref, scene_ref) -> void:
	battle_log = log_ref
	battle_scene = scene_ref


func attack(attacker, target, skill_key: String = "Q") -> void:
	if attacker == null:
		return

	skill_controller.activate(attacker.ward_id, skill_key, attacker)

	var pressed_button = null

	match skill_key:
		"Q": pressed_button = attacker.skill_q
		"W": pressed_button = attacker.skill_w
		"E": pressed_button = attacker.skill_e

	if pressed_button != null:
		await AnimationCode.skill_used_animation(pressed_button)

	await SkillExecutor.execute_skill(self, attacker, target, skill_key)

	skill_controller.clear()


func deal_damage_with_modifiers(attacker, target, base_damage: int, skill_key: String, forced_damage_type: String = "") -> void:
	if target == null:
		return

	var final_damage: int = base_damage
	var damage_type: String = forced_damage_type
	var mult: float = 1.0

	var armor: int = 0
	if target.has_node("WardHealthScript") or target.get("health"):
		armor = target.health.current_armor

	if damage_type == "" and attacker != null and attacker.ward_id != "":
		var attacker_data = WardDatabase.get_data(attacker.ward_id)
		if not attacker_data.is_empty():
			var skills = attacker_data.get("skills", {})
			var skill_data = skills.get(skill_key, {})
			damage_type = skill_data.get("damage_type", "phys")

	if damage_type != "phys" and damage_type != "passive" and damage_type != "":
		var target_data = WardDatabase.get_data(target.ward_id)
		var target_element = target_data.get("element", "phys")
		if ELEMENT_MULTIPLIERS.has(target_element):
			var def_mults = ELEMENT_MULTIPLIERS[target_element]
			if def_mults.has(damage_type):
				mult = def_mults[damage_type]
				
	var armor_dmg = mini(base_damage, armor)
	var hp_dmg = base_damage - armor_dmg
	var final_hp_dmg = int(hp_dmg * mult)
	final_damage = armor_dmg + final_hp_dmg

	await apply_damage(
		attacker,
		target,
		final_damage,
		skill_key,
		"-",
		"skill",
		base_damage,
		mult
	)



func apply_damage(
	source,
	target,
	damage: int,
	skill_key: String = "Q",
	status_text: String = "-",
	damage_source: String = "effect",
	base_damage: int = 0,
	mult: float = 1.0
) -> void:
	if target == null:
		return

	var source_name: String = "Невідомо"
	var source_team: String = "-"

	if source != null:
		source_name = source.name
		source_team = source.team

	var hp_before: int = target.current_hp
	var max_hp: int = target.max_hp

	if damage_source == "skill" and source != null:
		# Підваріанти удару (skill_key містить "_") отримують власний anim_id:
		# "Q_water_bonus" → "liah_q_water_bonus", "Q_rage" → "mais_oichi_q_rage" тощо
		var anim_id: String = skill_controller.active_skill_id
		if "_" in skill_key and source != null:
			anim_id = source.ward_id + "_" + skill_key.to_lower()
		# Анімація визначається за skill_id — аніматор додає гілки в skill_animation_dispatcher.gd
		await SkillAnimationDispatcher.play(
			anim_id,
			source,
			target,
			func():
				var hp_before_hit: int = target.current_hp

				await target.take_damage(damage, source, skill_key)

				var hp_after_hit: int = target.current_hp
				var _hp_different: int = hp_before_hit - hp_after_hit

				if damage > 0:
					SkillExecutor.check_rage_passive(self, target)
					# Пасивні удари (гідра тощо) не тригерять вогняний щит
					if skill_key != "P":
						_check_fire_shield(source, target)

					AnimationCode.animation_dmg_number(
						damage,
						target.portrait.get_global_rect().get_center()
					)
		)
	else:
		var hp_before_hit: int = target.current_hp

		await target.take_damage(damage, source, skill_key)

		var hp_after_hit: int = target.current_hp
		var _hp_different: int = hp_before_hit - hp_after_hit

		if damage > 0:
			SkillExecutor.check_rage_passive(self, target)
			if skill_key != "P":
				_check_fire_shield(source, target)

			AnimationCode.animation_dmg_number(
				damage,
				target.portrait.get_global_rect().get_center()
			)

	var hp_after: int = target.current_hp

	if battle_log:
		battle_log.add_attack(
			source_name,
			source_team,
			skill_key,
			damage,
			status_text,
			target.name,
			target.team,
			hp_before,
			hp_after,
			max_hp,
			damage_source,
			base_damage,
			mult
		)
	else:
		print(source_name, " завдав ", damage, " шкоди ", target.name)

	if target.is_dead and battle_log:
		battle_log.add_death(target.name, target.team)
		SkillExecutor.check_liah_passive(self, source, true)

func _check_fire_shield(attacker, target) -> void:
	if attacker == null or target == null: return
	if target.has_meta("fire_shield") and target.get_meta("fire_shield"):
		target.set_meta("fire_shield", false)
		target._update_status_visuals()
		attacker.add_status("burning", 2)
		if battle_log:
			battle_log.add_entry("Вогняний щит відбиває атаку! " + attacker.name + " отримує 2 стаки Горіння.")
			battle_log.add_effect(attacker.name, attacker.team, "Горіння (2 стаки)")

func calc_damage_only(attacker, target, base_damage: int, skill_key: String, forced_damage_type: String = "") -> Dictionary:
	var damage_type: String = forced_damage_type
	var mult: float = 1.0

	var armor: int = 0
	if target.get("health"):
		armor = target.health.current_armor

	if damage_type == "" and attacker != null and attacker.ward_id != "":
		var attacker_data = WardDatabase.get_data(attacker.ward_id)
		if not attacker_data.is_empty():
			var skill_data = attacker_data.get("skills", {}).get(skill_key, {})
			damage_type = skill_data.get("damage_type", "phys")

	if damage_type != "phys" and damage_type != "passive" and damage_type != "":
		var target_element = WardDatabase.get_data(target.ward_id).get("element", "phys")
		if ELEMENT_MULTIPLIERS.has(target_element) and ELEMENT_MULTIPLIERS[target_element].has(damage_type):
			mult = ELEMENT_MULTIPLIERS[target_element][damage_type]

	var armor_dmg: int = mini(base_damage, armor)
	var final_damage: int = armor_dmg + int((base_damage - armor_dmg) * mult)

	return {"final_damage": final_damage, "mult": mult}



func get_alive_wards(wards: Array) -> Array:
	var result: Array = []

	for ward in wards:
		if not ward.is_dead:
			result.append(ward)

	return result


func is_team_dead(wards: Array) -> bool:
	for ward in wards:
		if not ward.is_dead:
			return false

	return true


func kill_team(wards: Array) -> void:
	for ward in wards:
		if not ward.is_dead:
			await apply_damage(
				null,
				ward,
				ward.current_hp,
				"-",
				"-",
				"surrender"
			)
