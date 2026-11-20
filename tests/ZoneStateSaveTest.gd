# tests/ZoneStateSaveTest.gd
extends SceneTree

func _init() -> void:
	var game_state = load("res://scripts/autoload/GameState.gd").new()
	assert(game_state.get("is_deep_forest_unlocked") != null, "GameState must have is_deep_forest_unlocked")
	assert(game_state.is_deep_forest_unlocked == false, "Default is_deep_forest_unlocked must be false")
	assert(game_state.get("interacted_props_today") != null, "GameState must have interacted_props_today")
	assert(game_state.interacted_props_today.is_empty(), "Default interacted_props_today must be empty")
	
	# Test backward compatibility auto-unlock when Rast Heart 2 quest is already completed
	var mock_old_save = {
		"nama": "Pemain",
		"hari": 5,
		"jam": 10,
		"energi": 100,
		"reputasi": 20,
		"tier_warung": 2,
		"koin": 500,
		"inventori": [],
		"posisi": {"x": 1320.0, "y": 476.0},
		"quests": {
			"rast": {"current_chapter": 3, "heart_level": 2, "objective_index": 0, "completed": false}
		}
	}
	game_state._load_save_data(mock_old_save)
	assert(game_state.is_deep_forest_unlocked == true, "Save with Rast heart >= 2 must auto unlock deep forest")
	assert(game_state.interacted_props_today.is_empty(), "Old save missing interacted_props_today must default to []")

	# Test signal deep_forest_unlocked_changed
	var signal_emitted: Array = []
	game_state.deep_forest_unlocked_changed.connect(func(unlocked: bool): signal_emitted.append(unlocked))
	game_state.is_deep_forest_unlocked = false
	assert(signal_emitted == [false], "deep_forest_unlocked_changed signal should emit on change")

	# Test mark_prop_interacted and is_prop_interacted_today
	game_state.mark_prop_interacted("fruit_tree_apel_hutan_z1")
	game_state.mark_prop_interacted("fruit_tree_apel_hutan_z1") # Duplicate should be ignored
	game_state.mark_prop_interacted("fresh_spring_sungai_z2")
	assert(game_state.interacted_props_today.size() == 2, "Duplicate mark_prop_interacted must not create duplicates")
	assert(game_state.is_prop_interacted_today("fruit_tree_apel_hutan_z1") == true, "Marked prop must return true")
	assert(game_state.is_prop_interacted_today("fresh_spring_sungai_z2") == true, "Marked prop must return true")
	assert(game_state.is_prop_interacted_today("unrelated_prop_xyz") == false, "Unmarked prop must return false")

	# Test round-trip serialization in _create_save_data and _load_save_data
	game_state.is_deep_forest_unlocked = true
	var saved_data = game_state._create_save_data(Vector2(100, 100), "res://scenes/Main.tscn")
	assert(saved_data.get("is_deep_forest_unlocked") == true, "Saved data must contain is_deep_forest_unlocked")
	assert(saved_data.has("interacted_props_today"), "Saved data must contain interacted_props_today key")
	assert(saved_data["interacted_props_today"] == ["fruit_tree_apel_hutan_z1", "fresh_spring_sungai_z2"], "Saved data must preserve interacted props")

	game_state.is_deep_forest_unlocked = false
	game_state.interacted_props_today.clear()
	assert(game_state.interacted_props_today.is_empty())
	game_state._load_save_data(saved_data)
	assert(game_state.is_deep_forest_unlocked == true, "Loaded data must restore is_deep_forest_unlocked")
	assert(game_state.interacted_props_today == ["fruit_tree_apel_hutan_z1", "fresh_spring_sungai_z2"], "Loaded data must restore interacted_props_today")

	# Test clearing on sleep()
	game_state.sleep(6, 1.0)
	assert(game_state.interacted_props_today.is_empty(), "sleep() must clear interacted_props_today")

	# Test clearing on start_new_game()
	game_state.mark_prop_interacted("inspectable_stump_z3")
	assert(game_state.interacted_props_today.size() == 1)
	game_state.start_new_game("Pengelana Baru")
	assert(game_state.interacted_props_today.is_empty(), "start_new_game() must clear interacted_props_today")

	# Test World integration with interactive props and save state
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	world._game_state = game_state

	# Initially no props interacted
	var tree = world.get_interactive_prop("fruit_tree_apel_hutan_z1")
	assert(tree != null, "fruit_tree_apel_hutan_z1 must exist in world")
	assert(tree.daily_interacted == false, "Tree should not be interacted initially")
	assert(tree.has_fruit == true, "Tree should have fruit initially")
	assert(tree.can_interact() == true, "Tree should be interactable")

	# Interact via world.interact_with_prop
	var interact_res = world.interact_with_prop(tree)
	assert(interact_res.get("success") == true, "Interact with tree must succeed")
	assert(tree.daily_interacted == true, "Tree daily_interacted must be true")
	assert(tree.has_fruit == false, "Tree has_fruit must be false")
	assert(tree.can_interact() == false, "Tree can_interact must be false after harvest")
	assert(game_state.is_prop_interacted_today("fruit_tree_apel_hutan_z1") == true, "GameState must track interacted prop")

	# Save state after interaction
	var world_save_data = game_state._create_save_data(Vector2(100, 100), "res://scenes/Main.tscn")
	assert("fruit_tree_apel_hutan_z1" in world_save_data["interacted_props_today"])

	# Reset on day change
	world._on_day_changed(2)
	assert(game_state.interacted_props_today.is_empty(), "World._on_day_changed must clear game_state.interacted_props_today")
	assert(tree.daily_interacted == false, "Tree daily_interacted must reset to false on day change")
	assert(tree.has_fruit == true, "Tree has_fruit must reset to true on day change")
	assert(tree.can_interact() == true, "Tree can_interact must be true after reset")

	# Reload saved state and sync back to World
	game_state._load_save_data(world_save_data)
	assert(game_state.is_prop_interacted_today("fruit_tree_apel_hutan_z1") == true)
	world._sync_interactive_props_state()
	assert(tree.daily_interacted == true, "Loaded state must restore tree.daily_interacted = true")
	assert(tree.has_fruit == false, "Loaded state must restore tree.has_fruit = false")
	assert(tree.can_interact() == false, "Tree must not be interactable when loaded from interacted state")

	world.free()
	game_state.free()
	print("ZoneStateSaveTest passed.")
	quit(0)
