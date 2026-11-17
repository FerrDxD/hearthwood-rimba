extends Node

signal energy_changed(new_value: int)
signal coins_changed(new_value: int)
signal inventory_changed
signal state_changed

const MAX_ENERGY: int = 100
const STARTING_COINS: int = 100
const ITEM_CATALOG_PATH: String = "res://data/items/items.json"

var player_name: String = "Pengelana"
var current_day: int = 1
var current_hour: int = 6
var current_minute: int = 0
var energy: int = MAX_ENERGY
var coins: int = STARTING_COINS
var inventory: Array[Dictionary] = []
var item_catalog: Dictionary = {}
var npc_heart_levels: Dictionary = {}
var reputation: int = 0
var warung_tier: int = 0


func _ready() -> void:
	_load_item_catalog()


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


func get_item_definition(item_id: String) -> Dictionary:
	var definition: Variant = item_catalog.get(item_id, {})
	return definition if typeof(definition) == TYPE_DICTIONARY else {}


func get_item_count(item_id: String) -> int:
	var count := 0
	for stack in inventory:
		if str(stack.get("id", "")) == item_id:
			count += int(stack.get("jumlah", 0))
	return count


func add_item(
	item_id: String, quantity: int = 1, cooked_on_day: int = -1, quality: int = 0
) -> bool:
	if not _validate_item_addition(item_id, quantity, cooked_on_day, quality):
		return false
	_add_item_stack(item_id, quantity, cooked_on_day, quality)
	inventory_changed.emit()
	state_changed.emit()
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or get_item_count(item_id) < quantity:
		return false

	var remaining := quantity
	for index in range(inventory.size() - 1, -1, -1):
		var stack: Dictionary = inventory[index]
		if str(stack.get("id", "")) != item_id:
			continue
		var removed := mini(remaining, int(stack.get("jumlah", 0)))
		stack["jumlah"] = int(stack["jumlah"]) - removed
		remaining -= removed
		if int(stack["jumlah"]) == 0:
			inventory.remove_at(index)
		if remaining == 0:
			break

	inventory_changed.emit()
	state_changed.emit()
	return true


func get_item_energy(item_id: String, quality: int = 0) -> int:
	var definition := get_item_definition(item_id)
	var energy_values: Variant = definition.get("energi_per_kualitas")
	if typeof(energy_values) != TYPE_DICTIONARY:
		return int(definition.get("energi", 0))
	var selected_quality := 2 if quality == 0 else clampi(quality, 1, 3)
	return int(energy_values.get(str(selected_quality), 0))


func purchase_item(item_id: String, price: int) -> bool:
	if item_id.is_empty() or price <= 0:
		push_error("A purchase requires a valid item ID and a positive price.")
		return false
	if not item_catalog.has(item_id):
		push_error("Cannot purchase an unknown item: %s" % item_id)
		return false
	if not _validate_item_addition(item_id, 1, -1, 0):
		return false
	if coins < price:
		return false

	_add_item_stack(item_id, 1, -1, 0)
	coins -= price
	coins_changed.emit(coins)
	inventory_changed.emit()
	state_changed.emit()
	return true


func _load_item_catalog() -> void:
	if not FileAccess.file_exists(ITEM_CATALOG_PATH):
		push_error("Item catalog file not found: %s" % ITEM_CATALOG_PATH)
		return
	var file := FileAccess.open(ITEM_CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read item catalog file: %s" % ITEM_CATALOG_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("items")) != TYPE_ARRAY:
		push_error("Item catalog must contain an items array: %s" % ITEM_CATALOG_PATH)
		return

	for entry in parsed["items"]:
		if typeof(entry) != TYPE_DICTIONARY:
			push_error("Item catalog entries must be objects: %s" % ITEM_CATALOG_PATH)
			item_catalog.clear()
			return
		var item_id: Variant = entry.get("id")
		var display_name: Variant = entry.get("nama")
		if (
			typeof(item_id) != TYPE_STRING
			or typeof(display_name) != TYPE_STRING
			or str(item_id).is_empty()
			or str(display_name).is_empty()
			or item_catalog.has(item_id)
		):
			push_error("Item catalog has an invalid or duplicate ID: %s" % ITEM_CATALOG_PATH)
			item_catalog.clear()
			return
		if str(entry.get("kategori", "")) == "masakan":
			var energy_values: Variant = entry.get("energi_per_kualitas")
			if typeof(energy_values) != TYPE_DICTIONARY:
				push_error("Cooked items require energy values for each quality: %s" % item_id)
				item_catalog.clear()
				return
			for food_quality in range(1, 4):
				if not energy_values.has(str(food_quality)) or int(energy_values[str(food_quality)]) <= 0:
					push_error("Cooked items require positive energy for quality %d: %s" % [
						food_quality,
						item_id,
					])
					item_catalog.clear()
					return
		item_catalog[item_id] = entry


func _validate_item_addition(
	item_id: String, quantity: int, cooked_on_day: int, quality: int
) -> bool:
	if not item_catalog.has(item_id) or quantity <= 0:
		push_error("Cannot add an unknown item or non-positive quantity: %s" % item_id)
		return false
	var is_cooked_item := str(item_catalog[item_id].get("kategori", "")) == "masakan"
	if is_cooked_item and (cooked_on_day < 1 or quality < 1 or quality > 3):
		push_error("Cooked items require a valid cooking day and quality: %s" % item_id)
		return false
	if not is_cooked_item and (cooked_on_day >= 1 or quality != 0):
		push_error("Cooking metadata is only valid for cooked items: %s" % item_id)
		return false
	return true


func _add_item_stack(item_id: String, quantity: int, cooked_on_day: int, quality: int) -> void:
	for stack in inventory:
		if (
			str(stack.get("id", "")) == item_id
			and int(stack.get("tanggal_masak", -1)) == cooked_on_day
			and int(stack.get("kualitas", 0)) == quality
		):
			stack["jumlah"] = int(stack.get("jumlah", 0)) + quantity
			return
	inventory.append({
		"id": item_id,
		"jumlah": quantity,
		"tanggal_masak": cooked_on_day,
		"kualitas": quality,
	})
