extends Node

signal energy_changed(new_value: int)
signal coins_changed(new_value: int)
signal inventory_changed
signal state_changed

const MAX_ENERGY: int = 100
const STARTING_COINS: int = 100

var player_name: String = "Pengelana"
var current_day: int = 1
var current_hour: int = 6
var current_minute: int = 0
var energy: int = MAX_ENERGY
var coins: int = STARTING_COINS
var inventory: Dictionary = {}
var npc_heart_levels: Dictionary = {}
var reputation: int = 0
var warung_tier: int = 0


func change_energy(amount: int) -> void:
	var previous_energy := energy
	energy = clampi(energy + amount, 0, MAX_ENERGY)
	if energy != previous_energy:
		energy_changed.emit(energy)


func sleep(wake_hour: int, recovery_ratio: float) -> void:
	current_day += 1
	current_hour = wake_hour
	current_minute = 0
	energy = roundi(MAX_ENERGY * recovery_ratio)
	energy_changed.emit(energy)
	state_changed.emit()


func get_npc_heart_level(npc_id: String) -> int:
	return int(npc_heart_levels.get(npc_id, 0))


func purchase_item(item_id: String, price: int) -> bool:
	if item_id.is_empty() or price <= 0:
		push_error("A purchase requires a valid item ID and a positive price.")
		return false
	if coins < price:
		return false

	coins -= price
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	coins_changed.emit(coins)
	inventory_changed.emit()
	state_changed.emit()
	return true
