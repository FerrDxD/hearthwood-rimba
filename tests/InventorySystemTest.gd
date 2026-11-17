extends SceneTree

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const INVENTORY_UI_SCENE: PackedScene = preload("res://scenes/InventoryUI.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	game_state.inventory.clear()
	game_state.coins = game_state.STARTING_COINS

	if game_state.item_catalog.size() != 25:
		push_error("The item catalog should load all 25 item definitions.")
		quit(1)
		return
	if not game_state.add_item("sayur_liar", 2) or game_state.get_item_count("sayur_liar") != 2:
		push_error("Adding items should create a quantity stack.")
		quit(1)
		return
	if not game_state.remove_item("sayur_liar") or game_state.get_item_count("sayur_liar") != 1:
		push_error("Removing an item should reduce its stack quantity.")
		quit(1)
		return
	if not game_state.add_item("sup_sayur_bening", 2, game_state.current_day, 3):
		push_error("Cooked items should keep their cooking date and quality.")
		quit(1)
		return
	if game_state.get_item_energy("sup_sayur_bening", 3) != 40:
		push_error("Food energy should reflect its quality.")
		quit(1)
		return

	var inventory_ui := INVENTORY_UI_SCENE.instantiate() as HearthwoodInventoryUI
	root.add_child(inventory_ui)
	await process_frame
	inventory_ui.toggle_inventory()
	if not inventory_ui.is_open():
		push_error("Inventory UI should open when toggled.")
		quit(1)
		return
	if not _contains_text(inventory_ui, "Energi +40") or not _contains_text(
		inventory_ui, "Dimasak hari %d" % game_state.current_day
	):
		push_error("Inventory UI should show cooked food energy and cooking date.")
		quit(1)
		return

	var world := WORLD_SCENE.instantiate() as HearthwoodWorld
	root.add_child(world)
	await process_frame
	var pickup := world.get_closest_item_pickup(Vector2(104.0, 218.0), 2.0)
	if pickup == null or not world.collect_item_pickup(pickup):
		push_error("The player should be able to collect nearby forage.")
		quit(1)
		return
	if game_state.get_item_count("sayur_liar") != 2:
		push_error("Collecting forage should add it to the inventory.")
		quit(1)
		return
	if world.get_closest_item_pickup(Vector2(104.0, 218.0), 2.0) != null:
		push_error("Collected forage should no longer be available that day.")
		quit(1)
		return

	time_system.sleep()
	await process_frame
	if world.get_closest_item_pickup(Vector2(104.0, 218.0), 2.0) == null:
		push_error("Forage should respawn after the player sleeps.")
		quit(1)
		return

	if not game_state.purchase_item("tepung", 20) or game_state.get_item_count("tepung") != 1:
		push_error("Shop purchases should add items to the inventory stack.")
		quit(1)
		return

	print("Item catalog, inventory, food metadata, pickups, and respawn tests passed.")
	quit(0)


func _contains_text(parent: Node, expected_text: String) -> bool:
	for child in parent.get_children():
		if child is Label and expected_text in child.text:
			return true
		if _contains_text(child, expected_text):
			return true
	return false
