extends SceneTree

const MAIN_MENU_PATH: String = "res://scenes/MainMenu.tscn"
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
const TEST_SAVE_PATH: String = "user://phase9-main-menu-test.json"


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	_remove_test_file()
	if not game_state.start_new_game("Rina"):
		_fail("Could not initialize the menu save fixture.")
		return
	game_state.current_day = 6
	game_state.current_hour = 10
	game_state.energy = 55
	game_state.coins = 500
	var save_result: Dictionary = game_state.save_game(
		Vector2(456.5, 321.25),
		MAIN_SCENE_PATH,
		TEST_SAVE_PATH
	)
	if not bool(save_result.get("valid", false)):
		_fail("Could not write the menu save fixture.")
		return

	if change_scene_to_file(MAIN_MENU_PATH) != OK:
		_fail("Could not open the main menu scene.")
		return
	await process_frame
	await process_frame
	var menu := current_scene as HearthwoodMainMenu
	if menu == null:
		_fail("The main menu did not become the active scene.")
		return
	menu.configure_save_file_path(TEST_SAVE_PATH)
	var initial_day: int = game_state.current_day
	var initial_hour: int = game_state.current_hour
	var initial_minute: int = game_state.current_minute
	await create_timer(1.7).timeout
	if (
		game_state.current_day != initial_day
		or game_state.current_hour != initial_hour
		or game_state.current_minute != initial_minute
	):
		_fail("The game clock should remain paused while the main menu is open.")
		return

	var continue_button := menu.find_child("continueButton", true, false) as Button
	var new_game_button := menu.find_child("newGameButton", true, false) as Button
	if (
		continue_button == null
		or new_game_button == null
		or continue_button.disabled
		or continue_button.custom_minimum_size.y < 44.0
	):
		_fail("The main menu should expose an accessible Continue action for a valid save.")
		return
	var menu_panel := menu.find_child("contentPanel", true, false) as Control
	var exit_button := menu.find_child("exitButton", true, false) as Button
	if (
		menu_panel == null
		or exit_button == null
		or exit_button.get_global_rect().end.y > menu_panel.get_global_rect().end.y
	):
		_fail("Main menu actions should fit inside the menu panel.")
		return
	for button_name in [
		"continueButton",
		"newGameButton",
		"loadButton",
		"settingsButton",
		"exitButton",
	]:
		var menu_button := menu.find_child(button_name, true, false) as Button
		if menu_button == null or menu_button.custom_minimum_size.y < 44.0:
			_fail("Main menu buttons should provide touch targets of at least 44 pixels.")
			return

	continue_button.pressed.emit()
	await process_frame
	await process_frame
	if (
		current_scene == null
		or current_scene.scene_file_path != MAIN_SCENE_PATH
		or game_state.player_name != "Rina"
		or game_state.current_day != 6
		or game_state.energy != 55
		or game_state.pending_player_position != Vector2(456.5, 321.25)
	):
		_fail("Continue should load state and position before entering the game.")
		return

	if change_scene_to_file(MAIN_MENU_PATH) != OK:
		_fail("Could not return to the main menu for the new-game test.")
		return
	await process_frame
	await process_frame
	menu = current_scene as HearthwoodMainMenu
	if menu == null:
		_fail("The main menu did not reopen.")
		return
	menu.configure_save_file_path(TEST_SAVE_PATH)
	var load_button := menu.find_child("loadButton", true, false) as Button
	if load_button == null or load_button.disabled:
		_fail("The main menu should expose the saved slot through Load Game.")
		return
	load_button.pressed.emit()
	var load_confirmation := menu.find_child(
		"confirmationDialog", true, false
	) as ConfirmationDialog
	if load_confirmation == null or not load_confirmation.visible:
		_fail("Load Game should confirm loading the single save slot.")
		return
	load_confirmation.confirmed.emit()
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != MAIN_SCENE_PATH:
		_fail("Confirmed Load Game should enter the saved game.")
		return

	if change_scene_to_file(MAIN_MENU_PATH) != OK:
		_fail("Could not return to the menu for the new-game test.")
		return
	await process_frame
	await process_frame
	menu = current_scene as HearthwoodMainMenu
	if menu == null:
		_fail("The main menu did not reopen for the new-game test.")
		return
	menu.configure_save_file_path(TEST_SAVE_PATH)
	var name_input := menu.find_child("playerName", true, false) as LineEdit
	new_game_button = menu.find_child("newGameButton", true, false) as Button
	if name_input == null or new_game_button == null:
		_fail("The main menu should expose a player name and New Game action.")
		return
	name_input.text = "Laras"
	new_game_button.pressed.emit()
	var confirmation := menu.find_child("confirmationDialog", true, false) as ConfirmationDialog
	if confirmation == null or not confirmation.visible:
		_fail("Starting a new game with an existing save should require confirmation.")
		return
	confirmation.confirmed.emit()
	await process_frame
	await process_frame
	if (
		current_scene == null
		or current_scene.scene_file_path != MAIN_SCENE_PATH
		or game_state.player_name != "Laras"
		or game_state.current_day != 1
		or game_state.current_hour != 6
		or game_state.energy != game_state.MAX_ENERGY
		or game_state.coins != game_state.STARTING_COINS
		or game_state.warung_tier != 0
		or not game_state.inventory.is_empty()
	):
		_fail("Confirmed New Game should reset gameplay state before entering the world.")
		return

	paused = false
	await _cleanup_active_scene()
	_remove_test_file()
	print("Main menu continue, new-game confirmation, state reset, and player-name tests passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	_cleanup_active_scene()
	_remove_test_file()
	quit(1)


func _cleanup_active_scene() -> void:
	if current_scene == null:
		return
	var audio_director := current_scene.get_node_or_null("AudioDirector")
	if audio_director != null:
		var music_player := audio_director.get_node_or_null("MusicPlayer") as AudioStreamPlayer
		var sfx_player := audio_director.get_node_or_null("SfxPlayer") as AudioStreamPlayer
		if music_player != null:
			music_player.stop()
			music_player.stream = null
		if sfx_player != null:
			sfx_player.stop()
			sfx_player.stream = null
	current_scene.queue_free()
	await process_frame
	await create_timer(0.5).timeout


func _remove_test_file() -> void:
	if not FileAccess.file_exists(TEST_SAVE_PATH):
		return
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	if error != OK:
		push_error("Could not remove the temporary menu save (code %d)." % error)
