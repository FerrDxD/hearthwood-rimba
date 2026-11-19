extends SceneTree

const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
const TEST_SAVE_PATH: String = "user://phase10_flow_test.json"
const FOREST_VEGETABLE_POSITION: Vector2 = Vector2(104.0, 1178.0)
const COOKING_STATION_POSITION: Vector2 = Vector2(1210.0, 478.0)
const VERAL_POSITION: Vector2 = Vector2(1390.0, 342.0)
const HOME_POSITION: Vector2 = Vector2(1320.0, 476.0)


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	if not game_state.start_new_game("Rimba"):
		push_error("Could not start a new game for the phase ten flow test.")
		quit(1)
		return
	var scene_error := change_scene_to_file(MAIN_SCENE_PATH)
	if scene_error != OK:
		push_error("Could not load the main game scene for the phase ten flow test.")
		quit(1)
		return
	await process_frame
	await process_frame

	var main := current_scene
	if main == null:
		push_error("The main game scene was not activated.")
		quit(1)
		return
	var player := main.get("_player") as CharacterBody2D
	var world := main.get("_world") as HearthwoodWorld
	var dialog_ui := main.get("_dialog_ui") as HearthwoodDialogUI
	var cooking_system := main.get("_cooking_system") as HearthwoodCookingSystem
	var cooking_ui := main.get("_cooking_ui") as HearthwoodCookingUI
	var warung_system := main.get("_warung_system") as HearthwoodWarungSystem
	if (
		player == null
		or world == null
		or dialog_ui == null
		or cooking_system == null
		or cooking_ui == null
		or warung_system == null
		or player.global_position != Vector2(210.0, 462.0)
		or str(main.call("_current_prologue_step")) != "prologue_find_rast"
	):
		push_error("A new game should start under the great tree with its first objective.")
		quit(1)
		return
	var quest_callback := Callable(main, "_on_quest_completed")
	var upgrade_callback := Callable(main, "_on_warung_upgraded")
	var day_callback := Callable(main, "_on_day_changed")
	if game_state.quest_completed.is_connected(quest_callback):
		game_state.quest_completed.disconnect(quest_callback)
	if game_state.warung_upgraded.is_connected(upgrade_callback):
		game_state.warung_upgraded.disconnect(upgrade_callback)
	var time_system = root.get_node("TimeSystem")
	if time_system.day_changed.is_connected(day_callback):
		time_system.day_changed.disconnect(day_callback)

	var rast := _find_npc(world, "rast")
	if rast == null:
		push_error("Rast was not available at the start of the forest route.")
		quit(1)
		return
	player.global_position = rast.global_position
	main.call("_interact")
	if (
		str(main.call("_current_prologue_step")) != "prologue_collect_sayur"
		or not dialog_ui.is_open()
		or not _dialog_contains(dialog_ui, "sayur liar")
	):
		push_error("Meeting Rast should advance the survival tutorial and explain foraging.")
		quit(1)
		return
	dialog_ui.close_dialog()

	var vegetable := world.get_closest_item_pickup(FOREST_VEGETABLE_POSITION, 2.0)
	if vegetable == null or not world.collect_item_pickup(vegetable):
		push_error("The prologue vegetable should be collectable in the forest.")
		quit(1)
		return
	main.call("_advance_prologue_after_foraging")
	if (
		game_state.get_item_count("sayur_liar") != 1
		or str(main.call("_current_prologue_step")) != "prologue_meet_veral"
	):
		push_error("Collecting a wild vegetable should unlock the village meeting.")
		quit(1)
		return

	game_state.current_hour = 8
	time_system.sync_from_game_state()
	await process_frame
	var veral := _find_npc(world, "veral")
	if veral == null:
		push_error("Veral should be available during the village introduction.")
		quit(1)
		return
	player.global_position = veral.global_position
	main.call("_interact")
	if (
		str(main.call("_current_prologue_step")) != "prologue_cook_first_meal"
		or game_state.get_item_count("garam") != 1
		or not _dialog_contains(dialog_ui, "Sup Sayur Bening")
	):
		push_error("Veral should provide the cooking test and its missing ingredient.")
		quit(1)
		return
	dialog_ui.close_dialog()

	player.global_position = COOKING_STATION_POSITION
	main.call("_interact")
	if not cooking_ui.is_open():
		push_error("The player should be able to open the cooking UI at the village fire.")
		quit(1)
		return
	var cooking_result := cooking_system.cook(
		"sup_sayur_bening",
		1,
		"api_unggun",
		"yellow"
	)
	if (
		not bool(cooking_result.get("valid", false))
		or str(main.call("_current_prologue_step")) != "prologue_receive_residence_permit"
		or game_state.get_item_count("sup_sayur_bening") != 1
	):
		push_error("Cooking the first meal should advance the prologue and preserve its dish.")
		quit(1)
		return
	cooking_ui.close_cooking()

	player.global_position = veral.global_position
	main.call("_interact")
	var upgrade_button := _find_button(dialog_ui, "Izin & upgrade warung")
	if (
		str(main.call("_current_prologue_step")) != "prologue_settle_in_hut"
		or not _dialog_contains(dialog_ui, "izin tinggal")
		or upgrade_button == null
		or upgrade_button.visible
	):
		push_error("Veral should grant residence before exposing business upgrades.")
		quit(1)
		return
	dialog_ui.close_dialog()

	player.global_position = HOME_POSITION
	main.call("_interact")
	if (
		not str(main.call("_current_prologue_step")).is_empty()
		or player.global_position != HOME_POSITION
		or game_state.current_day != 1
	):
		push_error("The first interaction with the village hut should settle, not sleep, the player.")
		quit(1)
		return

	game_state.current_hour = 13
	time_system.sync_from_game_state()
	await process_frame
	var vea := _find_npc(world, "vea")
	if vea == null:
		push_error("Vea should be available for the first warung service.")
		quit(1)
		return
	player.global_position = vea.global_position
	main.call("_interact")
	var serve_button := _find_button(dialog_ui, "Layani pelanggan")
	if serve_button == null or not serve_button.visible:
		push_error("The settled player should be able to serve a starting customer.")
		quit(1)
		return
	serve_button.pressed.emit()
	var soup_button := _find_button(main.get("_gift_ui"), "Sup Sayur Bening")
	if soup_button == null:
		push_error("The first cooked meal should be available to serve to a customer.")
		quit(1)
		return
	soup_button.pressed.emit()
	if (
		game_state.reputation != 1
		or game_state.coins <= game_state.STARTING_COINS
		or not game_state.customers_served_today.has("vea")
	):
		push_error("Serving a liked meal should connect the prologue to the warung systems.")
		quit(1)
		return
	(main.get("_gift_ui") as HearthwoodGiftUI).close_gifts()
	var affection_system := main.get("_affection_system") as HearthwoodAffectionSystem
	if affection_system == null:
		push_error("The affection system should be active in the main game.")
		quit(1)
		return
	affection_system.heart_level_changed.emit("vea", 1)
	if not str(main.get("_hint_label").text).contains("Vea mencapai hati 1"):
		push_error("Affection progress should notify the player in the HUD.")
		quit(1)
		return

	player.global_position = veral.global_position
	main.call("_interact")
	upgrade_button = _find_button(dialog_ui, "Izin & upgrade warung")
	if upgrade_button == null or not upgrade_button.visible:
		push_error("Veral should expose the upgrade flow after the player settles.")
		quit(1)
		return
	upgrade_button.pressed.emit()
	var warung_ui := main.get("_warung_ui") as HearthwoodWarungUI
	if warung_ui == null or not warung_ui.is_open():
		push_error("Veral's upgrade action should open the warung progression UI.")
		quit(1)
		return
	game_state.reputation = 10
	game_state.coins = 500
	if not game_state.add_item("kayu"):
		push_error("Could not provide the tier-one material for the upgrade flow test.")
		quit(1)
		return
	var tier_one_button := warung_ui.get("_upgrade_button") as Button
	if tier_one_button == null or tier_one_button.disabled:
		push_error("The upgrade UI should enable the first tier when its costs are met.")
		quit(1)
		return
	tier_one_button.pressed.emit()
	if (
		game_state.warung_tier != 1
		or not game_state.business_permits.has(1)
		or game_state.coins != 0
		or game_state.get_item_count("kayu") != 0
	):
		push_error("Confirming the first warung upgrade should apply its permit and costs.")
		quit(1)
		return
	warung_ui.close_upgrade()

	var save_result: Dictionary = game_state.save_game(
		player.global_position,
		MAIN_SCENE_PATH,
		TEST_SAVE_PATH
	)
	if not bool(save_result.get("valid", false)):
		push_error("Could not save the completed prologue for the resume test.")
		quit(1)
		return
	game_state.completed_quests.clear()
	var load_result: Dictionary = game_state.load_game(TEST_SAVE_PATH, MAIN_SCENE_PATH)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	if (
		not bool(load_result.get("valid", false))
		or not game_state.completed_quests.has("prologue_receive_residence_permit")
		or not game_state.completed_quests.has("prologue_settle_in_hut")
		or game_state.warung_tier != 1
		or not str(main.call("_current_prologue_step")).is_empty()
	):
		push_error("Saving and loading should preserve the completed prologue state.")
		quit(1)
		return

	main.queue_free()
	await process_frame
	await create_timer(0.5).timeout
	print("Forest awakening, Rast, foraging, Veral, cooking, residence, settlement, service, and save flow passed.")
	quit(0)


func _find_npc(world: HearthwoodWorld, npc_id: String) -> HearthwoodNPC:
	for child in world.get_children():
		if child is HearthwoodNPC and child.npc_id == npc_id:
			return child as HearthwoodNPC
	return null


func _find_button(parent: Node, button_text: String) -> Button:
	for child in parent.get_children():
		if child is Button and (child as Button).text.contains(button_text):
			return child as Button
		var nested_button := _find_button(child, button_text)
		if nested_button != null:
			return nested_button
	return null


func _dialog_contains(dialog_ui: HearthwoodDialogUI, text: String) -> bool:
	var dialogue_label := dialog_ui.get("_dialogue_label") as Label
	return dialogue_label != null and dialogue_label.text.contains(text)
