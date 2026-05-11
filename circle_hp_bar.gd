extends Control

@onready var delay_bar: TextureProgressBar = get_node_or_null("Delay")
@onready var current_bar: TextureProgressBar = get_node_or_null("Current")

var max_hp: int = 100
var current_hp: int = 100

var delay_tween: Tween


func _ready() -> void:
	if delay_bar == null:
		delay_bar = get_node_or_null("Delay2")

	if current_bar == null:
		current_bar = get_node_or_null("Current2")

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_bar(delay_bar)
	_setup_bar(current_bar)


func setup_hp(new_max_hp: int, start_hp: int = -1) -> void:
	max_hp = max(new_max_hp, 1)

	if start_hp == -1:
		current_hp = max_hp
	else:
		current_hp = clamp(start_hp, 0, max_hp)

	if delay_bar:
		delay_bar.max_value = max_hp
		delay_bar.value = current_hp

	if current_bar:
		current_bar.max_value = max_hp
		current_bar.value = current_hp


func set_hp(new_hp: int, animated: bool = true) -> void:
	current_hp = clamp(new_hp, 0, max_hp)

	if current_bar:
		current_bar.value = current_hp

	if delay_tween:
		delay_tween.kill()

	if delay_bar == null:
		return

	if not animated:
		delay_bar.value = current_hp
		return

	await get_tree().create_timer(0.18).timeout

	delay_tween = create_tween()
	delay_tween.set_trans(Tween.TRANS_CUBIC)
	delay_tween.set_ease(Tween.EASE_OUT)
	delay_tween.tween_property(delay_bar, "value", current_hp, 0.45)


func _setup_bar(bar: TextureProgressBar) -> void:
	if bar == null:
		return

	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	bar.min_value = 0
	bar.max_value = max_hp
	bar.value = current_hp

	bar.fill_mode = TextureProgressBar.FILL_COUNTER_CLOCKWISE
	bar.radial_initial_angle = -90.0
	bar.radial_fill_degrees = 360.0
