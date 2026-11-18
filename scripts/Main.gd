extends Node2D

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/Player.tscn")
const DIALOG_UI_SCENE: PackedScene = preload("res://scenes/DialogUI.tscn")
const SHOP_UI_SCENE: PackedScene = preload("res://scenes/ShopUI.tscn")
const INVENTORY_UI_SCENE: PackedScene = preload("res://scenes/InventoryUI.tscn")
const COOKING_SYSTEM_SCENE: PackedScene = preload("res://scenes/CookingSystem.tscn")
const COOKING_UI_SCENE: PackedScene = preload("res://scenes/CookingUI.tscn")
const AFFECTION_SYSTEM_SCENE: PackedScene = preload("res://scenes/AffectionSystem.tscn")
const GIFT_UI_SCENE: PackedScene = preload("res://scenes/GiftUI.tscn")
const WARUNG_SYSTEM_SCENE: PackedScene = preload("res://scenes/WarungSystem.tscn")
const WARUNG_UI_SCENE: PackedScene = preload("res://scenes/WarungUI.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/PauseMenu.tscn")
const MAIN_MENU_SCENE_PATH: String = "res://scenes/MainMenu.tscn"
const AUDIO_DIRECTOR_SCRIPT: Script = preload("res://scripts/systems/AudioDirector.gd")
const PROLOGUE_DATA_PATH: String = "res://data/story/prologue.json"
const PROLOGUE_FIND_RAST: String = "prologue_find_rast"
const PROLOGUE_COLLECT_SAYUR: String = "prologue_collect_sayur"
const PROLOGUE_MEET_VERAL: String = "prologue_meet_veral"
const PROLOGUE_COOK_FIRST_MEAL: String = "prologue_cook_first_meal"
const PROLOGUE_RECEIVE_RESIDENCE_PERMIT: String = "prologue_receive_residence_permit"
const PROLOGUE_SETTLE_IN_HUT: String = "prologue_settle_in_hut"
const PROLOGUE_STEP_IDS: Array[String] = [
	PROLOGUE_FIND_RAST,
	PROLOGUE_COLLECT_SAYUR,
	PROLOGUE_MEET_VERAL,
	PROLOGUE_COOK_FIRST_MEAL,
	PROLOGUE_RECEIVE_RESIDENCE_PERMIT,
	PROLOGUE_SETTLE_IN_HUT,
]
const HOME_POSITION: Vector2 = Vector2(1320.0, 476.0)

var _world: HearthwoodWorld
var _player: CharacterBody2D
var _clock_label: Label
var _energy_label: Label
var _energy_bar: ProgressBar
var _coins_label: Label
var _hint_label: Label
var _objective_label: Label
var _dialog_ui: HearthwoodDialogUI
var _shop_ui: HearthwoodShopUI
var _inventory_ui: HearthwoodInventoryUI
var _cooking_system: HearthwoodCookingSystem
var _cooking_ui: HearthwoodCookingUI
var _affection_system: HearthwoodAffectionSystem
var _gift_ui: HearthwoodGiftUI
var _warung_system: HearthwoodWarungSystem
var _warung_ui: HearthwoodWarungUI
var _pause_menu: HearthwoodPauseMenu
var _audio_director: HearthwoodAudioDirector
var _current_shopkeeper: HearthwoodShopNPC
var _prologue_data: Dictionary = {}
var _hint_feedback_time_remaining: float = 0.0


func _ready() -> void:
	if not _load_prologue_data():
		return
	var game_state = get_node("/root/GameState")
	_world = WORLD_SCENE.instantiate()
	add_child(_world)

	_player = PLAYER_SCENE.instantiate()
	_player.position = game_state.pending_player_position
	add_child(_player)

	var camera: Camera2D = _player.get_node("camera2d")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 880

	_audio_director = AUDIO_DIRECTOR_SCRIPT.new()
	_audio_director.name = "AudioDirector"
	_audio_director.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio_director)
	_update_audio_context()

	_create_hud()
	_dialog_ui = DIALOG_UI_SCENE.instantiate()
	add_child(_dialog_ui)
	_dialog_ui.gift_requested.connect(_on_gift_requested)
	_dialog_ui.service_requested.connect(_on_service_requested)
	_dialog_ui.upgrade_requested.connect(_on_upgrade_requested)
	_shop_ui = SHOP_UI_SCENE.instantiate()
	add_child(_shop_ui)
	_shop_ui.talk_requested.connect(_on_shop_talk_requested)
	_shop_ui.closed.connect(_on_shop_closed)
	_inventory_ui = INVENTORY_UI_SCENE.instantiate()
	add_child(_inventory_ui)
	_cooking_system = COOKING_SYSTEM_SCENE.instantiate()
	add_child(_cooking_system)
	_cooking_system.cooking_completed.connect(_on_cooking_completed)
	_affection_system = AFFECTION_SYSTEM_SCENE.instantiate()
	_affection_system.heart_level_changed.connect(_on_heart_level_changed)
	_affection_system.set_cooking_system(_cooking_system)
	add_child(_affection_system)
	_warung_system = WARUNG_SYSTEM_SCENE.instantiate()
	_warung_system.set_systems(_cooking_system, _affection_system)
	add_child(_warung_system)
	_cooking_ui = COOKING_UI_SCENE.instantiate()
	add_child(_cooking_ui)
	_cooking_ui.set_cooking_system(_cooking_system)
	_gift_ui = GIFT_UI_SCENE.instantiate()
	_gift_ui.set_affection_system(_affection_system)
	_gift_ui.set_warung_system(_warung_system)
	add_child(_gift_ui)
	_warung_ui = WARUNG_UI_SCENE.instantiate()
	_warung_ui.set_warung_system(_warung_system)
	add_child(_warung_ui)
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(_pause_menu)
	_pause_menu.save_requested.connect(_on_manual_save_requested)
	_pause_menu.load_requested.connect(_on_manual_load_requested)
	_pause_menu.main_menu_requested.connect(_on_main_menu_requested)
	_connect_signals()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not (
		event is InputEventKey and event.is_echo()
	):
		_open_pause_menu()
	elif event.is_action_pressed("interact") and not (
		event is InputEventKey and event.is_echo()
	):
		_interact()
	elif event.is_action_pressed("inventory") and not (event is InputEventKey and event.is_echo()):
		_toggle_inventory()


func _process(delta: float) -> void:
	_update_audio_context()
	_advance_prologue_after_foraging()
	if _hint_feedback_time_remaining > 0.0:
		_hint_feedback_time_remaining = maxf(
			0.0,
			_hint_feedback_time_remaining - delta
		)
		if _hint_feedback_time_remaining > 0.0:
			return
	if (
		_dialog_ui.is_open()
		or _inventory_ui.is_open()
		or _cooking_ui.is_open()
		or _gift_ui.is_open()
		or _warung_ui.is_open()
		or _pause_menu.is_open()
	):
		return

	var nearby_npc := _world.get_closest_named_npc(_player.global_position, 64.0)
	if nearby_npc != null:
		if nearby_npc is HearthwoodShopNPC:
			_hint_label.text = "Belanja atau bicara dengan %s  |  E" % nearby_npc.get_display_name()
			return
		_hint_label.text = "Bicara dengan %s  |  E" % nearby_npc.get_display_name()
		return

	var nearby_pickup := _world.get_closest_item_pickup(_player.global_position, 64.0)
	if nearby_pickup != null:
		_hint_label.text = "Ambil %s  |  E" % nearby_pickup.get_display_name()
		return

	if _world.is_near_cooking_station(_player.global_position):
		_hint_label.text = "Masak di api unggun  |  E"
		return

	if _world.is_near_bed(_player.global_position):
		_hint_label.text = "Tempat istirahat  |  E untuk tidur dan berganti hari"
	else:
		_hint_label.text = "WASD / panah untuk bergerak  |  E untuk berinteraksi"


func _connect_signals() -> void:
	var game_state = get_node("/root/GameState")
	var time_system = get_node("/root/TimeSystem")
	game_state.energy_changed.connect(_update_energy)
	game_state.coins_changed.connect(_update_coins)
	game_state.warung_upgraded.connect(_on_warung_upgraded)
	game_state.quest_completed.connect(_on_quest_completed)
	time_system.hour_changed.connect(_update_hud)
	time_system.day_changed.connect(_on_day_changed)
	time_system.minute_changed.connect(_on_minute_changed)
	time_system.sleep_started.connect(_on_sleep_started)


func _create_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var interface := Control.new()
	interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(interface)

	var status_panel := PanelContainer.new()
	status_panel.position = Vector2(16.0, 16.0)
	interface.add_child(status_panel)
	var status_layout := VBoxContainer.new()
	status_panel.add_child(status_layout)

	_clock_label = Label.new()
	_clock_label.add_theme_font_size_override("font_size", 20)
	status_layout.add_child(_clock_label)

	_energy_label = Label.new()
	status_layout.add_child(_energy_label)

	_energy_bar = ProgressBar.new()
	_energy_bar.custom_minimum_size = Vector2(180.0, 18.0)
	_energy_bar.max_value = 100.0
	_energy_bar.show_percentage = false
	status_layout.add_child(_energy_bar)

	_coins_label = Label.new()
	status_layout.add_child(_coins_label)

	_objective_label = Label.new()
	_objective_label.custom_minimum_size = Vector2(280.0, 0.0)
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 14)
	status_layout.add_child(_objective_label)

	_hint_label = Label.new()
	_hint_label.position = Vector2(16.0, 210.0)
	_hint_label.add_theme_font_size_override("font_size", 15)
	interface.add_child(_hint_label)

	var pause_button := Button.new()
	pause_button.text = "Menu"
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.offset_left = -84.0
	pause_button.offset_top = 16.0
	pause_button.offset_right = -16.0
	pause_button.offset_bottom = 68.0
	pause_button.custom_minimum_size = Vector2(68.0, 52.0)
	pause_button.pressed.connect(_open_pause_menu)
	interface.add_child(pause_button)

	var controls := TouchControls.new()
	controls.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interface.add_child(controls)
	controls.interact_pressed.connect(_interact)
	controls.inventory_pressed.connect(_toggle_inventory)

	_hint_label.text = "WASD / panah untuk bergerak  |  E untuk berinteraksi"


func _update_hud(_value: int = 0, _minute: int = 0) -> void:
	var game_state = get_node("/root/GameState")
	_clock_label.text = "Hari %d  |  %02d:%02d" % [
		game_state.current_day,
		game_state.current_hour % 24,
		game_state.current_minute,
	]
	_update_energy(game_state.energy)
	_update_coins(game_state.coins)
	_refresh_prologue_objective()
	_update_audio_context()


func _update_audio_context() -> void:
	if not is_instance_valid(_audio_director) or not is_instance_valid(_player):
		return
	var game_state = get_node("/root/GameState")
	var track := "forest"
	if game_state.current_hour >= 18 or game_state.current_hour < 6:
		track = "night"
	elif _player.global_position.x >= 560.0:
		track = "village"
	_audio_director.play_music(track)


func _update_energy(value: int) -> void:
	_energy_label.text = "Energi: %d / %d" % [value, 100]
	_energy_bar.value = value


func _update_coins(value: int) -> void:
	_coins_label.text = "Koin: %d" % value


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_hud()


func _on_day_changed(_day: int) -> void:
	_update_hud()
	_auto_save()


func _on_warung_upgraded(_new_tier: int) -> void:
	_update_hud()
	_auto_save()


func _on_quest_completed(_quest_id: String) -> void:
	_update_hud()
	_auto_save()


func _on_cooking_completed(_recipe_id: String) -> void:
	_audio_director.play_sfx("cook")
	if _recipe_id == "sup_sayur_bening" and _current_prologue_step() == PROLOGUE_COOK_FIRST_MEAL:
		_complete_prologue_step(PROLOGUE_COOK_FIRST_MEAL)


func _on_heart_level_changed(_npc_id: String, _new_level: int) -> void:
	_audio_director.play_sfx("heart_up")
	var npc_name := _world.get_named_npc_name(_npc_id)
	if npc_name.is_empty():
		push_error("Could not display affection progress for NPC: %s" % _npc_id)
		return
	_show_hint_feedback("%s mencapai hati %d." % [npc_name, _new_level])


func _show_hint_feedback(message: String) -> void:
	_hint_label.text = message
	_hint_feedback_time_remaining = 3.0


func _on_sleep_started(_wake_hour: int) -> void:
	_audio_director.play_sfx("sleep")


func _auto_save() -> void:
	var result := _save_current_game()
	if not bool(result.get("valid", false)):
		push_error("Automatic save failed: %s" % str(result.get("pesan", "")))


func _save_current_game() -> Dictionary:
	var current_scene := get_tree().current_scene
	if current_scene == null or not is_instance_valid(_player):
		push_error("Cannot save without an active scene and player.")
		return {"valid": false, "pesan": "Lokasi pemain tidak tersedia."}
	return get_node("/root/GameState").save_game(
		_player.global_position,
		current_scene.scene_file_path
	)


func _on_manual_save_requested() -> void:
	var result := _save_current_game()
	_pause_menu.show_status(str(result.get("pesan", "Save tidak dapat dilakukan.")))


func _on_manual_load_requested() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		_pause_menu.show_status("Scene aktif tidak tersedia.")
		return
	var result: Dictionary = get_node("/root/GameState").load_game(
		get_node("/root/GameState").SAVE_FILE_PATH,
		current_scene.scene_file_path
	)
	if not bool(result.get("valid", false)):
		_pause_menu.show_status(str(result.get("pesan", "Game tidak dapat dimuat.")))
		return
	_player.global_position = result["posisi"]
	get_node("/root/TimeSystem").sync_from_game_state()
	_update_hud()
	_pause_menu.show_status(str(result.get("pesan", "Game berhasil dimuat.")))


func _on_main_menu_requested() -> void:
	var result := _save_current_game()
	if not bool(result.get("valid", false)):
		_pause_menu.show_status(str(result.get("pesan", "Game tidak dapat disimpan.")))
		return
	_pause_menu.close_menu()
	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error("Could not return to the main menu (code %d)." % error)


func _open_pause_menu() -> void:
	if (
		_pause_menu.is_open()
		or _dialog_ui.is_open()
		or _shop_ui.is_open()
		or _inventory_ui.is_open()
		or _cooking_ui.is_open()
		or _gift_ui.is_open()
		or _warung_ui.is_open()
	):
		return
	_pause_menu.open_menu()


func _on_shop_talk_requested(shop_id: String) -> void:
	if not is_instance_valid(_current_shopkeeper) or _current_shopkeeper.npc_id != shop_id:
		push_error("Shop dialogue requested without a matching shopkeeper.")
		return
	_dialog_ui.open_dialog(
		_current_shopkeeper.get_display_name(),
		_current_shopkeeper.get_role(),
		_current_shopkeeper.get_dialogue(),
		_current_shopkeeper.npc_id,
		_warung_system.is_customer_available(_current_shopkeeper.npc_id)
	)
	_current_shopkeeper.mark_met()


func _on_gift_requested(npc_id: String, npc_name: String) -> void:
	_gift_ui.open_gifts(npc_id, npc_name)


func _on_service_requested(npc_id: String, npc_name: String) -> void:
	if not _is_prologue_complete():
		_hint_label.text = _get_prologue_objective()
		return
	_gift_ui.open_gifts(npc_id, npc_name, true)


func _on_upgrade_requested() -> void:
	if not _is_prologue_complete():
		_hint_label.text = _get_prologue_objective()
		return
	_warung_ui.open_upgrade()


func _on_shop_hours_changed(is_open: bool) -> void:
	if not is_open and _shop_ui.is_open():
		_shop_ui.close_shop()


func _on_shop_closed() -> void:
	if is_instance_valid(_current_shopkeeper):
		var hours_changed_callback := Callable(self, "_on_shop_hours_changed")
		if _current_shopkeeper.shop_hours_changed.is_connected(hours_changed_callback):
			_current_shopkeeper.shop_hours_changed.disconnect(hours_changed_callback)
	_current_shopkeeper = null


func _toggle_inventory() -> void:
	if (
		_dialog_ui.is_open()
		or _shop_ui.is_open()
		or _cooking_ui.is_open()
		or _gift_ui.is_open()
		or _warung_ui.is_open()
		or _pause_menu.is_open()
	):
		return
	_inventory_ui.toggle_inventory()


func _interact() -> void:
	if (
		_dialog_ui.is_open()
		or _shop_ui.is_open()
		or _inventory_ui.is_open()
		or _cooking_ui.is_open()
		or _gift_ui.is_open()
		or _warung_ui.is_open()
		or _pause_menu.is_open()
	):
		return
	_audio_director.play_sfx("interact")

	var nearby_npc := _world.get_closest_named_npc(_player.global_position, 56.0)
	if nearby_npc != null:
		if nearby_npc is HearthwoodShopNPC:
			_current_shopkeeper = nearby_npc as HearthwoodShopNPC
			if not _shop_ui.open_shop(
				_current_shopkeeper.npc_id,
				_current_shopkeeper.get_display_name(),
				_current_shopkeeper.get_discount_percent()
			):
				_current_shopkeeper = null
			else:
				var hours_changed_callback := Callable(self, "_on_shop_hours_changed")
				if not _current_shopkeeper.shop_hours_changed.is_connected(hours_changed_callback):
					_current_shopkeeper.shop_hours_changed.connect(hours_changed_callback)
			return
		if _handle_prologue_interaction(nearby_npc):
			return
		var prologue_complete := _is_prologue_complete()
		_dialog_ui.open_dialog(
			nearby_npc.get_display_name(),
			nearby_npc.get_role(),
			nearby_npc.get_dialogue(),
			nearby_npc.npc_id,
			prologue_complete and _warung_system.is_customer_available(nearby_npc.npc_id),
			prologue_complete
			and nearby_npc.npc_id == "veral"
			and get_node("/root/GameState").warung_tier < 2
		)
		nearby_npc.mark_met()
	else:
		var nearby_pickup := _world.get_closest_item_pickup(_player.global_position, 56.0)
		if nearby_pickup != null:
			var item_name := nearby_pickup.get_display_name()
			if _world.collect_item_pickup(nearby_pickup):
				_hint_label.text = "%s dikumpulkan." % item_name
				_advance_prologue_after_foraging()
			return
		elif _world.is_near_cooking_station(_player.global_position):
			_cooking_ui.open_cooking(_cooking_system)
		elif _world.is_near_bed(_player.global_position):
			if _current_prologue_step() == PROLOGUE_SETTLE_IN_HUT:
				_player.global_position = HOME_POSITION
				_complete_prologue_step(PROLOGUE_SETTLE_IN_HUT)
				_hint_label.text = "Kamu menetap di gubuk pinggir desa."
				return
			get_node("/root/TimeSystem").sleep()
			_hint_label.text = "Hari baru dimulai. Energi sudah pulih."
		else:
			_hint_label.text = "Jelajahi jalan menuju desa untuk menemukan tempat beristirahat."


func _load_prologue_data() -> bool:
	if not FileAccess.file_exists(PROLOGUE_DATA_PATH):
		push_error("Prologue data file not found: %s" % PROLOGUE_DATA_PATH)
		return false
	var file := FileAccess.open(PROLOGUE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read prologue data: %s" % PROLOGUE_DATA_PATH)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if (
		typeof(parsed) != TYPE_DICTIONARY
		or typeof(parsed.get("dialogues")) != TYPE_DICTIONARY
		or typeof(parsed.get("objectives")) != TYPE_DICTIONARY
	):
		push_error("Prologue data must contain dialogues and objectives objects.")
		return false
	for dialogue_key in [
		"rast_first_meeting",
		"rast_after_meeting",
		"veral_cooking_test",
		"veral_waiting_for_meal",
		"veral_residence_permit",
	]:
		if typeof(parsed["dialogues"].get(dialogue_key)) != TYPE_STRING:
			push_error("Prologue data is missing dialogue '%s'." % dialogue_key)
			return false
	for objective_key in PROLOGUE_STEP_IDS + [
		"prologue_rebuild_warung",
		"prologue_warung_complete",
	]:
		if typeof(parsed["objectives"].get(objective_key)) != TYPE_STRING:
			push_error("Prologue data is missing objective '%s'." % objective_key)
			return false
	_prologue_data = parsed
	return true


func _current_prologue_step() -> String:
	var game_state = get_node("/root/GameState")
	for step_id in PROLOGUE_STEP_IDS:
		if not game_state.completed_quests.has(step_id):
			return step_id
	return ""


func _is_prologue_complete() -> bool:
	return _current_prologue_step().is_empty()


func _complete_prologue_step(step_id: String) -> void:
	if _current_prologue_step() != step_id:
		return
	if not get_node("/root/GameState").complete_quest(step_id):
		push_error("Could not complete prologue step: %s" % step_id)


func _advance_prologue_after_foraging() -> void:
	if (
		_current_prologue_step() == PROLOGUE_COLLECT_SAYUR
		and get_node("/root/GameState").get_item_count("sayur_liar") > 0
	):
		_complete_prologue_step(PROLOGUE_COLLECT_SAYUR)


func _handle_prologue_interaction(npc: HearthwoodNPC) -> bool:
	var game_state = get_node("/root/GameState")
	var step_id := _current_prologue_step()
	var dialogue_key := ""

	if npc.npc_id == "rast":
		if step_id == PROLOGUE_FIND_RAST:
			dialogue_key = "rast_first_meeting"
			_complete_prologue_step(PROLOGUE_FIND_RAST)
		elif not game_state.completed_quests.has(PROLOGUE_RECEIVE_RESIDENCE_PERMIT):
			dialogue_key = "rast_after_meeting"
	elif npc.npc_id == "veral":
		if step_id == PROLOGUE_MEET_VERAL:
			if not game_state.add_item("garam"):
				push_error("Could not provide the tutorial cooking ingredient.")
				return true
			dialogue_key = "veral_cooking_test"
			_complete_prologue_step(PROLOGUE_MEET_VERAL)
		elif step_id == PROLOGUE_COOK_FIRST_MEAL:
			dialogue_key = "veral_waiting_for_meal"
		elif step_id == PROLOGUE_RECEIVE_RESIDENCE_PERMIT:
			dialogue_key = "veral_residence_permit"
			_complete_prologue_step(PROLOGUE_RECEIVE_RESIDENCE_PERMIT)

	if dialogue_key.is_empty():
		return false
	var dialogue: String = _prologue_data["dialogues"][dialogue_key]
	dialogue = dialogue.replace("{nama}", str(game_state.player_name))
	_dialog_ui.open_dialog(
		npc.get_display_name(),
		npc.get_role(),
		dialogue,
		npc.npc_id
	)
	npc.mark_met()
	return true


func _refresh_prologue_objective() -> void:
	if _objective_label == null:
		return
	_objective_label.text = _get_prologue_objective()


func _get_prologue_objective() -> String:
	var game_state = get_node("/root/GameState")
	var objective_key := _current_prologue_step()
	if objective_key.is_empty():
		objective_key = (
			"prologue_warung_complete"
			if game_state.warung_tier >= game_state.MAX_WARUNG_TIER
			else "prologue_rebuild_warung"
		)
	return str(_prologue_data["objectives"][objective_key])
