extends SceneTree

const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/PauseMenu.tscn")
const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const TEST_SAVE_PATH: String = "user://phase8-save-test.json"
const INVALID_SAVE_PATH: String = "user://phase8-invalid-save-test.json"
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"

var _quest_completion_count: int = 0
var _pause_save_request_count: int = 0
var _pause_load_request_count: int = 0
var _pause_main_menu_request_count: int = 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	_remove_test_file(TEST_SAVE_PATH)
	_remove_test_file(INVALID_SAVE_PATH)
	_reset_game_state(game_state)
	game_state.player_name = "Sari"
	game_state.current_day = 4
	game_state.current_hour = 24
	game_state.current_minute = 18
	game_state.energy = 63
	game_state.coins = 777
	game_state.reputation = 17
	game_state.warung_tier = 2
	game_state.business_permits.assign([1, 2])
	game_state.unlocked_recipes.assign([
		"sup_sayur_bening",
		"bubur_hangat_hutan",
		"sayur_asam_segar",
	])
	game_state.npc_heart_levels["vea"] = 2
	game_state.npc_met["vea"] = true
	game_state.affection_points["vea"] = 58
	game_state.gifts_given_today["gil"] = true
	game_state.customers_served_today["vea"] = true
	game_state.customers_served_today["talia"] = true
	game_state.disliked_gift_streaks["rave"] = 2
	game_state.npc_gift_history["vea"] = ["sup_sayur_bening"]
	game_state.current_weather = "dingin"
	game_state.npc_recently_returned_from_forest["rast"] = true
	game_state.items_received_from_npcs.assign(["pisau_kecil"])
	game_state.collected_forage_today.assign(["sayur_liar_1"])
	game_state.interacted_props_today.assign(["fruit_tree_apel_hutan_z1", "fresh_spring_sungai_z2", "village_well"])
	game_state.unlocked_quests.assign(["rast_main"])
	game_state.completed_quests.assign(["village_intro"])
	if (
		not game_state.add_item("kayu", 3)
		or not game_state.add_item("sup_sayur_bening", 2, 4, 3)
		or not game_state.add_item("air_bersih", 5)
	):
		push_error("Save fixture inventory could not be created.")
		quit(1)
		return

	var save_result: Dictionary = game_state.save_game(
		Vector2(456.5, 321.25),
		MAIN_SCENE_PATH,
		TEST_SAVE_PATH
	)
	if not bool(save_result.get("valid", false)) or not game_state.has_save_game(TEST_SAVE_PATH):
		push_error("Manual save should write a valid file in the requested slot.")
		quit(1)
		return
	var saved_data := _read_json(TEST_SAVE_PATH)
	if (
		int(saved_data.get("hari", 0)) != 4
		or int(saved_data.get("jam", 0)) != 24
		or str(saved_data.get("nama_pemain", "")) != "Sari"
		or int(saved_data.get("koin", 0)) != 777
		or int(saved_data.get("reputasi", 0)) != 17
		or int(saved_data.get("tier_warung", 0)) != 2
		or not saved_data.get("pelanggan_hari_ini", {}).has("vea")
		or not saved_data.get("pelanggan_hari_ini", {}).has("talia")
		or str(saved_data.get("inventori", [])[1].get("item", "")) != "sup_sayur_bening"
		or int(saved_data.get("inventori", [])[1].get("hari_terakhir_diproses", 0)) != 4
		or saved_data.get("interacted_props_today", []) != ["fruit_tree_apel_hutan_z1", "fresh_spring_sungai_z2", "village_well"]
	):
		push_error("Save JSON should preserve the PRD fields and cooked-item metadata.")
		quit(1)
		return

	_reset_game_state(game_state)
	var load_result: Dictionary = game_state.load_game(TEST_SAVE_PATH, MAIN_SCENE_PATH)
	if (
		not bool(load_result.get("valid", false))
		or load_result.get("posisi") != Vector2(456.5, 321.25)
		or game_state.player_name != "Sari"
		or game_state.current_day != 4
		or game_state.current_hour != 24
		or game_state.current_minute != 18
		or game_state.energy != 63
		or game_state.coins != 777
		or game_state.reputation != 17
		or game_state.warung_tier != 2
		or game_state.business_permits != [1, 2]
		or game_state.get_item_count("kayu") != 3
		or game_state.get_item_count("sup_sayur_bening") != 2
		or game_state.get_item_count("air_bersih") != 5
		or game_state.unlocked_recipes != [
			"sup_sayur_bening",
			"bubur_hangat_hutan",
			"sayur_asam_segar",
		]
		or game_state.get_npc_heart_level("vea") != 2
		or not game_state.npc_met.has("vea")
		or int(game_state.affection_points.get("vea", 0)) != 58
		or not game_state.gifts_given_today.has("gil")
		or not game_state.customers_served_today.has("vea")
		or not game_state.customers_served_today.has("talia")
		or int(game_state.disliked_gift_streaks.get("rave", 0)) != 2
		or not game_state.npc_gift_history["vea"].has("sup_sayur_bening")
		or game_state.current_weather != "dingin"
		or not game_state.npc_recently_returned_from_forest.has("rast")
		or game_state.items_received_from_npcs != ["pisau_kecil"]
		or game_state.collected_forage_today != ["sayur_liar_1"]
		or game_state.interacted_props_today != ["fruit_tree_apel_hutan_z1", "fresh_spring_sungai_z2", "village_well"]
		or game_state.unlocked_quests != ["rast_main"]
		or game_state.completed_quests != ["village_intro"]
	):
		push_error("Load should restore gameplay state, inventory, and player position.")
		quit(1)
		return

	var world := WORLD_SCENE.instantiate() as HearthwoodWorld
	root.add_child(world)
	await process_frame
	if world.get_closest_item_pickup(Vector2(104.0, 1178.0), 2.0) != null:
		push_error("A collected forage spot should stay empty after loading a save.")
		quit(1)
		return
	var loaded_tree = world.get_interactive_prop("fruit_tree_apel_hutan_z1")
	if loaded_tree == null or not loaded_tree.daily_interacted or loaded_tree.has_fruit:
		push_error("An interacted prop should preserve its interacted state after loading a save.")
		quit(1)
		return
	var loaded_well = world.get_village_well()
	if loaded_well == null or not loaded_well.daily_interacted:
		push_error("Village well should preserve its interacted state after loading a save.")
		quit(1)
		return
	game_state.collected_forage_today.clear()
	game_state.interacted_props_today.clear()
	time_system.sync_from_game_state()
	world._on_day_changed(game_state.current_day)
	await process_frame
	if world.get_closest_item_pickup(Vector2(104.0, 1178.0), 2.0) == null:
		push_error("Synchronizing a loaded day should refresh the forage world.")
		quit(1)
		return
	if loaded_tree.daily_interacted or not loaded_tree.has_fruit:
		push_error("An interacted prop should reset to interactable after a new day.")
		quit(1)
		return
	if loaded_well.daily_interacted:
		push_error("Village well should reset to interactable after a new day.")
		quit(1)
		return
	var tables: Array = world.get_warung_tables()
	if tables.size() < 2:
		push_error("World should provide at least two dining tables for warung operations.")
		quit(1)
		return
	var table_1 = tables[0]
	var table_2 = tables[1]
	table_1.seat_customer("vea", "sup_sayur_bening")
	table_2.seat_customer("talia", "sup_sayur_bening")
	table_2.serve_food("sup_sayur_bening", 2)
	table_2.finish_eating()
	if table_1.is_available() or table_2.is_available():
		push_error("Tables should be occupied and dirty before sleeping.")
		quit(1)
		return

	game_state.interacted_props_today.append("village_well")
	game_state.customers_served_today["vea"] = true
	game_state.sleep(8, 0.8)
	if game_state.interacted_props_today.has("village_well"):
		push_error("Sleeping should reset interacted_props_today including village_well.")
		quit(1)
		return
	if not table_1.is_available() or table_1.current_state != table_1.TableState.EMPTY:
		push_error("Sleeping (GameState.sleep()) should reset occupied table to empty.")
		quit(1)
		return
	if not table_2.is_available() or table_2.current_state != table_2.TableState.EMPTY:
		push_error("Sleeping (GameState.sleep()) should reset dirty table to empty.")
		quit(1)
		return
	if not game_state.customers_served_today.is_empty():
		push_error("Sleeping should reset customers_served_today.")
		quit(1)
		return

	game_state.coins = 123
	var wrong_scene_result: Dictionary = game_state.load_game(
		TEST_SAVE_PATH,
		"res://scenes/ShopUI.tscn"
	)
	if bool(wrong_scene_result.get("valid", true)) or game_state.coins != 123:
		push_error("A scene mismatch should be rejected without mutating game state.")
		quit(1)
		return

	var invalid_file := FileAccess.open(INVALID_SAVE_PATH, FileAccess.WRITE)
	if invalid_file == null:
		push_error("Could not create malformed-save test fixture.")
		quit(1)
		return
	invalid_file.store_string("{")
	invalid_file.close()
	var malformed_result: Dictionary = game_state.load_game(INVALID_SAVE_PATH)
	if bool(malformed_result.get("valid", true)) or game_state.coins != 123:
		push_error("Malformed save data should be rejected without mutating game state.")
		quit(1)
		return

	var incomplete_file := FileAccess.open(INVALID_SAVE_PATH, FileAccess.WRITE)
	if incomplete_file == null:
		push_error("Could not create incomplete-save test fixture.")
		quit(1)
		return
	incomplete_file.store_string("{\"versi\":1}")
	incomplete_file.close()
	var incomplete_result: Dictionary = game_state.load_game(INVALID_SAVE_PATH)
	if bool(incomplete_result.get("valid", true)) or game_state.coins != 123:
		push_error("Incomplete save data should be rejected without partial state changes.")
		quit(1)
		return

	game_state.quest_completed.connect(_on_quest_completed)
	_quest_completion_count = 0
	if (
		not game_state.complete_quest("test_autosave")
		or game_state.complete_quest("test_autosave")
		or _quest_completion_count != 1
	):
		push_error("Quest completion should emit once so the main scene can auto-save.")
		quit(1)
		return

	var pause_menu := PAUSE_MENU_SCENE.instantiate() as HearthwoodPauseMenu
	root.add_child(pause_menu)
	await process_frame
	_pause_save_request_count = 0
	_pause_load_request_count = 0
	pause_menu.save_requested.connect(_on_pause_save_requested)
	pause_menu.load_requested.connect(_on_pause_load_requested)
	pause_menu.main_menu_requested.connect(_on_pause_main_menu_requested)
	pause_menu.open_menu()
	if not pause_menu.is_open() or not paused:
		push_error("Opening the pause menu should pause the game.")
		quit(1)
		return
	var pause_save_button := _find_button(pause_menu, "Simpan game")
	var pause_load_button := _find_button(pause_menu, "Muat game")
	var pause_main_menu_button := _find_button(pause_menu, "Ke menu utama")
	var resume_button := _find_button(pause_menu, "Lanjutkan")
	if (
		pause_save_button == null
		or pause_load_button == null
		or pause_main_menu_button == null
		or resume_button == null
	):
		push_error("Pause menu should expose save, load, main-menu, and resume actions.")
		quit(1)
		return
	pause_save_button.pressed.emit()
	pause_load_button.pressed.emit()
	pause_main_menu_button.pressed.emit()
	resume_button.pressed.emit()
	if (
		_pause_save_request_count != 1
		or _pause_load_request_count != 1
		or _pause_main_menu_request_count != 1
		or pause_menu.is_open()
		or paused
	):
		push_error("Pause menu actions should dispatch save/load and resume correctly.")
		quit(1)
		return

	_remove_test_file(TEST_SAVE_PATH)
	_remove_test_file(INVALID_SAVE_PATH)
	print("Save round-trip, validation, quest notification, and pause UI tests passed.")
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
	game_state.interacted_props_today.clear()
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
	game_state.reputation = 0
	game_state.warung_tier = 0


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _remove_test_file(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var error := DirAccess.remove_absolute(absolute_path)
		if error != OK:
			push_error("Could not remove temporary save test file (code %d)." % error)


func _on_quest_completed(_quest_id: String) -> void:
	_quest_completion_count += 1


func _on_pause_save_requested() -> void:
	_pause_save_request_count += 1


func _on_pause_load_requested() -> void:
	_pause_load_request_count += 1


func _on_pause_main_menu_requested() -> void:
	_pause_main_menu_request_count += 1


func _find_button(parent: Node, button_text: String) -> Button:
	for child in parent.get_children():
		if child is Button and button_text in child.text:
			return child
		var nested_button := _find_button(child, button_text)
		if nested_button != null:
			return nested_button
	return null
