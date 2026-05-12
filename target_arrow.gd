extends Node2D

@onready var body: Sprite2D = $Body
@onready var head: AnimatedSprite2D = $Head

var start_position: Vector2
var texture_scroll: float = 0.0
var texture_twist: float = 0.0

@export var head_tip_offset: float = 35.0
@export var body_end_gap: float = 0.0

@export var scroll_speed: float = 55
@export var twist_speed: float = 16

@export var animate_scroll: bool = true
@export var animate_twist: bool = true


func _ready() -> void:
	body.centered = false
	body.region_enabled = true
	body.scale = Vector2.ONE
	body.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	if head.sprite_frames:
		head.play()


func setup(from_position: Vector2) -> void:
	start_position = from_position
	global_position = start_position


func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var direction: Vector2 = mouse_pos - start_position
	var distance: float = direction.length()

	if distance < 1.0:
		return

	var tex_w: float = body.texture.get_width()
	var tex_h: float = body.texture.get_height()

	var body_length: float = max(distance - head_tip_offset - body_end_gap, 1.0)

	global_position = start_position
	rotation = direction.angle() + PI / 2.0

	if animate_scroll:
		texture_scroll += scroll_speed * delta
		texture_scroll = fmod(texture_scroll, tex_h)

	if animate_twist:
		texture_twist += twist_speed * delta
		texture_twist = fmod(texture_twist, tex_w)

	body.region_rect = Rect2(
		texture_twist,
		texture_scroll,
		tex_w,
		body_length
	)

	body.position = Vector2(
		-tex_w * 0.5,
		-body_length
	)

	head.position = Vector2(
		0,
		-distance + head_tip_offset
	)
