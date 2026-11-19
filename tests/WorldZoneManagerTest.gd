extends SceneTree

var signal_received: bool = false
var signaled_id: String = ""
var signaled_name: String = ""

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	var world = world_scene.instantiate()
	assert(world.has_method("get_zone_rect"), "World must implement get_zone_rect")
	assert(world.has_method("change_zone"), "World must implement change_zone")
	assert(world.has_method("get_zone_name"), "World must implement get_zone_name")
	assert(world.has_method("get_zone_for_position"), "World must implement get_zone_for_position")
	
	# Verify all 6 forest zones and village exist
	var expected_zones = ["village", "forest_zone_1", "forest_zone_2", "forest_zone_3", "forest_zone_4", "forest_zone_5", "forest_zone_6"]
	for zid in expected_zones:
		var rect: Rect2 = world.get_zone_rect(zid)
		assert(rect.size.x > 0 and rect.size.y > 0, "Zone " + zid + " must have valid rect size")
		assert(world.get_zone_name(zid) != "", "Zone " + zid + " must have a non-empty display name")
	
	# Verify village rect preserves existing world bounds and positions
	var village_rect: Rect2 = world.get_zone_rect("village")
	assert(village_rect.has_point(world.BED_POSITION), "Village rect must contain bed position")
	assert(village_rect.has_point(world.COOKING_STATION_POSITION), "Village rect must contain cooking station")
	
	# Verify Great Tree position is within forest_zone_6
	var f6_rect: Rect2 = world.get_zone_rect("forest_zone_6")
	assert(f6_rect.has_point(world.GREAT_TREE_POSITION), "forest_zone_6 must contain Great Tree position")
	
	# Test changing zone directly
	signal_received = false
	signaled_id = ""
	signaled_name = ""
	world.zone_changed.connect(func(zid, zname):
		signal_received = true
		signaled_id = zid
		signaled_name = zname
	)
	
	world.change_zone("forest_zone_1", Vector2(100.0, 1000.0), false)
	assert(world.current_zone_id == "forest_zone_1", "current_zone_id must update to forest_zone_1")
	assert(signal_received, "zone_changed signal must be emitted")
	assert(signaled_id == "forest_zone_1", "Emitted zone_id must match")
	assert(signaled_name == "Pintu Rimba", "Emitted zone_name must match Pintu Rimba")
	
	# Verify zone gates exist between key connections
	assert(world.get_zone_gate("forest_zone_1", "village") != null, "Gate W1->Village must exist")
	assert(world.get_zone_gate("village", "forest_zone_1") != null, "Gate Village->W1 must exist")
	assert(world.get_zone_gate("forest_zone_1", "forest_zone_3") != null, "Gate W1->W3 must exist")
	assert(world.get_zone_gate("forest_zone_3", "forest_zone_6") != null, "Gate W3->W6 must exist")
	
	world.free()
	print("WorldZoneManagerTest passed.")
	quit(0)
