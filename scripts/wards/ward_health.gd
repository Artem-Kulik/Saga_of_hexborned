extends Node

signal hp_changed(current_hp: int, max_hp: int)
signal died

var max_hp: int = 100
var current_hp: int = 80
var is_dead: bool = false
var current_armor: int = 0

var hp_bar = null


func setup(max_hp_value: int, start_hp_value: int, hp_bar_ref) -> void:
	max_hp = max(max_hp_value, 1)
	current_hp = clamp(start_hp_value, 0, max_hp)
	is_dead = false

	hp_bar = hp_bar_ref

	if hp_bar and hp_bar.has_method("setup_hp"):
		hp_bar.setup_hp(max_hp, current_hp)

	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: int, attacker = null, skill_key: String = "") -> void:
	if is_dead:
		return

	var remaining_damage = amount
	
	if current_armor > 0:
		if remaining_damage <= current_armor:
			current_armor -= remaining_damage
			remaining_damage = 0
		else:
			remaining_damage -= current_armor
			current_armor = 0
		if get_parent() and get_parent().has_method("update_armor_status"):
			get_parent().update_armor_status(current_armor)
			
	if remaining_damage > 0:
		set_hp(current_hp - remaining_damage)

	if skill_key == "Q" and attacker != null:
		AnimationCode.play_glass_hit_on_target(attacker, get_parent())

func add_armor(amount: int) -> void:
	if is_dead: return
	current_armor += amount
	if get_parent() and get_parent().has_method("update_armor_status"):
		get_parent().update_armor_status(current_armor)

func heal(amount: int) -> void:
	if is_dead:
		return

	current_hp = clamp(current_hp + amount, 0, max_hp)

	if hp_bar and hp_bar.has_method("set_hp"):
		hp_bar.set_hp(current_hp, true)

	hp_changed.emit(current_hp, max_hp)


func set_hp(value: int) -> void:
	current_hp = clamp(value, 0, max_hp)

	if hp_bar and hp_bar.has_method("set_hp"):
		hp_bar.set_hp(current_hp, false)

	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return

	is_dead = true

	if hp_bar and hp_bar.has_method("set_hp"):
		hp_bar.set_hp(0, true)

	died.emit()
