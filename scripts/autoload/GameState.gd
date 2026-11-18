extends Node

signal energy_changed(new_value: int)
signal coins_changed(new_value: int)
signal inventory_changed
signal state_changed
signal warung_upgraded(new_tier: int)
signal quest_completed(quest_id: String)

const MAX_ENERGY: int = 100
const STARTING_COINS: int = 100
const MAX_WARUNG_TIER: int = 2
const NEW_GAME_START_POSITION: Vector2 = Vector2(210.0, 462.0)
const ITEM_CATALOG_PATH: String = "res://data/items/items.json"
const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_VERSION: int = 1
const SAVE_SYSTEM_SCRIPT: Script = preload("res://scripts/systems/SaveSystem.gd")

var player_name: String = "Pengelana"
var current_day: int = 1
var current_hour: int = 6
var current_minute: int = 0
var pending_player_position: Vector2 = NEW_GAME_START_POSITION
var energy: int = MAX_ENERGY
var coins: int = STARTING_COINS
var inventory: Array[Dictionary] = []
var item_catalog: Dictionary = {}
var unlocked_recipes: Array[String] = ["sup_sayur_bening", "bubur_hangat_hutan"]
var unlocked_quests: Array[String] = []
var completed_quests: Array[String] = []
var items_received_from_npcs: Array[String] = []
var collected_forage_today: Array[String] = []
var business_permits: Array[int] = []
var npc_heart_levels: Dictionary = {}
var npc_met: Dictionary = {}
var affection_points: Dictionary = {}
var gifts_given_today: Dictionary = {}
var customers_served_today: Dictionary = {}
var disliked_gift_streaks: Dictionary = {}
var npc_gift_history: Dictionary = {}
var current_weather: String = "cerah"
var npc_recently_returned_from_forest: Dictionary = {}
var reputation: int = 0
var warung_tier: int = 0
var _save_system: HearthwoodSaveSystem


func _ready() -> void:
	_load_item_catalog()
	_save_system = SAVE_SYSTEM_SCRIPT.new()
	add_child(_save_system)


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
	gifts_given_today.clear()
	customers_served_today.clear()
	collected_forage_today.clear()
	energy_changed.emit(energy)
	state_changed.emit()


func start_new_game(new_player_name: String) -> bool:
	var normalized_name := new_player_name.strip_edges()
	if normalized_name.is_empty():
		push_error("A new game requires a non-empty player name.")
		return false

	player_name = normalized_name
	current_day = 1
	current_hour = 6
	current_minute = 0
	pending_player_position = NEW_GAME_START_POSITION
	energy = MAX_ENERGY
	coins = STARTING_COINS
	inventory.clear()
	unlocked_recipes.assign(["sup_sayur_bening", "bubur_hangat_hutan"])
	unlocked_quests.clear()
	completed_quests.clear()
	items_received_from_npcs.clear()
	collected_forage_today.clear()
	business_permits.clear()
	npc_heart_levels.clear()
	npc_met.clear()
	affection_points.clear()
	gifts_given_today.clear()
	customers_served_today.clear()
	disliked_gift_streaks.clear()
	npc_gift_history.clear()
	current_weather = "cerah"
	npc_recently_returned_from_forest.clear()
	reputation = 0
	warung_tier = 0
	energy_changed.emit(energy)
	coins_changed.emit(coins)
	inventory_changed.emit()
	state_changed.emit()
	get_node("/root/TimeSystem").sync_from_game_state()
	return true


func get_npc_heart_level(npc_id: String) -> int:
	return int(npc_heart_levels.get(npc_id, 0))


func earn_coins(amount: int) -> bool:
	if amount <= 0:
		push_error("Earned coins must be a positive amount.")
		return false
	coins += amount
	coins_changed.emit(coins)
	state_changed.emit()
	return true


func increase_reputation(amount: int) -> bool:
	if amount <= 0:
		push_error("Reputation increase must be a positive amount.")
		return false
	reputation += amount
	state_changed.emit()
	return true


func upgrade_warung(new_tier: int, coin_cost: int, materials: Dictionary) -> bool:
	if (
		new_tier != warung_tier + 1
		or new_tier > MAX_WARUNG_TIER
		or coin_cost <= 0
		or coins < coin_cost
	):
		return false
	for item_id in materials:
		var quantity := int(materials[item_id])
		if quantity <= 0 or get_item_count(str(item_id)) < quantity:
			return false

	for item_id in materials:
		_remove_item_quantity(str(item_id), int(materials[item_id]))
	coins -= coin_cost
	warung_tier = new_tier
	if not business_permits.has(new_tier):
		business_permits.append(new_tier)
	coins_changed.emit(coins)
	inventory_changed.emit()
	state_changed.emit()
	warung_upgraded.emit(new_tier)
	return true


func complete_quest(quest_id: String) -> bool:
	if quest_id.is_empty() or completed_quests.has(quest_id):
		return false
	completed_quests.append(quest_id)
	quest_completed.emit(quest_id)
	state_changed.emit()
	return true


func has_save_game(file_path: String = SAVE_FILE_PATH) -> bool:
	return FileAccess.file_exists(file_path)


func inspect_save_game(file_path: String = SAVE_FILE_PATH) -> Dictionary:
	if _save_system == null:
		push_error("GameState save system is not ready.")
		return {"valid": false, "exists": false, "pesan": "Sistem save belum siap."}
	var read_result := _save_system.read_save(file_path)
	if not bool(read_result.get("valid", false)):
		return read_result
	var save_data: Dictionary = read_result["data"]
	if not _is_valid_save_data(save_data):
		return {
			"valid": false,
			"exists": true,
			"pesan": "Data save tidak lengkap atau tidak sesuai versi.",
		}
	return {
		"valid": true,
		"exists": true,
		"nama_pemain": str(save_data["nama_pemain"]),
		"hari": int(save_data["hari"]),
		"tier_warung": int(save_data["tier_warung"]),
		"scene": str(save_data["posisi"]["scene"]),
		"pesan": "Save siap dimuat.",
	}


func save_game(
	player_position: Vector2,
	scene_path: String,
	file_path: String = SAVE_FILE_PATH
) -> Dictionary:
	if _save_system == null:
		push_error("GameState save system is not ready.")
		return {"valid": false, "pesan": "Sistem save belum siap."}
	if (
		scene_path.is_empty()
		or not FileAccess.file_exists(scene_path)
		or not is_finite(player_position.x)
		or not is_finite(player_position.y)
	):
		return {"valid": false, "pesan": "Lokasi pemain atau scene tidak valid."}
	return _save_system.write_save(
		file_path,
		_create_save_data(player_position, scene_path)
	)


func load_game(
	file_path: String = SAVE_FILE_PATH,
	expected_scene_path: String = ""
) -> Dictionary:
	if _save_system == null:
		push_error("GameState save system is not ready.")
		return {"valid": false, "exists": false, "pesan": "Sistem save belum siap."}
	var read_result := _save_system.read_save(file_path)
	if not bool(read_result.get("valid", false)):
		return read_result
	var save_data: Dictionary = read_result["data"]
	if not _is_valid_save_data(save_data):
		return {
			"valid": false,
			"exists": true,
			"pesan": "Data save tidak lengkap atau tidak sesuai versi.",
		}
	var saved_position: Dictionary = save_data["posisi"]
	var saved_scene_path := str(saved_position["scene"])
	if not expected_scene_path.is_empty() and saved_scene_path != expected_scene_path:
		return {
			"valid": false,
			"exists": true,
			"pesan": "Save berasal dari scene yang tidak dapat dimuat saat ini.",
		}
	_restore_save_data(save_data)
	return {
		"valid": true,
		"exists": true,
		"pesan": "Game berhasil dimuat.",
		"posisi": Vector2(float(saved_position["x"]), float(saved_position["y"])),
		"scene": saved_scene_path,
	}


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
	return remove_items({item_id: quantity})


func remove_items(requirements: Dictionary) -> bool:
	if requirements.is_empty():
		return false
	for item_id in requirements:
		var quantity := int(requirements[item_id])
		if quantity <= 0 or get_item_count(str(item_id)) < quantity:
			return false

	for item_id in requirements:
		_remove_item_quantity(str(item_id), int(requirements[item_id]))
	inventory_changed.emit()
	state_changed.emit()
	return true


func remove_item_stack(
	item_id: String, quantity: int, cooked_on_day: int, quality: int
) -> bool:
	if quantity <= 0:
		return false
	for index in inventory.size():
		var stack: Dictionary = inventory[index]
		if (
			str(stack.get("id", "")) == item_id
			and int(stack.get("tanggal_masak", -1)) == cooked_on_day
			and int(stack.get("kualitas", 0)) == quality
		):
			if int(stack.get("jumlah", 0)) < quantity:
				return false
			stack["jumlah"] = int(stack["jumlah"]) - quantity
			if int(stack["jumlah"]) == 0:
				inventory.remove_at(index)
			inventory_changed.emit()
			state_changed.emit()
			return true
	return false


func age_cooked_food() -> void:
	var inventory_changed_by_age := false
	for index in range(inventory.size() - 1, -1, -1):
		var stack: Dictionary = inventory[index]
		var item_id := str(stack.get("id", ""))
		if str(get_item_definition(item_id).get("kategori", "")) != "masakan":
			continue
		var cooked_on_day := int(stack.get("tanggal_masak", 0))
		var processed_day := int(stack.get("hari_terakhir_diproses", cooked_on_day))
		var elapsed_days := current_day - processed_day
		if elapsed_days <= 0:
			continue
		var shelf_life := int(get_item_definition(item_id).get("masa_simpan_hari", 3))
		if current_day - cooked_on_day >= shelf_life:
			inventory.remove_at(index)
		else:
			stack["kualitas"] = maxi(1, int(stack.get("kualitas", 1)) - elapsed_days)
			stack["hari_terakhir_diproses"] = current_day
		inventory_changed_by_age = true
	if inventory_changed_by_age:
		_merge_matching_stacks()
		inventory_changed.emit()
		state_changed.emit()


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


func _create_save_data(player_position: Vector2, scene_path: String) -> Dictionary:
	var saved_inventory: Array[Dictionary] = []
	for stack in inventory:
		saved_inventory.append({
			"item": str(stack.get("id", "")),
			"jumlah": int(stack.get("jumlah", 0)),
			"tanggal_masak": int(stack.get("tanggal_masak", -1)),
			"kualitas": int(stack.get("kualitas", 0)),
			"hari_terakhir_diproses": int(
				stack.get("hari_terakhir_diproses", stack.get("tanggal_masak", -1))
			),
		})
	return {
		"versi": SAVE_VERSION,
		"nama_pemain": player_name,
		"hari": current_day,
		"jam": current_hour,
		"menit": current_minute,
		"energi": energy,
		"koin": coins,
		"reputasi": reputation,
		"posisi": {
			"x": player_position.x,
			"y": player_position.y,
			"scene": scene_path,
		},
		"inventori": saved_inventory,
		"resep_terbuka": unlocked_recipes.duplicate(),
		"hati_npc": npc_heart_levels.duplicate(true),
		"poin_afeksi": affection_points.duplicate(true),
		"tier_warung": warung_tier,
		"izin_usaha": business_permits.duplicate(),
		"item_dihadikan": items_received_from_npcs.duplicate(),
		"quest_terbuka": unlocked_quests.duplicate(),
		"quest_selesai": completed_quests.duplicate(),
		"npc_ditemui": npc_met.duplicate(true),
		"forage_terkumpul_hari_ini": collected_forage_today.duplicate(),
		"hadiah_hari_ini": gifts_given_today.duplicate(true),
		"pelanggan_hari_ini": customers_served_today.duplicate(true),
		"streak_tidak_suka": disliked_gift_streaks.duplicate(true),
		"riwayat_masakan_npc": npc_gift_history.duplicate(true),
		"cuaca": current_weather,
		"rast_kembali_dari_hutan": npc_recently_returned_from_forest.duplicate(true),
	}


func _is_valid_save_data(data: Dictionary) -> bool:
	var required_fields := [
		"versi",
		"nama_pemain",
		"hari",
		"jam",
		"menit",
		"energi",
		"koin",
		"reputasi",
		"posisi",
		"inventori",
		"resep_terbuka",
		"hati_npc",
		"poin_afeksi",
		"tier_warung",
		"izin_usaha",
		"item_dihadikan",
		"quest_terbuka",
		"quest_selesai",
		"npc_ditemui",
		"forage_terkumpul_hari_ini",
		"hadiah_hari_ini",
		"pelanggan_hari_ini",
		"streak_tidak_suka",
		"riwayat_masakan_npc",
		"cuaca",
		"rast_kembali_dari_hutan",
	]
	for field in required_fields:
		if not data.has(field):
			return false
	for field in ["versi", "hari", "jam", "menit", "energi", "koin", "reputasi", "tier_warung"]:
		if not _is_integer_value(data[field]):
			return false
	if (
		int(data["versi"]) != SAVE_VERSION
		or typeof(data["nama_pemain"]) != TYPE_STRING
		or str(data["nama_pemain"]).is_empty()
		or int(data["hari"]) < 1
		or int(data["jam"]) < 6
		or int(data["jam"]) >= 30
		or int(data["menit"]) < 0
		or int(data["menit"]) >= 60
		or int(data["energi"]) < 0
		or int(data["energi"]) > MAX_ENERGY
		or int(data["koin"]) < 0
		or int(data["reputasi"]) < 0
		or int(data["tier_warung"]) < 0
		or int(data["tier_warung"]) > MAX_WARUNG_TIER
		or typeof(data["cuaca"]) != TYPE_STRING
		or str(data["cuaca"]).is_empty()
	):
		return false

	var position_data: Variant = data["posisi"]
	if (
		typeof(position_data) != TYPE_DICTIONARY
		or not position_data.has("x")
		or not position_data.has("y")
		or not position_data.has("scene")
		or not _is_numeric_value(position_data["x"])
		or not _is_numeric_value(position_data["y"])
		or not is_finite(float(position_data["x"]))
		or not is_finite(float(position_data["y"]))
		or typeof(position_data["scene"]) != TYPE_STRING
		or not FileAccess.file_exists(str(position_data["scene"]))
	):
		return false

	return (
		_is_valid_saved_inventory(data["inventori"], int(data["hari"]))
		and _is_valid_recipe_array(data["resep_terbuka"])
		and _is_valid_npc_integer_dictionary(data["hati_npc"], 0, 3)
		and _is_valid_npc_integer_dictionary(data["poin_afeksi"], 0, 90)
		and _is_valid_business_permits(data["izin_usaha"], int(data["tier_warung"]))
		and _is_valid_received_items(data["item_dihadikan"])
		and _is_valid_unique_string_array(data["quest_terbuka"])
		and _is_valid_unique_string_array(data["quest_selesai"])
		and _is_valid_npc_boolean_dictionary(data["npc_ditemui"])
		and _is_valid_unique_string_array(data["forage_terkumpul_hari_ini"])
		and _is_valid_npc_boolean_dictionary(data["hadiah_hari_ini"])
		and _is_valid_npc_boolean_dictionary(data["pelanggan_hari_ini"])
		and _is_valid_npc_integer_dictionary(data["streak_tidak_suka"], 0, 2)
		and _is_valid_npc_recipe_history(data["riwayat_masakan_npc"])
		and _is_valid_npc_boolean_dictionary(data["rast_kembali_dari_hutan"])
	)


func _restore_save_data(data: Dictionary) -> void:
	player_name = str(data["nama_pemain"])
	current_day = int(data["hari"])
	current_hour = int(data["jam"])
	current_minute = int(data["menit"])
	energy = int(data["energi"])
	coins = int(data["koin"])
	reputation = int(data["reputasi"])
	warung_tier = int(data["tier_warung"])
	inventory.clear()
	for stack in data["inventori"]:
		inventory.append({
			"id": str(stack["item"]),
			"jumlah": int(stack["jumlah"]),
			"tanggal_masak": int(stack["tanggal_masak"]),
			"kualitas": int(stack["kualitas"]),
			"hari_terakhir_diproses": int(stack["hari_terakhir_diproses"]),
		})
	unlocked_recipes.clear()
	for recipe_id in data["resep_terbuka"]:
		unlocked_recipes.append(str(recipe_id))
	npc_heart_levels = data["hati_npc"].duplicate(true)
	affection_points = data["poin_afeksi"].duplicate(true)
	business_permits.clear()
	for permit in data["izin_usaha"]:
		business_permits.append(int(permit))
	items_received_from_npcs.clear()
	for item_id in data["item_dihadikan"]:
		items_received_from_npcs.append(str(item_id))
	unlocked_quests.clear()
	for quest_id in data["quest_terbuka"]:
		unlocked_quests.append(str(quest_id))
	completed_quests.clear()
	for quest_id in data["quest_selesai"]:
		completed_quests.append(str(quest_id))
	npc_met = data["npc_ditemui"].duplicate(true)
	collected_forage_today.clear()
	for spawn_id in data["forage_terkumpul_hari_ini"]:
		collected_forage_today.append(str(spawn_id))
	gifts_given_today = data["hadiah_hari_ini"].duplicate(true)
	customers_served_today = data["pelanggan_hari_ini"].duplicate(true)
	disliked_gift_streaks = data["streak_tidak_suka"].duplicate(true)
	npc_gift_history = data["riwayat_masakan_npc"].duplicate(true)
	current_weather = str(data["cuaca"])
	npc_recently_returned_from_forest = data["rast_kembali_dari_hutan"].duplicate(true)
	energy_changed.emit(energy)
	coins_changed.emit(coins)
	inventory_changed.emit()
	state_changed.emit()


func _is_valid_saved_inventory(value: Variant, saved_day: int) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	for stack in value:
		if (
			typeof(stack) != TYPE_DICTIONARY
			or not stack.has("item")
			or not stack.has("jumlah")
			or not stack.has("tanggal_masak")
			or not stack.has("kualitas")
			or not stack.has("hari_terakhir_diproses")
			or typeof(stack["item"]) != TYPE_STRING
			or not _is_integer_value(stack["jumlah"])
			or not _is_integer_value(stack["tanggal_masak"])
			or not _is_integer_value(stack["kualitas"])
			or not _is_integer_value(stack["hari_terakhir_diproses"])
			or not item_catalog.has(str(stack["item"]))
			or int(stack["jumlah"]) <= 0
		):
			return false
		var definition: Dictionary = get_item_definition(str(stack["item"]))
		var cooked_on_day := int(stack["tanggal_masak"])
		var quality := int(stack["kualitas"])
		var processed_day := int(stack["hari_terakhir_diproses"])
		if str(definition.get("kategori", "")) == "masakan":
			if (
				cooked_on_day < 1
				or cooked_on_day > saved_day
				or quality < 1
				or quality > 3
				or processed_day < cooked_on_day
				or processed_day > saved_day
			):
				return false
		elif cooked_on_day != -1 or quality != 0 or processed_day != -1:
			return false
	return true


func _is_valid_recipe_array(value: Variant) -> bool:
	if not _is_valid_unique_string_array(value):
		return false
	for recipe_id in value:
		if not FileAccess.file_exists("res://data/recipes/%s.json" % recipe_id):
			return false
	return true


func _is_valid_received_items(value: Variant) -> bool:
	if not _is_valid_unique_string_array(value):
		return false
	for item_id in value:
		if not item_catalog.has(item_id):
			return false
	return true


func _is_valid_unique_string_array(value: Variant) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	var unique_values: Array[String] = []
	for entry in value:
		if typeof(entry) != TYPE_STRING or str(entry).is_empty() or unique_values.has(entry):
			return false
		unique_values.append(str(entry))
	return true


func _is_valid_business_permits(value: Variant, saved_tier: int) -> bool:
	if typeof(value) != TYPE_ARRAY:
		return false
	var permits: Array[int] = []
	for entry in value:
		if (
			not _is_integer_value(entry)
			or int(entry) < 1
			or int(entry) > saved_tier
			or permits.has(int(entry))
		):
			return false
		permits.append(int(entry))
	return true


func _is_valid_npc_integer_dictionary(
	value: Variant, minimum: int, maximum: int
) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for npc_id in value:
		if (
			not _is_known_npc_id(str(npc_id))
			or not _is_integer_value(value[npc_id])
			or int(value[npc_id]) < minimum
			or int(value[npc_id]) > maximum
		):
			return false
	return true


func _is_valid_npc_boolean_dictionary(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for npc_id in value:
		if not _is_known_npc_id(str(npc_id)) or typeof(value[npc_id]) != TYPE_BOOL:
			return false
	return true


func _is_valid_npc_recipe_history(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for npc_id in value:
		if not _is_known_npc_id(str(npc_id)) or not _is_valid_recipe_array(value[npc_id]):
			return false
	return true


func _is_known_npc_id(npc_id: String) -> bool:
	return (
		not npc_id.is_empty()
		and not npc_id.contains("/")
		and not npc_id.contains("\\")
		and FileAccess.file_exists("res://data/npcs/%s.json" % npc_id)
	)


func _is_numeric_value(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _is_integer_value(value: Variant) -> bool:
	return (
		_is_numeric_value(value)
		and is_finite(float(value))
		and is_equal_approx(float(value), float(int(value)))
	)


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
			if (
				typeof(energy_values) != TYPE_DICTIONARY
				or int(entry.get("harga_jual", 0)) <= 0
			):
				push_error("Cooked items require quality energy and a sale price: %s" % item_id)
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
	if (
		is_cooked_item
		and (
			cooked_on_day < 1
			or cooked_on_day > current_day
			or quality < 1
			or quality > 3
		)
	):
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
		"hari_terakhir_diproses": cooked_on_day,
	})


func _remove_item_quantity(item_id: String, quantity: int) -> void:
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
			return


func _merge_matching_stacks() -> void:
	var merged_stacks: Array[Dictionary] = []
	for stack in inventory:
		var found_matching_stack := false
		for existing_stack in merged_stacks:
			if (
				str(existing_stack.get("id", "")) == str(stack.get("id", ""))
				and int(existing_stack.get("tanggal_masak", -1))
				== int(stack.get("tanggal_masak", -1))
				and int(existing_stack.get("kualitas", 0)) == int(stack.get("kualitas", 0))
			):
				existing_stack["jumlah"] = (
					int(existing_stack.get("jumlah", 0)) + int(stack.get("jumlah", 0))
				)
				found_matching_stack = true
				break
		if not found_matching_stack:
			merged_stacks.append(stack)
	inventory = merged_stacks
