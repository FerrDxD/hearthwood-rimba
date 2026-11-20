# tests/VillagePropsIntegrationTest.gd
extends SceneTree

const WORLD_SCENE_PATH: String = "res://scenes/tilemap/MainTileset.tscn"
const VILLAGE_WELL_SCRIPT: Script = preload("res://scripts/world/VillageWell.gd")
const NOTICE_BOARD_SCRIPT: Script = preload("res://scripts/world/NoticeBoard.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- Running VillagePropsIntegrationTest ---")
	test_village_props_instantiation()
	test_village_well_interaction_and_state()
	test_notice_board_interaction()
	test_daily_reset_sync()

	if _failed:
		push_error("VillagePropsIntegrationTest failed!")
		quit(1)
		return

	print("VillagePropsIntegrationTest passed.")
	quit(0)


func _assert(condition: bool, message: String) -> bool:
	if not condition:
		push_error("Assertion failed: %s" % message)
		_failed = true
		return false
	return true


func test_village_props_instantiation() -> void:
	print("Testing village props instantiation in World...")
	var world_scene := load(WORLD_SCENE_PATH) as PackedScene
	if not _assert(world_scene != null, "MainTileset scene must exist"):
		return

	var world = world_scene.instantiate()
	if not _assert(world != null, "World instance must not be null"):
		return
	root.add_child(world)

	if not _assert(world.has_method("get_village_well"), "World must provide get_village_well()"):
		root.remove_child(world)
		world.free()
		return
	if not _assert(world.has_method("get_notice_board"), "World must provide get_notice_board()"):
		root.remove_child(world)
		world.free()
		return

	var well = world.get_village_well()
	_assert(well != null, "get_village_well() must return an instance")
	_assert(well is VILLAGE_WELL_SCRIPT, "get_village_well() must return HearthwoodVillageWell")
	_assert(well.prop_id == "village_well", "Well prop_id must be 'village_well'")
	_assert(well.position == Vector2(1050.0, 460.0), "Well must be at Vector2(1050.0, 460.0)")

	var board = world.get_notice_board()
	_assert(board != null, "get_notice_board() must return an instance")
	_assert(board is NOTICE_BOARD_SCRIPT, "get_notice_board() must return HearthwoodNoticeBoard")
	_assert(board.prop_id == "notice_board", "Board prop_id must be 'notice_board'")
	_assert(board.position == Vector2(1130.0, 460.0), "Board must be at Vector2(1130.0, 460.0)")

	var all_props: Array = world.get_interactive_props()
	_assert(all_props.has(well), "world.get_interactive_props() must contain village well")
	_assert(all_props.has(board), "world.get_interactive_props() must contain notice board")
	_assert(world.get_interactive_prop("village_well") == well, "get_interactive_prop('village_well') must return well")
	_assert(world.get_interactive_prop("notice_board") == board, "get_interactive_prop('notice_board') must return board")

	root.remove_child(world)
	world.free()
	print("Village props instantiation finished.")


func test_village_well_interaction_and_state() -> void:
	print("Testing village well interaction and GameState synchronization...")
	var game_state = root.get_node_or_null("GameState")
	if not _assert(game_state != null, "GameState autoload must exist"):
		return

	game_state.energy = 50
	game_state.interacted_props_today.clear()
	var initial_water: int = game_state.get_item_count("air_bersih")

	var world_scene := load(WORLD_SCENE_PATH) as PackedScene
	var world = world_scene.instantiate()
	world._game_state = game_state
	root.add_child(world)

	if not world.has_method("get_village_well"):
		_assert(false, "World missing get_village_well()")
		root.remove_child(world)
		world.free()
		return

	var well = world.get_village_well()
	if not _assert(well != null, "Well must exist"):
		root.remove_child(world)
		world.free()
		return

	_assert(well.daily_interacted == false, "Well must not be interacted initially")
	_assert(well.can_interact() == true, "Well must be interactable initially")

	# Interact with prop via world helper or direct prop interact
	var res: Dictionary = world.interact_with_prop(well)
	_assert(res.get("success", false) == true, "Interacting with well must succeed")
	_assert(game_state.energy == 55, "Interacting with well must restore +5 energy (50 -> 55)")
	_assert(game_state.get_item_count("air_bersih") == initial_water + 1, "Interacting with well must award 1 air_bersih")
	_assert(game_state.is_prop_interacted_today("village_well") == true, "GameState must record village_well in interacted_props_today")
	_assert(well.daily_interacted == true, "Well daily_interacted must be true")
	_assert(well.can_interact() == false, "Well can_interact must be false")

	# Repeat interaction must fail
	var repeat_res: Dictionary = world.interact_with_prop(well)
	_assert(repeat_res.get("success", false) == false, "Repeat well interaction must fail")
	_assert(game_state.energy == 55, "Energy must not change on repeated well interaction")
	_assert(game_state.get_item_count("air_bersih") == initial_water + 1, "Water must not be awarded again on repeated well interaction")

	root.remove_child(world)
	world.free()
	print("Village well interaction and GameState synchronization finished.")


func test_notice_board_interaction() -> void:
	print("Testing notice board interaction in World...")
	var game_state = root.get_node_or_null("GameState")
	if not _assert(game_state != null, "GameState autoload must exist"):
		return
	game_state.interacted_props_today.clear()

	var world_scene := load(WORLD_SCENE_PATH) as PackedScene
	var world = world_scene.instantiate()
	world._game_state = game_state
	root.add_child(world)

	if not world.has_method("get_notice_board"):
		_assert(false, "World missing get_notice_board()")
		root.remove_child(world)
		world.free()
		return

	var board = world.get_notice_board()
	if not _assert(board != null, "Board must exist"):
		root.remove_child(world)
		world.free()
		return

	var res: Dictionary = world.interact_with_prop(board)
	_assert(res.get("success", false) == true, "Interacting with notice board must succeed")
	_assert(res.has("data"), "Notice board interaction result must have 'data'")
	var data: Dictionary = res.get("data", {})
	_assert(data.has("weather"), "Notice board data must have 'weather'")
	_assert(data.has("craving_hint"), "Notice board data must have 'craving_hint'")
	_assert(data.has("mayor_note"), "Notice board data must have 'mayor_note'")
	_assert(game_state.is_prop_interacted_today("notice_board") == true, "GameState must track notice_board interaction")

	root.remove_child(world)
	world.free()
	print("Notice board interaction finished.")


func test_daily_reset_sync() -> void:
	print("Testing daily reset synchronization with World...")
	var game_state = root.get_node_or_null("GameState")
	if not _assert(game_state != null, "GameState autoload must exist"):
		return

	game_state.energy = 60
	game_state.interacted_props_today.clear()

	var world_scene := load(WORLD_SCENE_PATH) as PackedScene
	var world = world_scene.instantiate()
	world._game_state = game_state
	root.add_child(world)

	if not world.has_method("get_village_well") or not world.has_method("get_notice_board"):
		_assert(false, "World missing village prop query methods")
		root.remove_child(world)
		world.free()
		return

	var well = world.get_village_well()
	var board = world.get_notice_board()

	# Interact with both
	world.interact_with_prop(well)
	world.interact_with_prop(board)
	_assert(game_state.is_prop_interacted_today("village_well") == true, "Well must be marked in GameState")
	_assert(game_state.is_prop_interacted_today("notice_board") == true, "Board must be marked in GameState")
	_assert(well.daily_interacted == true, "Well daily_interacted must be true")
	_assert(board.daily_interacted == true, "Board daily_interacted must be true")

	# Day change triggered
	world._on_day_changed(2)

	_assert(game_state.interacted_props_today.is_empty(), "_on_day_changed must clear game_state.interacted_props_today")
	_assert(well.daily_interacted == false, "_on_day_changed must reset well.daily_interacted to false")
	_assert(well.can_interact() == true, "Well must be interactable after daily reset")
	_assert(board.daily_interacted == false, "_on_day_changed must reset board.daily_interacted to false")

	# Re-interact with well after day change
	var res: Dictionary = world.interact_with_prop(well)
	_assert(res.get("success", false) == true, "Well must be interactable again after daily reset")
	_assert(game_state.is_prop_interacted_today("village_well") == true, "GameState must record re-interaction")

	root.remove_child(world)
	world.free()
	print("Daily reset synchronization finished.")
