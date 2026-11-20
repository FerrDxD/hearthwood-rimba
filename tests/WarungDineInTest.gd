# tests/WarungDineInTest.gd
extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/Main.tscn")
const WARUNG_TABLE_SCRIPT = preload("res://scripts/world/WarungTable.gd")

var _failed: bool = false


func _initialize() -> void:
	call_deferred("_run_tests")


func _assert(condition: bool, message: String) -> bool:
	if not condition:
		push_error("Assertion failed: %s" % message)
		_failed = true
		return false
	return true


func _run_tests() -> void:
	print("--- Running WarungDineInTest ---")
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")

	# Reset state
	game_state.inventory.clear()
	game_state.customers_served_today.clear()
	game_state.current_day = 2
	game_state.current_hour = 17
	game_state.current_minute = 0
	game_state.warung_tier = 1
	game_state.reputation = 10
	game_state.coins = 100

	# Add cooked dish to inventory: "sup_sayur_bening" x2
	game_state.add_item("sup_sayur_bening", 2, 2, 2)

	var main = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	if not _assert(main.has_method("get_warung_system"), "Main must have get_warung_system()"):
		main.queue_free()
		quit(1)
		return

	var warung_system = main.get_warung_system()
	if not _assert(warung_system != null, "Warung system must exist"):
		main.queue_free()
		quit(1)
		return

	# Test start service rush
	var open_result = warung_system.start_service_rush()
	if not _assert(bool(open_result.get("valid", false)), "Service rush must open successfully when conditions met: " + str(open_result.get("pesan", ""))):
		main.queue_free()
		quit(1)
		return

	if not _assert(warung_system.is_service_active(), "Service rush must be marked active"):
		main.queue_free()
		quit(1)
		return

	# Simulate customer seating
	var seated = warung_system.spawn_next_customer()
	if not _assert(seated, "Customer must be seated at an available table"):
		main.queue_free()
		quit(1)
		return

	var tables: Array = main.get_world().get_warung_tables()
	var occupied_table = null
	for t in tables:
		if t is WARUNG_TABLE_SCRIPT and not t.is_available():
			occupied_table = t
			break
	if not _assert(occupied_table != null, "At least one table must be occupied"):
		main.queue_free()
		quit(1)
		return

	if not _assert(occupied_table.current_state == WARUNG_TABLE_SCRIPT.TableState.WAITING_FOOD, "Table state must be WAITING_FOOD"):
		main.queue_free()
		quit(1)
		return

	var initial_dish_count: int = game_state.get_item_count(occupied_table.requested_recipe_id)
	var serve_success: bool = warung_system.serve_table(occupied_table)
	if not _assert(serve_success, "Serving table from inventory must succeed"):
		main.queue_free()
		quit(1)
		return

	if not _assert(game_state.get_item_count(occupied_table.requested_recipe_id) == initial_dish_count - 1, "Inventory dish count must decrease by 1"):
		main.queue_free()
		quit(1)
		return

	if not _assert(occupied_table.current_state == WARUNG_TABLE_SCRIPT.TableState.EATING, "Table state must transition to EATING"):
		main.queue_free()
		quit(1)
		return

	# Simulate finish eating and table clearing
	occupied_table.finish_eating()
	if not _assert(occupied_table.current_state == WARUNG_TABLE_SCRIPT.TableState.DIRTY, "Table state must transition to DIRTY after eating"):
		main.queue_free()
		quit(1)
		return

	var collected_coins: int = occupied_table.clear_table()
	if not _assert(collected_coins > 0, "Clearing dirty table must collect coins"):
		main.queue_free()
		quit(1)
		return

	if not _assert(occupied_table.current_state == WARUNG_TABLE_SCRIPT.TableState.EMPTY, "Table state must return to EMPTY after clearing"):
		main.queue_free()
		quit(1)
		return

	# End rush and check daily summary data
	var summary: Dictionary = warung_system.end_service_rush()
	if not _assert(not warung_system.is_service_active(), "Service rush must be marked inactive after end"):
		main.queue_free()
		quit(1)
		return

	if not _assert(int(summary.get("customers_served", 0)) >= 1, "Summary must record served customers (>= 1)"):
		main.queue_free()
		quit(1)
		return

	if not _assert(int(summary.get("total_coins_earned", 0)) > 0, "Summary must record earned coins (> 0)"):
		main.queue_free()
		quit(1)
		return

	main.queue_free()

	if _failed:
		push_error("WarungDineInTest failed!")
		quit(1)
		return

	print("WarungDineInTest passed.")
	quit(0)
