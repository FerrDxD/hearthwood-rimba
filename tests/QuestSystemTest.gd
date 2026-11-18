extends SceneTree

const QUEST_SYSTEM_SCENE: PackedScene = preload("res://scenes/QuestSystem.tscn")
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
const TEST_SAVE_PATH: String = "user://phase12-quest-test.json"
const PROLOGUE_STEPS: Array[String] = [
	"prologue_find_rast",
	"prologue_collect_sayur",
	"prologue_meet_veral",
	"prologue_cook_first_meal",
	"prologue_receive_residence_permit",
	"prologue_settle_in_hut",
]


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_remove_test_file(TEST_SAVE_PATH)
	var game_state = root.get_node("GameState")
	_reset_game_state(game_state)

	var quest_system := QUEST_SYSTEM_SCENE.instantiate() as HearthwoodQuestSystem
	root.add_child(quest_system)
	await process_frame

	if (
		quest_system.get_quest_ids() != ["rast", "veral"]
		or quest_system.get_chapter("rast").get("hati", -1) != 0
		or quest_system.get_chapter("veral").get("hati", -1) != 0
		or quest_system.get_chapter("rast").get("butuh", {}).size() != 1
		or int(quest_system.get_chapter("rast").get("butuh", {}).get("kayu", 0)) != 1
	):
		push_error("Quest data should expose four sequential chapters for Rast and Veral.")
		quit(1)
		return

	# Chapter 0 needs its item and is gated by heart level 0.
	game_state.add_item("kayu", 1)
	var coins_before: int = game_state.coins
	var first_result: Dictionary = quest_system.turn_in("rast")
	if (
		not bool(first_result.get("valid", false))
		or game_state.get_item_count("kayu") != 0
		or game_state.coins != coins_before + 40
		or game_state.reputation != 1
		or quest_system.get_chapter_index("rast") != 1
		or not game_state.completed_quests.has("rast_quest_1")
		or quest_system.get_chapter("rast").get("hati", -1) != 1
	):
		push_error("Handing over the first Rast chapter should consume its item and award its reward.")
		quit(1)
		return

	# Chapter 1 is gated until Rast reaches heart 1.
	game_state.add_item("jamur_hutan", 2)
	if (
		quest_system.can_turn_in("rast")
		or bool(quest_system.turn_in("rast").get("valid", true))
		or not quest_system.get_requirement_text("rast").contains("hati 1")
	):
		push_error("A quest chapter must not be turned in before its heart level is reached.")
		quit(1)
		return

	game_state.npc_heart_levels["rast"] = 1
	if not quest_system.can_turn_in("rast"):
		push_error("Reaching the required heart should unlock the next Rast chapter.")
		quit(1)
		return
	coins_before = game_state.coins
	if (
		not bool(quest_system.turn_in("rast").get("valid", false))
		or game_state.coins != coins_before + 60
		or game_state.reputation != 3
		or quest_system.get_chapter_index("rast") != 2
	):
		push_error("The second Rast chapter should award its coins and reputation.")
		quit(1)
		return

	game_state.npc_heart_levels["rast"] = 2
	game_state.add_item("kayu", 1)
	game_state.add_item("daun_hutan", 2)
	if (
		not bool(quest_system.turn_in("rast").get("valid", false))
		or game_state.get_item_count("tombak_hutan") != 1
		or quest_system.get_smoke_clues().size() != 1
		or quest_system.get_chapter_index("rast") != 3
	):
		push_error("The deep-forest chapter should award its defense item and first smoke clue.")
		quit(1)
		return

	game_state.npc_heart_levels["rast"] = 3
	game_state.add_item("kayu", 3)
	if (
		not bool(quest_system.turn_in("rast").get("valid", false))
		or not game_state.unlocked_features.has("gudang_bahan")
		or not quest_system.is_quest_complete("rast")
		or not str(quest_system.get_objective("rast")).is_empty()
	):
		push_error("The final Rast chapter should unlock its feature and complete the quest.")
		quit(1)
		return

	# Veral chapters: permit board, mediation meal, council pastry, kingdom trip.
	game_state.add_item("kayu", 1)
	if not bool(quest_system.turn_in("veral").get("valid", false)):
		push_error("Veral's first chapter should accept its requested material.")
		quit(1)
		return
	game_state.npc_heart_levels["veral"] = 1
	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 2)
	if not bool(quest_system.turn_in("veral").get("valid", false)):
		push_error("Veral's mediation chapter should accept a cooked meal.")
		quit(1)
		return
	game_state.npc_heart_levels["veral"] = 2
	game_state.add_item("kue_manis_liar", 1, game_state.current_day, 2)
	if (
		not bool(quest_system.turn_in("veral").get("valid", false))
		or quest_system.get_smoke_clues().size() != 2
		or not game_state.unlocked_features.has("area_tani")
	):
		push_error("Veral's council chapter should add a clue and unlock the farming area.")
		quit(1)
		return
	game_state.npc_heart_levels["veral"] = 3
	game_state.add_item("rempah_eksklusif", 2)
	coins_before = game_state.coins
	if (
		not bool(quest_system.turn_in("veral").get("valid", false))
		or game_state.coins != coins_before - 100 + 200
		or quest_system.get_smoke_clues().size() != 3
		or not game_state.unlocked_features.has("perdagangan_kerajaan")
		or not quest_system.is_quest_complete("veral")
	):
		push_error("Veral's kingdom chapter should charge travel costs and add the final clue.")
		quit(1)
		return

	# Quest state survives a save/load round trip.
	var save_result: Dictionary = game_state.save_game(
		Vector2(210.0, 462.0),
		MAIN_SCENE_PATH,
		TEST_SAVE_PATH
	)
	if not bool(save_result.get("valid", false)):
		push_error("Quest progress should be serializable.")
		quit(1)
		return
	_reset_game_state(game_state)
	var load_result: Dictionary = game_state.load_game(TEST_SAVE_PATH, MAIN_SCENE_PATH)
	if (
		not bool(load_result.get("valid", false))
		or int(game_state.quest_chapters.get("rast", 0)) != 4
		or int(game_state.quest_chapters.get("veral", 0)) != 4
		or game_state.smoke_clues.size() != 3
		or not game_state.unlocked_features.has("perdagangan_kerajaan")
	):
		push_error("Loading should restore quest chapters, smoke clues, and unlocked features.")
		quit(1)
		return

	# A pre-0.2.0 save without quest fields still loads with defaults.
	var legacy_data := _read_json(TEST_SAVE_PATH)
	legacy_data.erase("bab_quest")
	legacy_data.erase("petunjuk_asap")
	legacy_data.erase("fitur_terbuka")
	if not _write_json(TEST_SAVE_PATH, legacy_data):
		push_error("Could not write the legacy save fixture.")
		quit(1)
		return
	_reset_game_state(game_state)
	if (
		not bool(game_state.load_game(TEST_SAVE_PATH, MAIN_SCENE_PATH).get("valid", false))
		or not game_state.quest_chapters.is_empty()
		or not game_state.smoke_clues.is_empty()
	):
		push_error("Saves from v1.0 should load with empty quest progress.")
		quit(1)
		return

	_remove_test_file(TEST_SAVE_PATH)

	# Main scene integration: talking to an NPC hands over a ready chapter.
	_reset_game_state(game_state)
	for step_id in PROLOGUE_STEPS:
		game_state.completed_quests.append(step_id)
	game_state.npc_heart_levels["rast"] = 0
	game_state.add_item("kayu", 1)
	var scene_error := change_scene_to_file(MAIN_SCENE_PATH)
	if scene_error != OK:
		push_error("Could not load the main scene for the quest integration test.")
		quit(1)
		return
	await process_frame
	await process_frame
	var main := current_scene
	var player := main.get("_player") as CharacterBody2D
	var world := main.get("_world") as HearthwoodWorld
	var dialog_ui := main.get("_dialog_ui") as HearthwoodDialogUI
	if player == null or world == null or dialog_ui == null:
		push_error("The main scene should expose its player, world, and dialog UI.")
		quit(1)
		return
	game_state.current_hour = 8
	root.get_node("TimeSystem").sync_from_game_state()
	await process_frame
	var rast := _find_npc(world, "rast")
	if rast == null:
		push_error("Rast should be available for the main quest turn-in.")
		quit(1)
		return
	player.global_position = rast.global_position
	main.call("_interact")
	if (
		not dialog_ui.is_open()
		or game_state.get_item_count("kayu") != 0
		or int(game_state.quest_chapters.get("rast", 0)) != 1
		or not _dialog_contains(dialog_ui, "kayu")
		or not str(main.get("_objective_label").text).contains("papan pengumuman")
	):
		push_error("Talking to Rast should hand over the ready chapter and update the HUD objective.")
		quit(1)
		return
	dialog_ui.close_dialog()

	main.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("Quest chapters, heart gates, rewards, clues, save round-trip, and dialog integration passed.")
	quit(0)


func _reset_game_state(game_state: Variant) -> void:
	game_state.player_name = "Pengelana"
	game_state.current_day = 1
	game_state.current_hour = 6
	game_state.current_minute = 0
	game_state.energy = game_state.MAX_ENERGY
	game_state.coins = game_state.STARTING_COINS
	game_state.inventory.clear()
	game_state.unlocked_recipes.assign(["sup_sayur_bening", "bubur_hangat_hutan"])
	game_state.unlocked_quests.clear()
	game_state.completed_quests.clear()
	game_state.items_received_from_npcs.clear()
	game_state.collected_forage_today.clear()
	game_state.business_permits.clear()
	game_state.npc_heart_levels.clear()
	game_state.npc_met.clear()
	game_state.affection_points.clear()
	game_state.gifts_given_today.clear()
	game_state.customers_served_today.clear()
	game_state.disliked_gift_streaks.clear()
	game_state.npc_gift_history.clear()
	game_state.npc_recently_returned_from_forest.clear()
	game_state.current_weather = "cerah"
	game_state.quest_chapters.clear()
	game_state.smoke_clues.clear()
	game_state.unlocked_features.clear()
	game_state.reputation = 0
	game_state.warung_tier = 0


func _find_npc(world: HearthwoodWorld, npc_id: String) -> HearthwoodNPC:
	for child in world.get_children():
		if child is HearthwoodNPC and child.npc_id == npc_id:
			return child as HearthwoodNPC
	return null


func _dialog_contains(dialog_ui: HearthwoodDialogUI, text: String) -> bool:
	var dialogue_label := dialog_ui.get("_dialogue_label") as Label
	return dialogue_label != null and dialogue_label.text.to_lower().contains(text.to_lower())


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
