# tests/ForestLandmarksTest.gd
extends SceneTree

const FOREST_VEGETABLE_POSITION: Vector2 = Vector2(104.0, 1178.0)
const PLAYER_START_POSITION: Vector2 = Vector2(210.0, 462.0)
const EXPECTED_ZONE_IDS: Array[String] = [
	"forest_zone_1",
	"forest_zone_2",
	"forest_zone_3",
	"forest_zone_4",
	"forest_zone_5",
	"forest_zone_6",
]

func _init() -> void:
	var world_scene = load("res://scenes/tilemap/MainTileset.tscn")
	assert(world_scene != null, "MainTileset.tscn must exist")
	var world = world_scene.instantiate()
	assert(world != null, "World instance must be created")

	# Test 1: Helper method get_zone_landmarks must exist
	assert(world.has_method("get_zone_landmarks"), "World must implement get_zone_landmarks(zone_id)")
	assert(world.has_method("get_obstacle_rects"), "World must implement get_obstacle_rects()")

	# Test 2: Verify each of the 6 forest zones has landmarks initialized
	for zid in EXPECTED_ZONE_IDS:
		var landmarks: Array = world.get_zone_landmarks(zid)
		assert(not landmarks.is_empty(), "Zone %s must have landmarks initialized" % zid)
		var zone_rect: Rect2 = world.get_zone_rect(zid)
		assert(zone_rect.size.x > 0 and zone_rect.size.y > 0, "Zone rect for %s must be valid" % zid)

		for lm in landmarks:
			assert(lm.has("id"), "Landmark in %s must have id" % zid)
			assert(lm.has("name"), "Landmark in %s must have name" % zid)
			assert(lm.has("type"), "Landmark in %s must have type" % zid)
			assert(lm.has("position"), "Landmark in %s must have position" % zid)
			var pos: Vector2
			if typeof(lm["position"]) == TYPE_VECTOR2:
				pos = lm["position"]
			elif typeof(lm["position"]) == TYPE_ARRAY:
				pos = Vector2(float(lm["position"][0]), float(lm["position"][1]))
			else:
				assert(false, "Invalid position format for landmark %s" % lm["id"])
			assert(zone_rect.has_point(pos), "Landmark %s position %s must be within %s rect %s" % [lm["id"], str(pos), zid, str(zone_rect)])

	# Test 3: Specific landmark presence per zone
	# Zone 1: Boundary arch, gravel path, signpost
	var z1_types: Array = _get_landmark_types(world.get_zone_landmarks("forest_zone_1"))
	assert(z1_types.has("boundary_arch"), "Zone 1 must have boundary_arch")
	assert(z1_types.has("pathway"), "Zone 1 must have pathway")
	assert(z1_types.has("signpost"), "Zone 1 must have signpost")

	# Zone 2: River, stepping stones, bridge, sand bank
	var z2_types: Array = _get_landmark_types(world.get_zone_landmarks("forest_zone_2"))
	assert(z2_types.has("river"), "Zone 2 must have river")
	assert(z2_types.has("stepping_stones"), "Zone 2 must have stepping_stones")
	assert(z2_types.has("bridge"), "Zone 2 must have bridge")

	# Zone 3: Camp tent, campfire, log pile, woodcutter stump
	var z3_types: Array = _get_landmark_types(world.get_zone_landmarks("forest_zone_3"))
	assert(z3_types.has("camp_tent"), "Zone 3 must have camp_tent")
	assert(z3_types.has("campfire"), "Zone 3 must have campfire")
	assert(z3_types.has("log_pile"), "Zone 3 must have log_pile")

	# Zone 4: Marsh pond, canopy thicket, berry grove
	var z4_types: Array = _get_landmark_types(world.get_zone_landmarks("forest_zone_4"))
	assert(z4_types.has("marsh_pond"), "Zone 4 must have marsh_pond")
	assert(z4_types.has("canopy_thicket"), "Zone 4 must have canopy_thicket")

	# Zone 5: Root archway, fossil boulder, root cleft
	var z5_types: Array = _get_landmark_types(world.get_zone_landmarks("forest_zone_5"))
	assert(z5_types.has("root_archway"), "Zone 5 must have root_archway")
	assert(z5_types.has("fossil_boulder"), "Zone 5 must have fossil_boulder")

	# Zone 6: Great sanctuary tree, altar, lantern pedestal
	var z6_types: Array = _get_landmark_types(world.get_zone_landmarks("forest_zone_6"))
	assert(z6_types.has("great_tree"), "Zone 6 must have great_tree")
	assert(z6_types.has("altar"), "Zone 6 must have altar")
	assert(z6_types.has("lantern_pedestal"), "Zone 6 must have lantern_pedestal")

	# Test 4: Verify that NO landmark obstacle collides with any ZoneGate2D collision shape or spawn pos
	var obstacles: Array[Rect2] = world.get_obstacle_rects()
	assert(not obstacles.is_empty(), "World obstacles must not be empty")

	var gates: Array[ZoneGate2D] = []
	if world.has_method("get_zone_gates"):
		gates = world.get_zone_gates()
	else:
		for child in world.get_children():
			if child is ZoneGate2D:
				gates.append(child)

	assert(not gates.is_empty(), "World must have ZoneGate2D instances")

	for gate in gates:
		var col_shape: CollisionShape2D = null
		for child in gate.get_children():
			if child is CollisionShape2D:
				col_shape = child
				break
		assert(col_shape != null and col_shape.shape is RectangleShape2D, "Gate must have RectangleShape2D")
		var rect_shape := col_shape.shape as RectangleShape2D
		var gate_rect := Rect2(gate.position - rect_shape.size * 0.5, rect_shape.size)

		for obs in obstacles:
			assert(not obs.intersects(gate_rect), "Obstacle %s collides with gate %s (gate rect %s)" % [str(obs), gate.name, str(gate_rect)])
			assert(not obs.has_point(gate.target_spawn_position), "Obstacle %s blocks gate target_spawn_position %s for gate %s" % [str(obs), str(gate.target_spawn_position), gate.name])

	# Test 5: Verify FOREST_VEGETABLE_POSITION (104.0, 1178.0) is not obstructed
	var veg_clearance: float = 16.0
	var veg_rect := Rect2(FOREST_VEGETABLE_POSITION - Vector2(veg_clearance, veg_clearance), Vector2(veg_clearance * 2.0, veg_clearance * 2.0))
	for obs in obstacles:
		assert(not obs.intersects(veg_rect), "Obstacle %s obstructs FOREST_VEGETABLE_POSITION %s" % [str(obs), str(FOREST_VEGETABLE_POSITION)])

	# Test 6: Verify player start position (210.0, 462.0) is not obstructed
	for obs in obstacles:
		assert(not obs.has_point(PLAYER_START_POSITION), "Obstacle %s obstructs player start position %s" % [str(obs), str(PLAYER_START_POSITION)])

	world.free()
	print("ForestLandmarksTest passed.")
	quit(0)


func _get_landmark_types(landmarks: Array) -> Array:
	var types: Array = []
	for lm in landmarks:
		if lm.has("type"):
			types.append(lm["type"])
	return types
