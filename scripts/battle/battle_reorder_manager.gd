extends Node

signal reorder_confirmed

var ally_container = null
var confirm_order_button = null
var battle_log = null

var reorder_phase: bool = false
var dragging_ward = null
var dragged_from_index: int = -1
var drag_mouse_offset: Vector2 = Vector2.ZERO

var ally_wards: Array = []


func setup(
	ally_container_ref,
	ally_wards_ref: Array,
	confirm_button_ref,
	log_ref
) -> void:
	ally_container = ally_container_ref
	ally_wards = ally_wards_ref
	confirm_order_button = confirm_button_ref
	battle_log = log_ref

	if confirm_order_button:
		confirm_order_button.visible = false
		confirm_order_button.pressed.connect(_on_confirm_order_pressed)


func start_reorder_phase() -> void:
	reorder_phase = true

	if confirm_order_button:
		confirm_order_button.visible = true

	if battle_log:
		battle_log.add_entry("Ти ходиш другим. Перестав Вардів і натисни Готово.")


func stop_reorder_phase() -> void:
	reorder_phase = false

	if dragging_ward != null:
		drop_dragged_ward()

	if confirm_order_button:
		confirm_order_button.visible = false


func process_drag() -> void:
	if dragging_ward == null:
		return

	dragging_ward.global_position = get_viewport().get_mouse_position() - drag_mouse_offset


func handle_input(event: InputEvent) -> bool:
	if dragging_ward == null:
		return false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			drop_dragged_ward()
			return true

	return false


func start_drag_ward(ward) -> void:
	if not reorder_phase:
		return

	if ward.team != "ally":
		return

	if dragging_ward != null:
		return

	dragging_ward = ward
	dragged_from_index = ally_wards.find(ward)

	if dragged_from_index == -1:
		dragging_ward = null
		return

	drag_mouse_offset = get_viewport().get_mouse_position() - ward.global_position
	ward.z_index = 100


func drop_dragged_ward() -> void:
	if dragging_ward == null:
		return

	var nearest_index: int = _get_nearest_ally_slot_index(get_viewport().get_mouse_position())

	if nearest_index == -1:
		nearest_index = dragged_from_index

	dragging_ward.z_index = 0

	if nearest_index != dragged_from_index:
		_swap_ally_wards(dragged_from_index, nearest_index)

	await get_tree().process_frame

	_refresh_ally_wards_order()

	dragging_ward = null
	dragged_from_index = -1
	drag_mouse_offset = Vector2.ZERO


func get_ally_wards() -> Array:
	return ally_wards


func _swap_ally_wards(index_a: int, index_b: int) -> void:
	if index_a < 0 or index_b < 0:
		return

	if index_a >= ally_wards.size() or index_b >= ally_wards.size():
		return

	var new_order: Array = ally_wards.duplicate()

	var temp = new_order[index_a]
	new_order[index_a] = new_order[index_b]
	new_order[index_b] = temp

	for i in range(new_order.size()):
		ally_container.move_child(new_order[i], i)

	ally_wards = new_order


func _get_nearest_ally_slot_index(mouse_global_pos: Vector2) -> int:
	var nearest_index: int = -1
	var nearest_distance: float = INF

	for i in range(ally_wards.size()):
		var ward = ally_wards[i]

		if ward == dragging_ward:
			continue

		var ward_center: Vector2 = ward.global_position + ward.size / 2.0
		var distance: float = mouse_global_pos.distance_to(ward_center)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = i

	if nearest_index == -1:
		return dragged_from_index

	return nearest_index


func _refresh_ally_wards_order() -> void:
	ally_wards.clear()

	for child in ally_container.get_children():
		if child.has_method("take_damage"):
			ally_wards.append(child)


func _on_confirm_order_pressed() -> void:
	if not reorder_phase:
		return

	stop_reorder_phase()
	reorder_confirmed.emit()
