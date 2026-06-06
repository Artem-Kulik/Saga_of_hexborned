extends Control

# ─── UI nodes (створюємо в коді) ───────────────────────────────────────────
var _status_label: Label
var _ip_field: LineEdit
var _host_btn: Button
var _join_btn: Button
var _back_btn: Button
var _ip_display: Label

func _ready() -> void:
	_build_ui()
	_connect_network_signals()

# ─── Побудова UI ────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.03, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.custom_minimum_size = Vector2(500, 420)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	add_child(center)

	# Заголовок
	var title := Label.new()
	title.text = "ДУЕЛЬ — ЛОКАЛЬНА МЕРЕЖА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.42))
	title.add_theme_font_size_override("font_size", 28)
	center.add_child(title)

	# Роздільник
	center.add_child(_sep())

	# HOST секція
	var host_section := VBoxContainer.new()
	host_section.add_theme_constant_override("separation", 8)
	center.add_child(host_section)

	var host_title := Label.new()
	host_title.text = "▶ Створити гру (Хост)"
	host_title.add_theme_color_override("font_color", Color(0.7, 0.9, 0.5))
	host_section.add_child(host_title)

	_ip_display = Label.new()
	_ip_display.text = "Ваша IP: " + NetworkManager.get_local_ip()
	_ip_display.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	host_section.add_child(_ip_display)

	_host_btn = _make_button("СТАТИ ХОСТОМ", Color(0.2, 0.6, 0.2))
	_host_btn.pressed.connect(_on_host_pressed)
	host_section.add_child(_host_btn)

	# Роздільник
	center.add_child(_sep())

	# JOIN секція
	var join_section := VBoxContainer.new()
	join_section.add_theme_constant_override("separation", 8)
	center.add_child(join_section)

	var join_title := Label.new()
	join_title.text = "▶ Підключитися до хоста"
	join_title.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0))
	join_section.add_child(join_title)

	var ip_row := HBoxContainer.new()
	ip_row.add_theme_constant_override("separation", 10)
	join_section.add_child(ip_row)

	_ip_field = LineEdit.new()
	_ip_field.placeholder_text = "192.168.x.x"
	_ip_field.custom_minimum_size = Vector2(260, 40)
	_ip_field.add_theme_font_size_override("font_size", 18)
	ip_row.add_child(_ip_field)

	_join_btn = _make_button("ПІДКЛЮЧИТИСЯ", Color(0.2, 0.4, 0.8))
	_join_btn.custom_minimum_size = Vector2(180, 40)
	_join_btn.pressed.connect(_on_join_pressed)
	ip_row.add_child(_join_btn)

	# Роздільник
	center.add_child(_sep())

	# Статус
	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	_status_label.add_theme_font_size_override("font_size", 16)
	center.add_child(_status_label)

	# Назад
	_back_btn = _make_button("← НАЗАД", Color(0.5, 0.3, 0.3))
	_back_btn.custom_minimum_size = Vector2(160, 38)
	_back_btn.pressed.connect(_on_back_pressed)
	center.add_child(_back_btn)

func _sep() -> HSeparator:
	var s := HSeparator.new()
	s.add_theme_color_override("color", Color(0.3, 0.25, 0.15))
	s.custom_minimum_size = Vector2(0, 2)
	return s

func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(260, 44)
	btn.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r * 0.3, color.g * 0.3, color.b * 0.3, 0.95)
	style.border_color = color
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_LEFT, CORNER_BOTTOM_RIGHT]:
		style.set_corner_radius(corner, 6)
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(color.r * 0.5, color.g * 0.5, color.b * 0.5, 0.95)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	return btn

# ─── Підключення сигналів ───────────────────────────────────────────────────
func _connect_network_signals() -> void:
	NetworkManager.peer_connected.connect(_on_peer_connected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.peer_disconnected.connect(_on_peer_disconnected)

func _disconnect_network_signals() -> void:
	if NetworkManager.peer_connected.is_connected(_on_peer_connected):
		NetworkManager.peer_connected.disconnect(_on_peer_connected)
	if NetworkManager.connection_failed.is_connected(_on_connection_failed):
		NetworkManager.connection_failed.disconnect(_on_connection_failed)
	if NetworkManager.peer_disconnected.is_connected(_on_peer_disconnected):
		NetworkManager.peer_disconnected.disconnect(_on_peer_disconnected)

# ─── Обробники кнопок ───────────────────────────────────────────────────────
func _on_host_pressed() -> void:
	var err := NetworkManager.host_game()
	if err != OK:
		_set_status("❌ Не вдалося запустити сервер (помилка %d)" % err, Color("#ff6060"))
		return
	_host_btn.disabled = true
	_join_btn.disabled = true
	_set_status("✅ Сервер запущено. Ваша IP: %s\nЧекаємо на суперника..." % NetworkManager.get_local_ip(), Color("#80e080"))

func _on_join_pressed() -> void:
	var ip := _ip_field.text.strip_edges()
	if ip == "":
		_set_status("⚠️ Введіть IP адресу хоста", Color("#ffcc60"))
		return
	var err := NetworkManager.join_game(ip)
	if err != OK:
		_set_status("❌ Помилка підключення (код %d)" % err, Color("#ff6060"))
		return
	_host_btn.disabled = true
	_join_btn.disabled = true
	_set_status("⏳ Підключаємося до %s..." % ip, Color("#80c0ff"))

func _on_back_pressed() -> void:
	NetworkManager.disconnect_game()
	_disconnect_network_signals()
	get_tree().change_scene_to_file("res://Основа/animation/sigils_fade/water/main_menu.tscn")

# ─── Мережеві колбеки ───────────────────────────────────────────────────────
func _on_peer_connected() -> void:
	_set_status("🤝 Суперник знайдений! Переходимо до вибору вардів...", Color("#ffe080"))
	await get_tree().create_timer(1.0).timeout
	_disconnect_network_signals()
	get_tree().change_scene_to_file("res://scripts/net/mp_choose_wards.tscn")

func _on_connection_failed() -> void:
	_host_btn.disabled = false
	_join_btn.disabled = false
	_set_status("❌ Не вдалося підключитися. Перевір IP та спробуй ще.", Color("#ff6060"))

func _on_peer_disconnected() -> void:
	_host_btn.disabled = false
	_join_btn.disabled = false
	_set_status("❌ Суперник відключився.", Color("#ff6060"))
	NetworkManager.disconnect_game()

func _set_status(text: String, color: Color = Color.WHITE) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)
