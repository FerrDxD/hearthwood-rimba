extends Node
class_name HearthwoodWarungSystem

const TIER_DATA_PATH: String = "res://data/warung/tiers.json"

var _tiers: Array[Dictionary] = []
var _cooking_system: HearthwoodCookingSystem
var _affection_system: HearthwoodAffectionSystem


func _ready() -> void:
	_load_tiers()


func set_systems(
	cooking_system: HearthwoodCookingSystem,
	affection_system: HearthwoodAffectionSystem
) -> void:
	_cooking_system = cooking_system
	_affection_system = affection_system


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
