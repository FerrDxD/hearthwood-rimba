extends Node
class_name HearthwoodAffectionSystem

signal heart_level_changed(npc_id: String, new_level: int)

const NPC_DATA_DIRECTORY: String = "res://data/npcs"
const HEART_POINT_THRESHOLDS: Array[int] = [0, 10, 40, 90]
const MAX_HEART_LEVEL: int = 3

var _cooking_system: HearthwoodCookingSystem


func set_cooking_system(cooking_system: HearthwoodCookingSystem) -> void:
	_cooking_system = cooking_system


func give_food(
	npc_id: String,
	item_id: String,
	cooked_on_day: int,
	quality: int,
	is_special: bool = false,
	is_customer_service: bool = false
) -> Dictionary:
	var game_state = get_node("/root/GameState")
	var daily_interactions: Dictionary = (
		game_state.customers_served_today if is_customer_service else game_state.gifts_given_today
	)
	if daily_interactions.has(npc_id):
		return _invalid_gift(
			"Pelanggan ini sudah dilayani hari ini."
			if is_customer_service
			else "Kamu sudah memberi masakan kepada NPC ini hari ini."
		)

	var npc_data := _load_npc_data(npc_id)
	if npc_data.is_empty():
		return _invalid_gift("Data NPC tidak tersedia.")
	var item_definition: Dictionary = game_state.get_item_definition(item_id)
	if str(item_definition.get("kategori", "")) != "masakan":
		return _invalid_gift("Hanya masakan yang bisa diberikan.")
	if _cooking_system == null:
		push_error("Affection system requires a cooking system before gifts can be given.")
		return _invalid_gift("Sistem memasak belum tersedia.")
	var shelf_life := int(item_definition.get("masa_simpan_hari", 3))
	if (
		cooked_on_day < 1
		or cooked_on_day > game_state.current_day
		or game_state.current_day - cooked_on_day >= shelf_life
		or quality < 1
		or quality > 3
	):
		return _invalid_gift("Masakan ini sudah tidak layak diberikan.")
	var recipe := _cooking_system.get_recipe(item_id)
	if recipe.is_empty():
		push_error("Cooked item has no matching recipe: %s" % item_id)
		return _invalid_gift("Data resep tidak tersedia.")
	var reaction := _get_reaction(npc_id, item_id, recipe, npc_data, is_special)
	if not game_state.remove_item_stack(item_id, 1, cooked_on_day, quality):
		return _invalid_gift("Masakan yang dipilih sudah tidak tersedia.")
	if npc_id == "rast":
		game_state.npc_recently_returned_from_forest.erase(npc_id)

	var base_points := _get_base_points(reaction)
	var points_delta := _apply_quality_penalty(base_points, quality)
	var disliked_streak := int(game_state.disliked_gift_streaks.get(npc_id, 0))
	if reaction == "tidak_suka":
		disliked_streak += 1
		if disliked_streak >= 3:
			reaction = "benci"
			points_delta = -3
			disliked_streak = 0
	else:
		disliked_streak = 0
	game_state.disliked_gift_streaks[npc_id] = disliked_streak

	daily_interactions[npc_id] = true
	var history: Array = game_state.npc_gift_history.get(npc_id, [])
	if not history.has(item_id):
		history.append(item_id)
	game_state.npc_gift_history[npc_id] = history

	var old_level := clampi(game_state.get_npc_heart_level(npc_id), 0, MAX_HEART_LEVEL)
	var old_points := int(game_state.affection_points.get(npc_id, 0))
	var point_floor := HEART_POINT_THRESHOLDS[old_level]
	var new_points := clampi(old_points + points_delta, point_floor, HEART_POINT_THRESHOLDS[-1])
	points_delta = new_points - old_points
	game_state.affection_points[npc_id] = new_points
	var new_level := old_level
	while (
		new_level < MAX_HEART_LEVEL
		and new_points >= HEART_POINT_THRESHOLDS[new_level + 1]
	):
		new_level += 1
	game_state.npc_heart_levels[npc_id] = new_level

	var reward_messages := PackedStringArray()
	for heart_level in range(old_level + 1, new_level + 1):
		var reward_message := _apply_heart_reward(npc_id, npc_data, heart_level)
		if not reward_message.is_empty():
			reward_messages.append(reward_message)
	game_state.state_changed.emit()
	if new_level > old_level:
		heart_level_changed.emit(npc_id, new_level)

	var message := _build_result_message(reaction, points_delta, new_points, new_level)
	if not reward_messages.is_empty():
		message += "\n" + "\n".join(reward_messages)
	return {
		"valid": true,
		"reaction": reaction,
		"points_gained": points_delta,
		"total_points": new_points,
		"heart_level": new_level,
		"pesan": message,
	}


func preview_food_reaction(
	npc_id: String, item_id: String, is_special: bool = false
) -> String:
	var npc_data := _load_npc_data(npc_id)
	if npc_data.is_empty():
		return ""
	if _cooking_system == null:
		push_error("Affection system requires a cooking system to evaluate food.")
		return ""
	var recipe := _cooking_system.get_recipe(item_id)
	if recipe.is_empty():
		return ""
	return _get_reaction(npc_id, item_id, recipe, npc_data, is_special)


func _get_reaction(
	npc_id: String,
	item_id: String,
	recipe: Dictionary,
	npc_data: Dictionary,
	is_special: bool
) -> String:
	if _is_special_gift(npc_id, recipe, is_special):
		return "spesial"
	if _recipe_list_contains(recipe, "favorit_npc", npc_id):
		return "favorit"
	if _recipe_list_contains(recipe, "tidak_suka_npc", npc_id):
		return "tidak_suka"

	var game_state = get_node("/root/GameState")
	var history: Array = game_state.npc_gift_history.get(npc_id, [])
	var food_preferences: Dictionary = npc_data.get("selera_masakan", {})
	if _matches_preferences(
		npc_data.get("tidak_suka", []), recipe, history, item_id
	) or _matches_preferences(
		food_preferences.get("tidak_suka", []), recipe, history, item_id
	):
		return "tidak_suka"
	if _recipe_list_contains(recipe, "suka_npc", npc_id):
		return "suka"
	if _matches_preferences(npc_data.get("suka", []), recipe, history, item_id):
		return "suka"
	if _matches_preferences(
		food_preferences.get("suka", []), recipe, history, item_id
	):
		return "suka"
	return "netral"


func _is_special_gift(npc_id: String, recipe: Dictionary, explicit_condition: bool) -> bool:
	if explicit_condition:
		return true
	var game_state = get_node("/root/GameState")
	if (
		npc_id == "rast"
		and bool(game_state.npc_recently_returned_from_forest.get(npc_id, false))
	):
		return true
	if str(game_state.current_weather) != "dingin":
		return false
	for tag_value in recipe.get("sifat_rasa", []):
		if str(tag_value) in ["hangat", "menghangatkan"]:
			return true
	return false


func _matches_preferences(
	preferences: Array, recipe: Dictionary, history: Array, item_id: String
) -> bool:
	for preference_value in preferences:
		var preference := str(preference_value).to_lower()
		if preference == "menu_baru" and not history.has(item_id):
			return true
		if preference == "menu_berulang" and history.has(item_id):
			return true
		var food_descriptors: Array = recipe.get("sifat_rasa", []).duplicate()
		food_descriptors.append(str(recipe.get("nama", "")))
		food_descriptors.append(str(recipe.get("id", "")).replace("_", " "))
		for descriptor_value in food_descriptors:
			var descriptor := str(descriptor_value).replace("_", " ").to_lower()
			if (
				not descriptor.is_empty()
				and (preference.contains(descriptor) or descriptor.contains(preference))
			):
				return true
	return false


func _recipe_list_contains(recipe: Dictionary, key: String, npc_id: String) -> bool:
	var npc_ids: Variant = recipe.get(key, [])
	return typeof(npc_ids) == TYPE_ARRAY and npc_ids.has(npc_id)


func _get_base_points(reaction: String) -> int:
	match reaction:
		"spesial":
			return 8
		"favorit":
			return 5
		"suka":
			return 3
		"netral":
			return 1
	return 0


func _apply_quality_penalty(base_points: int, quality: int) -> int:
	if base_points <= 0:
		return base_points
	var quality_steps_below_three := 3 - quality
	return floori(float(base_points) * (100.0 - 20.0 * quality_steps_below_three) / 100.0)


func _apply_heart_reward(
	npc_id: String, npc_data: Dictionary, heart_level: int
) -> String:
	var game_state = get_node("/root/GameState")
	var rewards: Dictionary = npc_data.get("hadiah", {})
	var reward: Variant = rewards.get("hati_%d" % heart_level, {})
	if typeof(reward) != TYPE_DICTIONARY:
		push_error("NPC reward must be an object: %s (heart %d)" % [npc_id, heart_level])
		return ""
	var reward_type := str(reward.get("tipe", ""))
	var reward_text := str(reward.get("isi", ""))
	match reward_type:
		"info":
			return "Hati %d — %s" % [heart_level, reward_text]
		"diskon":
			return "Hati %d — diskon toko %d%% terbuka." % [
				heart_level,
				int(reward.get("nilai", 0)),
			]
		"resep", "diskon_resep":
			var recipe_name := str(reward.get("resep", ""))
			if _cooking_system == null:
				push_error("Cooking system is unavailable for recipe reward: %s" % recipe_name)
				return "Hati %d — hadiah resep belum dapat dibuka." % heart_level
			if not _cooking_system.unlock_recipe_by_name(recipe_name):
				if reward_type == "diskon_resep":
					return "Hati %d — diskon toko %d%% terbuka; resep %s sudah terbuka." % [
						heart_level,
						int(reward.get("nilai", 0)),
						recipe_name,
					]
				return "Hati %d — resep %s sudah terbuka." % [heart_level, recipe_name]
			if reward_type == "diskon_resep":
				return "Hati %d — diskon toko %d%% dan resep %s terbuka." % [
					heart_level,
					int(reward.get("nilai", 0)),
					recipe_name,
				]
			return "Hati %d — resep %s terbuka." % [heart_level, recipe_name]
		"cerita":
			return "Hati %d — %s" % [
				heart_level,
				reward_text if not reward_text.is_empty() else "cerita pribadi baru terbuka.",
			]
		"quest":
			var quest_id := "%s_main" % npc_id
			if not game_state.unlocked_quests.has(quest_id):
				game_state.unlocked_quests.append(quest_id)
			return "Hati %d — %s" % [
				heart_level,
				reward_text if not reward_text.is_empty() else "main quest terbuka untuk versi mendatang.",
			]
	push_error("Unsupported NPC reward type '%s': %s" % [reward_type, npc_id])
	return ""


func _build_result_message(
	reaction: String, points_delta: int, total_points: int, heart_level: int
) -> String:
	var reaction_name := reaction.replace("_", " ").capitalize()
	var point_text := "+%d" % points_delta if points_delta > 0 else str(points_delta)
	return "%s! %s poin afeksi. Total %d; hati %d." % [
		reaction_name,
		point_text,
		total_points,
		heart_level,
	]


func _load_npc_data(npc_id: String) -> Dictionary:
	var path := "%s/%s.json" % [NPC_DATA_DIRECTORY, npc_id]
	if not FileAccess.file_exists(path):
		push_error("NPC data file not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not read NPC data file: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("hadiah")) != TYPE_DICTIONARY:
		push_error("NPC data is missing reward information: %s" % path)
		return {}
	return parsed


func _invalid_gift(message: String) -> Dictionary:
	return {"valid": false, "pesan": message}
