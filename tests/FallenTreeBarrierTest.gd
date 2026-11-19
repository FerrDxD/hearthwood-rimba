# tests/FallenTreeBarrierTest.gd
extends SceneTree

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	var game_state = load("res://scripts/autoload/GameState.gd").new()
	game_state.is_deep_forest_unlocked = false
	world._game_state = game_state
	world._update_fallen_tree_barriers()
	
	# Verify gate to forest_zone_6 from forest_zone_3 is blocked
	var gate_3_to_6 = world.get_zone_gate("forest_zone_3", "forest_zone_6")
	assert(gate_3_to_6 != null, "Gate 3->6 must exist")
	assert(gate_3_to_6.is_blocked == true, "Gate 3->6 must be blocked when locked")
	assert(gate_3_to_6.blocked_dialog_key != "", "Gate 3->6 must have blocked_dialog_key")
	assert(gate_3_to_6.blocked_dialog_key == "fallen_tree_blocked", "Gate 3->6 blocked_dialog_key must be fallen_tree_blocked")
	
	# Verify gate to forest_zone_5 from forest_zone_3 and from forest_zone_2 are blocked
	var gate_3_to_5 = world.get_zone_gate("forest_zone_3", "forest_zone_5")
	assert(gate_3_to_5 != null and gate_3_to_5.is_blocked == true, "Gate 3->5 must be blocked when locked")
	assert(gate_3_to_5.blocked_dialog_key == "fallen_tree_blocked", "Gate 3->5 blocked_dialog_key must be fallen_tree_blocked")
	
	var gate_2_to_5 = world.get_zone_gate("forest_zone_2", "forest_zone_5")
	assert(gate_2_to_5 != null and gate_2_to_5.is_blocked == true, "Gate 2->5 must be blocked when locked")
	assert(gate_2_to_5.blocked_dialog_key == "fallen_tree_blocked", "Gate 2->5 blocked_dialog_key must be fallen_tree_blocked")
	
	# Verify blocked attempt emits blocked_attempted signal
	var blocked_called: Array = [false]
	gate_3_to_6.blocked_attempted.connect(func(g, key): blocked_called[0] = true)
	var transition_result = gate_3_to_6.trigger_transition()
	assert(transition_result == false, "Blocked gate trigger_transition must return false")
	assert(blocked_called[0] == true, "blocked_attempted must be emitted")
	
	# Verify blocked dialog text
	var dialog_text = world.get_blocked_dialog_text("fallen_tree_blocked")
	assert(dialog_text.contains("tumbang"), "Blocked dialog text should describe fallen tree")
	
	# Simulate unlocking deep forest (e.g. via Rast Heart 2 quest)
	game_state.is_deep_forest_unlocked = true
	world._update_fallen_tree_barriers()
	assert(gate_3_to_6.is_blocked == false, "Gate 3->6 must be unblocked when is_deep_forest_unlocked is true")
	assert(gate_3_to_5.is_blocked == false, "Gate 3->5 must be unblocked when is_deep_forest_unlocked is true")
	assert(gate_2_to_5.is_blocked == false, "Gate 2->5 must be unblocked when is_deep_forest_unlocked is true")
	
	# Verify QuestSystem integration with Rast Heart 2 quest completion
	var quest_system = load("res://scripts/systems/QuestSystem.gd").new()
	quest_system._game_state = game_state
	game_state.is_deep_forest_unlocked = false
	world._update_fallen_tree_barriers()
	assert(gate_3_to_6.is_blocked == true, "Gate 3->6 should be re-blocked when is_deep_forest_unlocked is false")
	
	quest_system.complete_chapter("rast", 2)
	assert(game_state.is_deep_forest_unlocked == true, "Rast chapter 2 completion must unlock deep forest")
	assert(gate_3_to_6.is_blocked == false, "Gate 3->6 must be unblocked after quest unlocks deep forest")
	
	quest_system.free()
	game_state.free()
	world.free()
	print("FallenTreeBarrierTest passed.")
	quit(0)
