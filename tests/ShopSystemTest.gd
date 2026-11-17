extends SceneTree

const SHOP_NPC_SCENE: PackedScene = preload("res://scenes/ShopNPC.tscn")
const SHOP_UI_SCENE: PackedScene = preload("res://scenes/ShopUI.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	var schedules_file := FileAccess.open("res://data/schedules.json", FileAccess.READ)
	var schedules: Dictionary = JSON.parse_string(schedules_file.get_as_text())

	var giral := SHOP_NPC_SCENE.instantiate() as HearthwoodShopNPC
	giral.configure_named("giral", "res://data/npcs/giral.json", schedules["giral"])
	root.add_child(giral)
	await process_frame

	game_state.current_hour = 7
	game_state.current_minute = 0
	time_system.minute_changed.emit(game_state.current_day, 7, 0)
	if not giral.is_shop_open() or not giral.can_interact():
		push_error("Giral should be open from 07:00.")
		quit(1)
		return

	game_state.current_hour = 12
	time_system.minute_changed.emit(game_state.current_day, 12, 0)
	if giral.is_shop_open() or giral.can_interact():
		push_error("Giral should be closed at 12:00.")
		quit(1)
		return

	var talia := SHOP_NPC_SCENE.instantiate() as HearthwoodShopNPC
	talia.configure_named("talia", "res://data/npcs/talia.json", schedules["talia"])
	root.add_child(talia)
	game_state.current_hour = 13
	time_system.minute_changed.emit(game_state.current_day, 13, 0)
	if not talia.is_shop_open() or not talia.can_interact():
		push_error("Talia should be open from 13:00.")
		quit(1)
		return

	game_state.current_hour = 18
	time_system.minute_changed.emit(game_state.current_day, 18, 0)
	if talia.is_shop_open() or talia.can_interact():
		push_error("Talia should be closed at 18:00.")
		quit(1)
		return

	game_state.npc_heart_levels.clear()
	if giral.get_discount_percent() != 0:
		push_error("Merchants should have no discount before heart level 2.")
		quit(1)
		return
	game_state.npc_heart_levels["giral"] = 2
	if giral.get_discount_percent() != 5:
		push_error("Heart level 2 should grant a 5% merchant discount.")
		quit(1)
		return
	game_state.npc_heart_levels["giral"] = 3
	if giral.get_discount_percent() != 15:
		push_error("Heart level 3 should grant a 15% merchant discount.")
		quit(1)
		return

	game_state.npc_heart_levels.clear()
	game_state.coins = game_state.STARTING_COINS
	game_state.inventory.clear()
	var shop_ui := SHOP_UI_SCENE.instantiate() as HearthwoodShopUI
	root.add_child(shop_ui)
	await process_frame
	if not shop_ui.open_shop("giral", "Giral", 5):
		push_error("Giral shop UI did not open.")
		quit(1)
		return

	var buy_button := _find_button(shop_ui, "Beli")
	if buy_button == null:
		push_error("Shop UI did not create a buy button.")
		quit(1)
		return
	buy_button.pressed.emit()
	if game_state.coins != 81 or game_state.get_item_count("tepung") != 1:
		push_error("Discounted purchase did not update coins and inventory correctly.")
		quit(1)
		return

	game_state.coins = 0
	if game_state.purchase_item("garam", 10) or game_state.get_item_count("garam") > 0:
		push_error("An unaffordable purchase should not change inventory.")
		quit(1)
		return

	print("Shop opening hours, discounts, UI, and purchase tests passed.")
	quit(0)


func _find_button(parent: Node, button_text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == button_text:
			return child
		var nested_button := _find_button(child, button_text)
		if nested_button != null:
			return nested_button
	return null
