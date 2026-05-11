extends Node

signal hp_changed(current_hp: int, max_hp: int)
signal died

var max_hp: int = 100
var current_hp: int = 80
var is_dead: bool = false

var hp_bar = null


func setup(max_hp_value: int, start_hp_value: int, hp_bar_ref) -> void:
	max_hp = max(max_hp_value, 1)
	current_hp = clamp(start_hp_value, 0, max_hp)
	is_dead = false

	hp_bar = hp_bar_ref

	if hp_bar and hp_bar.has_method("setup_hp"):
		hp_bar.setup_hp(max_hp, current_hp)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)

	if hp_bar and hp_bar.has_method("set_hp"):
		hp_bar.set_hp(current_hp, true)

	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit()
