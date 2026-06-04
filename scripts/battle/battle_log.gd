extends Node

var entries: Array[String] = []

var battle_log_panel: Control = null
var log_scroll: ScrollContainer = null
var log_container: VBoxContainer = null

var current_turn_number: int = 0
var current_turn_panel: PanelContainer = null
var current_turn_events: VBoxContainer = null


func setup_ui(panel_ref: Control) -> void:
	battle_log_panel = panel_ref

	if battle_log_panel == null:
		return

	_hide_old_log_table()
	_create_log_container()
	clear_log()


func start_turn(turn_number: int) -> void:
	current_turn_number = turn_number
	current_turn_panel = null
	current_turn_events = null


func add_entry(text: String) -> void:
	entries.append(text)
	print(text)


func add_empty_line() -> void:
	entries.append("")
	print("")


func add_attack(
	attacker_name: String,
	attacker_team: String,
	skill_name: String,
	damage: int,
	status_text: String,
	target_name: String,
	target_team: String,
	hp_before: int,
	hp_after: int,
	max_hp: int,
	damage_source: String = "skill",
	base_damage: int = 0,
	mult: float = 1.0
) -> void:
	var full_text := attacker_name + " -> " + target_name + " | " + str(damage) + " damage"
	entries.append(full_text)
	print(full_text)

	_add_attack_event(
		attacker_name,
		attacker_team,
		skill_name,
		damage,
		status_text,
		target_name,
		target_team,
		hp_before,
		hp_after,
		max_hp,
		damage_source,
		base_damage,
		mult
	)

	if status_text != "-" and status_text != "":
		add_effect(target_name, target_team, status_text)


func add_effect(target_name: String, target_team: String, effect_text: String) -> void:
	entries.append(target_name + " отримав ефект: " + effect_text)
	print(target_name, " отримав ефект: ", effect_text)

	var accent := _get_team_accent(target_team)

	_add_event_block(
		"✦",
		"ЕФЕКТ",
		accent,
		"[color=" + _team_name_color(target_team) + "]" + target_name + "[/color] [color=#d8caa0]отримав ефект[/color]\n" +
		"[color=#bfa7ff]" + effect_text + "[/color]"
	)


func add_death(ward_name: String, ward_team: String) -> void:
	entries.append(ward_name + " загинув")
	print(ward_name, " загинув")

	_add_event_block(
		"☠",
		"ЗАГИБЕЛЬ",
		Color("#e53935"),
		"[color=" + _team_name_color(ward_team) + "]" + ward_name + "[/color] [color=#ff453d]загинув[/color]"
	)


func add_heal(ward_name: String, ward_team: String, hp_before: int, hp_after: int, max_hp: int) -> void:
	entries.append(ward_name + " відновив HP")
	print(ward_name, " відновив HP")

	_add_event_block(
		"+",
		"ЛІКУВАННЯ",
		Color("#64c850"),
		"[color=" + _team_name_color(ward_team) + "]" + ward_name + "[/color] [color=#d8caa0]відновив здоров'я[/color]\n" +
		_make_hp_text(hp_before, hp_after, max_hp)
	)

func add_cooldown(ward_name: String, ward_team: String, skill_key: String, cd_turns: int) -> void:
	entries.append(ward_name + " скіл " + skill_key + " на КД " + str(cd_turns))
	print(ward_name, " → скіл ", skill_key, " на КД: ", cd_turns, " ходів")

	_add_event_block(
		"⏳",
		"КД СКІЛУ",
		Color("#5bbfd4"),
		"[color=" + _team_name_color(ward_team) + "]" + ward_name + "[/color]" +
		" [color=#d8caa0]→ скіл[/color] " +
		"[color=#f0d870][b]" + skill_key + "[/b][/color]" +
		" [color=#d8caa0]відпочиває[/color] " +
		"[color=#5bbfd4][b]" + str(cd_turns) + "[/b][/color]" +
		" [color=#8ab8c2]" + ("хід" if cd_turns == 1 else "ходи" if cd_turns < 5 else "ходів") + "[/color]"
	)


func clear_log() -> void:
	entries.clear()
	current_turn_number = 0
	current_turn_panel = null
	current_turn_events = null

	if log_container == null:
		return

	for child in log_container.get_children():
		child.queue_free()


func get_entries() -> Array[String]:
	return entries


func _hide_old_log_table() -> void:
	var old_table = battle_log_panel.get_node_or_null("BattleLog")
	if old_table:
		old_table.visible = false

	# ВАЖЛИВО:
	# Label зверху НЕ ховаємо, бо це твій напис BATTLE LOG.


func _create_log_container() -> void:
	var existing_scroll = battle_log_panel.get_node_or_null("LogScroll")

	if existing_scroll:
		log_scroll = existing_scroll
		log_container = log_scroll.get_node_or_null("LogContainer")
		return

	log_scroll = ScrollContainer.new()
	log_scroll.name = "LogScroll"

	log_scroll.anchor_left = 0.065
	log_scroll.anchor_top = 0.145
	log_scroll.anchor_right = 0.935
	log_scroll.anchor_bottom = 0.91

	log_scroll.offset_left = 0
	log_scroll.offset_top = 0
	log_scroll.offset_right = 0
	log_scroll.offset_bottom = 0

	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	battle_log_panel.add_child(log_scroll)

	log_container = VBoxContainer.new()
	log_container.name = "LogContainer"
	log_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_container.add_theme_constant_override("separation", 7)

	log_scroll.add_child(log_container)


func _ensure_turn_panel() -> void:
	if current_turn_events != null:
		return

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#120d08", 0.76)
	style.border_color = Color("#9b6a35", 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 7
	style.content_margin_top = 6
	style.content_margin_right = 7
	style.content_margin_bottom = 7

	panel.add_theme_stylebox_override("panel", style)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	panel.add_child(root)

	var title := RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("normal_font_size", 15)
	title.text = "[center][color=#c89a4b]──── TURN " + str(current_turn_number) + " ────[/color][/center]"

	root.add_child(title)

	current_turn_events = VBoxContainer.new()
	current_turn_events.add_theme_constant_override("separation", 5)
	current_turn_events.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(current_turn_events)

	log_container.add_child(panel)
	log_container.move_child(panel, 0)

	current_turn_panel = panel


func _add_attack_event(
	attacker_name: String,
	attacker_team: String,
	skill_name: String,
	damage: int,
	_status_text: String,
	target_name: String,
	target_team: String,
	hp_before: int,
	hp_after: int,
	max_hp: int,
	damage_source: String,
	base_damage: int,
	mult: float
) -> void:
	var accent := _get_team_accent(attacker_team)
	var header := "АТАКА ГРАВЦЯ"

	if attacker_team == "enemy":
		header = "АТАКА ВОРОГА"

	var text := "[color=" + _team_name_color(attacker_team) + "]" + attacker_name + "[/color] "
	text += "[color=#9b7145]ударив[/color] "
	text += "[color=" + _team_name_color(target_team) + "]" + target_name + "[/color]\n"

	text += "[color=" + accent.to_html(false).insert(0, "#") + "]Скіл: " + skill_name + "[/color]  "
	
	if mult != 1.0 and base_damage > 0:
		var mult_str = str(mult)
		if mult_str.ends_with(".0"):
			mult_str = str(int(mult))
		text += "[color=#e24b3f]Шкода: " + str(base_damage) + " (×" + mult_str + ") = " + str(damage) + "[/color]  "
	else:
		text += "[color=#e24b3f]Шкода: " + str(damage) + "[/color]  "
		
	text += "[color=#aa8755]Джерело: " + damage_source + "[/color]"

	if hp_before != hp_after:
		text += "\n" + _make_hp_text(hp_before, hp_after, max_hp)

	_add_event_block(
		"⚔",
		header,
		accent,
		text
	)


func _add_event_block(
	icon_text: String,
	header_text: String,
	accent_color: Color,
	body_bbcode: String
) -> void:
	if log_container == null:
		return

	_ensure_turn_panel()

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#090705", 0.76)
	style.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.55)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 6
	style.content_margin_top = 4
	style.content_margin_right = 6
	style.content_margin_bottom = 5

	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var icon := Label.new()
	icon.text = icon_text
	icon.custom_minimum_size = Vector2(20, 24)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 17)
	icon.add_theme_color_override("font_color", accent_color)
	row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)

	var header := Label.new()
	header.text = header_text
	header.add_theme_font_size_override("font_size", 10)
	header.add_theme_color_override("font_color", accent_color)
	text_box.add_child(header)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.text = body_bbcode
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 12)
	body.add_theme_color_override("default_color", Color("#d8caa0"))
	text_box.add_child(body)

	current_turn_events.add_child(panel)


func _make_hp_text(hp_before: int, hp_after: int, max_hp: int) -> String:
	if hp_before == hp_after:
		return ""

	var after_color := "#d84335"

	if hp_after > hp_before:
		after_color = "#63c95a"

	return "[color=#d8caa0]HP: [/color][color=#e6d2a0]" + str(hp_before) + "[/color] [color=#9c6a3d]→[/color] [color=" + after_color + "]" + str(hp_after) + "[/color][color=#8a7a55] / " + str(max_hp) + "[/color]"


func _get_team_accent(team: String) -> Color:
	if team == "ally":
		return Color("#d6a744")

	return Color("#d84335")


func _team_name_color(team: String) -> String:
	if team == "ally":
		return "#f0c86a"

	return "#ff5a45"
