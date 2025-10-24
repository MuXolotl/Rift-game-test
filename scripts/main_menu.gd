extends Control

@onready var play_button = $ButtonContainer/PlayButton
@onready var options_button = $ButtonContainer/OptionsButton
@onready var quit_button = $ButtonContainer/QuitButton

func _ready():
	# Подключаем сигналы кнопок
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Показываем курсор в меню
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play_pressed():
	print("Начинаем игру...")
	get_tree().change_scene_to_file("res://scenes/levels/test_level.tscn")

func _on_options_pressed():
	print("Настройки (пока не реализовано)")

func _on_quit_pressed():
	print("Выход из игры")
	get_tree().quit()
