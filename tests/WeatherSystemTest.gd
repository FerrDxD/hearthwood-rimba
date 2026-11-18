extends SceneTree

const COOKING_SYSTEM_SCENE: PackedScene = preload("res://scenes/CookingSystem.tscn")
const COOKING_UI_SCENE: PackedScene = preload("res://scenes/CookingUI.tscn")
const AFFECTION_SYSTEM_SCENE: PackedScene = preload("res://scenes/AffectionSystem.tscn")
const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
const TEST_SAVE_PATH: String = "user://phase14-weather-test.json"
const FORAGE_POSITION: Vector2 = Vector2(104.0, 218.0)
const RAIN_FORAGE_POSITION: Vector2 = Vector2(300.0, 700.0)


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_remove_test_file(TEST_SAVE_PATH)
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	_reset_game_state(game_state)

	if (
		game_state.get_weather_for_day(1) != "cerah"
		or game_state.get_weather_for_day(2) != "hujan"
		or game_state.get_weather_for_day(4) != "badai"
		or game_state.get_weather_for_day(7) != "cerah"
	):
		push_error("Weather should follow a deterministic daily cycle.")
		quit(1)
		return

	time_system.sleep()
	if game_state.current_day != 2 or game_state.current_weather != "hujan":
		push_error("Sleeping should advance the day and set that day's weather.")
		quit(1)
		return

	var save_result: Dictionary = game_state.save_game(
		Vector2(210.0, 462.0),
		MAIN_SCENE_PATH,
		TEST_SAVE_PATH
	)
	if not bool(save_result.get("valid", false)):
		push_error("Weather should be serializable.")
		quit(1)
		return
	_reset_game_state(game_state)
	game_state.current_weather = "cerah"
	if (
		not bool(game_state.load_game(TEST_SAVE_PATH, MAIN_SCENE_PATH).get("valid", false))
		or game_state.current_weather != "hujan"
	):
		push_error("Loading should restore the saved weather.")
		quit(1)
		return
	_remove_test_file(TEST_SAVE_PATH)

	var cooking_system := COOKING_SYSTEM_SCENE.instantiate() as HearthwoodCookingSystem
	root.add_child(cooking_system)
	await process_frame
	if cooking_system.is_recipe_available("sup_kaldu_kayu"):
		push_error("The timber broth recipe should be locked before Rast's heart-two chapter.")
		quit(1)
		return

	game_state.add_item("kayu")
	game_state.add_item("sayur_liar")
	game_state.add_item("garam")
	if game_state.unlocked_recipes.has("sup_kaldu_kayu"):
		push_error("Quest-gated recipes should not unlock from ingredients alone.")
		quit(1)
		return
	game_state.quest_chapters["rast"] = 3
	game_state.state_changed.emit()
	if not game_state.unlocked_recipes.has("sup_kaldu_kayu"):
		push_error("Finishing Rast's heart-two chapter should unlock Sup Kaldu Kayu.")
		quit(1)
		return

	game_state.add_item("rempah_eksklusif")
	if game_state.unlocked_recipes.has("nasi_kuning_rempah"):
		push_error("Nasi Kuning Rempah should also require Veral's heart-two chapter.")
		quit(1)
		return
	game_state.quest_chapters["veral"] = 3
	game_state.state_changed.emit()
	if not game_state.unlocked_recipes.has("nasi_kuning_rempah"):
		push_error("Completing both requirements should unlock Nasi Kuning Rempah.")
		quit(1)
		return

	var cooking_ui := COOKING_UI_SCENE.instantiate() as HearthwoodCookingUI
	root.add_child(cooking_ui)
	await process_frame
	cooking_ui.set_cooking_system(cooking_system)
	cooking_ui.open_cooking(cooking_system)
	var timing_track = cooking_ui.get("_timing_track")
	if timing_track == null:
		push_error("Cooking UI should expose its timing track.")
		quit(1)
		return
	for expected in [["cerah", 0.16], ["hujan", 0.10], ["badai", 0.06]]:
		game_state.current_weather = str(expected[0])
		if not is_equal_approx(timing_track.get_green_zone_size(), float(expected[1])):
			push_error("The green timing zone should match the weather: %s" % expected[0])
			quit(1)
			return

	var affection_system := AFFECTION_SYSTEM_SCENE.instantiate() as HearthwoodAffectionSystem
	affection_system.set_cooking_system(cooking_system)
	root.add_child(affection_system)
	await process_frame
	game_state.current_weather = "hujan"
	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 3)
	var rain_gift: Dictionary = affection_system.give_food(
		"nue",
		"sup_sayur_bening",
		game_state.current_day,
		3
	)
	if rain_gift.get("reaction") != "spesial":
		push_error("Warm food should be special during rain.")
		quit(1)
		return

	var world := WORLD_SCENE.instantiate() as HearthwoodWorld
	root.add_child(world)
	await process_frame
	game_state.current_hour = 8
	game_state.current_minute = 0
	game_state.current_weather = "cerah"
	time_system.sync_from_game_state()
	await process_frame
	var giral := _find_npc(world, "giral") as HearthwoodShopNPC
	if giral == null or not giral.is_shop_open():
		push_error("Giral should be open at 08:00 in clear weather.")
		quit(1)
		return
	game_state.current_weather = "badai"
	time_system.sync_from_game_state()
	await process_frame
	if giral.is_shop_open() or giral.can_interact():
		push_error("Giral should close during a storm.")
		quit(1)
		return
	game_state.current_hour = 13
	time_system.sync_from_game_state()
	await process_frame
	var talia := _find_npc(world, "talia") as HearthwoodShopNPC
	if talia == null or not talia.is_shop_open():
		push_error("Talia has no weather closure and should stay open at 13:00.")
		quit(1)
		return

	game_state.current_weather = "hujan"
	game_state.collected_forage_today.clear()
	world.call("_spawn_forage_items")
	await process_frame
	var rain_bonus := world.get_closest_item_pickup(RAIN_FORAGE_POSITION, 2.0)
	var before_rain: int = game_state.get_item_count("jamur_hutan")
	if rain_bonus == null or str(rain_bonus.item_id) != "jamur_hutan":
		push_error("Rain should add a bonus forage spot.")
		quit(1)
		return
	if not world.collect_item_pickup(rain_bonus):
		push_error("The rain forage spot should be collectable.")
		quit(1)
		return
	if game_state.get_item_count("jamur_hutan") != before_rain + 1:
		push_error("Collecting the rain forage spot should add one item.")
		quit(1)
		return

	game_state.current_weather = "cerah"
	game_state.collected_forage_today.clear()
	world.call("_spawn_forage_items")
	await process_frame
	if world.get_closest_item_pickup(RAIN_FORAGE_POSITION, 2.0) != null:
		push_error("The bonus forage spot should only appear during rain.")
		quit(1)
		return
	var clear_pickup := world.get_closest_item_pickup(FORAGE_POSITION, 2.0)
	if clear_pickup == null:
		push_error("Clear weather should spawn regular forage.")
		quit(1)
		return

	print("Weather cycle, save, recipe gates, timing zone, NPC reaction, shops, and forage tests passed.")
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
	game_state.quest_chapters.clear()
	game_state.smoke_clues.clear()
	game_state.unlocked_features.clear()
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
	game_state.current_weather = "cerah"
	game_state.npc_recently_returned_from_forest.clear()
	game_state.reputation = 0
	game_state.warung_tier = 0


func _find_npc(world: HearthwoodWorld, npc_id: String) -> HearthwoodNPC:
	for child in world.get_children():
		if child is HearthwoodNPC and child.npc_id == npc_id:
			return child as HearthwoodNPC
	return null


func _remove_test_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
