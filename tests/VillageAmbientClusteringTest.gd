# tests/VillageAmbientClusteringTest.gd
extends SceneTree

const MARKET_RECT := Rect2(920.0, 220.0, 260.0, 160.0)
const PLAZA_RECT := Rect2(1000.0, 380.0, 240.0, 160.0)
const TAVERN_RECT := Rect2(1180.0, 380.0, 200.0, 160.0)
const RESIDENTIAL_RECT := Rect2(650.0, 560.0, 350.0, 200.0)
const VILLAGE_RECT := Rect2(580.0, 120.0, 950.0, 680.0)
const FOREST_BOUNDARY_X := 560.0

func _assert(condition: bool, message: String) -> void:
	if not condition:
		printerr("ASSERTION FAILED: " + message)
		quit(1)
		# Force stop execution
		assert(condition, message)

func _init() -> void:
	print("Running VillageAmbientClusteringTest...")
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	root.add_child(world)

	_assert(world.has_method("update_ambient_clustering_for_hour"), "World must have update_ambient_clustering_for_hour method")
	_assert(world.has_method("get_ambient_clustering_info"), "World must have get_ambient_clustering_info method")

	var ambient_count = world.get_ambient_npc_count()
	_assert(ambient_count == 32, "Expected 32 ambient NPCs, got %d" % ambient_count)

	var hours_to_test = [
		{"hour": 9, "name": "market", "rect": MARKET_RECT},
		{"hour": 13, "name": "plaza", "rect": PLAZA_RECT},
		{"hour": 18, "name": "tavern", "rect": TAVERN_RECT},
		{"hour": 22, "name": "residential", "rect": RESIDENTIAL_RECT},
		{"hour": 6, "name": "residential", "rect": RESIDENTIAL_RECT},
	]

	for test_case in hours_to_test:
		var hour: int = test_case["hour"]
		var expected_name: String = test_case["name"]
		var target_rect: Rect2 = test_case["rect"]

		world.update_ambient_clustering_for_hour(hour)
		var info: Dictionary = world.get_ambient_clustering_info()

		_assert(info.has("current_cluster_name"), "Info must contain current_cluster_name")
		_assert(info["current_cluster_name"] == expected_name, "Hour %d expected cluster %s, got %s" % [hour, expected_name, info.get("current_cluster_name", "")])
		_assert(info.has("clustered_npcs"), "Info must contain clustered_npcs")
		_assert(info.has("free_wanderers"), "Info must contain free_wanderers")

		var clustered_npcs: Array = info["clustered_npcs"]
		var free_wanderers: Array = info["free_wanderers"]

		_assert(clustered_npcs.size() == 24, "Expected exactly 24 clustered NPCs, got %d" % clustered_npcs.size())
		_assert(free_wanderers.size() == 8, "Expected exactly 8 free wanderers, got %d" % free_wanderers.size())

		# Check clustered NPCs are inside the designated cluster rectangle
		for npc in clustered_npcs:
			_assert(target_rect.has_point(npc.global_position), "Clustered NPC %s at %s must be inside %s rect %s" % [npc.npc_id, str(npc.global_position), expected_name, str(target_rect)])
			var mz: Rect2 = npc._movement_zone
			_assert(mz.position.x >= FOREST_BOUNDARY_X, "NPC %s movement_zone x (%f) must be >= %f" % [npc.npc_id, mz.position.x, FOREST_BOUNDARY_X])
			_assert(target_rect.encloses(mz), "NPC %s movement_zone %s must be enclosed in %s" % [npc.npc_id, str(mz), str(target_rect)])

		# Check free wanderers are within village bounds
		for npc in free_wanderers:
			_assert(npc.global_position.x >= FOREST_BOUNDARY_X, "Free wanderer %s x (%f) must be >= %f" % [npc.npc_id, npc.global_position.x, FOREST_BOUNDARY_X])
			_assert(VILLAGE_RECT.has_point(npc.global_position), "Free wanderer %s at %s must be inside village rect %s" % [npc.npc_id, str(npc.global_position), str(VILLAGE_RECT)])
			var mz: Rect2 = npc._movement_zone
			_assert(mz.position.x >= FOREST_BOUNDARY_X, "Free wanderer %s movement_zone x must be >= %f" % [npc.npc_id, FOREST_BOUNDARY_X])

		# HARD CONSTRAINT: Check ALL 32 ambient NPCs stay strictly x >= 560.0
		for npc in world._ambient_npcs:
			_assert(npc.global_position.x >= FOREST_BOUNDARY_X, "NPC %s global_position.x (%f) strictly >= 560.0" % [npc.npc_id, npc.global_position.x])
			var mz: Rect2 = npc._movement_zone
			_assert(mz.position.x >= FOREST_BOUNDARY_X, "NPC %s movement_zone.position.x (%f) strictly >= 560.0" % [npc.npc_id, mz.position.x])

	# Test update_npc_positions_for_hour triggers ambient clustering as well
	world.update_npc_positions_for_hour(13)
	var midday_info: Dictionary = world.get_ambient_clustering_info()
	_assert(midday_info["current_cluster_name"] == "plaza", "update_npc_positions_for_hour must update ambient clustering to plaza at 13")

	world.free()
	print("VillageAmbientClusteringTest passed.")
	quit(0)
