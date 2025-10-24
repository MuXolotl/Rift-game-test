extends "res://scripts/pickup_base.gd"

@export var ammo_amount: int = 10

func _ready():
	item_name = "Патроны"
	item_value = ammo_amount
	super._ready()

func pickup(player) -> bool:
	if player.has_method("add_ammo"):
		player.add_ammo(ammo_amount)
		print("Подобраны патроны: +", ammo_amount)
		return true
	return false
