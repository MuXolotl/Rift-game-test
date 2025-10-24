extends CharacterBody3D

# Скорости движения
const WALK_SPEED = 3.5
const SPRINT_SPEED = 6.0
const CROUCH_SPEED = 1.5
const JUMP_VELOCITY = 4.5

# Чувствительность мыши
const MOUSE_SENSITIVITY = 0.003

# Состояния
var is_sprinting = false
var is_crouching = false
var pause_cooldown = false

# Гравитация из настроек
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Переменные для звука шагов
var footstep_timer = 0.0
const FOOTSTEP_INTERVAL = 0.5  # Интервал между шагами

# Параметры здоровья
var max_health = 100.0
var current_health = 100.0
var is_dead = false

# Параметры стрельбы
const SHOOT_RANGE = 50.0
const SHOOT_DAMAGE = 50.0

# Система патронов
var max_ammo = 30
var current_ammo = 10  # Начинаем с небольшим количеством
var ammo_reserve = 20  # Запас патронов
var clip_size = 10  # Размер магазина
var is_reloading = false

# Ссылки на компоненты
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var flashlight = $Head/Flashlight
@onready var collision_shape = $CollisionShape3D
@onready var footstep_sound = $FootstepSound

# UI элементы
@onready var health_bar = $CanvasLayer/HUD/HealthBar
@onready var health_label = $CanvasLayer/HUD/HealthLabel

# UI для патронов
@onready var ammo_label = $CanvasLayer/HUD/AmmoLabel  # Создадим позже

# Меню паузы
@onready var pause_menu = $CanvasLayer/PauseMenu
@onready var resume_button = $CanvasLayer/PauseMenu/Panel/VBoxContainer/ResumeButton
@onready var restart_button = $CanvasLayer/PauseMenu/Panel/VBoxContainer/RestartButton
@onready var menu_button = $CanvasLayer/PauseMenu/Panel/VBoxContainer/MainMenuButton

@onready var death_screen = $CanvasLayer/DeathScreen
@onready var respawn_button = $CanvasLayer/DeathScreen/RespawnButton

# Высоты для стояния и приседания
const STANDING_HEIGHT = 1.8
const CROUCHING_HEIGHT = 1.0
const HEAD_STANDING_Y = 1.6
const HEAD_CROUCHING_Y = 0.8

func _ready():
	# Инициализация состояния
	is_dead = false
	current_health = max_health
	
	# Убеждаемся что экран смерти скрыт
	if death_screen:
		death_screen.visible = false
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Инициализация UI
	update_health_ui()
	# Инициализация UI патронов
	update_ammo_ui()
	# Подключаем кнопки паузы
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	# Кнопка респавна
	if respawn_button:
		respawn_button.pressed.connect(_on_restart_pressed)
	# Отладка UI
	if pause_menu:
		print("PauseMenu найден")
		print("Process mode: ", pause_menu.process_mode)
	if resume_button:
		print("Кнопка Resume найдена")
		print("Кнопка видима: ", resume_button.visible)
	# Диагностика при нажатии Escape

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Обработка приседания
	handle_crouch(delta)
	
	# Обработка спринта
	handle_sprint()
	
	# Прыжок (только если не присели)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY
	
	# Определяем скорость движения
	var current_speed = WALK_SPEED
	if is_sprinting and not is_crouching:
		current_speed = SPRINT_SPEED
	elif is_crouching:
		current_speed = CROUCH_SPEED
	
	# Получаем направление движения
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Применяем движение
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	# Обработка звука шагов
	if velocity.length() > 0.1 and is_on_floor():
		footstep_timer += delta
		var interval = FOOTSTEP_INTERVAL
		if is_sprinting:
			interval *= 0.7  # Чаще при беге
		elif is_crouching:
			interval *= 1.5  # Реже при приседании
		
		if footstep_timer >= interval:
			# Пока без звука, но логика готова
			print("Шаг!")  # Будет выводить в консоль
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0
	
	move_and_slide()

func handle_crouch(delta):
	# Получаем форму капсулы коллизии
	var shape = collision_shape.shape as CapsuleShape3D
	
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		# Плавно меняем высоту капсулы
		shape.height = lerp(shape.height, CROUCHING_HEIGHT, 10 * delta)
		# Плавно опускаем голову
		head.position.y = lerp(head.position.y, HEAD_CROUCHING_Y, 10 * delta)
	else:
		is_crouching = false
		# Возвращаем высоту
		shape.height = lerp(shape.height, STANDING_HEIGHT, 10 * delta)
		head.position.y = lerp(head.position.y, HEAD_STANDING_Y, 10 * delta)

func handle_sprint():
	if Input.is_action_pressed("sprint") and not is_crouching:
		is_sprinting = true
	else:
		is_sprinting = false

func _input(event):
	# Поворот камеры мышью
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, -1.5, 1.5)
	
	# Фонарик
	if event.is_action_pressed("flashlight"):
		flashlight.visible = !flashlight.visible
	
	# Стрельба
	if event.is_action_pressed("shoot"):
		shoot()
	
	# Перезарядка
	if event.is_action_pressed("reload"):
		reload()
	
	# ТОЛЬКО ОДНА обработка паузы!
	if event.is_action_pressed("ui_cancel"):
		if not is_dead:
			toggle_pause()

	# Диагностика при нажатии Escape
	if event.is_action_pressed("ui_cancel"):
		print("=== ДИАГНОСТИКА ПАУЗЫ ===")
		print("Перед паузой:")
		print("- Игра на паузе: ", get_tree().paused)
		print("- Меню паузы видимо: ", pause_menu.visible if pause_menu else "НЕ НАЙДЕНО")
		print("- Режим мыши: ", Input.get_mouse_mode())
		print("- Process mode меню: ", pause_menu.process_mode if pause_menu else "НЕ НАЙДЕНО")
		
		if not is_dead:
			toggle_pause()
			
		# Проверка после переключения (с задержкой)
		await get_tree().create_timer(0.1).timeout
		print("После паузы:")
		print("- Игра на паузе: ", get_tree().paused)
		print("- Меню паузы видимо: ", pause_menu.visible if pause_menu else "НЕ НАЙДЕНО")
		print("- Режим мыши: ", Input.get_mouse_mode())
		print("======================")

func take_damage(damage):
	if is_dead:
		return
	
	current_health -= damage
	current_health = max(0, current_health)
	update_health_ui()
	
	print("Игрок получил урон: ", damage)
	print("Осталось здоровья: ", current_health)
	
	# Проверка смерти
	if current_health <= 0:
		die()

func update_health_ui():
	if health_bar:
		health_bar.value = (current_health / max_health) * 100
	if health_label:
		health_label.text = "Health: " + str(int(current_health)) + "/" + str(int(max_health))

func die():
	is_dead = true
	print("ИГРОК МЁРТВ!")
	
	# Останавливаем игру и показываем экран смерти
	await get_tree().create_timer(1.0).timeout
	
	if death_screen:
		death_screen.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		# НЕ ставим игру на паузу, чтобы анимации продолжались
	else:
		# Запасной вариант если нет экрана смерти
		get_tree().paused = true
		pause_menu.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func shoot():
	# Проверки перед выстрелом
	if is_reloading:
		print("Перезарядка...")
		return
	
	if current_ammo <= 0:
		print("Нет патронов! Нажмите R для перезарядки")
		# Звук пустого магазина (добавим позже)
		return
	
	# Визуальный эффект выстрела - мигание фонарика
	if flashlight.visible:
		var original_energy = flashlight.light_energy
		flashlight.light_energy = 4.0  # Яркая вспышка
		await get_tree().create_timer(0.05).timeout
		flashlight.light_energy = original_energy
	
	# Тратим патрон
	current_ammo -= 1
	update_ammo_ui()
	
	# Отдача оружия
	head.rotation.x += 0.01  # Небольшой подъём камеры
	await get_tree().create_timer(0.1).timeout
	head.rotation.x -= 0.01  # Возврат обратно
	
	# Создаём луч от камеры вперёд
	var space_state = get_world_3d().direct_space_state
	var cam = camera
	var from = cam.global_transform.origin
	var to = from - cam.global_transform.basis.z * SHOOT_RANGE
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		print("Попали в: ", result.collider.name)
		# Если попали во врага
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(SHOOT_DAMAGE)

func reload():
	if is_reloading:
		return
	
	if current_ammo == clip_size:
		print("Магазин полный")
		return
	
	if ammo_reserve <= 0:
		print("Нет патронов в запасе!")
		return
	
	is_reloading = true
	print("Перезарядка...")
	
	# Анимация перезарядки (2 секунды)
	await get_tree().create_timer(2.0).timeout
	
	# Вычисляем сколько патронов нужно
	var needed = clip_size - current_ammo
	var to_reload = min(needed, ammo_reserve)
	
	current_ammo += to_reload
	ammo_reserve -= to_reload
	
	is_reloading = false
	update_ammo_ui()
	print("Перезарядка завершена!")

func update_ammo_ui():
	if ammo_label:
		ammo_label.text = "Ammo: " + str(current_ammo) + "/" + str(ammo_reserve)

func add_ammo(amount):
	ammo_reserve = min(ammo_reserve + amount, 99)
	update_ammo_ui()

func toggle_pause():
	if is_dead or pause_cooldown:
		return
	
	# Защита от двойного вызова
	pause_cooldown = true
	
	# Переключаем паузу
	get_tree().paused = !get_tree().paused
	pause_menu.visible = get_tree().paused
	
	if get_tree().paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		print("ПАУЗА ВКЛЮЧЕНА - курсор виден")
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		print("ПАУЗА ВЫКЛЮЧЕНА - курсор спрятан")
	
	# Сброс защиты через небольшую задержку
	await get_tree().create_timer(0.1).timeout
	pause_cooldown = false

func _on_resume_pressed():
	toggle_pause()

func _on_restart_pressed():
	# Скрываем экран смерти
	if death_screen:
		death_screen.visible = false
	
	# Сбрасываем паузу если была
	get_tree().paused = false
	
	# Перезагружаем сцену
	get_tree().reload_current_scene()

func _on_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
