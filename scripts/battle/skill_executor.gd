extends Node

# Визначає, яку ціль потребує скіл:
# "single_enemy" - один клік по ворогу
# "all_enemies" - б'є всіх ворогів одразу (не треба клікати)
# "self" - застосовується на себе (не треба клікати)
static func get_skill_target_type(ward_id: String, skill_key: String, attacker = null) -> String:
	match ward_id:
		"liah":
			if skill_key == "W": return "all_enemies"
			if skill_key == "E": return "self"
		"mais_oichi":
			if skill_key == "W": return "self"
			if skill_key == "E": return "single_enemy"
		"grump":
			if skill_key == "Q": return "all_enemies"
			if skill_key == "E": return "all_enemies"
		"riker":
			if skill_key == "W":
				var last = attacker.get_meta("riker_last_skill", "") if attacker != null and attacker.has_meta("riker_last_skill") else ""
				if last == "E": return "all_enemies"
				return "single_enemy"
		"iskoris":
			if skill_key == "E": return "all_enemies"
		"etesena":
			if skill_key == "Q": return "all_enemies"
			if skill_key == "W": return "etesena_w"
		"otsii":
			if skill_key == "Q": return "all_enemies"
			if skill_key == "W": return "single_ally"
			if skill_key == "E": return "single_enemy"
		"siomyi":
			if skill_key == "Q": return "single_any"
			if skill_key == "W": return "single_ally"
			if skill_key == "E": return "single_enemy"
		"zhnets":
			if skill_key == "Q": return "all_enemies"
			if skill_key == "W": return "single_enemy"
			if skill_key == "E": return "single_enemy"
		"parasyt":
			if skill_key == "Q": return "single_enemy"
			if skill_key == "W": return "single_enemy"
			if skill_key == "E": return "self"
		"adoneia":
			if skill_key == "E": return "self"
			var in_golem: bool = attacker != null and attacker.has_meta("golem_form")
			if in_golem: return "all_enemies"
			return "single_enemy"
		"fizita":
			if skill_key == "W": return "single_ally"
		"shusima":
			if skill_key == "W": return "self"
			if skill_key == "E": return "self"

	return "single_enemy"


# Виконує унікальну логіку скілу
static func execute_skill(resolver, attacker, target, skill_key: String) -> void:
	var ward_id = attacker.ward_id
	var base_damage = attacker.skill_damage # 50
	
	match ward_id:
		"liah":
			await _execute_liah(resolver, attacker, target, skill_key, base_damage)
		"mais_oichi":
			await _execute_mais_oichi(resolver, attacker, target, skill_key, base_damage)
		"shopey":
			await _execute_shopey(resolver, attacker, target, skill_key, base_damage)
		"grump":
			await _execute_grump(resolver, attacker, target, skill_key, base_damage)
		"riker":
			await _execute_riker(resolver, attacker, target, skill_key)
		"iskoris":
			await _execute_iskoris(resolver, attacker, target, skill_key)
		"etesena":
			await _execute_etesena(resolver, attacker, target, skill_key)
		"otsii":
			await _execute_otsii(resolver, attacker, target, skill_key)
		"siomyi":
			await _execute_siomyi(resolver, attacker, target, skill_key)
		"zhnets":
			await _execute_zhnets(resolver, attacker, target, skill_key)
		"parasyt":
			await _execute_parasyt(resolver, attacker, target, skill_key)
		"adoneia":
			await _execute_adoneia(resolver, attacker, target, skill_key)
		"fizita":
			await _execute_fizita(resolver, attacker, target, skill_key)
		"shusima":
			await _execute_shusima(resolver, attacker, target, skill_key)
		_:
			# Стандартна атака для всіх інших поки що
			await _execute_basic_attack(resolver, attacker, target, skill_key, base_damage)


static func _execute_basic_attack(resolver, attacker, target, skill_key: String, base_damage: int) -> void:
	if target == null: return
	await resolver.deal_damage_with_modifiers(attacker, target, base_damage, skill_key)


static func _execute_liah(resolver, attacker, target, skill_key: String, _base_damage: int) -> void:
	match skill_key:
		"Q":
			# Течія: Наносить 50(фіз). Якщо ціль мала максимальне HP — атакує ще раз (водяний).
			if target == null: return
			var was_full_hp = (target.current_hp == target.max_hp)
			if was_full_hp:
				resolver.battle_log.add_entry("Течія: додатковий водяний удар!")
			var d1 = resolver.calc_damage_only(attacker, target, 50, "Q", "phys")
			var d2_callable := Callable()
			if was_full_hp:
				var d2 = resolver.calc_damage_only(attacker, target, 50, "Q_water_bonus", "water")
				d2_callable = func():
					await resolver.apply_damage(attacker, target, d2.final_damage, "Q_water_bonus", "-", "effect", 50, d2.mult)
			await SkillAnimationDispatcher.play_liah_q(
				attacker, target,
				func(): await resolver.apply_damage(attacker, target, d1.final_damage, "Q", "-", "effect", 50, d1.mult),
				d2_callable,
				was_full_hp
			)
				
		"W":
			# Кола на воді: Атакує всіх ворогів, наносить 35(вода). Якщо хтось гине — атакує ще раз.
			var enemy_side_w: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
			var center_w: Vector2 = Vector2(903, 542)

			# Рух Лії вперед
			var av_w: Control = attacker.get_node_or_null("WardVisual")
			var start_pos_w: Vector2 = av_w.global_position if av_w else Vector2.ZERO
			if av_w:
				var t := av_w.create_tween()
				t.tween_property(av_w, "global_position", center_w, 0.20)
				await t.finished

			# Ефект
			await AnimationCode.anim_liah_w_effect(center_w)

			# Шкода всім ворогам
			var trigger_again = false
			var enemies = resolver.get_alive_wards(enemy_side_w)
			for enemy in enemies:
				var hp_before = enemy.current_hp
				await resolver.deal_damage_with_modifiers(attacker, enemy, 35, skill_key, "", true)
				if enemy.is_dead and hp_before > 0:
					trigger_again = true

			if trigger_again:
				resolver.battle_log.add_entry("Кола на воді: ефект спрацював повторно!")
				enemies = resolver.get_alive_wards(enemy_side_w)
				for enemy in enemies:
					await resolver.deal_damage_with_modifiers(attacker, enemy, 35, skill_key, "", true)

			# Повернення
			if av_w:
				var t := av_w.create_tween()
				t.tween_property(av_w, "global_position", start_pos_w, 0.20)
				await t.finished

		"E":
			# Загороджуючий водопад: Стає невибираною як ціль до свого наступного ходу.
			resolver.battle_log.add_entry("Лія активує Загороджуючий водопад!")
			attacker.set_meta("untargetable", true)
			attacker.modulate.a = 0.5 # Трішки прозора
			
			if resolver.battle_log:
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Загороджуючий водопад (невидимість)")


# Пасивка Лії: лікування при вбивстві
static func check_liah_passive(resolver, attacker, target_died: bool) -> void:
	if attacker == null: return
	if attacker.ward_id == "liah" and target_died:
		var allies = resolver.get_alive_wards(resolver.battle_scene.ally_wards if attacker.team == "ally" else resolver.battle_scene.enemy_wards)
		resolver.battle_log.add_entry("Спокій (Пасивка): Лія лікує союзників!")
		for ally in allies:
			var hp_before = ally.current_hp
			ally.health.heal(50)
			if resolver.battle_log:
				resolver.battle_log.add_heal(ally.name, ally.team, hp_before, ally.current_hp, ally.max_hp)

static func check_rage_passive(resolver, target) -> void:
	if target.ward_id != "mais_oichi":
		return
	if target._rage_gained_this_turn:
		return
	target._rage_gained_this_turn = true
	target.add_status("rage", 1)
	resolver.battle_log.add_entry("Майстер Оічі отримує стак Ражу!")

static func _execute_mais_oichi(resolver, attacker, target, skill_key: String, _base_damage: int) -> void:
	match skill_key:
		"Q":
			if target == null: return
			var phys_damage = 105
			var rage_stacks = attacker.get_status("rage")
			var fire_damage = 15 * rage_stacks
			
			# Фізичний удар
			await resolver.deal_damage_with_modifiers(attacker, target, phys_damage, skill_key, "phys")
			
			# Вогняний удар від ражу
			if fire_damage > 0:
				resolver.battle_log.add_entry("Додаткова шкода від Ражу: " + str(fire_damage) + " (вогонь)")
				await resolver.deal_damage_with_modifiers(attacker, target, fire_damage, "Q_rage", "fire")
			
			if rage_stacks > 0:
				attacker.remove_status("rage", rage_stacks)
				resolver.battle_log.add_entry("Стаки Ражу скинуто.")
				
		"W":
			# Жар: Накладає на себе щит з ВОГНЮ, котрий дає 30 броні.
			attacker.health.add_armor(30)
			attacker.set_meta("fire_shield", true)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry(
					"Жар: +30 броні (разом: %d). Вогняний щит активний!" % attacker.health.current_armor
				)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Вогняний щит + Броня +30 (разом: %d)" % attacker.health.current_armor)
				
		"E":
			# Чесний бій: Провокує ціль на 1 хід. Збільшує свою броню на 100.
			if target == null: return
			resolver.battle_log.add_entry("Майстер Оічі провокує ворога і отримує +100 броні!")
			attacker.health.add_armor(100)

			target.add_status("taunt", 1)
			target.taunted_by = attacker.ward_id

			if resolver.battle_log:
				resolver.battle_log.add_effect(target.name, target.team, "Провокація (мусить атакувати Оічі)")


# =============================================================================
# SHOPEY (Шопей)
# =============================================================================
# Пасивка: при ударі 37% — Відсічена Голова б'є випадкового іншого ворога (45 повітря).
# Якщо живий лише один ворог — жодна гідра не спрацьовує.
# E встановлює прапорець: наступна здібність гарантовано тригерить гідру.

static func _execute_shopey(resolver, attacker, target, skill_key: String, _base_damage: int) -> void:
	# Перевіряємо та споживаємо прапорець від E до виконання скіла
	var e_hydra_ready: bool = attacker.has_meta("shopey_hydra_ready") and attacker.get_meta("shopey_hydra_ready")
	if e_hydra_ready:
		attacker.set_meta("shopey_hydra_ready", false)

	match skill_key:
		"Q":
			# Поривистий випад: 75 фіз
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 75, skill_key, "phys")
			if e_hydra_ready:
				await _shopey_trigger_hydra(resolver, attacker, target)
				# E-буф спожито — пасивка не кидається
			else:
				await _shopey_passive_check(resolver, attacker, target)

		"W":
			# Ріжуча гідра: 90 повітря + власна гідра W (завжди, без пасивки)
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 90, skill_key, "air")
			await _shopey_trigger_hydra(resolver, attacker, target)
			if e_hydra_ready:
				await _shopey_trigger_hydra(resolver, attacker, target)

		"E":
			# Наскок: 30 фіз → встановлює прапорець для наступної здібності
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 30, skill_key, "phys")
			if e_hydra_ready:
				# E-буф спожито — пасивка не кидається
				await _shopey_trigger_hydra(resolver, attacker, target)
			else:
				await _shopey_passive_check(resolver, attacker, target)
			attacker.set_meta("shopey_hydra_ready", true)
			if resolver.battle_log:
				resolver.battle_log.add_entry("Шопей: наступна здібність гарантовано викличе Відсічену Гідру!")
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Наскок (гарантована гідра)")


# Випадковий живий ворог, відмінний від основної цілі.
# Повертає null якщо таких немає (єдиний ворог або всі інші мертві).
static func _shopey_get_other_enemy(resolver, attacker, exclude_target):
	var all_enemies = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
	var others: Array = resolver.get_alive_wards(all_enemies).filter(
		func(w): return w != exclude_target
	)
	if others.is_empty():
		return null
	return others[randi() % others.size()]


# Відсічена Голова Гідри: 45 повітря по випадковому іншому ворогу.
static func _shopey_trigger_hydra(resolver, attacker, exclude_target) -> void:
	var hydra_target = _shopey_get_other_enemy(resolver, attacker, exclude_target)
	if hydra_target == null:
		return
	if resolver.battle_log:
		resolver.battle_log.add_entry("Відсічена Голова Гідри атакує " + hydra_target.name + "!")
	await resolver.deal_damage_with_modifiers(attacker, hydra_target, 45, "P", "air")


# Пасивка: 37% шанс тригернути гідру після кожного скіла.
static func _shopey_passive_check(resolver, attacker, attacked_target) -> void:
	if randf() >= 0.37:
		return
	var hydra_target = _shopey_get_other_enemy(resolver, attacker, attacked_target)
	if hydra_target == null:
		return
	if resolver.battle_log:
		resolver.battle_log.add_entry("Пасивка Відсічена Гідра: атакує " + hydra_target.name + "!")
	await resolver.deal_damage_with_modifiers(attacker, hydra_target, 45, "P", "air")


# =============================================================================
# GRUMP (Грумп)
# =============================================================================
# P — Наростання породи: +25 броні після кожного власного скіла.
# Q — Клятва Варда: 20 фіз по всіх ворогах.
# W — Борозда: 30 фіз + оглушення 1 хід.
# E — Вибух породи: (25 + поточна броня) фіз по всіх, броня → 0.

static func _execute_grump(resolver, attacker, target, skill_key: String, _base_damage: int) -> void:
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards

	match skill_key:
		"Q":
			# Клятва Варда: 20 фіз по всіх ворогах
			for enemy in resolver.get_alive_wards(enemy_side):
				await resolver.deal_damage_with_modifiers(attacker, enemy, 20, skill_key, "phys", true)

		"W":
			# Борозда: 30 фіз + оглушення 1 хід
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 30, skill_key, "phys")
			if not target.is_dead:
				target.add_status("stun", 1)
				if resolver.battle_log:
					resolver.battle_log.add_entry(target.name + " оглушений на 1 хід!")
					resolver.battle_log.add_effect(target.name, target.team, "Оглушення (1 хід)")

		"E":
			# Вибух породи: (25 + поточна броня) фіз по всіх, після — броня Грумпа → 0
			var armor: int = attacker.health.current_armor
			var total_damage: int = 25 + armor
			if resolver.battle_log:
				resolver.battle_log.add_entry(
					"Вибух породи: %d пошкоджень (25 + %d броні) по всіх!" % [total_damage, armor]
				)
			for enemy in resolver.get_alive_wards(enemy_side):
				await resolver.deal_damage_with_modifiers(attacker, enemy, total_damage, skill_key, "phys", true)
			attacker.health.current_armor = 0
			attacker.update_armor_status(0)
			if resolver.battle_log:
				resolver.battle_log.add_entry("Броня Грумпа скинута до 0.")

	# Пасивка: +25 броні наприкінці кожного ходу
	_grump_end_of_turn_passive(resolver, attacker)


static func _grump_end_of_turn_passive(resolver, attacker) -> void:
	attacker.health.add_armor(25)
	attacker.update_armor_status(attacker.health.current_armor)
	if resolver.battle_log:
		resolver.battle_log.add_entry(
			"Наростання породи: +25 броні. Всього броні: %d" % attacker.health.current_armor
		)
		resolver.battle_log.add_effect(
			attacker.name, attacker.team, "Броня +25 (всього: %d)" % attacker.health.current_armor
		)


# =============================================================================
# RIKER (Рікер)
# =============================================================================
# P — На волосині: при смертельному ударі — відміняє його, авто-використовує E, потім вмирає.
# Q — Роздирання: 2 удари по 35(вода) по одній цілі.
# W — Стиль Доломедес (КД 2): якщо Q → 3 удари по 45(вода); якщо E → 60(вода) по всіх ворогах.
# E — Кігті: 60(вода) по цілі + сусідня (центр для крайніх; для центру — рандом з крайніх).

static func _execute_riker(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 35, skill_key, "water")
			if not target.is_dead:
				await resolver.deal_damage_with_modifiers(attacker, target, 35, skill_key, "water")
			attacker.set_meta("riker_last_skill", "Q")

		"W":
			var last: String = attacker.get_meta("riker_last_skill", "") if attacker.has_meta("riker_last_skill") else ""
			if last == "Q":
				if target == null: return
				if resolver.battle_log:
					resolver.battle_log.add_entry("Стиль Доломедес: три удари по цілі!")
				for i in 3:
					if target.is_dead: break
					await resolver.deal_damage_with_modifiers(attacker, target, 45, skill_key, "water")
			elif last == "E":
				if resolver.battle_log:
					resolver.battle_log.add_entry("Стиль Доломедес: удар по всіх ворогах!")
				var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
				for enemy in resolver.get_alive_wards(enemy_side):
					await resolver.deal_damage_with_modifiers(attacker, enemy, 60, skill_key, "water", true)
			else:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Стиль Доломедес: потрібно спочатку використати Q або E!")
			attacker.set_meta("riker_last_skill", "W")

		"E":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 60, skill_key, "water")
			var neighbor = _riker_get_neighbor(resolver, attacker, target)
			if neighbor != null and not neighbor.is_dead:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Кігті: б'є сусідній варт — %s!" % neighbor.name)
				await resolver.deal_damage_with_modifiers(attacker, neighbor, 60, skill_key, "water")
			attacker.set_meta("riker_last_skill", "E")


# Повертає сусідній ворожий варт для скіла E Рікера.
# Крайній (0 або 2) → центр (1); центр (1) → рандом з живих крайніх.
# Якщо центр мертвий і ціль — крайня → null (немає сусіда).
static func _riker_get_neighbor(resolver, attacker, target):
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
	var idx: int = enemy_side.find(target)
	if idx < 0:
		return null

	if idx == 1:
		# Центр → рандом із живих крайніх
		var candidates: Array = []
		if not enemy_side[0].is_dead:
			candidates.append(enemy_side[0])
		if enemy_side.size() > 2 and not enemy_side[2].is_dead:
			candidates.append(enemy_side[2])
		if candidates.is_empty():
			return null
		return candidates[randi() % candidates.size()]
	else:
		# Крайній (0 або 2) → центр (1)
		if enemy_side.size() > 1 and not enemy_side[1].is_dead:
			return enemy_side[1]
		return null


# =============================================================================
# ISKORIS (Іскоріс)
# =============================================================================
# P — Тисяча Порізів: кожна атака → 20+10*N повітря + 1 стак "cuts" на цілі (N = поточні стаки).
# Q — Укус: 10+10*N повітря → пасивка.
# W — Пісня мерця (КД 4): два удари, кожен 10+10*N повітря → пасивка × 2.
# E — Ріжучий смерч (КД 4): 10+10*N повітря по всіх ворогах → пасивка кожному.

static func _execute_iskoris(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await _iskoris_hit(resolver, attacker, target, 10, skill_key)

		"W":
			if target == null: return
			await _iskoris_hit(resolver, attacker, target, 10, skill_key)
			if not target.is_dead:
				await _iskoris_hit(resolver, attacker, target, 10, skill_key)

		"E":
			var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
			for enemy in resolver.get_alive_wards(enemy_side):
				await _iskoris_hit(resolver, attacker, enemy, 10, skill_key, true)


# Один удар Іскоріса: base + стаки → пасивний удар → +1 стак.
# is_aoe=true → без анімації руху атакера (для AoE скілів).
static func _iskoris_hit(resolver, attacker, target, base_dmg: int, skill_key: String, is_aoe: bool = false) -> void:
	var stacks: int = target.get_status("cuts")
	var skill_dmg: int = base_dmg + 10 * stacks
	var passive_dmg: int = 20

	if resolver.battle_log and stacks > 0:
		resolver.battle_log.add_entry(
			"Тисяча Порізів: %d стак(и) → скіл +%d" % [stacks, 10 * stacks]
		)

	# Основний удар скіла
	await resolver.deal_damage_with_modifiers(attacker, target, skill_dmg, skill_key, "air", is_aoe)

	if target.is_dead:
		return

	# Пасивний удар (завжди без руху — пасивка анімується на місці)
	await resolver.deal_damage_with_modifiers(attacker, target, passive_dmg, "P_cuts", "air", true)

	if target.is_dead:
		return

	# Накладання стаку та оновлення тултіпу
	target.add_status("cuts", 1)
	target._update_status_visuals()


# =============================================================================
# ETESENA (Етесена)
# =============================================================================
# P — Пасивка: якщо ціль оглушена — 33% шанс пробити і нанести таку ж шкоду сусідній цілі.
# Q — Укол: 3 голки по 25(фіз), кожна летить у рандомну живу ціль.
# W — Танець (КД 3): гравець обирає 3 цілі → 1-й 35(фіз), 2-й оглушення, 3-й 45(фіз).
#     Цілі передаються через meta "etesena_w_targets".
# E — Північні вітри (КД 5): 5 голок × 25(фіз) в одну ціль; якщо оглушена — продовжує +1 хід.

static func _execute_etesena(resolver, attacker, target, skill_key: String) -> void:
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards

	match skill_key:
		"Q":
			for i in 3:
				var alive = resolver.get_alive_wards(enemy_side)
				if alive.is_empty(): break
				var t = alive[randi() % alive.size()]
				await resolver.deal_damage_with_modifiers(attacker, t, 25, skill_key, "phys", true)
				await _etesena_passive_check(resolver, attacker, t, 25, enemy_side)

		"W":
			var targets: Array = attacker.get_meta("etesena_w_targets", [])
			if attacker.has_meta("etesena_w_targets"):
				attacker.remove_meta("etesena_w_targets")
			for i in targets.size():
				var t = targets[i]
				if t == null or not is_instance_valid(t) or t.is_dead:
					continue
				match i:
					0:
						await resolver.deal_damage_with_modifiers(attacker, t, 35, skill_key, "phys")
						await _etesena_passive_check(resolver, attacker, t, 35, enemy_side)
					1:
						t.add_status("stun", 1)
						if resolver.battle_log:
							resolver.battle_log.add_entry(t.name + " оглушений!")
							resolver.battle_log.add_effect(t.name, t.team, "Оглушення (1 хід)")
					2:
						await resolver.deal_damage_with_modifiers(attacker, t, 45, skill_key, "phys")
						await _etesena_passive_check(resolver, attacker, t, 45, enemy_side)

		"E":
			if target == null: return
			for i in 5:
				if target.is_dead: break
				await resolver.deal_damage_with_modifiers(attacker, target, 25, skill_key, "phys", true)
				await _etesena_passive_check(resolver, attacker, target, 25, enemy_side)
			if not target.is_dead and target.get_status("stun") > 0:
				target.add_status("stun", 1)
				if resolver.battle_log:
					resolver.battle_log.add_entry("Північні вітри: оглушення продовжено +1 хід!")


# Пасивка: 33% шанс пробити оглушену ціль і нанести таку ж шкоду сусідній.
static func _etesena_passive_check(resolver, attacker, target, damage: int, enemy_side: Array) -> void:
	if target.is_dead: return
	if target.get_status("stun") <= 0: return
	if randf() >= 0.33: return
	var neighbor = _etesena_get_neighbor(enemy_side, target)
	if neighbor == null or neighbor.is_dead: return
	if resolver.battle_log:
		resolver.battle_log.add_entry("Пасивна: голка пробиває оглушеного і б'є %s!" % neighbor.name)
	await resolver.deal_damage_with_modifiers(attacker, neighbor, damage, "P_etesena", "phys")


# Сусідній варт: крайній (0/2) → центр (1); центр (1) → рандом живого крайнього.
static func _etesena_get_neighbor(enemy_side: Array, target) -> Variant:
	var idx: int = enemy_side.find(target)
	if idx < 0: return null
	if idx == 1:
		var candidates: Array = []
		if not enemy_side[0].is_dead: candidates.append(enemy_side[0])
		if enemy_side.size() > 2 and not enemy_side[2].is_dead: candidates.append(enemy_side[2])
		if candidates.is_empty(): return null
		return candidates[randi() % candidates.size()]
	else:
		if enemy_side.size() > 1 and not enemy_side[1].is_dead: return enemy_side[1]
		return null


# =============================================================================
# OTSII (Оцій)
# =============================================================================
# P — При смерті союзника: зменшує КД скіла з найбільшим КД на 2 (пріоритет макс.КД).
#     При власній смерті: дає Коло пекельного вогню випадковому союзнику.
# Q — Вигорання: 1 стак горіння на випадкового ворога.
# W — Коло пекельного вогню (КД 4): знімає всі негативні ефекти з союзника,
#     накладає fire_circle (2 ходи). Атакуючий цей варт отримує 2 стаки горіння.
# E — Рик (КД 4): Оцій + союзник атакують ціль; союзник використовує Q; +1 горіння.

static func _execute_otsii(resolver, attacker, target, skill_key: String) -> void:
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards

	match skill_key:
		"Q":
			var alive = resolver.get_alive_wards(enemy_side)
			if alive.is_empty(): return
			var t = alive[randi() % alive.size()]
			t.add_status("burning", 1)
			t._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Вигорання: " + t.name + " отримує 1 стак горіння!")
				resolver.battle_log.add_effect(t.name, t.team, "Горіння (1 стак)")

		"W":
			if target == null: target = attacker
			target.remove_negative_effects()
			target.add_status("fire_circle", 2)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Коло пекельного вогню: %s очищений і захищений на 2 ходи!" % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Коло пекельного вогню (2 ходи)")

		"E":
			if target == null: return
			target.add_status("burning", 1)
			target._update_status_visuals()
			var ally_side: Array = resolver.battle_scene.ally_wards if attacker.team == "ally" else resolver.battle_scene.enemy_wards
			var alive_allies: Array = resolver.get_alive_wards(ally_side).filter(func(w): return w != attacker)
			if alive_allies.is_empty():
				if resolver.battle_log:
					resolver.battle_log.add_entry("Рик: %s +1 горіння (союзників немає)." % target.name)
			else:
				var ally_helper = alive_allies[randi() % alive_allies.size()]
				var hp_before_e: int = target.current_hp if is_instance_valid(target) else 0
				if resolver.battle_log:
					resolver.battle_log.add_entry("Рик: %s +1 горіння. %s атакує разом з Оцієм → %s!" % [target.name, ally_helper.name, target.name])
				await execute_skill(resolver, ally_helper, target, "Q")
				if resolver.battle_log and is_instance_valid(target):
					var hp_after_e: int = target.current_hp
					resolver.battle_log.add_entry("  → %s [Q]: HP %s: %d → %d (%s)" % [
						ally_helper.name, target.name, hp_before_e, hp_after_e,
						"загинув!" if target.is_dead else "-%d" % (hp_before_e - hp_after_e)
					])


static func check_otsii_passive_death(resolver, dead_ward) -> void:
	var team_side: Array = resolver.battle_scene.ally_wards if dead_ward.team == "ally" else resolver.battle_scene.enemy_wards

	# Otsii сам помер → Коло пекельного вогню випадковому союзнику
	if dead_ward.ward_id == "otsii":
		var alive_allies: Array = team_side.filter(func(w): return not w.is_dead)
		if not alive_allies.is_empty():
			var lucky = alive_allies[randi() % alive_allies.size()]
			lucky.add_status("fire_circle", 2)
			lucky._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Оцій: передає Коло пекельного вогню " + lucky.name + "!")
				resolver.battle_log.add_effect(lucky.name, lucky.team, "Коло пекельного вогню (2 ходи)")
		return

	# Союзник помер → живий Оцій зменшує КД скіла з найбільшим поточним КД на 2
	var otsii_ward = null
	for w in team_side:
		if w.ward_id == "otsii" and not w.is_dead:
			otsii_ward = w
			break
	if otsii_ward == null:
		return

	var alive_wards: Array = team_side.filter(func(w): return not w.is_dead)
	var cd_skills: Array = []
	for w in alive_wards:
		for sk in ["Q", "W", "E"]:
			var cd_val: int = w._current_cd.get(sk, 0)
			if cd_val > 0:
				cd_skills.append({"ward": w, "skill": sk, "cd": cd_val})

	if cd_skills.is_empty():
		if resolver.battle_log:
			resolver.battle_log.add_entry("Оцій (пасивна): немає скілів на КД.")
		return

	var chosen = cd_skills[randi() % cd_skills.size()]
	var new_cd: int = max(0, chosen.cd - 2)
	chosen.ward._current_cd[chosen.skill] = new_cd
	chosen.ward._sync_cd_buttons()
	if resolver.battle_log:
		resolver.battle_log.add_entry(
			"Оцій (пасивна): %s скіл %s — КД -2 (залишок: %d)" % [chosen.ward.name, chosen.skill, new_cd]
		)
		resolver.battle_log.add_effect(chosen.ward.name, chosen.ward.team, "КД %s -2 (=Оцій)" % chosen.skill)


# =============================================================================
# SIOMYI (Сьомий слуга)
# =============================================================================
# P — З пилу жару: на початку ходу — 2 стаки горіння рандомному варду (в battle_scene).
# Q — Покарання: ворог → +N стаків горіння (N=поточні стаки); союзник → -N стаків.
# W — Бар'єр (КД 3): союзник отримує "barrier" (2 ходи, 30 HP щит). Логіка в battle_resolver.
# E — Вогонь сьомого (КД 7): якщо >5 горіння → конвертує кожні 5 стаків у 1 "fire_seventh".

static func _execute_siomyi(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			var total_burn: int = target.get_status("burning")
			if total_burn <= 0:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Покарання: %s не має стаків горіння." % target.name)
				return
			if target.team != attacker.team:
				target.extend_burning(1)
				if resolver.battle_log:
					resolver.battle_log.add_entry("Покарання: %s — тривалість всіх стаків горіння +1 хід! (стаків: %d)" % [target.name, total_burn])
					resolver.battle_log.add_effect(target.name, target.team, "Горіння: тривалість +1 хід (%d стаків)" % total_burn)
			else:
				target.reduce_burning_turns(1)
				if resolver.battle_log:
					resolver.battle_log.add_entry("Покарання: %s — тривалість всіх стаків горіння -1 хід! (стаків: %d)" % [target.name, total_burn])
					resolver.battle_log.add_effect(target.name, target.team, "Горіння: тривалість -1 хід (%d стаків)" % total_burn)

		"W":
			if target == null: target = attacker
			target.add_status("barrier", 2)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Бар'єр: %s захищений щитом (30 HP, 2 ходи)!" % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Бар'єр (2 ходи, 30 HP)")

		"E":
			if target == null: return
			var burn_total: int = target.get_status("burning")
			if burn_total < 5:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Вогонь сьомого: потрібно мінімум 5 стаків горіння! (зараз: %d)" % burn_total)
				return
			# Активуємо всі стаки горіння — вони завдають урону і зникають
			var burn_dmg: int = target.activate_all_burning()
			if resolver.battle_log:
				resolver.battle_log.add_entry(
					"Вогонь сьомого: активує %d стаків горіння — %d вогняного урону!" % [burn_total, burn_dmg]
				)
			if burn_dmg > 0:
				await resolver.deal_damage_with_modifiers(attacker, target, burn_dmg, "E_burning", "fire")
			if target.is_dead: return
			# Накладаємо Вогонь сьомого (1 стек на кожні 5 горінь)
			var vos: int = burn_total / 5
			target.add_status("fire_seventh", vos)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry(
					"Вогонь сьомого: %s позначений! +%d стак(и) — вся команда ворога горітиме!" % [target.name, vos]
				)
				resolver.battle_log.add_effect(target.name, target.team, "Вогонь сьомого (%d стак(и))" % vos)


# =============================================================================
# ZHNETS (Жнець)
# =============================================================================
# P — Присутність: коли ворог перетинає поріг 50% HP — 1 горіння (2 ходи) двом рандомним ворогам.
#     Логіка в battle_resolver._check_zhnets_passive.
# Q — Прокляття жнеця: 20 вогню по всіх + 1 горіння (2 ходи) кожному.
# W — Маска горгони (КД 4): 3 горіння (2 ходи) на ціль.
# E — Жнива (КД 3): позначає ціль "Жнивою". На початку НАСТУПНОГО ходу Жнеця:
#     активує всі стаки горіння (count×turns×50) + 80 фіз.

static func _execute_zhnets(resolver, attacker, target, skill_key: String) -> void:
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards

	match skill_key:
		"Q":
			for enemy in resolver.get_alive_wards(enemy_side):
				await resolver.deal_damage_with_modifiers(attacker, enemy, 20, skill_key, "fire", true)
				if not enemy.is_dead:
					enemy.add_burning(1, 2)
					if resolver.battle_log:
						resolver.battle_log.add_effect(enemy.name, enemy.team, "Горіння +1 стак (2 ходи)")
			if resolver.battle_log:
				resolver.battle_log.add_entry("Прокляття жнеця: всі вороги — 20 вогню + 1 горіння (2 ходи)!")

		"W":
			if target == null: return
			target.add_burning(3, 2)
			if resolver.battle_log:
				resolver.battle_log.add_entry("Маска горгони: %s — 3 стаки горіння (2 ходи)!" % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Горіння (3 стаки, 2 ходи)")

		"E":
			if target == null: return
			if attacker.has_meta("zhnets_e_target"):
				if resolver.battle_log:
					resolver.battle_log.add_entry("Жнива вже активна — дочекайся наступного ходу!")
				return
			target.add_status("reaping", 1)
			target._update_status_visuals()
			attacker.set_meta("zhnets_e_target", target)
			attacker.set_meta("zhnets_e_just_used", true)
			if resolver.battle_log:
				resolver.battle_log.add_entry("Жнива: %s позначений! Атака в кінці наступного ходу Жнеця." % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Жнива (наступний хід Жнеця)")


# =============================================================================
# PARASYT (Паразит)
# =============================================================================
# P — Паразитування: при смерті ворога хілиться на 75 HP (в battle_resolver).
# Q — Укол: 75 фіз шкоди.
# W — Асиміляція (КД 2): -35 самошкоди + накладає "parasitism" ворогу (1 хід).
#     На початку ходу ворога він б'є випадкового союзника випадковим single_enemy скілом.
# E — Плач чаші (КД 2): -195 самошкоди + Регенерація 3 ходи (100 HP/хід).

static func _execute_parasyt(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 75, skill_key, "phys")

		"W":
			if target == null: return
			if resolver.battle_log:
				resolver.battle_log.add_entry("Асиміляція: %s вплітається у %s (-35 HP собі)!" % [attacker.name, target.name])
			await resolver.deal_damage_with_modifiers(null, attacker, 35, "self_damage", "phys")
			if attacker.is_dead: return
			target.add_status("parasitism", 1)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_effect(target.name, target.team, "Паразитування (1 хід)")

		"E":
			if resolver.battle_log:
				resolver.battle_log.add_entry("Плач чаші: %s жертвує 195 HP — набирається сил!" % attacker.name)
			await resolver.deal_damage_with_modifiers(null, attacker, 195, "self_damage", "phys")
			if attacker.is_dead: return
			attacker.add_status("regen", 3)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Регенерація (3 ходи, 100 HP/хід)")


# =============================================================================
# ADONEIA (Адонея)
# =============================================================================
# P — Відповідь: при падінні нижче 50% HP — +1 стак Контратаки (в battle_resolver).
# Q — Пролом: 2×30 фіз; Голем-Q: 60 фіз по всіх ворогах.
# W — Майстер кулачного бою: 40 фіз + провокація + контратака на себе;
#     Голем-W: 3×35 фіз по рандомних + провокація кожному.
# E — Форма Голема: не витрачає хід, макс/поточне HP +100, 2 ходи (хід E рахується).
#     Змінює Q/W. Після завершення: HP-реверт + оглушення 2.

static func _execute_adoneia(resolver, attacker, target, skill_key: String) -> void:
	var in_golem: bool = attacker.has_meta("golem_form")
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards

	match skill_key:
		"Q":
			if in_golem:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Пролом (Голем): %s дробить усіх ворогів! (60 фіз)" % attacker.name)
				for enemy in resolver.get_alive_wards(enemy_side):
					await resolver.deal_damage_with_modifiers(attacker, enemy, 60, skill_key, "phys", true)
			else:
				if target == null: return
				if resolver.battle_log:
					resolver.battle_log.add_entry("Пролом: %s б'є двічі по 30!" % attacker.name)
				await resolver.deal_damage_with_modifiers(attacker, target, 30, skill_key, "phys")
				if not target.is_dead:
					await resolver.deal_damage_with_modifiers(attacker, target, 30, skill_key, "phys")

		"W":
			if in_golem:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Гром кулаків (Голем): %s завдає 3 удари по рандомних цілях!" % attacker.name)
				var taunted_set: Dictionary = {}
				for i in 3:
					var alive: Array = resolver.get_alive_wards(enemy_side)
					if alive.is_empty(): break
					var t = alive[randi() % alive.size()]
					await resolver.deal_damage_with_modifiers(attacker, t, 35, skill_key, "phys", true)
					if not t.is_dead:
						taunted_set[t] = true
				for t in taunted_set.keys():
					if not t.is_dead:
						t.add_status("taunt", 1)
						t.taunted_by = attacker.ward_id
						t._update_status_visuals()
						if resolver.battle_log:
							resolver.battle_log.add_effect(t.name, t.team, "Провокація (Голем Адонеї)")
				if resolver.battle_log and not taunted_set.is_empty():
					resolver.battle_log.add_entry("Гром кулаків: поранені вороги спровоковані!")
			else:
				if target == null: return
				await resolver.deal_damage_with_modifiers(attacker, target, 40, skill_key, "phys")
				if not target.is_dead:
					target.add_status("taunt", 1)
					target.taunted_by = attacker.ward_id
					target._update_status_visuals()
					if resolver.battle_log:
						resolver.battle_log.add_entry("Майстер кулачного бою: %s спровокований!" % target.name)
						resolver.battle_log.add_effect(target.name, target.team, "Провокація (1 хід)")
				attacker.set_status_max("counterattack", 2)
				attacker._update_status_visuals()
				if resolver.battle_log:
					var ca_turns: int = attacker.get_status("counterattack")
					resolver.battle_log.add_entry("Контратака: %s готова відповісти — діє %d ход(и)!" % [attacker.name, ca_turns])
					resolver.battle_log.add_effect(attacker.name, attacker.team, "Контратака %d ход(и)" % ca_turns)

		"E":
			var hp_was: int = attacker.current_hp
			var max_was: int = attacker.max_hp
			attacker.set_meta("golem_base_max_hp", attacker.max_hp)
			attacker.set_meta("golem_form", 2)
			attacker.max_hp += 100
			attacker.current_hp += 100
			if attacker.get("health") != null:
				attacker.health.setup(attacker.max_hp, attacker.current_hp, attacker.hp_bar)
			if resolver.battle_log:
				resolver.battle_log.add_entry("⚙ Форма Голема! %s перетворюється на Кам'яного Голема!" % attacker.name)
				resolver.battle_log.add_entry("HP: %d → %d | Макс. HP: %d → %d" % [hp_was, attacker.current_hp, max_was, attacker.max_hp])
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Форма Голема (2 ходи, +100 HP)")


# =============================================================================
# FIZITA (Фізіта)
# =============================================================================
# P — Тяжіння: старт бою +2 стаки (одноразово); початок ходу +2/+3/+4…  стаки (cap=4+2×раунд).
# Q — Шквал: витрачає всі стаки, 40 фіз за кожен стак.
# W — Стіна (КД 1): союзник (не себе) отримує стіну HP=40×стаки; поглинає всі удари.
# E — Сметіння: 70 фіз; ціль отримує Сметіння (12×стаки)% шанс промаху свого скіла.

static func _execute_fizita(resolver, attacker, target, skill_key: String) -> void:
	var stacks: int = attacker.get_status("gravity")

	match skill_key:
		"Q":
			if stacks <= 0:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Шквал: немає стаків Тяжіння!")
				return
			if target == null: return
			var q_dmg: int = 40 * stacks
			attacker.remove_status("gravity", stacks)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Шквал: %s випускає %d стак(и) — %d фіз шкоди!" % [attacker.name, stacks, q_dmg])
			await resolver.deal_damage_with_modifiers(attacker, target, q_dmg, skill_key, "phys")

		"W":
			if target == null: return
			if stacks <= 0:
				if resolver.battle_log:
					resolver.battle_log.add_entry("Стіна: немає стаків Тяжіння!")
				return
			var wall_hp: int = 40 * stacks
			attacker.remove_status("gravity", stacks)
			attacker._update_status_visuals()
			target.add_status("phisita_wall", wall_hp)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Стіна: %s захищений кам'яною стіною (%d HP)!" % [target.name, wall_hp])
				resolver.battle_log.add_effect(target.name, target.team, "Кам'яна стіна (%d HP)" % wall_hp)

		"E":
			if target == null: return
			var e_chance: int = 12 * stacks
			attacker.remove_status("gravity", stacks)
			attacker._update_status_visuals()
			await resolver.deal_damage_with_modifiers(attacker, target, 70, skill_key, "phys")
			if not target.is_dead and stacks > 0:
				target.add_status("phisita_e", 1)
				target.set_meta("phisita_e_chance", e_chance)
				target._update_status_visuals()
				if resolver.battle_log:
					resolver.battle_log.add_entry("Сметіння: %s тепер має %d%% шанс промаху свого скіла!" % [target.name, e_chance])
					resolver.battle_log.add_effect(target.name, target.team, "Сметіння (%d%%)" % e_chance)


# =============================================================================
# SHUSIMA (Шусіма)
# =============================================================================
# P — Розсипання: 90 фіз шкоди собі на початку ходу (у battle_scene.gd).
# Q — Висушення: 40 фіз ворогу + реген 20 HP/хід на 2 ходи собі.
# W — Зибучі піски: 150 фіз ВСІМ вардам (союзники+вороги+себе); виживші союзники реген 70 HP/хід на 2 ходи.
# E — Розпад (КД 3): рандомному ворогу фіз шкода рівна поточному HP Шусіми.

static func _execute_shusima(resolver, attacker, target, skill_key: String) -> void:
	var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
	var ally_side: Array  = resolver.battle_scene.ally_wards  if attacker.team == "ally" else resolver.battle_scene.enemy_wards

	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 40, skill_key, "phys")
			if attacker.is_dead: return
			var prev_regen_q: int = attacker.get_meta("regen_amount", 0) if attacker.has_meta("regen_amount") else 0
			attacker.add_status("regen", 2)
			attacker.set_meta("regen_amount", max(prev_regen_q, 20))
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_entry("Висушення: %s відновлює сили — реген 20 HP/хід на 2 ходи." % attacker.name)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Регенерація 20 HP (2 ходи)")

		"W":
			if resolver.battle_log:
				resolver.battle_log.add_entry("Зибучі піски: %s атакує всіх вардів — 150 фіз кожному!" % attacker.name)
			var all_wards: Array = resolver.battle_scene.ally_wards + resolver.battle_scene.enemy_wards
			for w in all_wards:
				if not w.is_dead:
					await resolver.deal_damage_with_modifiers(attacker, w, 150, skill_key, "phys", true)
			var alive_allies: Array = resolver.get_alive_wards(ally_side)
			var regen_count: int = 0
			for ally in alive_allies:
				var prev_regen_w: int = ally.get_meta("regen_amount", 0) if ally.has_meta("regen_amount") else 0
				ally.add_status("regen", 2)
				ally.set_meta("regen_amount", max(prev_regen_w, 70))
				ally._update_status_visuals()
				resolver.battle_log.add_effect(ally.name, ally.team, "Регенерація 70 HP (2 ходи)")
				regen_count += 1
			if resolver.battle_log and regen_count > 0:
				resolver.battle_log.add_entry("Зибучі піски: %d союзник(ів) отримали реген 70 HP/хід на 2 ходи." % regen_count)

		"E":
			var alive_enemies: Array = resolver.get_alive_wards(enemy_side)
			if alive_enemies.is_empty(): return
			var e_target = alive_enemies[randi() % alive_enemies.size()]
			var e_dmg: int = attacker.current_hp
			if resolver.battle_log:
				resolver.battle_log.add_entry("Розпад: %s концентрує %d HP → завдає %d фіз шкоди %s!" % [attacker.name, e_dmg, e_dmg, e_target.name])
			await resolver.deal_damage_with_modifiers(attacker, e_target, e_dmg, skill_key, "phys")
