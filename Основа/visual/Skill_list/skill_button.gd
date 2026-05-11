extends Control

signal skill_pressed(skill_key: String)

@export var skill_key := "Q"
@export var cooldown := 0

@onready var highlight = $Highlight
@onready var key_label = $Key


var base_scale := Vector2.ONE
var hover_scale := Vector2(1.12, 1.12)
var tween: Tween

func _ready():
	base_scale = scale
	highlight.visible = false
	key_label.text = skill_key


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			try_press()

func _input(event):
	if event.is_action_pressed("skill_" + skill_key.to_lower()):
		try_press()

func try_press():
	if cooldown > 0:
		return
	
	skill_pressed.emit(skill_key)

func _on_mouse_entered():
	highlight.visible = true
	animate_scale(hover_scale)

func _on_mouse_exited():
	highlight.visible = false
	animate_scale(base_scale)

func animate_scale(target_scale: Vector2):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.12)

func set_cooldown(value: int):
	cooldown = value
