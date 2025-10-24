extends Area3D

# Тип предмета (переопределяется в наследниках)
@export var item_name: String = "Item"
@export var item_value: float = 10.0

# Компоненты
@onready var mesh = $MeshInstance3D
@onready var animation_player = $AnimationPlayer

# Эффект покачивания
var time_passed = 0.0
var initial_y = 0.0
var bob_speed = 2.0
var bob_height = 0.2

func _ready():
	# Сохраняем начальную высоту
	initial_y = position.y
	
	# Запускаем анимацию вращения
	if animation_player and animation_player.has_animation("rotate"):
		animation_player.play("rotate")
	
	# Подключаем сигнал подбора
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	# Эффект покачивания вверх-вниз
	time_passed += delta
	position.y = initial_y + sin(time_passed * bob_speed) * bob_height

func _on_body_entered(body):
	if body.name == "Player":
		if pickup(body):
			queue_free()  # Удаляем предмет

# Виртуальная функция - переопределяется в наследниках
func pickup(_player) -> bool:
	print("Подобран: ", item_name)
	return true
