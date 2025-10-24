extends "res://scripts/pickup_base.gd"

# Параметры аптечки
@export var heal_amount: float = 25.0

func _ready():
	item_name = "Аптечка"
	item_value = heal_amount
	super._ready()  # Вызываем родительский _ready()

func pickup(player) -> bool:
	# Проверяем, нужно ли лечение
	if player.current_health >= player.max_health:
		print("Здоровье полное!")
		return false  # Не подбираем
	
	# Лечим игрока
	var old_health = player.current_health
	player.current_health = min(player.current_health + heal_amount, player.max_health)
	player.update_health_ui()
	
	var healed = player.current_health - old_health
	print("Подобрана аптечка! Восстановлено: ", healed, " HP")
	
	return true  # Предмет подобран
