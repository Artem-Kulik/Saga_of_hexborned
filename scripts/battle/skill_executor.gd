extends Node

# Визначає, яку ціль потребує скіл:
# "single_enemy" - один клік по ворогу
# "all_enemies" - б'є всіх ворогів одразу (не треба клікати)
# "self" - застосовується на себе (не треба клікати)
static func get_skill_target_type(ward_id: String, skill_key: String) -> String:
	match ward_id:
		"liah":
			if skill_key == "W": return "all_enemies"
			if skill_key == "E": return "self"
		"mais_oichi":
			if skill_key == "W": return "self"
			if skill_key == "E": return "single_enemy" # Taunts a specific enemy
	
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
		_:
			# Стандартна атака для всіх інших поки що
			await _execute_basic_attack(resolver, attacker, target, skill_key, base_damage)


static func _execute_basic_attack(resolver, attacker, target, skill_key: String, base_damage: int) -> void:
	if target == null: return
	await resolver.deal_damage_with_modifiers(attacker, target, base_damage, skill_key)


static func _execute_liah(resolver, attacker, target, skill_key: String, base_damage: int) -> void:
	match skill_key:
		"Q":
			# Течія: Наносить 50(фіз). Якщо ціль мала максимальне HP — атакує ще раз (водяний).
			if target == null: return
			var was_full_hp = (target.current_hp == target.max_hp)
			
			await resolver.deal_damage_with_modifiers(attacker, target, base_damage, skill_key) # phys
			
			if was_full_hp and not target.is_dead:
				resolver.battle_log.add_entry("Течія: додатковий водяний удар!")
				# Передаємо спеціальний флаг чи damage_type
				await resolver.deal_damage_with_modifiers(attacker, target, base_damage, "Q_water_bonus", "water")
				
		"W":
			# Кола на воді: Атакує всіх ворогів, наносить 35(вода). Якщо хтось гине — атакує ще раз.
			var trigger_again = false
			var enemies = resolver.get_alive_wards(resolver.battle_scene.enemy_wards)
			
			for enemy in enemies:
				var hp_before = enemy.current_hp
				await resolver.deal_damage_with_modifiers(attacker, enemy, 35, skill_key)
				if enemy.is_dead and hp_before > 0:
					trigger_again = true
			
			if trigger_again:
				resolver.battle_log.add_entry("Кола на воді: ефект спрацював повторно!")
				enemies = resolver.get_alive_wards(resolver.battle_scene.enemy_wards)
				for enemy in enemies:
					await resolver.deal_damage_with_modifiers(attacker, enemy, 35, skill_key)

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

static func _execute_mais_oichi(resolver, attacker, target, skill_key: String, base_damage: int) -> void:
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

static func _execute_shopey(resolver, attacker, target, skill_key: String, base_damage: int) -> void:
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
