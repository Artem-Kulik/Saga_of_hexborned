extends Control

@onready var delay_bar: TextureProgressBar = $Delay
@onready var current_bar: TextureProgressBar = $Current

var max_hp: int = 100
var current_hp: int = 100

var current_tween: Tween
var delay_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	delay_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup_hp(new_max_hp: int, start_hp: int) -> void:
	max_hp = max(new_max_hp, 1)
	current_hp = clamp(start_hp, 0, max_hp)

	delay_bar.min_value = 0
	delay_bar.max_value = max_hp
	delay_bar.value = current_hp

	current_bar.min_value = 0
	current_bar.max_value = max_hp
	current_bar.value = current_hp


func set_hp(new_hp: int, animated: bool = true) -> void:
	var target_hp: int = clamp(new_hp, 0, max_hp)

	if current_tween:
		current_tween.kill()

	if delay_tween:
		delay_tween.kill()

	if not animated:
		current_hp = target_hp
		current_bar.value = target_hp
		delay_bar.value = target_hp
		return

	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_CUBIC)
	current_tween.set_ease(Tween.EASE_OUT)
	current_tween.tween_property(current_bar, "value", target_hp, 0.22)

	await get_tree().create_timer(0.18).timeout

	delay_tween = create_tween()
	delay_tween.set_trans(Tween.TRANS_CUBIC)
	delay_tween.set_ease(Tween.EASE_OUT)
	delay_tween.tween_property(delay_bar, "value", target_hp, 0.5)

	current_hp = target_hp
