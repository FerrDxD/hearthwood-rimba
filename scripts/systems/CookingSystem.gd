extends Node
class_name HearthwoodCookingSystem

signal recipes_unlocked

const RECIPE_DIRECTORY: String = "res://data/recipes"
const TOOL_LEVELS: Dictionary = {
	"api_unggun": 0,
	"tungku": 1,
	"dapur_warteg": 2,
}
const TOOL_PORTION_LIMITS: Dictionary = {
	"api_unggun": 2,
	"tungku": 3,
	"dapur_warteg": 5,
}

var _recipes: Dictionary = {}
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	if not _load_recipes():
		return
	var game_state = get_node("/root/GameState")
	game_state.inventory_changed.connect(_refresh_recipe_unlocks)
	get_node("/root/TimeSystem").day_changed.connect(_on_day_changed)
	_refresh_recipe_unlocks()


func get_recipe(recipe_id: String) -> Dictionary:
	var recipe: Variant = _recipes.get(recipe_id, {})
	return recipe if typeof(recipe) == TYPE_DICTIONARY else {}


func unlock_recipe(recipe_id: String) -> bool:
	if not _recipes.has(recipe_id):
		push_error("Cannot unlock an unknown recipe: %s" % recipe_id)
		return false
	var game_state = get_node("/root/GameState")
	if game_state.unlocked_recipes.has(recipe_id):
		return false
	game_state.unlocked_recipes.append(recipe_id)
	recipes_unlocked.emit()
	game_state.state_changed.emit()
	return true


func unlock_recipe_by_name(recipe_name: String) -> bool:
	for recipe_id in _recipes:
		if str(_recipes[recipe_id].get("nama", "")) == recipe_name:
			return unlock_recipe(str(recipe_id))
	push_error("Cannot unlock an unknown recipe name: %s" % recipe_name)
	return false


func get_unlocked_recipe_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	var game_state = get_node("/root/GameState")
	for recipe_id in _recipes:
		if game_state.unlocked_recipes.has(recipe_id):
			unlocked_ids.append(recipe_id)
	return unlocked_ids


func get_available_tool_ids() -> Array[String]:
	var available_tools: Array[String] = []
	var highest_level := clampi(int(get_node("/root/GameState").warung_tier), 0, 2)
	for tool_id in TOOL_LEVELS:
		if int(TOOL_LEVELS[tool_id]) <= highest_level:
			available_tools.append(str(tool_id))
	return available_tools


func get_max_portions(tool_id: String) -> int:
	return int(TOOL_PORTION_LIMITS.get(tool_id, 0))


func preview_cooking(recipe_id: String, portions: int, tool_id: String) -> Dictionary:
	var game_state = get_node("/root/GameState")
	var recipe := get_recipe(recipe_id)
	if recipe.is_empty() or not game_state.unlocked_recipes.has(recipe_id):
		return _invalid_preview("Resep belum terbuka.")
	if not TOOL_LEVELS.has(tool_id) or not get_available_tool_ids().has(tool_id):
		return _invalid_preview("Alat masak belum tersedia.")
	if int(TOOL_LEVELS[tool_id]) < int(TOOL_LEVELS[str(recipe["alat_minimum"])]):
		return _invalid_preview("Resep ini membutuhkan %s." % _get_tool_name(
			str(recipe["alat_minimum"])
		))
	var max_portions := get_max_portions(tool_id)
	if portions < 1 or portions > max_portions:
		return _invalid_preview("Porsi harus antara 1 dan %d." % max_portions)

	var energy_cost := portions * 5
	if game_state.energy < energy_cost:
		return _invalid_preview("Energi tidak cukup (butuh %d)." % energy_cost)

	var ingredients: Dictionary = {}
	for item_id in recipe["bahan_per_porsi"]:
		var required_count := int(recipe["bahan_per_porsi"][item_id]) * portions
		ingredients[str(item_id)] = required_count
		var owned_count: int = game_state.get_item_count(str(item_id))
		if owned_count < required_count:
			var item_name := str(game_state.get_item_definition(str(item_id)).get("nama", item_id))
			return _invalid_preview("Butuh %s ×%d (tersedia %d)." % [
				item_name,
				required_count,
				owned_count,
			])

	return {
		"valid": true,
		"pesan": "Siap dimasak: %d porsi, biaya %d energi." % [portions, energy_cost],
		"bahan": ingredients,
		"biaya_energi": energy_cost,
		"maks_porsi": max_portions,
	}


func cook(
	recipe_id: String, portions: int, tool_id: String, timing_result: String = "skip"
) -> Dictionary:
	var preview := preview_cooking(recipe_id, portions, tool_id)
	if not bool(preview.get("valid", false)):
		return preview
	if not ["green", "yellow", "red", "skip"].has(timing_result):
		return _invalid_preview("Hasil mini-game timing tidak valid.")

	var game_state = get_node("/root/GameState")
	if not game_state.remove_items(preview["bahan"]):
		return _invalid_preview("Bahan berubah sebelum proses memasak dimulai.")
	game_state.change_energy(-int(preview["biaya_energi"]))

	var recipe := get_recipe(recipe_id)
	var quality := _calculate_quality(int(recipe["kualitas_dasar"]), timing_result)
	if not game_state.add_item(recipe_id, portions, game_state.current_day, quality):
		push_error("Validated cooked item could not be added to inventory: %s" % recipe_id)
		return _invalid_preview("Hasil masakan gagal disimpan.")

	return {
		"valid": true,
		"resep": recipe_id,
		"porsi": portions,
		"kualitas": quality,
		"tanggal_masak": game_state.current_day,
	}


func _calculate_quality(base_quality: int, timing_result: String) -> int:
	var quality := base_quality
	match timing_result:
		"green":
			quality += 1
		"red":
			quality -= 1
		"skip":
			quality += _random.randi_range(-1, 1)
	return clampi(quality, 1, 3)


func _load_recipes() -> bool:
	var directory := DirAccess.open(RECIPE_DIRECTORY)
	if directory == null:
		push_error("Recipe directory not found: %s" % RECIPE_DIRECTORY)
		return false
	var recipe_files := directory.get_files()
	recipe_files.sort()
	for file_name in recipe_files:
		if not file_name.ends_with(".json"):
			continue
		var path := "%s/%s" % [RECIPE_DIRECTORY, file_name]
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_error("Could not read recipe file: %s" % path)
			return false
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if typeof(parsed) != TYPE_DICTIONARY or not _is_valid_recipe(parsed, path):
			push_error("Recipe data is invalid: %s" % path)
			return false
		var recipe_id := str(parsed["id"])
		if _recipes.has(recipe_id):
			push_error("Duplicate recipe ID: %s" % recipe_id)
			return false
		_recipes[recipe_id] = parsed
	return not _recipes.is_empty()


func _is_valid_recipe(recipe: Dictionary, path: String) -> bool:
	for key in ["id", "nama", "alat_minimum", "bahan_per_porsi", "kualitas_dasar"]:
		if not recipe.has(key):
			push_error("Recipe is missing '%s': %s" % [key, path])
			return false
	if (
		typeof(recipe["id"]) != TYPE_STRING
		or typeof(recipe["nama"]) != TYPE_STRING
		or typeof(recipe["bahan_per_porsi"]) != TYPE_DICTIONARY
		or str(recipe["id"]).is_empty()
		or str(recipe["nama"]).is_empty()
		or not TOOL_LEVELS.has(str(recipe["alat_minimum"]))
		or int(recipe["kualitas_dasar"]) < 1
		or int(recipe["kualitas_dasar"]) > 3
		or recipe["bahan_per_porsi"].is_empty()
	):
		return false

	var game_state = get_node("/root/GameState")
	if (
		str(game_state.get_item_definition(str(recipe["id"])).get("kategori", ""))
		!= "masakan"
	):
		push_error("Recipe output must be a cooked item in the item catalog: %s" % path)
		return false
	for item_id in recipe["bahan_per_porsi"]:
		if (
			int(recipe["bahan_per_porsi"][item_id]) <= 0
			or str(game_state.get_item_definition(str(item_id)).get("kategori", ""))
			== "masakan"
		):
			push_error("Recipe contains an invalid ingredient: %s" % path)
			return false
	return true


func _refresh_recipe_unlocks() -> void:
	var game_state = get_node("/root/GameState")
	var newly_unlocked: Array[String] = []
	for recipe_id in _recipes:
		var recipe: Dictionary = _recipes[recipe_id]
		var item_opener := str(recipe.get("item_pembuka", ""))
		if (
			not item_opener.is_empty()
			and game_state.get_item_count(item_opener) > 0
			and not game_state.unlocked_recipes.has(recipe_id)
		):
			newly_unlocked.append(str(recipe_id))
	for recipe_id in newly_unlocked:
		unlock_recipe(recipe_id)


func _on_day_changed(_day: int) -> void:
	get_node("/root/GameState").age_cooked_food()


func _invalid_preview(message: String) -> Dictionary:
	return {"valid": false, "pesan": message}


func _get_tool_name(tool_id: String) -> String:
	match tool_id:
		"api_unggun":
			return "api unggun"
		"tungku":
			return "tungku"
		"dapur_warteg":
			return "dapur warteg"
	return tool_id
