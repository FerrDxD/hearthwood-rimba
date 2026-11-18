extends Node
class_name HearthwoodQuestSystem

signal quest_progressed(npc_id: String, chapter_index: int)

const QUEST_DATA_PATH: String = "res://data/story/quests.json"
const CHAPTER_COUNT: int = 4
const NPC_DATA_DIRECTORY: String = "res://data/npcs"

var _quests: Dictionary = {}


func _ready() -> void:
	_load_quests()


func get_quest_ids() -> Array[String]:
	var quest_ids: Array[String] = []
	for quest_id in _quests:
		quest_ids.append(str(quest_id))
	quest_ids.sort()
	return quest_ids


func get_chapter_index(npc_id: String) -> int:
	var game_state = get_node("/root/GameState")
	return clampi(int(game_state.quest_chapters.get(npc_id, 0)), 0, CHAPTER_COUNT)


func get_chapter(npc_id: String) -> Dictionary:
	var quest: Variant = _quests.get(npc_id, {})
	if typeof(quest) != TYPE_DICTIONARY:
		return {}
	var chapters: Array = quest.get("bab", [])
	var index := get_chapter_index(npc_id)
	if index >= chapters.size():
		return {}
	var chapter: Dictionary = chapters[index]
	var result := chapter.duplicate(true)
	result["npc_id"] = npc_id
	result["nama"] = str(quest.get("nama", ""))
	return result


func is_quest_complete(npc_id: String) -> bool:
	return not _quests.has(npc_id) or get_chapter(npc_id).is_empty()


func get_objective(npc_id: String) -> String:
	return str(get_chapter(npc_id).get("objective", ""))


func get_quest_name(npc_id: String) -> String:
	var quest: Variant = _quests.get(npc_id, {})
	if typeof(quest) != TYPE_DICTIONARY:
		return str(npc_id).capitalize()
	return str(quest.get("nama", str(npc_id).capitalize()))


func get_quest_summary(npc_id: String) -> Dictionary:
	var game_state = get_node("/root/GameState")
	var chapter := get_chapter(npc_id)
	return {
		"id": npc_id,
		"nama": get_quest_name(npc_id),
		"hati": game_state.get_npc_heart_level(npc_id),
		"chapter_index": get_chapter_index(npc_id),
		"total_chapter": CHAPTER_COUNT,
		"selesai": chapter.is_empty(),
		"judul": str(chapter.get("judul", "")),
		"objective": str(chapter.get("objective", "")),
		"kebutuhan": get_requirement_text(npc_id),
		"hadiah": get_reward_text(npc_id),
	}


func get_reward_text(npc_id: String) -> String:
	var chapter := get_chapter(npc_id)
	if chapter.is_empty():
		return ""
	var rewards: Dictionary = chapter.get("hadiah", {})
	var parts := PackedStringArray()
	if int(rewards.get("koin", 0)) > 0:
		parts.append("%d koin" % int(rewards["koin"]))
	if int(rewards.get("reputasi", 0)) > 0:
		parts.append("reputasi +%d" % int(rewards["reputasi"]))
	if rewards.has("item"):
		var item_id := str(rewards["item"])
		var item_name := str(
			get_node("/root/GameState").get_item_definition(item_id).get("nama", item_id)
		)
		parts.append(item_name)
	if rewards.has("fitur"):
		parts.append("fitur %s" % str(rewards["fitur"]).replace("_", " "))
	return ", ".join(parts)


func get_requirement_text(npc_id: String) -> String:
	var chapter := get_chapter(npc_id)
	if chapter.is_empty():
		return ""
	var game_state = get_node("/root/GameState")
	var required_heart := int(chapter.get("hati", 0))
	var current_heart: int = game_state.get_npc_heart_level(npc_id)
	if current_heart < required_heart:
		return "Dekatkan hati dengan %s ke hati %d (sekarang hati %d)." % [
			_get_display_name(npc_id),
			required_heart,
			current_heart,
		]

	var missing := PackedStringArray()
	var requirements: Dictionary = chapter.get("butuh", {})
	for item_id in requirements:
		var required := int(requirements[item_id])
		var owned: int = game_state.get_item_count(str(item_id))
		if owned < required:
			var item_name := str(
				game_state.get_item_definition(str(item_id)).get("nama", item_id)
			)
			missing.append("%s ×%d (tersedia %d)" % [item_name, required, owned])
	var coin_cost := int(chapter.get("biaya_koin", 0))
	if game_state.coins < coin_cost:
		missing.append("%d koin (tersedia %d)" % [coin_cost, game_state.coins])
	if missing.is_empty():
		return "Serahkan bahan kepada %s." % _get_display_name(npc_id)
	return "Butuh %s." % ", ".join(missing)


func can_turn_in(npc_id: String) -> bool:
	var chapter := get_chapter(npc_id)
	if chapter.is_empty():
		return false
	var game_state = get_node("/root/GameState")
	if game_state.get_npc_heart_level(npc_id) < int(chapter.get("hati", 0)):
		return false
	if game_state.coins < int(chapter.get("biaya_koin", 0)):
		return false
	for item_id in chapter.get("butuh", {}):
		if game_state.get_item_count(str(item_id)) < int(chapter["butuh"][item_id]):
			return false
	return true


func turn_in(npc_id: String) -> Dictionary:
	var chapter := get_chapter(npc_id)
	if chapter.is_empty():
		return {"valid": false, "pesan": "Quest ini sudah selesai."}
	if not can_turn_in(npc_id):
		return {"valid": false, "pesan": get_requirement_text(npc_id)}

	var game_state = get_node("/root/GameState")
	var requirements: Dictionary = chapter.get("butuh", {})
	if not requirements.is_empty() and not game_state.remove_items(requirements):
		return {"valid": false, "pesan": "Bahan quest berubah sebelum diserahkan."}
	var coin_cost := int(chapter.get("biaya_koin", 0))
	if coin_cost > 0 and not game_state.spend_coins(coin_cost):
		push_error("Validated quest coin cost could not be paid: %s" % npc_id)
		return {"valid": false, "pesan": "Koin tidak dapat dibayarkan."}

	var rewards: Dictionary = chapter.get("hadiah", {})
	var reward_messages := PackedStringArray()
	var coin_reward := int(rewards.get("koin", 0))
	if coin_reward > 0:
		game_state.earn_coins(coin_reward)
		reward_messages.append("%d koin" % coin_reward)
	var reputation_reward := int(rewards.get("reputasi", 0))
	if reputation_reward > 0:
		game_state.increase_reputation(reputation_reward)
		reward_messages.append("reputasi +%d" % reputation_reward)
	var item_reward := str(rewards.get("item", ""))
	if not item_reward.is_empty() and game_state.add_item(item_reward):
		if not game_state.items_received_from_npcs.has(item_reward):
			game_state.items_received_from_npcs.append(item_reward)
		reward_messages.append(str(game_state.get_item_definition(item_reward).get("nama", item_reward)))
	var feature_reward := str(rewards.get("fitur", ""))
	if not feature_reward.is_empty() and not game_state.unlocked_features.has(feature_reward):
		game_state.unlocked_features.append(feature_reward)
		reward_messages.append("fitur %s" % feature_reward.replace("_", " "))

	var chapter_index := get_chapter_index(npc_id)
	game_state.quest_chapters[npc_id] = chapter_index + 1
	var clue := str(chapter.get("petunjuk_asap", ""))
	if not clue.is_empty() and not game_state.smoke_clues.has(clue):
		game_state.smoke_clues.append(clue)

	var quest_id := "%s_quest_%d" % [npc_id, int(chapter.get("hati", 0)) + 1]
	game_state.complete_quest(quest_id)
	game_state.state_changed.emit()
	quest_progressed.emit(npc_id, chapter_index + 1)

	var message := str(chapter.get("dialog_selesai", ""))
	if not reward_messages.is_empty():
		message += "\nHadiah: %s." % ", ".join(reward_messages)
	if not clue.is_empty():
		message += "\nPetunjuk asap: %s" % clue
	return {
		"valid": true,
		"pesan": message,
		"chapter_index": chapter_index + 1,
		"komplit": is_quest_complete(npc_id),
		"petunjuk_asap": clue,
	}


func get_smoke_clues() -> Array[String]:
	var game_state = get_node("/root/GameState")
	var clues: Array[String] = []
	for clue in game_state.smoke_clues:
		clues.append(str(clue))
	return clues


func _get_display_name(npc_id: String) -> String:
	var path := "%s/%s.json" % [NPC_DATA_DIRECTORY, npc_id]
	if not FileAccess.file_exists(path):
		return npc_id.capitalize()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return npc_id.capitalize()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return npc_id.capitalize()
	return str(parsed.get("nama", npc_id.capitalize()))


func _load_quests() -> void:
	if not FileAccess.file_exists(QUEST_DATA_PATH):
		push_error("Quest data file not found: %s" % QUEST_DATA_PATH)
		return
	var file := FileAccess.open(QUEST_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read quest data: %s" % QUEST_DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or typeof(parsed.get("quests")) != TYPE_DICTIONARY:
		push_error("Quest data must contain a quests object: %s" % QUEST_DATA_PATH)
		return
	for npc_id in parsed["quests"]:
		var quest: Variant = parsed["quests"][npc_id]
		if not _is_valid_quest(str(npc_id), quest):
			_quests.clear()
			return
		_quests[str(npc_id)] = quest


func _is_valid_quest(npc_id: String, quest: Variant) -> bool:
	if (
		typeof(quest) != TYPE_DICTIONARY
		or typeof(quest.get("nama")) != TYPE_STRING
		or typeof(quest.get("bab")) != TYPE_ARRAY
		or quest["bab"].size() != CHAPTER_COUNT
		or not FileAccess.file_exists("%s/%s.json" % [NPC_DATA_DIRECTORY, npc_id])
	):
		push_error("Quest data is missing required fields: %s" % npc_id)
		return false
	var game_state = get_node("/root/GameState")
	for index in CHAPTER_COUNT:
		var chapter: Variant = quest["bab"][index]
		if (
			typeof(chapter) != TYPE_DICTIONARY
			or int(chapter.get("hati", -1)) != index
			or typeof(chapter.get("judul")) != TYPE_STRING
			or typeof(chapter.get("objective")) != TYPE_STRING
			or typeof(chapter.get("dialog_aktif")) != TYPE_STRING
			or typeof(chapter.get("dialog_selesai")) != TYPE_STRING
			or typeof(chapter.get("butuh")) != TYPE_DICTIONARY
			or typeof(chapter.get("hadiah")) != TYPE_DICTIONARY
			or typeof(chapter.get("petunjuk_asap")) != TYPE_STRING
			or str(chapter["objective"]).is_empty()
			or str(chapter["dialog_aktif"]).is_empty()
			or str(chapter["dialog_selesai"]).is_empty()
		):
			push_error("Quest chapter %d is invalid: %s" % [index, npc_id])
			return false
		for item_id in chapter["butuh"]:
			if (
				int(chapter["butuh"][item_id]) <= 0
				or game_state.get_item_definition(str(item_id)).is_empty()
			):
				push_error("Quest chapter %d requires an invalid item: %s" % [index, npc_id])
				return false
		var rewards: Dictionary = chapter["hadiah"]
		for reward_key in rewards:
			if not ["koin", "reputasi", "item", "fitur"].has(str(reward_key)):
				push_error("Quest chapter %d has an unsupported reward: %s" % [index, reward_key])
				return false
		if (
			(
				rewards.has("koin")
				and not _is_non_negative_int(rewards["koin"])
			)
			or (
				rewards.has("reputasi")
				and not _is_non_negative_int(rewards["reputasi"])
			)
			or (
				rewards.has("item")
				and game_state.get_item_definition(str(rewards["item"])).is_empty()
			)
			or (rewards.has("fitur") and typeof(rewards["fitur"]) != TYPE_STRING)
		):
			push_error("Quest chapter %d has invalid rewards: %s" % [index, npc_id])
			return false
		if chapter.has("biaya_koin") and not _is_non_negative_int(chapter["biaya_koin"]):
			push_error("Quest chapter %d has an invalid coin cost: %s" % [index, npc_id])
			return false
	return true


func _is_non_negative_int(value: Variant) -> bool:
	return (
		(typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT)
		and is_finite(float(value))
		and is_equal_approx(float(value), float(int(value)))
		and int(value) >= 0
	)
