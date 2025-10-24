extends CharacterBody3D

# Параметры врага
const SPEED = 2.0
const ATTACK_DAMAGE = 10.0
const ATTACK_COOLDOWN = 1.0

# Здоровье врага
var max_health = 100.0
var current_health = 100.0

# Состояния
enum State {IDLE, CHASING, ATTACKING}
var current_state = State.IDLE

# Цель
var player = null
var player_in_range = false
var can_attack = true

# Гравитация
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Ссылки на компоненты
@onready var detection_zone = $DetectionZone
@onready var attack_zone = $AttackZone

func _ready():
	# Подключаем сигналы для зон
	detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	detection_zone.body_exited.connect(_on_detection_zone_body_exited)
	attack_zone.body_entered.connect(_on_attack_zone_body_entered)
	attack_zone.body_exited.connect(_on_attack_zone_body_exited)

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Обработка состояний
	match current_state:
		State.IDLE:
			velocity.x = 0
			velocity.z = 0
			
		State.CHASING:
			if player:
				# Поворачиваемся к игроку
				look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
				
				# Двигаемся к игроку
				var direction = (player.global_position - global_position).normalized()
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
				
		State.ATTACKING:
			velocity.x = 0
			velocity.z = 0
			if can_attack and player:
				attack_player()
	
	move_and_slide()

func _on_detection_zone_body_entered(body):
	if body.name == "Player":
		player = body
		current_state = State.CHASING
		print("Враг заметил игрока!")

func _on_detection_zone_body_exited(body):
	if body.name == "Player":
		player = null
		current_state = State.IDLE
		print("Враг потерял игрока")

func _on_attack_zone_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		current_state = State.ATTACKING
		print("Враг атакует!")

func _on_attack_zone_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		if player:
			current_state = State.CHASING
		else:
			current_state = State.IDLE

func attack_player():
	if can_attack and player_in_range:
		can_attack = false
		
		# Наносим урон игроку (если у него есть метод take_damage)
		if player.has_method("take_damage"):
			player.take_damage(ATTACK_DAMAGE)
		else:
			print("Атака! Урон: ", ATTACK_DAMAGE)
		
		# Кулдаун атаки
		await get_tree().create_timer(ATTACK_COOLDOWN).timeout
		can_attack = true

func take_damage(damage):
	current_health -= damage
	print("Враг получил урон: ", damage, " Осталось HP: ", current_health)
	
	# Визуальная индикация урона (мигание)
	var mesh = $MeshInstance3D
	if mesh and mesh.material_override:
		var original_color = mesh.material_override.albedo_color
		mesh.material_override.albedo_color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		mesh.material_override.albedo_color = original_color
	
	if current_health <= 0:
		die()

func die():
	print("Враг уничтожен!")
	queue_free()  # Удаляем врага из игры
