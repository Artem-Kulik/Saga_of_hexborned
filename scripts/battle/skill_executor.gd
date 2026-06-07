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
			if skill_key == "W": return "single_any"
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
			if skill_key == "W": return "single_any"
		"shusima":
			if skill_key == "W": return "self"
			if skill_key == "E": return "self"
		"asteyah":
			if skill_key == "W": return "self"
			if skill_key == "E":
				if attacker != null and attacker.has_meta("asteyah_memory"):
					var mem: Dictionary = attacker.get_meta("asteyah_memory")
					return get_skill_target_type(mem.get("ward_id", ""), mem.get("skill_key", "Q"), attacker)
				return "single_enemy"
		"velodiy":
			if skill_key == "W": return "self"
			if skill_key == "E": return "self"
		"ashayah":
			if skill_key == "W": return "all_enemies"
			if skill_key == "E":
				if attacker != null and attacker.has_meta("ashayah_e_used"):
					return "all_enemies"
				return "single_enemy"
		"infected_1_a", "infected_1_b", "infected_1_c":
			if skill_key == "W": return "single_enemy"
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
		"asteyah":
			await _execute_asteyah(resolver, attacker, target, skill_key)
		"velodiy":
			await _execute_velodiy(resolver, attacker, target, skill_key)
		"ashayah":
			await _execute_ashayah(resolver, attacker, target, skill_key)
		"infected_1_a", "infected_1_b", "infected_1_c":
			await _execute_infected_1(resolver, attacker, target, skill_key)
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
				resolver.battle_log.add_info("Течія: додатковий водяний удар!")
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
				resolver.battle_log.add_info("Кола на воді: ефект спрацював повторно!")
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
			target = attacker  # E завжди на себе
			resolver.battle_log.add_info("Лія активує Загороджуючий водопад!")
			attacker.set_meta("untargetable", true)
			attacker.modulate.a = 0.5 # Трішки прозора
			
			if resolver.battle_log:
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Загороджуючий водопад (невидимість)")


# Пасивка Лії: лікування при вбивстві
static func check_liah_passive(resolver, attacker, target_died: bool) -> void:
	if attacker == null: return
	if attacker.ward_id == "liah" and target_died:
		var allies = resolver.get_alive_wards(resolver.battle_scene.ally_wards if attacker.team == "ally" else resolver.battle_scene.enemy_wards)
		resolver.battle_log.add_info("💚 Спокій: Лія лікує союзників +50 HP!", Color("#40b050"))
		resolver.battle_log.add_effect(attacker.name, attacker.team, "Спокій (пасивка)")
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
	resolver.battle_log.add_info("🔥 Раж: %s отримує стак Ражу (разом: %d)!" % [target.name, target.get_status("rage")])
	resolver.battle_log.add_effect(target.name, target.team, "Раж +1 (пасивка)")

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
				resolver.battle_log.add_info("Додаткова шкода від Ражу: " + str(fire_damage) + " (вогонь)")
				await resolver.deal_damage_with_modifiers(attacker, target, fire_damage, "Q_rage", "fire")
			
			if rage_stacks > 0:
				attacker.remove_status("rage", rage_stacks)
				resolver.battle_log.add_info("Стаки Ражу скинуто.")
				
		"W":
			# Жар: Накладає на себе щит з ВОГНЮ, котрий дає 30 броні.
			attacker.health.add_armor(30)
			attacker.set_meta("fire_shield", true)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info(
					"Жар: +30 броні (разом: %d). Вогняний щит активний!" % attacker.health.current_armor
				)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Вогняний щит + Броня +30 (разом: %d)" % attacker.health.current_armor)
				
		"E":
			# Чесний бій: Провокує ціль на 1 хід. Збільшує свою броню на 100.
			if target == null: return
			resolver.battle_log.add_info("Майстер Оічі провокує ворога і отримує +100 броні!")
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
				resolver.battle_log.add_info("Шопей: наступна здібність гарантовано викличе Відсічену Гідру!")
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
		resolver.battle_log.add_info("Відсічена Голова Гідри атакує " + hydra_target.name + "!")
	await resolver.deal_damage_with_modifiers(attacker, hydra_target, 45, "P", "air")


# Пасивка: 37% шанс тригернути гідру після кожного скіла.
static func _shopey_passive_check(resolver, attacker, attacked_target) -> void:
	if randf() >= 0.37:
		return
	var hydra_target = _shopey_get_other_enemy(resolver, attacker, attacked_target)
	if hydra_target == null:
		return
	if resolver.battle_log:
		resolver.battle_log.add_info("🐍 Відсічена Гідра (пасивка): атакує %s — 45 повітря!" % hydra_target.name)
		resolver.battle_log.add_effect(attacker.name, attacker.team, "Відсічена Гідра (пасивка)")
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
					resolver.battle_log.add_info(target.name + " оглушений на 1 хід!")
					resolver.battle_log.add_effect(target.name, target.team, "Оглушення (1 хід)")

		"E":
			# Вибух породи: (25 + поточна броня) фіз по всіх, після — броня Грумпа → 0
			var armor: int = attacker.health.current_armor
			var total_damage: int = 25 + armor
			if resolver.battle_log:
				resolver.battle_log.add_info(
					"Вибух породи: %d пошкоджень (25 + %d броні) по всіх!" % [total_damage, armor]
				)
			for enemy in resolver.get_alive_wards(enemy_side):
				await resolver.deal_damage_with_modifiers(attacker, enemy, total_damage, skill_key, "phys", true)
			attacker.health.current_armor = 0
			attacker.update_armor_status(0)
			if resolver.battle_log:
				resolver.battle_log.add_info("Броня Грумпа скинута до 0.")

	# Пасивка: +25 броні наприкінці кожного ходу
	_grump_end_of_turn_passive(resolver, attacker)


static func _grump_end_of_turn_passive(resolver, attacker) -> void:
	attacker.health.add_armor(25)
	attacker.update_armor_status(attacker.health.current_armor)
	if resolver.battle_log:
		resolver.battle_log.add_info(
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
					resolver.battle_log.add_info("Стиль Доломедес: три удари по цілі!")
				for i in 3:
					if target.is_dead: break
					await resolver.deal_damage_with_modifiers(attacker, target, 45, skill_key, "water")
			elif last == "E":
				if resolver.battle_log:
					resolver.battle_log.add_info("Стиль Доломедес: удар по всіх ворогах!")
				var enemy_side: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
				for enemy in resolver.get_alive_wards(enemy_side):
					await resolver.deal_damage_with_modifiers(attacker, enemy, 60, skill_key, "water", true)
			else:
				if resolver.battle_log:
					resolver.battle_log.add_info("Стиль Доломедес: потрібно спочатку використати Q або E!")
			attacker.set_meta("riker_w_last_variant", last)
			attacker.set_meta("riker_last_skill", "W")

		"E":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 60, skill_key, "water")
			var neighbor = _riker_get_neighbor(resolver, attacker, target)
			if neighbor != null and not neighbor.is_dead:
				if resolver.battle_log:
					resolver.battle_log.add_info("Кігті: б'є сусідній варт — %s!" % neighbor.name)
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
		resolver.battle_log.add_info(
			"Тисяча Порізів: %d стак(и) → скіл +%d" % [stacks, 10 * stacks]
		)

	# Основний удар скіла
	await resolver.deal_damage_with_modifiers(attacker, target, skill_dmg, skill_key, "air", is_aoe)

	if target.is_dead:
		return

	# Пасивний удар — 20 повітря (Тисяча порізів)
	if resolver.battle_log:
		resolver.battle_log.add_info("✂ Тисяча порізів (пасивка): 20 повітря по %s!" % target.name)
		resolver.battle_log.add_effect(attacker.name, attacker.team, "Тисяча порізів (пасивка)")
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
			# Стан для 2-ї цілі застосовуємо ДО атак — щоб пасивка з 1-ї не вбила ціль раніше
			if targets.size() >= 2:
				var _stun_t = targets[1]
				if _stun_t != null and is_instance_valid(_stun_t) and not _stun_t.is_dead:
					_stun_t.add_status("stun", 1)
					if resolver.battle_log:
						resolver.battle_log.add_info(_stun_t.name + " оглушений!")
						resolver.battle_log.add_effect(_stun_t.name, _stun_t.team, "Оглушення (1 хід)")
			for i in targets.size():
				var t = targets[i]
				if t == null or not is_instance_valid(t) or t.is_dead:
					continue
				match i:
					0:
						await resolver.deal_damage_with_modifiers(attacker, t, 35, skill_key, "phys")
						await _etesena_passive_check(resolver, attacker, t, 35, enemy_side)
					1:
						pass  # стан вже застосовано вище
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
					resolver.battle_log.add_info("Північні вітри: оглушення продовжено +1 хід!")


# Пасивка: 33% шанс пробити оглушену ціль і нанести таку ж шкоду сусідній.
static func _etesena_passive_check(resolver, attacker, target, damage: int, enemy_side: Array) -> void:
	if target.is_dead: return
	if target.get_status("stun") <= 0: return
	if randf() >= 0.33: return
	var neighbor = _etesena_get_neighbor(enemy_side, target)
	if neighbor == null or neighbor.is_dead: return
	if resolver.battle_log:
		resolver.battle_log.add_info("💨 Пасивка: голка пробиває оглушеного %s — б'є %s!" % [target.name, neighbor.name])
		resolver.battle_log.add_effect(attacker.name, attacker.team, "Пробивання (пасивка)")
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
				resolver.battle_log.add_info("Вигорання: " + t.name + " отримує 1 стак горіння!")
				resolver.battle_log.add_effect(t.name, t.team, "Горіння (1 стак)")

		"W":
			if target == null: target = attacker
			target.remove_negative_effects()
			target.add_status("fire_circle", 2)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info("Коло пекельного вогню: %s очищений і захищений на 2 ходи!" % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Коло пекельного вогню (2 ходи)")

		"E":
			if target == null: return
			target.add_status("burning", 1)
			target._update_status_visuals()
			var ally_side: Array = resolver.battle_scene.ally_wards if attacker.team == "ally" else resolver.battle_scene.enemy_wards
			var alive_allies: Array = resolver.get_alive_wards(ally_side).filter(func(w): return w != attacker)
			if alive_allies.is_empty():
				if resolver.battle_log:
					resolver.battle_log.add_info("Рик: %s +1 горіння (союзників немає)." % target.name)
			else:
				var ally_helper = alive_allies[randi() % alive_allies.size()]
				var hp_before_e: int = target.current_hp if is_instance_valid(target) else 0
				if resolver.battle_log:
					resolver.battle_log.add_info("Рик: %s +1 горіння. %s атакує разом з Оцієм → %s!" % [target.name, ally_helper.name, target.name])
				await execute_skill(resolver, ally_helper, target, "Q")
				if resolver.battle_log and is_instance_valid(target):
					var hp_after_e: int = target.current_hp
					resolver.battle_log.add_info("  → %s [Q]: HP %s: %d → %d (%s)" % [
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
				resolver.battle_log.add_info("Оцій: передає Коло пекельного вогню " + lucky.name + "!")
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
			resolver.battle_log.add_info("Оцій (пасивна): немає скілів на КД.")
		return

	var chosen = cd_skills[randi() % cd_skills.size()]
	var new_cd: int = max(0, chosen.cd - 2)
	chosen.ward._current_cd[chosen.skill] = new_cd
	chosen.ward._sync_cd_buttons()
	if resolver.battle_log:
		resolver.battle_log.add_info(
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
					resolver.battle_log.add_info("Покарання: %s не має стаків горіння." % target.name)
				return
			if target.team != attacker.team:
				target.extend_burning(1)
				if resolver.battle_log:
					resolver.battle_log.add_info("Покарання: %s — тривалість всіх стаків горіння +1 хід! (стаків: %d)" % [target.name, total_burn])
					resolver.battle_log.add_effect(target.name, target.team, "Горіння: тривалість +1 хід (%d стаків)" % total_burn)
			else:
				target.reduce_burning_turns(1)
				if resolver.battle_log:
					resolver.battle_log.add_info("Покарання: %s — тривалість всіх стаків горіння -1 хід! (стаків: %d)" % [target.name, total_burn])
					resolver.battle_log.add_effect(target.name, target.team, "Горіння: тривалість -1 хід (%d стаків)" % total_burn)

		"W":
			if target == null: target = attacker
			target.add_status("barrier", 2)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info("Бар'єр: %s захищений щитом (30 HP, 2 ходи)!" % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Бар'єр (2 ходи, 30 HP)")

		"E":
			if target == null: return
			var burn_total: int = target.get_status("burning")
			if burn_total < 5:
				if resolver.battle_log:
					resolver.battle_log.add_info("Вогонь сьомого: потрібно мінімум 5 стаків горіння! (зараз: %d)" % burn_total)
				return
			# Активуємо всі стаки горіння — вони завдають урону і зникають
			var burn_dmg: int = target.activate_all_burning()
			if resolver.battle_log:
				resolver.battle_log.add_info(
					"Вогонь сьомого: активує %d стаків горіння — %d вогняного урону!" % [burn_total, burn_dmg]
				)
			if burn_dmg > 0:
				await resolver.deal_damage_with_modifiers(attacker, target, burn_dmg, "E_burning", "fire")
			if target.is_dead: return
			# Накладаємо Вогонь сьомого (1 стек на кожні 5 горінь)
			var vos: int = int(burn_total / 5.0)
			target.add_status("fire_seventh", vos)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info(
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
				resolver.battle_log.add_info("Прокляття жнеця: всі вороги — 20 вогню + 1 горіння (2 ходи)!")

		"W":
			if target == null: return
			target.add_burning(3, 2)
			if resolver.battle_log:
				resolver.battle_log.add_info("Маска горгони: %s — 3 стаки горіння (2 ходи)!" % target.name)
				resolver.battle_log.add_effect(target.name, target.team, "Горіння (3 стаки, 2 ходи)")

		"E":
			if target == null: return
			if attacker.has_meta("zhnets_e_target"):
				if resolver.battle_log:
					resolver.battle_log.add_info("Жнива вже активна — дочекайся наступного ходу!")
				return
			target.add_status("reaping", 1)
			target._update_status_visuals()
			attacker.set_meta("zhnets_e_target", target)
			attacker.set_meta("zhnets_e_just_used", true)
			if resolver.battle_log:
				resolver.battle_log.add_info("Жнива: %s позначений! Атака в кінці наступного ходу Жнеця." % target.name)
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
				resolver.battle_log.add_info("Асиміляція: %s вплітається у %s (-35 HP собі)!" % [attacker.name, target.name])
			await resolver.deal_damage_with_modifiers(null, attacker, 35, "self_damage", "phys")
			if attacker.is_dead: return
			target.add_status("parasitism", 1)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_effect(target.name, target.team, "Паразитування (1 хід)")

		"E":
			if resolver.battle_log:
				resolver.battle_log.add_info("Плач чаші: %s жертвує 195 HP — набирається сил!" % attacker.name)
			await resolver.deal_damage_with_modifiers(null, attacker, 195, "self_damage", "phys")
			if attacker.is_dead: return
			attacker.add_regen(2, 3)
			if resolver.battle_log:
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Реген ×2 (3 ходи, +100 HP/хід)")


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
					resolver.battle_log.add_info("Пролом (Голем): %s дробить усіх ворогів! (60 фіз)" % attacker.name)
				for enemy in resolver.get_alive_wards(enemy_side):
					await resolver.deal_damage_with_modifiers(attacker, enemy, 60, skill_key, "phys", true)
			else:
				if target == null: return
				if resolver.battle_log:
					resolver.battle_log.add_info("Пролом: %s б'є двічі по 30!" % attacker.name)
				await resolver.deal_damage_with_modifiers(attacker, target, 30, skill_key, "phys")
				if not target.is_dead:
					await resolver.deal_damage_with_modifiers(attacker, target, 30, skill_key, "phys")

		"W":
			if in_golem:
				if resolver.battle_log:
					resolver.battle_log.add_info("Майстер громадних кулаків (Голем): %s завдає 2 удари по рандомних цілях!" % attacker.name)
				var taunted_set: Dictionary = {}
				for _i in 2:
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
							resolver.battle_log.add_effect(t.name, t.team, "Провокація (1 хід)")
				if resolver.battle_log and not taunted_set.is_empty():
					resolver.battle_log.add_info("Майстер громадних кулаків: поранені вороги спровоковані!")
			else:
				if target == null: return
				await resolver.deal_damage_with_modifiers(attacker, target, 40, skill_key, "phys")
				if not target.is_dead:
					target.add_status("taunt", 1)
					target.taunted_by = attacker.ward_id
					target._update_status_visuals()
					if resolver.battle_log:
						resolver.battle_log.add_info("Майстер кулачного бою: %s спровокований!" % target.name)
						resolver.battle_log.add_effect(target.name, target.team, "Провокація (1 хід)")
				var _ca_old_w: int = attacker.get_status("counterattack")
				var _ca_new_w: int = max(_ca_old_w, 1)
				if _ca_old_w > 0:
					attacker.remove_status("counterattack", _ca_old_w)
				attacker.add_status("counterattack", _ca_new_w)
				attacker._update_status_visuals()
				if resolver.battle_log:
					resolver.battle_log.add_info("Контратака: %s готова відповісти — діє %d хід!" % [attacker.name, _ca_new_w])
					resolver.battle_log.add_effect(attacker.name, attacker.team, "Контратака %d хід" % _ca_new_w)

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
				resolver.battle_log.add_info("⚙ Форма Голема! %s перетворюється на Кам'яного Голема!" % attacker.name)
				resolver.battle_log.add_info("HP: %d → %d | Макс. HP: %d → %d" % [hp_was, attacker.current_hp, max_was, attacker.max_hp])
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
					resolver.battle_log.add_info("Шквал: немає стаків Тяжіння!")
				return
			if target == null: return
			var q_dmg: int = 40 * stacks
			attacker.remove_status("gravity", stacks)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info("Шквал: %s випускає %d стак(и) — %d фіз шкоди!" % [attacker.name, stacks, q_dmg])
			await resolver.deal_damage_with_modifiers(attacker, target, q_dmg, skill_key, "phys")

		"W":
			if target == null: return
			if stacks <= 0:
				if resolver.battle_log:
					resolver.battle_log.add_info("Стіна: немає стаків Тяжіння!")
				return
			var wall_hp: int = 40 * stacks
			attacker.remove_status("gravity", stacks)
			attacker._update_status_visuals()
			target.add_status("phisita_wall", wall_hp)
			target._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info("Стіна: %s захищений кам'яною стіною (%d HP)!" % [target.name, wall_hp])
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
					resolver.battle_log.add_info("Сметіння: %s тепер має %d%% шанс промаху свого скіла!" % [target.name, e_chance])
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
			attacker.add_regen(1, 1)
			if resolver.battle_log:
				resolver.battle_log.add_info("Висушення: %s відновлює сили — 1 стак регену на 1 хід (+50 HP)." % attacker.name)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Реген ×1 (1 хід)")

		"W":
			if resolver.battle_log:
				resolver.battle_log.add_info("Зибучі піски: %s атакує всіх вардів — 150 фіз кожному!" % attacker.name)
			var all_wards: Array = resolver.battle_scene.ally_wards + resolver.battle_scene.enemy_wards
			for w in all_wards:
				if not w.is_dead:
					await resolver.deal_damage_with_modifiers(attacker, w, 150, skill_key, "phys", true)
			var alive_allies: Array = resolver.get_alive_wards(ally_side)
			var regen_count: int = 0
			for ally in alive_allies:
				ally.add_regen(2, 2)
				resolver.battle_log.add_effect(ally.name, ally.team, "Реген ×2 (2 ходи, +100 HP/хід)")
				regen_count += 1
			if resolver.battle_log and regen_count > 0:
				resolver.battle_log.add_info("Зибучі піски: %d союзник(ів) — 2 стаки регену на 2 ходи." % regen_count)

		"E":
			var alive_enemies: Array = resolver.get_alive_wards(enemy_side)
			if alive_enemies.is_empty(): return
			var e_target = alive_enemies[randi() % alive_enemies.size()]
			var e_dmg: int = attacker.current_hp
			if resolver.battle_log:
				resolver.battle_log.add_info("Розпад: %s концентрує %d HP → завдає %d фіз шкоди %s!" % [attacker.name, e_dmg, e_dmg, e_target.name])
			await resolver.deal_damage_with_modifiers(attacker, e_target, e_dmg, skill_key, "phys")


# =============================================================================
# ASTEYAH (Астея)
# =============================================================================
# P — Пам'ять: запам'ятовує останній Q/W/E ворога → записується в meta
#     (реалізовано в battle_resolver._check_asteyah_memory).
# Q — Кенсел: 35 вода + рандомний скіл цілі +1 КД.
# W — Таємні знання (CD 6): +2 реген (100 HP/хід). Ходить ще раз (battle_scene).
# E — Пам'ять: виконує запам'ятаний скіл ворога з Астеєю як атакером.

static func _execute_asteyah(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 35, skill_key, "water")
			if target.is_dead: return
			var cd_skills: Array = ["Q", "W", "E"]
			var chosen_cd: String = cd_skills[randi() % cd_skills.size()]
			var old_cd: int = target._current_cd.get(chosen_cd, 0)
			var new_cd: int = old_cd + 1
			target._current_cd[chosen_cd] = new_cd
			target._sync_cd_buttons()
			if resolver.battle_log:
				resolver.battle_log.add_info("Кенсел: %s відправляє скіл %s [%s] на перезарядку — КД: %d хід(и)!" % [
					attacker.name, chosen_cd, target.name, new_cd
				])
				resolver.battle_log.add_effect(target.name, target.team, "КД %s → %d (Кенсел)" % [chosen_cd, new_cd])

		"W":
			attacker.add_regen(1, 2)
			if resolver.battle_log:
				resolver.battle_log.add_info("Таємні знання: %s — 1 стак регену на 2 ходи (+50 HP/хід)." % attacker.name)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Реген ×1 (2 ходи)")
				resolver.battle_log.add_info("Таємні знання: %s ходить ще раз!" % attacker.name)

		"E":
			if not attacker.has_meta("asteyah_memory"):
				if resolver.battle_log:
					resolver.battle_log.add_info("Пам'ять: %s ще нічого не запам'ятала!" % attacker.name)
				return
			var mem: Dictionary = attacker.get_meta("asteyah_memory")
			var mem_ward_id: String = mem.get("ward_id", "")
			var mem_skill: String  = mem.get("skill_key", "Q")
			if resolver.battle_log:
				resolver.battle_log.add_info("Пам'ять: %s відтворює [%s → %s]!" % [attacker.name, mem_ward_id, mem_skill])
			var _temp_riker_meta: bool = false
			if mem_ward_id == "riker" and mem_skill == "W":
				attacker.set_meta("riker_last_skill", mem.get("riker_last_skill", ""))
				_temp_riker_meta = true
			await _asteyah_execute_memory(resolver, attacker, target, mem_ward_id, mem_skill)
			if _temp_riker_meta and attacker.has_meta("riker_last_skill"):
				attacker.remove_meta("riker_last_skill")


static func _execute_velodiy(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 90, skill_key, "phys")
			# Удар по сусідній цілі: 45 фіз
			var target_side: Array = resolver.battle_scene.ally_wards if target.team == "ally" else resolver.battle_scene.enemy_wards
			var target_pos: int = target_side.find(target)
			var splash_target = null
			if target_pos == 0 or target_pos == 2:
				var center = target_side[1] if target_side.size() > 1 else null
				if center != null and not center.is_dead and center != target:
					splash_target = center
			elif target_pos == 1:
				var candidates: Array = []
				if target_side.size() > 0 and not target_side[0].is_dead and target_side[0] != target:
					candidates.append(target_side[0])
				if target_side.size() > 2 and not target_side[2].is_dead and target_side[2] != target:
					candidates.append(target_side[2])
				if not candidates.is_empty():
					splash_target = candidates.pick_random()
			if splash_target != null:
				if resolver.battle_log:
					resolver.battle_log.add_info("Вода камінь точить: бризки — 45 фіз по %s!" % splash_target.name)
				await resolver.deal_damage_with_modifiers(attacker, splash_target, 45, "Q_splash", "phys", true)

		"W":
			attacker.add_status("counterattack", 2)
			attacker.add_status("phalanx", 2)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_info("Фаланга: %s приймає захисне положення — контратака 2 ходи, вхідна шкода +50%% на 2 ходи." % attacker.name)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Контратака 2 | Фаланга 2")

		"E":
			resolver.battle_scene._activate_oath_of_rain(attacker)
			if resolver.battle_log:
				resolver.battle_log.add_info("Клятва рицаря дощу Арная: %s викликає дощ на 4 раунди!" % attacker.name)
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Клятва дощу 4 раунди")


# =============================================================================
# АШАНА (ashayah)
# =============================================================================
# P — Крилатий трофей: при першому W краде 1 позитивний статус кожного ворога.
# Q — Пікирування: 60 фіз обраній цілі + 60 фіз рандомній іншій.
# W — Східний вітер (КД 5): 30 повітря всім ворогам, знімає 1 позит. статус кожному.
# E — Громовий спис (КД 3): 1-й раз: 150 повітря цілі + 50 іншим + оглушення 2; далі: 50 всім.

static func _execute_ashayah(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 60, skill_key, "phys")
			var enemy_side: Array = resolver.battle_scene.ally_wards if attacker.team == "enemy" else resolver.battle_scene.enemy_wards
			var others: Array = resolver.get_alive_wards(enemy_side).filter(func(w): return w != target)
			if not others.is_empty():
				var second = others[randi() % others.size()]
				if resolver.battle_log:
					resolver.battle_log.add_info("Пікирування: другий удар по %s!" % second.name)
				await resolver.deal_damage_with_modifiers(attacker, second, 60, "Q_second", "phys")

		"W":
			var enemy_side: Array = resolver.battle_scene.ally_wards if attacker.team == "enemy" else resolver.battle_scene.enemy_wards
			var is_first_w: bool = not attacker.has_meta("ashayah_w_first_used")
			for enemy in resolver.get_alive_wards(enemy_side):
				# Зберігаємо перший позитивний статус ДО нанесення шкоди
				var stolen_status: String = _ashayah_first_positive_status(enemy)
				var stolen_count: int = enemy.get_status(stolen_status) if stolen_status != "" else 0
				await resolver.deal_damage_with_modifiers(attacker, enemy, 30, skill_key, "air", true)
				# Знімаємо статус якщо ворог вижив (мертвий — вже чищений при смерті)
				if stolen_status != "" and not enemy.is_dead:
					enemy.remove_status(stolen_status, stolen_count)
					enemy._update_status_visuals()
					if resolver.battle_log:
						resolver.battle_log.add_info("Східний вітер: знято [%s] з %s." % [stolen_status, enemy.name])
				elif stolen_status != "" and resolver.battle_log:
					resolver.battle_log.add_info("Східний вітер: %s загинув — [%s] розсіявся." % [enemy.name, stolen_status])
				# Пасивка P: краде статус при першому W
				if is_first_w and stolen_status != "":
					_ashayah_steal_status(resolver, attacker, enemy, stolen_status, stolen_count)
					if resolver.battle_log:
						resolver.battle_log.add_info("🦅 Крилатий трофей: Ошая краде [%s] у %s!" % [stolen_status, enemy.name])
						resolver.battle_log.add_effect(attacker.name, attacker.team, "Крилатий трофей (пасивка)")
			if is_first_w:
				attacker.set_meta("ashayah_w_first_used", true)

		"E":
			var enemy_side: Array = resolver.battle_scene.ally_wards if attacker.team == "enemy" else resolver.battle_scene.enemy_wards
			if not attacker.has_meta("ashayah_e_used"):
				# Перший раз: 150 основній + 50 іншим + оглушення собі
				if target == null: return
				await resolver.deal_damage_with_modifiers(attacker, target, 150, skill_key, "air")
				for enemy in resolver.get_alive_wards(enemy_side):
					if enemy == target: continue
					await resolver.deal_damage_with_modifiers(attacker, enemy, 50, "E_aoe", "air", true)
				attacker.add_status("stun", 2)
				attacker._update_status_visuals()
				attacker.set_meta("ashayah_e_used", true)
				if resolver.battle_log:
					resolver.battle_log.add_info("Громовий спис: гнів неба обрушено! Ошая оглушена на 2 ходи.")
					resolver.battle_log.add_effect(attacker.name, attacker.team, "Оглушення 2 ходи")
			else:
				# Повторні рази: 50 всім
				if resolver.battle_log:
					resolver.battle_log.add_info("Громовий спис: повторний розряд по всіх ворогах!")
				for enemy in resolver.get_alive_wards(enemy_side):
					await resolver.deal_damage_with_modifiers(attacker, enemy, 50, skill_key, "air", true)


static func _ashayah_first_positive_status(ward) -> String:
	var positive: Array[String] = ["barrier", "counterattack", "regen", "fire_circle",
		"phisita_wall", "velodiy_oath", "phalanx", "prayers_barrier", "rage"]
	for s in positive:
		if ward.get_status(s) > 0:
			return s
	return ""


static func _ashayah_steal_status(resolver, ashayah, source, status: String, _count: int) -> void:
	if status == "velodiy_oath":
		resolver.battle_scene._steal_oath_as_carrier(ashayah, _count)
		return
	if status == "regen":
		# Копіюємо всі групи регену з джерела
		if source != null and source.get("regen_applications") != null:
			for app in source.regen_applications:
				ashayah.add_regen(app.count, app.turns)
		ashayah._update_status_visuals()
		return
	ashayah.add_status(status, _count)
	ashayah._update_status_visuals()


# ─── INFECTED_1 (Заражений — Стадія 1) ─────────────────────────────────────
static func _execute_infected_1(resolver, attacker, target, skill_key: String) -> void:
	match skill_key:
		"Q":
			if target == null: return
			await resolver.deal_damage_with_modifiers(attacker, target, 70, "Q", "light")
			if target.is_dead:
				# Вбиває → +2 КД рандомного скіла (не Q) рандомного живого ворога
				var enemy_team: Array = resolver.battle_scene.ally_wards if attacker.team == "enemy" else resolver.battle_scene.enemy_wards
				var alive: Array = []
				for w in enemy_team:
					if not w.is_dead:
						alive.append(w)
				if not alive.is_empty():
					var lucky = alive[randi() % alive.size()]
					var sk_pool: Array = []
					for sk in ["W", "E"]:
						if lucky._max_cd.get(sk, 0) > 0:
							sk_pool.append(sk)
					if not sk_pool.is_empty():
						var sk: String = sk_pool[randi() % sk_pool.size()]
						lucky._current_cd[sk] = lucky._current_cd.get(sk, 0) + 2
						lucky._sync_cd_buttons()
						resolver.battle_log.add_info("💫 Удар сяйва: КД [%s] %s +2!" % [sk, lucky.name], Color("#e0c040"))
		"W":
			if target == null: return
			target.add_status("plague", 3)
			target._update_status_visuals()
			resolver.battle_log.add_effect(target.name, target.team, "Чума (3 ходи)")
			resolver.battle_log.add_info("☠️ Чума: %s заражений — 15 сяйво щохід, 3 ходи." % target.name, Color("#90d060"))
		"E":
			# Витрачає 50% поточного HP (мін. 1 лишається)
			var hp_cost: int = int(attacker.current_hp / 2.0)
			if hp_cost > 0:
				var new_hp: int = max(1, attacker.current_hp - hp_cost)
				attacker.health.set_hp(new_hp)
				resolver.battle_log.add_info("✨ Спалах: %s витрачає %d HP!" % [attacker.name, hp_cost], Color("#e8e060"))
			# 100 сяйво шкоди всім ворогам
			var enemy_team: Array = resolver.battle_scene.ally_wards if attacker.team == "enemy" else resolver.battle_scene.enemy_wards
			for enemy in enemy_team:
				if not enemy.is_dead:
					await resolver.deal_damage_with_modifiers(attacker, enemy, 100, "E", "light", true)


static func _asteyah_execute_memory(resolver, attacker, target, ward_id: String, skill_key: String) -> void:
	match ward_id:
		"liah":     await _execute_liah(resolver, attacker, target, skill_key, 50)
		"mais_oichi": await _execute_mais_oichi(resolver, attacker, target, skill_key, 50)
		"shopey":   await _execute_shopey(resolver, attacker, target, skill_key, 50)
		"grump":    await _execute_grump(resolver, attacker, target, skill_key, 50)
		"riker":    await _execute_riker(resolver, attacker, target, skill_key)
		"iskoris":  await _execute_iskoris(resolver, attacker, target, skill_key)
		"etesena":  await _execute_etesena(resolver, attacker, target, skill_key)
		"otsii":    await _execute_otsii(resolver, attacker, target, skill_key)
		"siomyi":   await _execute_siomyi(resolver, attacker, target, skill_key)
		"zhnets":   await _execute_zhnets(resolver, attacker, target, skill_key)
		"parasyt":  await _execute_parasyt(resolver, attacker, target, skill_key)
		"adoneia":  await _execute_adoneia(resolver, attacker, target, skill_key)
		"fizita":   await _execute_fizita(resolver, attacker, target, skill_key)
		"shusima":  await _execute_shusima(resolver, attacker, target, skill_key)
		"asteyah":  await _execute_asteyah(resolver, attacker, target, skill_key)
		"velodiy":  await _execute_velodiy(resolver, attacker, target, skill_key)
		"ashayah": await _execute_ashayah(resolver, attacker, target, skill_key)
		"infected_1_a", "infected_1_b", "infected_1_c": await _execute_infected_1(resolver, attacker, target, skill_key)
		_:
			if target != null:
				await resolver.deal_damage_with_modifiers(attacker, target, 50, skill_key)
