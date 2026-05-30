extends Control

@onready var glow_1: TextureRect = $Background_box/glow

@export var glow_1_min := 0.15
@export var glow_1_max := 0.75
@export var glow_1_speed := 0.35

var t := 0.0


func _ready() -> void:
	_setup_glow(glow_1)


func _process(delta: float) -> void:
	t += delta
	var wave_1 := (sin(t * glow_1_speed) + 1.0) * 0.5
	glow_1.modulate.a = lerp(glow_1_min, glow_1_max, wave_1)


func _setup_glow(glow: TextureRect) -> void:
	glow.visible = true

	glow.modulate = Color(1, 1, 1, 1)
	glow.self_modulate = Color(1, 1, 1, 1)

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat

	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
