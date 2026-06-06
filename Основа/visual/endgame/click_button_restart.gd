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
			# Клієнт не може рестартити — лише хост вирішує
			disabled = true
			modulate.a = 0.4
			# Якщо суперник відключився — розблоковуємо
			NetworkManager.peer_disconnected.connect(func():
				disabled = false
				modulate.a = 1.0
			, CONNECT_ONE_SHOT)
		else:
			# Хост: клієнт теж отримає команду перезавантажити сцену
			NetworkManager.restart_requested.connect(func():
				get_tree().reload_current_scene()
			, CONNECT_ONE_SHOT)


func _pressed() -> void:
	if NetworkManager.is_multiplayer and not NetworkManager.is_host:
		return
	if NetworkManager.is_multiplayer and NetworkManager.is_host:
		NetworkManager.broadcast_restart()
	get_tree().reload_current_scene()


func _on_hover_enter() -> void:
	create_tween().tween_property(glow, "modulate:a", 0.7, 0.12)


func _on_hover_exit() -> void:
	create_tween().tween_property(glow, "modulate:a", 0.0, 0.12)
