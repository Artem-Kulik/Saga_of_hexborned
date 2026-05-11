extends Control

@onready var delay_bar: TextureProgressBar = $HP_delay
@onready var main_bar: TextureProgressBar = $HP_current

var current_hp := 100.0
var max_hp := 100.0
var tween: Tween

func _ready():
	setup_hp(200, 200)

func setup_hp(value: float, max_value: float):
	max_hp = max_value
	current_hp = value
	
	main_bar.max_value = max_hp
	delay_bar.max_value = max_hp
	
	main_bar.value = current_hp
	delay_bar.value = current_hp

func take_damage(amount: float):
	var new_hp = clamp(current_hp - amount, 0, max_hp)
	current_hp = new_hp
	
	main_bar.value = current_hp
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(delay_bar, "value", current_hp, 0.6)

func _input(event):
	if event.is_action_pressed("test"):
		take_damage(20)
