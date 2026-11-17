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
const PLAYER_START: Vector2 = Vector2(210.0, 432.0)

var _world: HearthwoodWorld
var _player: CharacterBody2D
var _clock_label: Label
var _energy_label: Label
var _energy_bar: ProgressBar
var _coins_label: Label
var _hint_label: Label
var _dialog_ui: HearthwoodDialogUI
var _shop_ui: HearthwoodShopUI
var _inventory_ui: HearthwoodInventoryUI
var _cooking_system: HearthwoodCookingSystem
var _cooking_ui: HearthwoodCookingUI
var _affection_system: HearthwoodAffectionSystem
var _gift_ui: HearthwoodGiftUI
var _warung_system: HearthwoodWarungSystem
var _warung_ui: HearthwoodWarungUI
var _current_shopkeeper: HearthwoodShopNPC


func _ready() -> void:
	_world = WORLD_SCENE.instantiate()
	add_child(_world)

	_player = PLAYER_SCENE.instantiate()
	_player.position = PLAYER_START
	add_child(_player)

	var camera: Camera2D = _player.get_node("camera2d")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 1600
	camera.limit_bottom = 880

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
	_affection_system = AFFECTION_SYSTEM_SCENE.instantiate()
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
	_connect_signals()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not (event is InputEventKey and event.is_echo()):
		_interact()
	elif event.is_action_pressed("inventory") and not (event is InputEventKey and event.is_echo()):
		_toggle_inventory()


func _process(_delta: float) -> void:
	if (
		_dialog_ui.is_open()
		or _inventory_ui.is_open()
		or _cooking_ui.is_open()
		or _gift_ui.is_open()
		or _warung_ui.is_open()
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
	time_system.hour_changed.connect(_update_hud)
	time_system.day_changed.connect(_update_hud)
	time_system.minute_changed.connect(_on_minute_changed)


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

	_hint_label = Label.new()
	_hint_label.position = Vector2(16.0, 106.0)
	_hint_label.add_theme_font_size_override("font_size", 15)
	interface.add_child(_hint_label)

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


func _update_energy(value: int) -> void:
	_energy_label.text = "Energi: %d / %d" % [value, 100]
	_energy_bar.value = value


func _update_coins(value: int) -> void:
	_coins_label.text = "Koin: %d" % value


func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_update_hud()


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
	_gift_ui.open_gifts(npc_id, npc_name, true)


func _on_upgrade_requested() -> void:
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
	):
		return

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
		_dialog_ui.open_dialog(
			nearby_npc.get_display_name(),
			nearby_npc.get_role(),
			nearby_npc.get_dialogue(),
			nearby_npc.npc_id,
			_warung_system.is_customer_available(nearby_npc.npc_id),
			nearby_npc.npc_id == "veral" and get_node("/root/GameState").warung_tier < 2
		)
		nearby_npc.mark_met()
	else:
		var nearby_pickup := _world.get_closest_item_pickup(_player.global_position, 56.0)
		if nearby_pickup != null:
			var item_name := nearby_pickup.get_display_name()
			if _world.collect_item_pickup(nearby_pickup):
				_hint_label.text = "%s dikumpulkan." % item_name
			return
		elif _world.is_near_cooking_station(_player.global_position):
			_cooking_ui.open_cooking(_cooking_system)
		elif _world.is_near_bed(_player.global_position):
			get_node("/root/TimeSystem").sleep()
			_hint_label.text = "Hari baru dimulai. Energi sudah pulih."
		else:
			_hint_label.text = "Jelajahi jalan menuju desa untuk menemukan tempat beristirahat."
