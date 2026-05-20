extends Control

@onready var bg = $paralax_bg
@onready var circle1 = $circle1
@onready var circle2 = $circle2
@onready var glow1 = $glow1
@onready var glow_rad = $menu_bg
@onready var glow_rad2 = $menu_bg2
@onready var logo_menu = $logo_menu
@onready var circle_glow_bg = $circle_glow_bg

@onready var branch1 = $branch1
@onready var branch2 = $branch2

@export var bg_power := 0.01
@export var circle1_power := 0.03
@export var circle2_power := 0.06

@export var circle1_rotation := 0.02
@export var circle2_rotation := -0.06

@export var glow_pulse_speed := 1.6
@export var glow_min_alpha := 0.35
@export var glow_max_alpha := 0.85

@export var glow_rad_rotation := 0.05
@export var glow_rad_rotation2 := -0.03
@export var logo_menu_rotation := 0.02
@export var circle_glow_bg_rotation := -0.04

@export var glow_rad_pulse_speed := 1.2
@export var glow_rad_min_alpha := 0.15
@export var glow_rad_max_alpha := 0.35

@export var branch1_sway_speed := 0.8
@export var branch1_sway_strength := 0.03
@export var branch2_sway_speed := 0.6
@export var branch2_sway_strength := 0.025

var bg_start: Vector2
var circle1_start: Vector2
var circle2_start: Vector2
var glow1_start: Vector2
var glow_rad_start: Vector2
var glow_rad2_start: Vector2
var logo_menu_start: Vector2
var circle_glow_bg_start: Vector2
var branch1_start: Vector2
var branch2_start: Vector2

var branch1_start_rotation: float
var branch2_start_rotation: float


func _ready() -> void:
	bg_start = bg.position
	circle1_start = circle1.position
	circle2_start = circle2.position
	glow1_start = glow1.position
	glow_rad_start = glow_rad.position
	glow_rad2_start = glow_rad2.position
	logo_menu_start = logo_menu.position
	circle_glow_bg_start = circle_glow_bg.position

	branch1_start = branch1.position
	branch2_start = branch2.position

	branch1_start_rotation = branch1.rotation
	branch2_start_rotation = branch2.rotation


func _process(delta: float) -> void:
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_center := get_viewport_rect().size / 2.0
	var offset := mouse_pos - screen_center

	bg.position = bg_start - offset * bg_power
	glow1.position = glow1_start - offset * bg_power
	glow_rad.position = glow_rad_start - offset * bg_power
	glow_rad2.position = glow_rad2_start - offset * bg_power
	logo_menu.position = logo_menu_start - offset * bg_power
	circle_glow_bg.position = circle_glow_bg_start - offset * bg_power

	branch1.position = branch1_start - offset * bg_power
	branch2.position = branch2_start - offset * bg_power

	circle1.position = circle1_start - offset * circle1_power
	circle2.position = circle2_start - offset * circle2_power

	circle1.rotation += circle1_rotation * delta
	circle2.rotation += circle2_rotation * delta
	glow_rad.rotation += glow_rad_rotation * delta
	glow_rad2.rotation += glow_rad_rotation2 * delta
	logo_menu.rotation += logo_menu_rotation * delta
	circle_glow_bg.rotation += circle_glow_bg_rotation * delta

	var time := Time.get_ticks_msec() * 0.001

	var pulse := (sin(time * glow_pulse_speed) + 1.0) / 2.0
	glow1.modulate.a = lerp(glow_min_alpha, glow_max_alpha, pulse)

	var glow_rad_pulse := (sin(time * glow_rad_pulse_speed) + 1.0) / 2.0
	glow_rad.modulate.a = lerp(glow_rad_min_alpha, glow_rad_max_alpha, glow_rad_pulse)
	glow_rad2.modulate.a = lerp(glow_rad_min_alpha, glow_rad_max_alpha, glow_rad_pulse)

	branch1.rotation = branch1_start_rotation + sin(time * branch1_sway_speed) * branch1_sway_strength
	branch2.rotation = branch2_start_rotation + sin(time * branch2_sway_speed) * branch2_sway_strength
