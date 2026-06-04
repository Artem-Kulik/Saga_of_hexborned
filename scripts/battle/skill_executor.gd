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
				d2_callable
			)
				
		"W":
			# Кола на воді: Атакує всіх ворогів, наносить 35(вода). Якщо хтось гине — атакує ще раз.
			var enemy_side_w: Array = resolver.battle_scene.enemy_wards if attacker.team == "ally" else resolver.battle_scene.ally_wards
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
			resolver.battle_log.add_entry("Майстер Оічі застосовує Жар: +30 броні")
			attacker.health.add_armor(30)
			attacker.set_meta("fire_shield", true)
			attacker._update_status_visuals()
			if resolver.battle_log:
				resolver.battle_log.add_effect(attacker.name, attacker.team, "Вогняний щит (+30 броні)")
				
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
