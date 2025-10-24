extends StaticBody3D

@export var is_locked: bool = false
@export var auto_close: bool = true
@export var auto_close_delay: float = 5.0

var is_open = false
var player_nearby = false
var initial_position: Vector3

@onready var animation_player = $AnimationPlayer
@onready var interaction_zone = $InteractionZone
@onready var hint_label = $InteractionHint
@onready var mesh_instance = $MeshInstance3D
@onready var collision_shape = $CollisionShape3D

func _ready():
	print("=== ДВЕРЬ ДИАГНОСТИКА ===")
	print("Позиция при старте: ", position)
	print("Глобальная позиция: ", global_position)
	print("Родитель: ", get_parent().name if get_parent() else "НЕТ")
	print("Transform: ", transform)
	print("=======================")
	
	# Подключаем сигналы зоны
	interaction_zone.body_entered.connect(_on_body_entered)
	interaction_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if not is_locked:
			hint_label.visible = true
			hint_label.text = "[E] " + ("Закрыть" if is_open else "Открыть")

func _on_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		hint_label.visible = false

func _input(event):
	if player_nearby and event.is_action_pressed("interact"):
		if not is_locked:
			toggle_door()
		else:
			print("Дверь заперта!")

func toggle_door():
	if is_open:
		close_door()
	else:
		open_door()

func open_door():
	if not is_open:
		is_open = true
		animation_player.play("open")
		# Отключаем коллизию когда дверь открыта
		collision_shape.disabled = true
		hint_label.text = "[E] Закрыть"
		
		if auto_close:
			await get_tree().create_timer(auto_close_delay).timeout
			if is_open:
				close_door()

func close_door():
	if is_open:
		is_open = false
		animation_player.play("close")
		# Включаем коллизию обратно
		collision_shape.disabled = false
		hint_label.text = "[E] Открыть"

func unlock():
	is_locked = false
	print("Дверь разблокирована!")
