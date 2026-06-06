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
	"light": {"fire": 2.0, "water": 2.0, "air": 2.0, "earth": 2.0, "light": 1.0}
}

func setup(log_ref, scene_ref) -> void:
	battle_log = log_ref
	battle_scene = scene_ref


func attack(attacker, target, skill_key: String = "Q") -> void:
	if attacker == null:
		return

	# === Пасивка Велодія: Захисний рефлекс — 35% відмінити ворожий скіл ===
	if skill_key in ["Q", "W", "E"]:
		var defender_side: Array = battle_scene.ally_wards if attacker.team == "enemy" else battle_scene.enemy_wards
		for w in defender_side:
			if w.ward_id == "velodiy" and not w.is_dead:
				var p_cd: int = w.get_meta("velodiy_p_cd", 0)
				if p_cd <= 0 and randf() < 0.35:
					w.set_meta("velodiy_p_cd", 2)
					if battle_log:
						battle_log.add_info("🛡 Захисний рефлекс! %s відміняє [%s → %s]! (КД 2 ходи)" % [w.name, attacker.name, skill_key], Color("#7080b0"))
						battle_log.add_effect(w.name, w.team, "Захисний рефлекс!")
					return
				break

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
					battle_log.add_info("💨 Сметіння! %s промахується — б'є %s замість %s" % [attacker.name, redirect.name, orig_name], Color("#9060a0"))
				effective_target = redirect

	await SkillExecutor.execute_skill(self, attacker, effective_target, skill_key)

	skill_controller.clear()
	_check_asteyah_memory(attacker, skill_key)


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

	# Земляні варди: подвійний урон у броню (ефективна броня вдвічі менша)
	var is_earth_attacker: bool = false
	if attacker != null and attacker.get("ward_id") and attacker.ward_id != "":
		var _att_data := WardDatabase.get_data(attacker.ward_id)
		is_earth_attacker = _att_data.get("element", "") == "earth"

	var armor_effective: int = armor / 2 if (is_earth_attacker and armor > 0) else armor
	var armor_dmg: int = mini(base_damage, armor_effective)
	var actual_armor_reduction: int = armor_dmg * 2 if is_earth_attacker else armor_dmg
	var hp_dmg: int = base_damage - armor_dmg
	var final_hp_dmg: int = int(hp_dmg * mult)
	final_damage = actual_armor_reduction + final_hp_dmg

	# === Фаланга Велодія: вхідна шкода +50% ===
	if target != null and target.get_status("phalanx") > 0:
		var before_phalanx: int = final_damage
		final_damage = int(final_damage * 1.5)
		if battle_log:
			battle_log.add_info("🛡 Фаланга: %s +50%% шкоди (%d → %d)" % [target.name, before_phalanx, final_damage], Color("#7080b0"))

	if armor_dmg > 0 and battle_log:
		if is_earth_attacker:
			battle_log.add_info("🪨 Земля×2: броня -%d | До HP: %d" % [actual_armor_reduction, final_hp_dmg])
		else:
			battle_log.add_info("  Броня поглинула %d | У HP: %d" % [armor_dmg, final_hp_dmg])

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
	# Земляні варди: бар'єр поглинає вдвічі менше (пробивають щит).
	if damage > 0 and skill_key != "P" and target.get_status("barrier") > 0:
		var _src_is_earth: bool = false
		if source != null and source.get("ward_id") and source.ward_id != "":
			var _src_data := WardDatabase.get_data(source.ward_id)
			_src_is_earth = _src_data.get("element", "") == "earth"
		var absorbed: int = mini(damage, 30)
		var absorbed_reduction: int = absorbed / 2 if _src_is_earth else absorbed
		damage -= absorbed_reduction
		target.remove_status("barrier", target.get_status("barrier"))
		target._update_status_visuals()
		if source != null and is_instance_valid(source) and not source.is_dead:
			source.add_status("burning", 1)
			source._update_status_visuals()
		if battle_log:
			var _barrier_log: String
			if _src_is_earth:
				_barrier_log = "🪨🔵 Земля пробиває бар'єр: поглинуто %d (×½) | До HP: %d" % [absorbed_reduction, damage]
			else:
				_barrier_log = "🔵 Бар'єр: поглинуто %d | До HP: %d" % [absorbed, damage]
			if source != null and is_instance_valid(source) and not source.is_dead:
				_barrier_log += " | %s +1 горіння" % source.name
			battle_log.add_info(_barrier_log, Color("#4878c0"))

	# Кам'яна стіна Фізіти: поглинає весь удар поки жива.
	# Земляні варди: стіна отримує подвійний урон (швидше руйнується).
	if damage > 0 and skill_key != "P" and target.get_status("phisita_wall") > 0:
		var _wall_is_earth: bool = false
		if source != null and source.get("ward_id") and source.ward_id != "":
			var _w_data := WardDatabase.get_data(source.ward_id)
			_wall_is_earth = _w_data.get("element", "") == "earth"
		var wall_hp: int = target.get_status("phisita_wall")
		target.remove_status("phisita_wall", wall_hp)
		var wall_damage: int = damage * 2 if _wall_is_earth else damage
		var new_wall_hp: int = wall_hp - wall_damage
		if new_wall_hp > 0:
			target.add_status("phisita_wall", new_wall_hp)
		target._update_status_visuals()
		if battle_log:
			if new_wall_hp <= 0:
				if _wall_is_earth:
					battle_log.add_info("🪨×2 Земля руйнує стіну %s (%d×2=%d)!" % [target.name, damage, wall_damage], Color("#906030"))
				else:
					battle_log.add_info("🪨 Стіна %s поглинула %d — зруйновано!" % [target.name, damage], Color("#906030"))
			else:
				battle_log.add_info("🪨 Стіна %s поглинула %d → лишилось %d HP" % [target.name, damage, new_wall_hp], Color("#906030"))
		return

	# Пасивка Рікера "На волосині": якщо удар смертельний — відміняє його, авто-використовує E, помирає.
	if target.ward_id == "riker" and damage > 0 and target.current_hp > 0 and skill_key != "passive_death":
		if not target.has_meta("riker_passive_used"):
			var armor: int = target.health.current_armor if target.get("health") else 0
			var hp_damage: int = damage - mini(damage, armor)
			if hp_damage >= target.current_hp:
				target.set_meta("riker_passive_used", true)
				if battle_log:
					battle_log.add_info("💀 На волосині: " + target.name + " відміняє смертельний удар!", Color("#d0a040"))
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

	if battle_log and source != null:
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
	elif battle_log == null:
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
		battle_log.add_info("🦠 Паразитування: %s поглинає силу загиблого!" % parasyt_ward.name, Color("#a060d0"))
		battle_log.add_heal(parasyt_ward.name, parasyt_ward.team, hp_before, parasyt_ward.current_hp, parasyt_ward.max_hp)

func _check_fire_shield(attacker, target) -> void:
	if attacker == null or target == null: return
	if target.has_meta("fire_shield") and target.get_meta("fire_shield"):
		target.set_meta("fire_shield", false)
		target._update_status_visuals()
		attacker.add_burning(2, 1)
		if battle_log:
			battle_log.add_info("🔥 Вогняний щит відбиває атаку! " + attacker.name + " отримує 2 стаки Горіння.", Color("#c86030"))
			battle_log.add_effect(attacker.name, attacker.team, "Горіння (2 стаки)")

func _check_fire_circle(attacker, target) -> void:
	if attacker == null or target == null: return
	if attacker.is_dead: return
	if target.get_status("fire_circle") > 0:
		attacker.add_burning(2, 1)
		if battle_log:
			battle_log.add_info("🔥 Коло пекельного вогню! " + attacker.name + " отримує 2 стаки горіння.", Color("#c86030"))
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
		battle_log.add_info("🔥 Присутність (%s): %s впав нижче 50%% — %d ворог(и) підпалено!" % [zhnets_ward.name, target.name, cnt], Color("#c86030"))

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
			battle_log.add_info("Відповідь (пасивка): %s нижче 50%% HP — Контратака %d хід(и)!" % [target.name, _ca_new_p])
			battle_log.add_effect(target.name, target.team, "Контратака %d хід(и) (пасивка)" % _ca_new_p)

	# Контратака: використовує Q скіл варда проти атакуючого
	if skill_key == "Q_counter": return
	if damage <= 0: return
	if target.get_status("counterattack") <= 0: return
	if target.has_meta("countered_this_turn"): return
	if source == null or not is_instance_valid(source) or source.is_dead: return

	target.set_meta("countered_this_turn", true)
	source.set_meta("countered_this_turn", true)  # запобігає контр-контратаці
	var ca_turns_left: int = target.get_status("counterattack")
	if battle_log:
		battle_log.add_info("⚡ Контратака! %s → Q проти %s! (ще %d хід(и))" % [target.name, source_name, ca_turns_left], Color("#d0a040"))
		battle_log.add_effect(target.name, target.team, "Контратака Q (%d ход(и))" % ca_turns_left)
	await SkillExecutor.execute_skill(self, target, source, "Q")


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


# Пасивка Астеї: запам'ятовує Q/W/E ворога після кожного його ходу.
# Іконка E на карті варда змінюється на іконку запам'ятаного скіла.
# Ліва панель опису — завжди з ward_database, не змінюється.
func _check_asteyah_memory(attacker, skill_key: String) -> void:
	if attacker == null: return
	if skill_key not in ["Q", "W", "E"]: return
	var watcher_side: Array = battle_scene.ally_wards if attacker.team == "enemy" else battle_scene.enemy_wards
	for w in watcher_side:
		if w.ward_id == "asteyah" and not w.is_dead:
			var _mem_dict: Dictionary = {"ward_id": attacker.ward_id, "skill_key": skill_key}
			if attacker.ward_id == "riker" and skill_key == "W":
				_mem_dict["riker_last_skill"] = attacker.get_meta("riker_w_last_variant", "")
			w.set_meta("asteyah_memory", _mem_dict)
			if battle_log:
				battle_log.add_info("🧠 Пам'ять: %s запам'ятала [%s → %s]!" % [w.name, attacker.name, skill_key])
			# Оновлюємо іконку кнопки E на картці варда на полі
			var mem_icon_path: String = WardDatabase.get_data(attacker.ward_id).get("skills", {}).get(skill_key, {}).get("icon", "")
			if mem_icon_path != "" and ResourceLoader.exists(mem_icon_path):
				var e_icon := w.skill_e.get_node_or_null("Icon") as TextureRect
				if e_icon:
					e_icon.texture = load(mem_icon_path)
			break
