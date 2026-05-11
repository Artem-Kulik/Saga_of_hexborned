extends Node

signal hp_changed(current_hp: int, max_hp: int)
signal died

var max_hp: int = 100
var current_hp: int = 100
var is_dead: bool = false

var hp_current = null
var hp_delay = null
var hp_tween: Tween


func setup(max_hp_value: int, hp_current_ref, hp_delay_ref) -> void:
	max_hp = max_hp_value
	current_hp = max_hp
	is_dead = false

	hp_current = hp_current_ref
	hp_delay = hp_delay_ref

	_setup_hp_bars()
	_update_hp_bar(false)


func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_hp -= amount
	current_hp = max(current_hp, 0)

	_update_hp_bar(true)
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit()


func _setup_hp_bars() -> void:
	if hp_current:
		hp_current.min_value = 0
		hp_current.max_value = 100
		hp_current.value = 100

	if hp_delay:
		hp_delay.min_value = 0
		hp_delay.max_value = 100
		hp_delay.value = 100


func _update_hp_bar(animated: bool = true) -> void:
	var hp_percent: float = float(current_hp) / float(max_hp)
	var hp_value: float = hp_percent * 100.0

	if hp_current:
		hp_current.value = hp_value

	if hp_delay:
		if hp_tween:
			hp_tween.kill()

		if animated:
			hp_tween = create_tween()
			hp_tween.tween_property(hp_delay, "value", hp_value, 0.4)
		else:
			hp_delay.value = hp_value
