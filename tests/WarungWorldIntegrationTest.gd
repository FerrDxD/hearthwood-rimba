# tests/WarungWorldIntegrationTest.gd
extends SceneTree

const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const COOKING_STATION_POS: Vector2 = Vector2(1210.0, 478.0)
const BED_POS: Vector2 = Vector2(1320.0, 476.0)

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
	print("--- Running WarungWorldIntegrationTest ---")
	var world = WORLD_SCENE.instantiate()
	if not _assert(world != null, "World scene must instantiate successfully"):
		quit(1)
		return

	root.add_child(world)
	await process_frame

	if not _assert(world.has_method("get_warung_tables"), "World must provide get_warung_tables()"):
		world.queue_free()
		quit(1)
		return

	if not _assert(world.has_method("get_warung_bell"), "World must provide get_warung_bell()"):
		world.queue_free()
		quit(1)
		return

	var tables: Array = world.get_warung_tables()
	if not _assert(tables.size() >= 2, "World must have at least 2 dining tables in the warung district, got %d" % tables.size()):
		world.queue_free()
		quit(1)
		return

	for i in range(tables.size()):
		var table = tables[i]
		_assert(table is Area2D, "Table %d must be an Area2D" % i)
		var pos: Vector2 = table.position
		_assert(pos.x >= 1040.0 and pos.x <= 1560.0, "Table %d at %s must be inside Warung District X bounds (1040-1560)" % [i, str(pos)])
		_assert(pos.y >= 440.0 and pos.y <= 880.0, "Table %d at %s must be inside Warung District Y bounds (440-880)" % [i, str(pos)])
		_assert(pos.distance_to(COOKING_STATION_POS) > 30.0, "Table %d at %s must not overlap cooking station at %s (dist: %f)" % [i, str(pos), str(COOKING_STATION_POS), pos.distance_to(COOKING_STATION_POS)])
		_assert(pos.distance_to(BED_POS) > 30.0, "Table %d at %s must not overlap bed at %s (dist: %f)" % [i, str(pos), str(BED_POS), pos.distance_to(BED_POS)])

	var bell: Node2D = world.get_warung_bell()
	if not _assert(bell != null, "World must provide warung bell / sign interaction point"):
		world.queue_free()
		quit(1)
		return

	_assert(bell is Area2D, "Warung bell must be an Area2D interaction point")
	var bell_pos: Vector2 = bell.position
	_assert(bell_pos.x >= 1040.0 and bell_pos.x <= 1560.0, "Warung bell at %s must be inside Warung District X bounds" % str(bell_pos))
	_assert(bell_pos.y >= 440.0 and bell_pos.y <= 880.0, "Warung bell at %s must be inside Warung District Y bounds" % str(bell_pos))
	_assert(bell_pos.distance_to(COOKING_STATION_POS) > 15.0, "Warung bell at %s must not overlap cooking station" % str(bell_pos))

	# Test daily reset on dirty tables
	if tables.size() > 0:
		var first_table = tables[0]
		if first_table.has_method("seat_customer") and first_table.has_method("serve_food") and first_table.has_method("finish_eating"):
			first_table.seat_customer("talia", "sup_sayur_bening")
			first_table.serve_food("sup_sayur_bening", 2)
			first_table.finish_eating()
			_assert(first_table.current_state == first_table.TableState.DIRTY, "Table should be dirty before day change")
			world._on_day_changed(2)
			_assert(first_table.current_state == first_table.TableState.EMPTY, "Table should be cleared / reset after day change")

	world.queue_free()

	if _failed:
		push_error("WarungWorldIntegrationTest failed!")
		quit(1)
		return

	print("WarungWorldIntegrationTest passed.")
	quit(0)
