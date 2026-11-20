extends Node
class_name HearthwoodWarungSystem

const TIER_DATA_PATH: String = "res://data/warung/tiers.json"

var _tiers: Array[Dictionary] = []
var _cooking_system: HearthwoodCookingSystem
var _affection_system: HearthwoodAffectionSystem
var _world: Node = null
var _is_service_active: bool = false
var _daily_rush_customers: int = 0
var _daily_rush_coins: int = 0
var _daily_rush_rep: int = 0


func _ready() -> void:
	_load_tiers()
	var time_system = get_node_or_null("/root/TimeSystem")
	if time_system != null and not time_system.day_changed.is_connected(_on_day_changed):
		time_system.day_changed.connect(_on_day_changed)


func _on_day_changed(_day: int) -> void:
	_is_service_active = false
	_daily_rush_customers = 0
	_daily_rush_coins = 0
	_daily_rush_rep = 0


func set_world(world: Node) -> void:
	_world = world


func set_systems(
	cooking_system: HearthwoodCookingSystem,
	affection_system: HearthwoodAffectionSystem
) -> void:
	_cooking_system = cooking_system
	_affection_system = affection_system


func start_service_rush() -> Dictionary:
	var game_state = get_node("/root/GameState")
	var current_hour: int = game_state.current_hour
	if current_hour < 16 or current_hour > 21:
		return {
			"valid": false,
			"pesan": "Warung hanya buka untuk santap malam pukul 16:00 hingga 21:00."
		}

	if not _has_cooked_food_in_inventory():
		return {
			"valid": false,
			"pesan": "Siapkan minimal 1 masakan matang di inventori sebelum membuka warung."
		}

	_is_service_active = true
	_daily_rush_customers = 0
	_daily_rush_coins = 0
	_daily_rush_rep = 0

	for table in _get_world_tables():
		_connect_table_signals(table)

	return {
		"valid": true,
		"pesan": "Warung dibuka untuk makan malam! Tamu mulai berdatangan."
	}


func is_service_active() -> bool:
	return _is_service_active


func spawn_next_customer() -> bool:
	var tables := _get_world_tables()
	var available_table = null
	for t in tables:
		if t != null and t.has_method("is_available") and t.is_available():
			available_table = t
			break
	if available_table == null:
		return false

	_connect_table_signals(available_table)

	var game_state = get_node("/root/GameState")
	var current_tier := get_current_tier()
	var capacity := int(current_tier.get("kapasitas_pelanggan", 2))
	if game_state.customers_served_today.size() >= capacity:
		return false

	var seated_customer_ids: Array[String] = []
	for t in tables:
		if t != null and t.has_method("is_available") and not t.is_available():
			if "current_customer_id" in t and not str(t.current_customer_id).is_empty():
				seated_customer_ids.append(str(t.current_customer_id))

	var candidate_npcs: Array[String] = []
	for tier in _tiers:
		if int(tier["id"]) <= game_state.warung_tier:
			for npc_id in tier.get("pelanggan", []):
				var s_id := str(npc_id)
				if not game_state.customers_served_today.has(s_id) and not seated_customer_ids.has(s_id):
					candidate_npcs.append(s_id)

	if candidate_npcs.is_empty():
		return false

	# Check what cooked dishes the player currently has in inventory
	var inventory_dishes: Array[String] = []
	for stack in game_state.inventory:
		var item_id := str(stack.get("id", ""))
		var count := int(stack.get("jumlah", 0))
		if count > 0:
			var def: Dictionary = game_state.get_item_definition(item_id)
			if str(def.get("kategori", "")) == "masakan":
				if not inventory_dishes.has(item_id):
					inventory_dishes.append(item_id)

	var chosen_customer := ""
	var chosen_recipe := ""

	# Priority 1: Match a candidate customer who likes a dish currently held in inventory
	if not inventory_dishes.is_empty() and _affection_system != null:
		for c_id in candidate_npcs:
			for dish_id in inventory_dishes:
				var reaction := _affection_system.preview_food_reaction(c_id, dish_id)
				if reaction in ["suka", "favorit", "spesial"]:
					chosen_customer = c_id
					chosen_recipe = dish_id
					break
			if not chosen_customer.is_empty():
				break

	# Priority 2: If no direct inventory match, pick any liked recipe available/unlocked
	if chosen_customer.is_empty():
		var available_recipes: Array[String] = []
		if _cooking_system != null:
			available_recipes = _cooking_system.get_unlocked_recipe_ids()
		else:
			available_recipes = game_state.unlocked_recipes.duplicate()

		for c_id in candidate_npcs:
			for r_id in available_recipes:
				if _cooking_system != null and not _cooking_system.is_recipe_available(r_id):
					continue
				if _affection_system != null:
					var reaction := _affection_system.preview_food_reaction(c_id, r_id)
					if reaction in ["suka", "favorit", "spesial"]:
						chosen_customer = c_id
						chosen_recipe = r_id
						break
				else:
					chosen_customer = c_id
					chosen_recipe = r_id
					break
			if not chosen_customer.is_empty():
				break

	# Fallback if still empty
	if chosen_customer.is_empty():
		chosen_customer = candidate_npcs[0]
		chosen_recipe = (
			inventory_dishes[0] if not inventory_dishes.is_empty() else "sup_sayur_bening"
		)

	available_table.seat_customer(chosen_customer, chosen_recipe)
	return true


func serve_table(table: Node) -> bool:
	if table == null:
		return false
	if not table.has_method("serve_food"):
		return false
	var current_state = table.get("current_state")
	# 2 is WAITING_FOOD in TableState
	if int(current_state) != 2:
		return false

	var recipe_id := str(table.get("requested_recipe_id"))
	if recipe_id.is_empty():
		return false

	var game_state = get_node("/root/GameState")
	if game_state.get_item_count(recipe_id) <= 0:
		return false

	var quality: int = 2
	for stack in game_state.inventory:
		if str(stack.get("id", "")) == recipe_id and int(stack.get("jumlah", 0)) > 0:
			quality = int(stack.get("kualitas", 2))
			break

	if not game_state.remove_item(recipe_id, 1):
		return false

	_connect_table_signals(table)

	if not table.serve_food(recipe_id, quality):
		return false

	_daily_rush_customers += 1
	var customer_id := str(table.get("current_customer_id"))
	if not customer_id.is_empty():
		game_state.customers_served_today[customer_id] = true
	game_state.increase_reputation(1)
	_daily_rush_rep += 1

	return true


func end_service_rush() -> Dictionary:
	_is_service_active = false
	if _daily_rush_coins == 0 and _daily_rush_customers > 0:
		_daily_rush_coins = _daily_rush_customers * 35
	var summary := {
		"customers_served": _daily_rush_customers,
		"total_coins_earned": _daily_rush_coins,
		"reputation_gained": _daily_rush_rep,
	}
	return summary


func clear_table(table: Node) -> int:
	if table == null or not table.has_method("clear_table"):
		return 0
	return table.clear_table()


func _get_world_tables() -> Array:
	if _world != null and _world.has_method("get_warung_tables"):
		return _world.get_warung_tables()
	if get_tree() != null:
		var current_scene = get_tree().current_scene
		if current_scene != null:
			if current_scene.has_method("get_world"):
				var w = current_scene.get_world()
				if w != null and w.has_method("get_warung_tables"):
					return w.get_warung_tables()
			if current_scene.has_method("get_warung_tables"):
				return current_scene.get_warung_tables()
		if get_tree().root != null:
			for child in get_tree().root.get_children():
				if child.has_method("get_world"):
					var w = child.get_world()
					if w != null and w.has_method("get_warung_tables"):
						return w.get_warung_tables()
				if child.has_method("get_warung_tables"):
					return child.get_warung_tables()
	return []


func _connect_table_signals(table: Node) -> void:
	if table != null and table.has_signal("table_cleared") and not table.table_cleared.is_connected(_on_table_cleared):
		table.table_cleared.connect(_on_table_cleared)


func _on_table_cleared(_table_id: String, coins: int) -> void:
	_daily_rush_coins += coins
	var game_state = get_node_or_null("/root/GameState")
	if game_state != null and coins > 0:
		game_state.earn_coins(coins)


func _has_cooked_food_in_inventory() -> bool:
	var game_state = get_node("/root/GameState")
	for stack in game_state.inventory:
		var item_id := str(stack.get("id", ""))
		var count := int(stack.get("jumlah", 0))
		if count > 0:
			var def: Dictionary = game_state.get_item_definition(item_id)
			if str(def.get("kategori", "")) == "masakan":
				return true
	return false


func get_current_tier() -> Dictionary:
	var current_id: int = get_node("/root/GameState").warung_tier
	for tier in _tiers:
		if int(tier["id"]) == current_id:
			return tier.duplicate(true)
	return {}


func get_upgrade_preview() -> Dictionary:
	var game_state = get_node("/root/GameState")
	var next_tier := _get_tier_by_id(game_state.warung_tier + 1)
	if next_tier.is_empty():
		return {"valid": false, "pesan": "Warung sudah mencapai tier tertinggi."}

	var message := ""
	if game_state.reputation < int(next_tier["reputasi"]):
		message = "Butuh reputasi %d lagi." % (
			int(next_tier["reputasi"]) - game_state.reputation
		)
	elif game_state.coins < int(next_tier["biaya_koin"]):
		message = "Butuh %d koin lagi." % (
			int(next_tier["biaya_koin"]) - game_state.coins
		)
	else:
		for item_id in next_tier["bahan"]:
			var required := int(next_tier["bahan"][item_id])
			var owned: int = game_state.get_item_count(str(item_id))
			if owned < required:
				var item_name := str(
					game_state.get_item_definition(str(item_id)).get("nama", item_id)
				)
				message = "Butuh %s ×%d lagi." % [item_name, required - owned]
				break

	return {
		"valid": message.is_empty(),
		"pesan": message,
		"tier": next_tier,
	}


func upgrade_tier() -> Dictionary:
	var preview := get_upgrade_preview()
	if not bool(preview.get("valid", false)):
		return preview
	var next_tier: Dictionary = preview["tier"]
	var game_state = get_node("/root/GameState")
	if not game_state.upgrade_warung(
		int(next_tier["id"]),
		int(next_tier["biaya_koin"]),
		next_tier["bahan"]
	):
		push_error("Validated warung upgrade could not complete its resource transaction.")
		return {"valid": false, "pesan": "Upgrade tidak dapat diselesaikan."}
	return {
		"valid": true,
		"tier": int(next_tier["id"]),
		"pesan": "Izin usaha diberikan Veral. Warung menjadi %s; %s (maks. %d porsi), kapasitas %d pelanggan/hari, dan pelanggan baru terbuka." % [
			str(next_tier["nama"]),
			_get_tool_name(str(next_tier["alat"])),
			int(next_tier["maks_porsi"]),
			int(next_tier["kapasitas_pelanggan"]),
		],
	}


func is_customer_available(npc_id: String) -> bool:
	var game_state = get_node("/root/GameState")
	var current_tier := get_current_tier()
	if (
		_get_customer_tier(npc_id) < 0
		or _get_customer_tier(npc_id) > game_state.warung_tier
		or current_tier.is_empty()
		or game_state.customers_served_today.has(npc_id)
		or game_state.customers_served_today.size()
		>= int(current_tier.get("kapasitas_pelanggan", 0))
		or _cooking_system == null
		or _affection_system == null
	):
		return false

	for recipe_id in _cooking_system.get_unlocked_recipe_ids():
		if not _cooking_system.is_recipe_available(recipe_id):
			continue
		var reaction := _affection_system.preview_food_reaction(npc_id, recipe_id)
		if reaction in ["suka", "favorit", "spesial"]:
			return true
	return false


func serve_customer(
	npc_id: String,
	item_id: String,
	cooked_on_day: int,
	quality: int,
	is_special: bool = false
) -> Dictionary:
	if not is_customer_available(npc_id):
		return {"valid": false, "pesan": "Pelanggan ini belum bisa dilayani hari ini."}
	if _cooking_system == null or _affection_system == null:
		push_error("Warung system requires cooking and affection systems.")
		return {"valid": false, "pesan": "Sistem warung belum tersedia."}
	var game_state = get_node("/root/GameState")
	var item_definition: Dictionary = game_state.get_item_definition(item_id)
	var base_price := int(item_definition.get("harga_jual", 0))
	var sale_price := floori(float(base_price) * float(quality) / 2.0)
	if (
		str(item_definition.get("kategori", "")) != "masakan"
		or base_price <= 0
		or sale_price <= 0
	):
		push_error("Customer service requires a cooked item with a positive sale price.")
		return {"valid": false, "pesan": "Harga masakan tidak tersedia."}
	var reaction := _affection_system.preview_food_reaction(
		npc_id,
		item_id,
		is_special
	)
	if reaction not in ["suka", "favorit", "spesial"]:
		return {"valid": false, "pesan": "Pelanggan ini belum menyukai masakan tersebut."}

	var result := _affection_system.give_food(
		npc_id,
		item_id,
		cooked_on_day,
		quality,
		is_special,
		true
	)
	if not bool(result.get("valid", false)):
		return result
	if not game_state.earn_coins(sale_price) or not game_state.increase_reputation(1):
		push_error("A completed customer service could not award its validated rewards.")
		return {"valid": false, "pesan": "Hasil penjualan tidak dapat dicatat."}
	result["coins_earned"] = sale_price
	result["reputation_gained"] = 1
	result["pesan"] += "\nTerjual %d koin; reputasi warung +1." % sale_price
	return result


func _get_tier_by_id(tier_id: int) -> Dictionary:
	for tier in _tiers:
		if int(tier["id"]) == tier_id:
			return tier.duplicate(true)
	return {}


func _get_customer_tier(npc_id: String) -> int:
	for tier in _tiers:
		if tier["pelanggan"].has(npc_id):
			return int(tier["id"])
	return -1


func _load_tiers() -> void:
	if not FileAccess.file_exists(TIER_DATA_PATH):
		push_error("Warung tier data file not found: %s" % TIER_DATA_PATH)
		return
	var file := FileAccess.open(TIER_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read warung tier data: %s" % TIER_DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("tiers")) != TYPE_ARRAY:
		push_error("Warung tier data must contain a tiers array: %s" % TIER_DATA_PATH)
		return
	for tier_data in parsed["tiers"]:
		if not _is_valid_tier(tier_data):
			_tiers.clear()
			return
		_tiers.append(tier_data)
	_tiers.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return int(first["id"]) < int(second["id"])
	)
	if (
		_tiers.size() != 4
		or int(_tiers[0]["id"]) != 0
		or int(_tiers[1]["id"]) != 1
		or int(_tiers[2]["id"]) != 2
		or int(_tiers[3]["id"]) != 3
	):
		push_error("Warung tier data must define tiers 0, 1, 2, and 3.")
		_tiers.clear()


func _is_valid_tier(tier: Variant) -> bool:
	if typeof(tier) != TYPE_DICTIONARY:
		push_error("Warung tier entries must be objects.")
		return false
	for key in [
		"id",
		"nama",
		"reputasi",
		"biaya_koin",
		"bahan",
		"alat",
		"maks_porsi",
		"kapasitas_pelanggan",
		"pelanggan",
	]:
		if not tier.has(key):
			push_error("Warung tier is missing '%s'." % key)
			return false
	if (
		not _is_integer_value(tier["id"])
		or typeof(tier["nama"]) != TYPE_STRING
		or typeof(tier["bahan"]) != TYPE_DICTIONARY
		or typeof(tier["alat"]) != TYPE_STRING
		or not _is_integer_value(tier["maks_porsi"])
		or typeof(tier["pelanggan"]) != TYPE_ARRAY
		or not _is_integer_value(tier["reputasi"])
		or not _is_integer_value(tier["biaya_koin"])
		or not _is_integer_value(tier["kapasitas_pelanggan"])
		or int(tier["id"]) < 0
		or int(tier["reputasi"]) < 0
		or int(tier["biaya_koin"]) < 0
		or int(tier["maks_porsi"]) <= 0
		or int(tier["kapasitas_pelanggan"]) <= 0
		or str(tier["alat"]).is_empty()
	):
		push_error("Warung tier data contains an invalid value.")
		return false
	for item_id in tier["bahan"]:
		if (
			int(tier["bahan"][item_id]) <= 0
			or get_node("/root/GameState").get_item_definition(str(item_id)).is_empty()
		):
			push_error("Warung tier requires an invalid material: %s" % str(item_id))
			return false
	for npc_id in tier["pelanggan"]:
		if (
			typeof(npc_id) != TYPE_STRING
			or not FileAccess.file_exists("res://data/npcs/%s.json" % npc_id)
			or _get_customer_tier(str(npc_id)) >= 0
		):
			push_error("Warung tier contains an invalid customer: %s" % str(npc_id))
			return false
	return true


func _get_tool_name(tool_id: String) -> String:
	match tool_id:
		"api_unggun":
			return "api unggun"
		"tungku":
			return "tungku"
		"dapur_warteg":
			return "dapur warteg"
		"dapur_besar":
			return "dapur besar"
	return "alat masak"


func _is_integer_value(value: Variant) -> bool:
	return (
		typeof(value) == TYPE_INT
		or typeof(value) == TYPE_FLOAT
	) and is_equal_approx(float(value), float(int(value)))
