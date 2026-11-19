# tests/ZoneStateSaveTest.gd
extends SceneTree

func _init() -> void:
	var game_state = load("res://scripts/autoload/GameState.gd").new()
	assert(game_state.get("is_deep_forest_unlocked") != null, "GameState must have is_deep_forest_unlocked")
	assert(game_state.is_deep_forest_unlocked == false, "Default is_deep_forest_unlocked must be false")
	
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

	# Test signal deep_forest_unlocked_changed
	var signal_emitted: Array = []
	game_state.deep_forest_unlocked_changed.connect(func(unlocked: bool): signal_emitted.append(unlocked))
	game_state.is_deep_forest_unlocked = false
	assert(signal_emitted == [false], "deep_forest_unlocked_changed signal should emit on change")

	# Test round-trip serialization in _create_save_data and _load_save_data
	game_state.is_deep_forest_unlocked = true
	var saved_data = game_state._create_save_data(Vector2(100, 100), "res://scenes/Main.tscn")
	assert(saved_data.get("is_deep_forest_unlocked") == true, "Saved data must contain is_deep_forest_unlocked")

	game_state.is_deep_forest_unlocked = false
	game_state._load_save_data(saved_data)
	assert(game_state.is_deep_forest_unlocked == true, "Loaded data must restore is_deep_forest_unlocked")

	print("ZoneStateSaveTest passed.")
	quit(0)
