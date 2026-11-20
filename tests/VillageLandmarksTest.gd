# tests/VillageLandmarksTest.gd
extends SceneTree

const WORLD_SCRIPT = preload("res://scripts/world/World.gd")

func _init() -> void:
	print("--- Running VillageLandmarksTest ---")
	var world = WORLD_SCRIPT.new()
	assert(world != null, "World instance must be created")

	# 1. Test get_village_buildings() API
	assert(world.has_method("get_village_buildings"), "World must have get_village_buildings()")
	assert(world.has_method("get_village_building"), "World must have get_village_building(id)")

	var buildings: Array[Dictionary] = world.get_village_buildings()
	assert(buildings.size() >= 6, "Must return at least 6 village building entries, got %d" % buildings.size())

	var expected_ids := [
		"town_hall",
		"giral_store",
		"talia_store",
		"player_warung",
		"village_granary",
		"residential_cottages"
	]

	for b_id in expected_ids:
		var found := false
		for b in buildings:
			if b.get("id") == b_id:
				found = true
				break
		assert(found, "get_village_buildings() must contain '%s'" % b_id)

		var single_b: Dictionary = world.get_village_building(b_id)
		assert(not single_b.is_empty(), "get_village_building('%s') must return non-empty dict" % b_id)
		assert(single_b.get("id") == b_id, "get_village_building('%s') id must match" % b_id)

	# Test individual cottage query
	var casha_cottage: Dictionary = world.get_village_building("cottage_casha")
	assert(not casha_cottage.is_empty(), "get_village_building('cottage_casha') must return cottage info")
	assert(casha_cottage.get("id") == "cottage_casha", "cottage id must match")

	# 2. Test building rects presence in World
	assert("_building_rects" in world, "World must have _building_rects property")
	var building_rects: Array = world._building_rects
	assert(building_rects.size() >= 6, "World._building_rects must contain at least 6 buildings (Town Hall, Giral, Talia, Warung, Granary, Cottages)")

	# Verify specific landmarks are covered in _building_rects
	var town_hall_rect := Rect2(1330.0, 240.0, 130.0, 84.0)
	var giral_rect := Rect2(970.0, 246.0, 92.0, 72.0)
	var talia_rect := Rect2(1102.0, 246.0, 92.0, 72.0)
	var warung_rect := Rect2(1268.0, 380.0, 104.0, 76.0)
	var granary_rect := Rect2(680.0, 640.0, 100.0, 76.0)

	var has_th := false
	var has_giral := false
	var has_talia := false
	var has_warung := false
	var has_granary := false
	var cottage_count := 0

	for rect in building_rects:
		if rect is Rect2:
			if rect.is_equal_approx(town_hall_rect):
				has_th = true
			elif rect.is_equal_approx(giral_rect):
				has_giral = true
			elif rect.is_equal_approx(talia_rect):
				has_talia = true
			elif rect.is_equal_approx(warung_rect):
				has_warung = true
			elif rect.is_equal_approx(granary_rect):
				has_granary = true
			elif rect.position.y >= 600.0 and rect.position.x >= 800.0:
				cottage_count += 1

	assert(has_th, "Town Hall rect must be in _building_rects")
	assert(has_giral, "Giral Store rect must be in _building_rects")
	assert(has_talia, "Talia Store rect must be in _building_rects")
	assert(has_warung, "Warung rect must be in _building_rects")
	assert(has_granary, "Granary rect must be in _building_rects")
	assert(cottage_count >= 3, "At least 3 residential cottages must be in _building_rects")

	# 3. Test obstacle collisions against critical positions
	var obstacles: Array[Rect2] = world.get_obstacle_rects()
	var critical_positions := {
		"Gate village <-> forest_zone_1": Vector2(565.0, 440.0),
		"Veral meeting position": Vector2(1390.0, 342.0),
		"Cooking Station": Vector2(1210.0, 478.0),
		"Bed": Vector2(1320.0, 476.0),
		"Village Well": Vector2(1050.0, 460.0),
		"Notice Board": Vector2(1130.0, 460.0),
	}

	for pos_name in critical_positions:
		var pos: Vector2 = critical_positions[pos_name]
		for obs in obstacles:
			assert(
				not obs.has_point(pos),
				"Critical point '%s' at %s collides with obstacle %s" % [pos_name, str(pos), str(obs)]
			)
			# Also verify a minimum comfortable clearance radius of 6 pixels around the point
			assert(
				not obs.intersects(Rect2(pos - Vector2(6.0, 6.0), Vector2(12.0, 12.0))),
				"Critical point '%s' at %s is too close to obstacle %s" % [pos_name, str(pos), str(obs)]
			)

	# 4. Test walkable passage between Cooking Station and Veral
	var start_pos := Vector2(1210.0, 478.0)
	var end_pos := Vector2(1390.0, 342.0)
	assert(_has_walkable_path(start_pos, end_pos, obstacles), "There must be a clear walkable passage between Cooking Station and Veral")

	world.free()
	print("VillageLandmarksTest passed.")
	quit(0)


func _has_walkable_path(start: Vector2, goal: Vector2, obstacles: Array[Rect2]) -> bool:
	# Simple grid BFS with cell size 16 to prove navigation path exists
	var cell_size := 16.0
	var min_x := 1150.0
	var max_x := 1450.0
	var min_y := 280.0
	var max_y := 540.0

	var start_cell := Vector2i(int((start.x - min_x) / cell_size), int((start.y - min_y) / cell_size))
	var goal_cell := Vector2i(int((goal.x - min_x) / cell_size), int((goal.y - min_y) / cell_size))

	var visited := {}
	var queue := [start_cell]
	visited[start_cell] = true

	var directions := [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal_cell:
			return true

		for d in directions:
			var neighbor: Vector2i = current + d
			if visited.has(neighbor):
				continue

			var world_x: float = min_x + float(neighbor.x) * cell_size + cell_size * 0.5
			var world_y: float = min_y + float(neighbor.y) * cell_size + cell_size * 0.5
			if world_x < min_x or world_x > max_x or world_y < min_y or world_y > max_y:
				continue

			var cell_rect := Rect2(world_x - 6.0, world_y - 6.0, 12.0, 12.0)
			var blocked := false
			for obs in obstacles:
				if obs.intersects(cell_rect):
					blocked = true
					break

			if not blocked:
				visited[neighbor] = true
				queue.append(neighbor)

	return false
