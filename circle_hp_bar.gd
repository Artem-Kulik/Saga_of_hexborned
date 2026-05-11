extends Control

@onready var delay_bar: TextureProgressBar = $Delay
@onready var current_bar: TextureProgressBar = $Current

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	delay_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

var max_hp: int = 100
var current_hp: int = 100


func setup_hp(new_max_hp: int, start_hp: int = -1) -> void:
	max_hp = new_max_hp
	
	if start_hp == -1:
		current_hp = max_hp
	else:
		current_hp = clamp(start_hp, 0, max_hp)

	delay_bar.max_value = max_hp
	current_bar.max_value = max_hp

	delay_bar.value = current_hp
	current_bar.value = current_hp


func set_hp(new_hp: int) -> void:
	current_hp = clamp(new_hp, 0, max_hp)

	current_bar.value = current_hp

	await get_tree().create_timer(0.15).timeout

	var tween := create_tween()
	tween.tween_property(delay_bar, "value", current_hp, 0.35)
