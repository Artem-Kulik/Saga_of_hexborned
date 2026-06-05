# =============================================================================
# SKILL ANIMATION DISPATCHER  —  файл аніматора
# =============================================================================
#
# ЯК ДОДАТИ АНІМАЦІЮ ДЛЯ СКІЛА:
#
#   1. Знайди ID скіла нижче (або в ward_database.gd → поле "id")
#   2. Розкоментуй потрібну гілку в match
#   3. Реалізуй функцію в animation_code.gd з підписом:
#
#        func anim_<skill_id>(attacker, target, on_hit: Callable) -> void
#
#   4. on_hit ОБОВ'ЯЗКОВО викликати в момент удару — він завдає шкоду і
#      оновлює HP, damage numbers, звук. Без нього скіл не завдасть шкоди!
#
# ПАРАМЕТРИ:
#   attacker — Ward (ward_slot.gd), що атакує
#              корисні поля: attacker.get_node("WardVisual"), attacker.portrait,
#                            attacker.global_position, attacker.ward_id
#   target   — Ward-ціль (може бути null в non-damage скілів типу баф/щит)
#   on_hit   — Callable без аргументів; виклик: on_hit.call()
#
# ПРИКЛАД готової анімації (скопіюй як шаблон):
#
#   "mais_oichi_q":
#       await AnimationCode.anim_mais_oichi_q(attacker, target, on_hit)
#
#   У animation_code.gd:
#   func anim_mais_oichi_q(attacker, target, on_hit: Callable) -> void:
#       # ... tween логіка ...
#       tween.tween_callback(func(): on_hit.call())   # ← удар і шкода тут
#       # ... tween продовження (відскок, повернення) ...
#       await tween.finished
#
# =============================================================================

class_name SkillAnimationDispatcher


static func play(skill_id: String, attacker, target, on_hit: Callable) -> void:
	match skill_id:

		# ── MAIS OICHI (Майстер Оічі) ─────────────────────────────────────────
		# "mais_oichi_q": await AnimationCode.anim_mais_oichi_q(attacker, target, on_hit)
		# "mais_oichi_w": await AnimationCode.anim_mais_oichi_w(attacker, target, on_hit)
		# "mais_oichi_e": await AnimationCode.anim_mais_oichi_e(attacker, target, on_hit)

		# ── ZHNETS (Жнець) ────────────────────────────────────────────────────
		# "zhnets_q": await AnimationCode.anim_zhnets_q(attacker, target, on_hit)
		# "zhnets_w": await AnimationCode.anim_zhnets_w(attacker, target, on_hit)
		# "zhnets_e": await AnimationCode.anim_zhnets_e(attacker, target, on_hit)

		# ── OTSII (Оцій) ──────────────────────────────────────────────────────
		# "otsii_q": await AnimationCode.anim_otsii_q(attacker, target, on_hit)
		# "otsii_w": await AnimationCode.anim_otsii_w(attacker, target, on_hit)
		# "otsii_e": await AnimationCode.anim_otsii_e(attacker, target, on_hit)

		# ── SIOMYI (Сьомий слуга) ─────────────────────────────────────────────
		# "siomyi_q": await AnimationCode.anim_siomyi_q(attacker, target, on_hit)
		# "siomyi_w": await AnimationCode.anim_siomyi_w(attacker, target, on_hit)
		# "siomyi_e": await AnimationCode.anim_siomyi_e(attacker, target, on_hit)

		# ── LIAH (Лія) ────────────────────────────────────────────────────────
		# "liah_q": два удари — маршрутизується через play_liah_q(attacker, target, on_hit_first, on_hit_second)
		"liah_w":
			await AnimationCode.anim_liah_w(attacker, target, on_hit)
		# "liah_e": await AnimationCode.anim_liah_e(attacker, target, on_hit)

		# ── RIKER (Рікер) ─────────────────────────────────────────────────────
		# "riker_q": await AnimationCode.anim_riker_q(attacker, target, on_hit)
		# "riker_w": await AnimationCode.anim_riker_w(attacker, target, on_hit)
		# "riker_e": await AnimationCode.anim_riker_e(attacker, target, on_hit)

		# ── ADONEIA (Адонея) ──────────────────────────────────────────────────
		# "adoneia_q": await AnimationCode.anim_adoneia_q(attacker, target, on_hit)
		# "adoneia_w": await AnimationCode.anim_adoneia_w(attacker, target, on_hit)
		# "adoneia_e": await AnimationCode.anim_adoneia_e(attacker, target, on_hit)

		# ── GRUMP (Грумп) ─────────────────────────────────────────────────────
		# "grump_q": await AnimationCode.anim_grump_q(attacker, target, on_hit)
		# "grump_w": await AnimationCode.anim_grump_w(attacker, target, on_hit)
		# "grump_e": await AnimationCode.anim_grump_e(attacker, target, on_hit)

		# ── KROMIUS (Кроміус) ─────────────────────────────────────────────────
		# "kromius_q": await AnimationCode.anim_kromius_q(attacker, target, on_hit)
		# "kromius_w": await AnimationCode.anim_kromius_w(attacker, target, on_hit)
		# "kromius_e": await AnimationCode.anim_kromius_e(attacker, target, on_hit)

		# ── PARASYT (Паразит) ─────────────────────────────────────────────────
		# "parasyt_q": await AnimationCode.anim_parasyt_q(attacker, target, on_hit)
		# "parasyt_w": await AnimationCode.anim_parasyt_w(attacker, target, on_hit)
		# "parasyt_e": await AnimationCode.anim_parasyt_e(attacker, target, on_hit)

		# ── FIZITA (Фізіта) ───────────────────────────────────────────────────
		# "fizita_q": await AnimationCode.anim_fizita_q(attacker, target, on_hit)
		# "fizita_w": await AnimationCode.anim_fizita_w(attacker, target, on_hit)
		# "fizita_e": await AnimationCode.anim_fizita_e(attacker, target, on_hit)

		# ── SHUSIMA (Шусіма) ──────────────────────────────────────────────────
		# "shusima_q": await AnimationCode.anim_shusima_q(attacker, target, on_hit)
		# "shusima_w": await AnimationCode.anim_shusima_w(attacker, target, on_hit)
		# "shusima_e": await AnimationCode.anim_shusima_e(attacker, target, on_hit)

		# ── ISKORIS (Іскоріс) ─────────────────────────────────────────────────
		# "iskoris_q": await AnimationCode.anim_iskoris_q(attacker, target, on_hit)
		# "iskoris_w": await AnimationCode.anim_iskoris_w(attacker, target, on_hit)
		# "iskoris_e": await AnimationCode.anim_iskoris_e(attacker, target, on_hit)

		# ── ETESENA (Етесена) ─────────────────────────────────────────────────
		# "etesena_q": await AnimationCode.anim_etesena_q(attacker, target, on_hit)
		# "etesena_w": await AnimationCode.anim_etesena_w(attacker, target, on_hit)
		# "etesena_e": await AnimationCode.anim_etesena_e(attacker, target, on_hit)

		# ── SHOPEY (Шопей) ────────────────────────────────────────────────────
		# "shopey_q": await AnimationCode.anim_shopey_q(attacker, target, on_hit)
		# "shopey_w": await AnimationCode.anim_shopey_w(attacker, target, on_hit)
		# "shopey_e": await AnimationCode.anim_shopey_e(attacker, target, on_hit)

		# ── DEFAULT ───────────────────────────────────────────────────────────
		# Стандартна анімація атаки — поки конкретна анімація не готова
		_:
			await AnimationCode.skill_hit_animation(attacker, target, on_hit)


# Liah Q — два удари: базовий фіз + умовний водяний projectile.
# on_hit_second: порожній Callable() якщо другий удар не спрацьовує.
static func play_liah_q(attacker, target, on_hit_first: Callable, on_hit_second: Callable, has_second_hit: bool = false) -> void:
	await AnimationCode.liah_q_combo_animation(attacker, target, on_hit_first, on_hit_second, has_second_hit)
