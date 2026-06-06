extends Button

@onready var glow = $"../Glow"

func _ready() -> void:
	disabled = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	glow.modulate.a = 0.0
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)

	if NetworkManager.is_multiplayer:
		if not NetworkManager.is_host:
			# Клієнт не може натискати "назад" — хост керує навігацією
			disabled = true
			modulate.a = 0.4
			# Коли хост повертається до вибору вардів — клієнт теж переходить
			NetworkManager.ward_select_requested.connect(_on_ward_select_from_host, CONNECT_ONE_SHOT)
			# Якщо суперник відключився — розблоковуємо кнопку
			NetworkManager.peer_disconnected.connect(func():
				disabled = false
				modulate.a = 1.0
			, CONNECT_ONE_SHOT)


func _on_ward_select_from_host() -> void:
	NetworkManager._my_wards_sent = false
	NetworkManager._opp_wards_got = false
	get_tree().change_scene_to_file("res://scripts/net/mp_choose_wards.tscn")


func _pressed() -> void:
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
		return
	if NetworkManager.is_multiplayer:
		# Хост повертається → сигналізуємо клієнту, потім переходимо самі
		NetworkManager._my_wards_sent = false
		NetworkManager._opp_wards_got = false
		NetworkManager.broadcast_go_ward_select()
		get_tree().change_scene_to_file("res://scripts/net/mp_choose_wards.tscn")
	else:
		get_tree().change_scene_to_file("res://Основа/animation/sigils_fade/water/main_menu.tscn")


func _on_hover_enter() -> void:
	create_tween().tween_property(glow, "modulate:a", 0.7, 0.12)


func _on_hover_exit() -> void:
	create_tween().tween_property(glow, "modulate:a", 0.0, 0.12)
