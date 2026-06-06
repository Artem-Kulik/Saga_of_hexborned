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

	# === СМЕТІННЯ: перевіряємо phisita_e перед виконанням скіла ===
	var effective_target = target
	var target_type: String = SkillExecutor.get_skill_target_type(attacker.ward_id, skill_key, attacker)
	if target_type == "single_enemy" and attacker.get_status("phisita_e") > 0:
		var chance: int = attacker.get_meta("phisita_e_chance", 0)
		attacker.remove_status("phisita_e", attacker.get_status("phisita_e"))
		if attacker.has_meta("phisita_e_chance"):
			attacker.remove_meta("phisita_e_chance")
		attacker._update_status_visuals()
		if chance > 0 and randf() * 100.0 < float(chance):
			var all_alive: Array = []
			for w in battle_scene.ally_wards + battle_scene.enemy_wards:
				if not w.is_dead and w != attacker and w != target:
					all_alive.append(w)
			if not all_alive.is_empty():
				var redirect = all_alive[randi() % all_alive.size()]
				if battle_log:
					var orig_name: String = target.name if target != null else "себе"
					battle_log.add_entry("Сметіння! %s [%s] промахується: ціль %s → б'є %s" % [
						attacker.name, skill_key, orig_name, redirect.name
					])
				effective_target = redirect

	await SkillExecutor.execute_skill(self, attacker, effective_target, skill_key)

	skill_controller.clear()


func deal_damage_with_modifiers(attacker, target, base_damage: int, skill_key: String, forced_damage_type: String = "", is_aoe: bool = false) -> void:
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

	if armor_dmg > 0 and battle_log:
		battle_log.add_entry("    → В броню: %d | У HP: %d" % [armor_dmg, final_hp_dmg])

	await apply_damage(
		attacker,
		target,
		final_damage,
		skill_key,
		"-",
		"effect" if is_aoe else "skill",
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

	# Бар'єр Сьомого: поглинає до 30 шкоди, атакуючий отримує 1 горіння, бар'єр зникає.
	if damage > 0 and skill_key != "P" and target.get_status("barrier") > 0:
		var absorbed: int = mini(damage, 30)
		damage -= absorbed
		target.remove_status("barrier", target.get_status("barrier"))
		target._update_status_visuals()
		if source != null and is_instance_valid(source) and not source.is_dead:
			source.add_status("burning", 1)
			source._update_status_visuals()
		if battle_log:
			battle_log.add_entry("Бар'єр: поглинуто %d → В щит: %d | До HP: %d | %s +1 горіння" % [absorbed, absorbed, damage, source.name if source else "?"])

	# Кам'яна стіна Фізіти: поглинає весь удар поки жива.
	if damage > 0 and skill_key != "P" and target.get_status("phisita_wall") > 0:
		var wall_hp: int = target.get_status("phisita_wall")
		target.remove_status("phisita_wall", wall_hp)
		var new_wall_hp: int = wall_hp - damage
		if new_wall_hp > 0:
			target.add_status("phisita_wall", new_wall_hp)
		target._update_status_visuals()
		if battle_log:
			var src: String = source.name if source != null else "?"
			if new_wall_hp <= 0:
				battle_log.add_entry("Стіна %s [%s → %s]: поглинула %d → стіна: %d→0 HP (зруйновано) | У варда: 0" % [target.name, src, skill_key, damage, wall_hp])
			else:
				battle_log.add_entry("Стіна %s [%s → %s]: поглинула %d → стіна: %d→%d HP | У варда: 0" % [target.name, src, skill_key, damage, wall_hp, new_wall_hp])
		return

	# Пасивка Рікера "На волосині": якщо удар смертельний — відміняє його, авто-використовує E, помирає.
	if target.ward_id == "riker" and damage > 0 and target.current_hp > 0 and skill_key != "passive_death":
		if not target.has_meta("riker_passive_used"):
			var armor: int = target.health.current_armor if target.get("health") else 0
			var hp_damage: int = damage - mini(damage, armor)
			if hp_damage >= target.current_hp:
				target.set_meta("riker_passive_used", true)
				if battle_log:
					battle_log.add_entry("На волосині: " + target.name + " відміняє смертельний удар!")
					battle_log.add_effect(target.name, target.team, "На волосині")
				skill_controller.activate("riker", "E", target)
				if source != null and not source.is_dead:
					await SkillExecutor.execute_skill(self, target, source, "E")
				else:
					var enemy_side: Array = battle_scene.enemy_wards if target.team == "ally" else battle_scene.ally_wards
					var alive = get_alive_wards(enemy_side)
					if not alive.is_empty():
						await SkillExecutor.execute_skill(self, target, alive[0], "E")
				skill_controller.clear()
				# Рікер вмирає після пасивки
				await apply_damage(null, target, target.current_hp + target.health.current_armor + 1, "passive_death", "-", "effect", 0, 1.0)
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
					if skill_key != "P":
						_check_fire_shield(source, target)
						_check_fire_circle(source, target)

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
				_check_fire_circle(source, target)

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

	_check_zhnets_passive(target, hp_before, hp_after)
	await _check_adoneia(target, source, hp_before, hp_after, damage, skill_key, source_name)

	if target.is_dead and battle_log:
		battle_log.add_death(target.name, target.team)
		battle_scene.clear_taunt_on_death(target)
		SkillExecutor.check_otsii_passive_death(self, target)
		SkillExecutor.check_liah_passive(self, source, true)
		_check_parasyt_passive(target)

func _check_parasyt_passive(dead_ward) -> void:
	if dead_ward == null: return
	var heal_side: Array = battle_scene.ally_wards if dead_ward.team == "enemy" else battle_scene.enemy_wards
	var parasyt_ward = null
	for w in heal_side:
		if w.ward_id == "parasyt" and not w.is_dead:
			parasyt_ward = w
			break
	if parasyt_ward == null: return
	var hp_before: int = parasyt_ward.current_hp
	parasyt_ward.health.heal(75)
	if battle_log:
		battle_log.add_entry("Паразитування: %s поглинає силу загиблого!" % parasyt_ward.name)
		battle_log.add_heal(parasyt_ward.name, parasyt_ward.team, hp_before, parasyt_ward.current_hp, parasyt_ward.max_hp)

func _check_fire_shield(attacker, target) -> void:
	if attacker == null or target == null: return
	if target.has_meta("fire_shield") and target.get_meta("fire_shield"):
		target.set_meta("fire_shield", false)
		target._update_status_visuals()
		attacker.add_burning(2, 1)
		if battle_log:
			battle_log.add_entry("Вогняний щит відбиває атаку! " + attacker.name + " отримує 2 стаки Горіння.")
			battle_log.add_effect(attacker.name, attacker.team, "Горіння (2 стаки)")

func _check_fire_circle(attacker, target) -> void:
	if attacker == null or target == null: return
	if attacker.is_dead: return
	if target.get_status("fire_circle") > 0:
		attacker.add_burning(2, 1)
		if battle_log:
			battle_log.add_entry("Коло пекельного вогню! " + attacker.name + " отримує 2 стаки горіння.")
			battle_log.add_effect(attacker.name, attacker.team, "Горіння (2 стаки від кола)")

func _check_zhnets_passive(target, hp_before: int, hp_after: int) -> void:
	if target == null or target.is_dead: return
	# Перетин порогу: був вище 50%, став нижче або рівно 50%
	if not (hp_before * 2 > target.max_hp and hp_after * 2 <= target.max_hp): return
	# Шукаємо живого Жнеця у грі, для якого target — ворог
	var zhnets_ward = null
	for w in battle_scene.ally_wards + battle_scene.enemy_wards:
		if w.ward_id == "zhnets" and not w.is_dead and w.team != target.team:
			zhnets_ward = w
			break
	if zhnets_ward == null: return
	# 1 стак горіння (2 ходи) двом рандомним живим ворогам Жнеця
	var enemy_side: Array = battle_scene.enemy_wards if zhnets_ward.team == "ally" else battle_scene.ally_wards
	var alive: Array = get_alive_wards(enemy_side)
	if alive.is_empty(): return
	alive.shuffle()
	var cnt: int = mini(2, alive.size())
	for i in range(cnt):
		alive[i].add_burning(1, 2)
		alive[i]._update_status_visuals()
		if battle_log:
			battle_log.add_effect(alive[i].name, alive[i].team, "Горіння +1 стак (Присутність)")
	if battle_log:
		battle_log.add_entry("Присутність (%s): %s впав нижче 50%% — %d ворог(и) підпалено!" % [zhnets_ward.name, target.name, cnt])

func _check_adoneia(target, source, hp_before: int, hp_after: int, damage: int, skill_key: String, source_name: String) -> void:
	if target == null or target.ward_id != "adoneia": return
	if target.is_dead: return

	# Пасивка P: 1 хід Контратаки при падінні нижче 50% HP
	if damage > 0 and hp_before * 2 > target.max_hp and hp_after * 2 <= target.max_hp:
		var _ca_old_p: int = target.get_status("counterattack")
		var _ca_new_p: int = max(_ca_old_p, 1)
		if _ca_old_p > 0:
			target.remove_status("counterattack", _ca_old_p)
		target.add_status("counterattack", _ca_new_p)
		target._update_status_visuals()
		if battle_log:
			battle_log.add_entry("Відповідь (пасивка): %s пробита нижче 50%% HP — Контратака на %d хід(и)!" % [target.name, _ca_new_p])
			battle_log.add_effect(target.name, target.team, "Контратака %d хід(и) (пасивка)" % _ca_new_p)

	# Контратака: спрацьовує раз за хід ворога — НЕ знімається при спрацюванні (тікає по ходах)
	if skill_key == "Q_counter": return
	if damage <= 0: return
	if target.get_status("counterattack") <= 0: return
	if target.has_meta("countered_this_turn"): return
	if source == null or not is_instance_valid(source) or source.is_dead: return

	target.set_meta("countered_this_turn", true)
	# Не знімаємо стаки — контратака діє до кінця своєї тривалості
	var ca_turns_left: int = target.get_status("counterattack")
	if battle_log:
		battle_log.add_entry("Контратака! %s відповідає — двічі б'є %s по 30! (залишилось %d ход(и))" % [target.name, source_name, ca_turns_left])
		battle_log.add_effect(target.name, target.team, "Контратака спрацювала (%d ход(и) лишилось)" % ca_turns_left)
	await deal_damage_with_modifiers(target, source, 30, "Q_counter", "phys")
	if source != null and is_instance_valid(source) and not source.is_dead:
		await deal_damage_with_modifiers(target, source, 30, "Q_counter", "phys")


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
