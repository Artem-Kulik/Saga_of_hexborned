extends Node

func animation_take_damage(node: CanvasItem):
	if node == null:
		return
	
	var start_color = node.modulate
	
	var tween := create_tween()

	tween.tween_property(node,
	"modulate",
	Color(1, 0.25, 0.25, 1),
	0.1
	)
	
	tween.tween_property(node,
	"modulate",
	start_color,
	0.15
	)
	
	await tween.finished

func skill_pressed_animation(node: CanvasItem):
	if node == null:
		return
	
	var tween := create_tween()
	
	tween.tween_property(node,
	"modulate",
	Color(0.0, 1.0, 0.055, 0.886),
	0.1
	)

func skill_used_animation(node):
	if node == null:
		return
	
	var tween := create_tween()
	
	tween.tween_property(node,
	"modulate",
	node.base_modulate,
	0.1
	)
	
	await tween.finished


func skill_qwe_animation(pressed_button):
	var skill_name = pressed_button
	print (skill_name)
