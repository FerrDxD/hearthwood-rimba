extends Node2D
class_name HearthwoodWorld

const TILE_SIZE: int = 16
const TILE_COUNT: int = 5
const WORLD_SIZE: Vector2i = Vector2i(1600, 880)
const FOREST_END_X: float = 560.0
const GREAT_TREE_POSITION: Vector2 = Vector2(210.0, 414.0)
const BED_POSITION: Vector2 = Vector2(1320.0, 476.0)
const BED_INTERACTION_RADIUS: float = 76.0
const COOKING_STATION_POSITION: Vector2 = Vector2(1210.0, 478.0)
const COOKING_STATION_INTERACTION_RADIUS: float = 64.0
const ZONE_RECTS: Dictionary = {
	"village": Rect2(560.0, 0.0, 1040.0, 880.0),
	"forest_zone_1": Rect2(0.0, 960.0, 560.0, 480.0),
	"forest_zone_2": Rect2(-560.0, 960.0, 560.0, 480.0),
	"forest_zone_3": Rect2(0.0, 480.0, 560.0, 480.0),
	"forest_zone_4": Rect2(560.0, -480.0, 560.0, 480.0),
	"forest_zone_5": Rect2(-560.0, 480.0, 560.0, 480.0),
	"forest_zone_6": Rect2(0.0, 0.0, 560.0, 480.0),
}
const ZONE_NAMES: Dictionary = {
	"village": "Desa Hearthwood",
	"forest_zone_1": "Pintu Rimba",
	"forest_zone_2": "Aliran Sungai Bebatuan",
	"forest_zone_3": "Pos Penebang Kayu",
	"forest_zone_4": "Semak Belukar Lembab",
	"forest_zone_5": "Lembah Akar Purba",
	"forest_zone_6": "Suaka Pohon Raksasa",
}
const VILLAGE_AMBIENT_RECT: Rect2 = Rect2(580.0, 120.0, 950.0, 680.0)
const TILESET_TEXTURE: Texture2D = preload("res://assets/sprites/tiles/main_tiles.png")
const NPC_SCENE: PackedScene = preload("res://scenes/NPC.tscn")
const SHOP_NPC_SCENE: PackedScene = preload("res://scenes/ShopNPC.tscn")
const ITEM_PICKUP_SCENE: PackedScene = preload("res://scenes/ItemPickup.tscn")
const FORAGE_SPAWN_POINTS: Array[Dictionary] = [
	{"spawn_id": "sayur_liar_1", "id": "sayur_liar", "position": Vector2(104.0, 218.0)},
	{"spawn_id": "sayur_liar_2", "id": "sayur_liar", "position": Vector2(360.0, 666.0)},
	{"spawn_id": "ikan_sungai_1", "id": "ikan_sungai", "position": Vector2(158.0, 720.0)},
	{"spawn_id": "daun_hutan_1", "id": "daun_hutan", "position": Vector2(478.0, 166.0)},
	{"spawn_id": "daun_hutan_2", "id": "daun_hutan", "position": Vector2(426.0, 738.0)},
	{"spawn_id": "buah_liar_1", "id": "buah_liar", "position": Vector2(290.0, 178.0)},
	{"spawn_id": "buah_liar_2", "id": "buah_liar", "position": Vector2(498.0, 590.0)},
	{"spawn_id": "akar_rempah_1", "id": "akar_rempah", "position": Vector2(184.0, 328.0)},
	{"spawn_id": "jamur_hutan_1", "id": "jamur_hutan", "position": Vector2(344.0, 272.0)},
	{"spawn_id": "jamur_hutan_2", "id": "jamur_hutan", "position": Vector2(254.0, 632.0)},
	{"spawn_id": "kayu_1", "id": "kayu", "position": Vector2(126.0, 574.0)},
	{"spawn_id": "batu_1", "id": "batu", "position": Vector2(398.0, 512.0)},
]
const RAIN_FORAGE_SPAWN: Dictionary = {
	"spawn_id": "hujan_jamur_1",
	"id": "jamur_hutan",
	"position": Vector2(300.0, 700.0),
}
const NAMED_NPC_IDS: Array[String] = [
	"giral",
	"talia",
	"casha",
	"vea",
	"nue",
	"jev",
	"gil",
	"rave",
	"kila",
	"rast",
	"veral",
	"arin",
	"budi",
	"siti",
	"pak_udin",
]

signal zone_changed(zone_id: String, zone_name: String)

var current_zone_id: String = "village"
var _zone_gates: Array[ZoneGate2D] = []
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false
var _game_state: Node = null
var _ground: TileMapLayer
var _random := RandomNumberGenerator.new()
var _tree_positions: Array[Vector2] = []
var _named_npcs: Array[HearthwoodNPC] = []
var _ambient_npcs: Array[HearthwoodNPC] = []
var _item_pickups: Array[HearthwoodItemPickup] = []
var _building_rects: Array[Rect2] = [
	Rect2(970.0, 246.0, 92.0, 72.0),
	Rect2(1102.0, 246.0, 92.0, 72.0),
	Rect2(1268.0, 380.0, 104.0, 76.0),
]


func _init() -> void:
	_random.seed = 713
	if _zone_gates.is_empty():
		_setup_zones_and_gates()
	if _named_npcs.is_empty():
		_spawn_named_npcs()
	if _ambient_npcs.is_empty():
		_spawn_ambient_npcs()


func _ready() -> void:
	_random.seed = 713
	_setup_fade_layer()
	if _zone_gates.is_empty():
		_setup_zones_and_gates()
	if _game_state == null and has_node("/root/GameState"):
		_game_state = get_node("/root/GameState")
	_update_fallen_tree_barriers()
	_ground = TileMapLayer.new()
	_ground.name = "ground"
	_ground.z_index = -1
	add_child(_ground)
	_create_tileset()
	_paint_ground()
	_place_trees()
	_add_building_collisions()
	if _named_npcs.is_empty():
		_spawn_named_npcs()
	if _ambient_npcs.is_empty():
		_spawn_ambient_npcs()
	_spawn_forage_items()
	get_node("/root/TimeSystem").day_changed.connect(_on_day_changed)
	get_node("/root/GameState").state_changed.connect(_on_state_changed)
	queue_redraw()


func get_zone_rect(zone_id: String) -> Rect2:
	return ZONE_RECTS.get(zone_id, Rect2())


func get_zone_name(zone_id: String) -> String:
	return ZONE_NAMES.get(zone_id, "")


func get_zone_for_position(pos: Vector2) -> String:
	for zid in ZONE_RECTS:
		var rect: Rect2 = ZONE_RECTS[zid]
		if rect.has_point(pos):
			return zid
	return ""


func get_zone_gate(source_zone_id: String, target_zone_id: String) -> ZoneGate2D:
	for gate in _zone_gates:
		if is_instance_valid(gate) and gate.source_zone_id == source_zone_id and gate.target_zone_id == target_zone_id:
			return gate
	return null


func change_zone(zone_id: String, target_pos: Vector2, animated: bool = true) -> void:
	if _is_transitioning:
		return
	if animated and is_inside_tree() and _fade_rect != null:
		_is_transitioning = true
		var tween := create_tween()
		tween.tween_property(_fade_rect, "modulate:a", 1.0, 0.2)
		tween.tween_callback(func():
			_apply_zone_change(zone_id, target_pos)
		)
		tween.tween_property(_fade_rect, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func():
			_is_transitioning = false
		)
	else:
		_apply_zone_change(zone_id, target_pos)


func _apply_zone_change(zone_id: String, target_pos: Vector2) -> void:
	current_zone_id = zone_id
	var player := _find_player()
	if is_instance_valid(player):
		player.global_position = target_pos
		var zone_rect := get_zone_rect(zone_id)
		if "world_bounds" in player:
			player.world_bounds = zone_rect
		var camera: Camera2D = player.get_node_or_null("camera2d")
		if camera == null:
			camera = player.get_node_or_null("Camera2D")
		if camera != null:
			camera.limit_left = int(zone_rect.position.x)
			camera.limit_top = int(zone_rect.position.y)
			camera.limit_right = int(zone_rect.end.x)
			camera.limit_bottom = int(zone_rect.end.y)
	zone_changed.emit(zone_id, get_zone_name(zone_id))


func _on_gate_triggered(target_zone_id: String, target_spawn_pos: Vector2) -> void:
	change_zone(target_zone_id, target_spawn_pos, true)


func _find_player() -> Node2D:
	if not is_inside_tree():
		return null
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0] as Node2D
	if get_parent() != null:
		var p := get_parent().get_node_or_null("Player") as Node2D
		if p != null:
			return p
	return get_tree().root.find_child("Player", true, false) as Node2D


func _setup_fade_layer() -> void:
	if _fade_layer != null:
		return
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)
	add_child(_fade_layer)


func _setup_zones_and_gates() -> void:
	if not _zone_gates.is_empty():
		return

	# Village <-> Forest Zone 1
	_create_gate("village", "forest_zone_1", Vector2(565.0, 440.0), Vector2(530.0, 1200.0), Vector2(16.0, 128.0))
	_create_gate("forest_zone_1", "village", Vector2(550.0, 1200.0), Vector2(590.0, 440.0), Vector2(16.0, 128.0))

	# Forest Zone 1 <-> Forest Zone 2
	_create_gate("forest_zone_1", "forest_zone_2", Vector2(10.0, 1200.0), Vector2(-30.0, 1200.0), Vector2(16.0, 128.0))
	_create_gate("forest_zone_2", "forest_zone_1", Vector2(-10.0, 1200.0), Vector2(30.0, 1200.0), Vector2(16.0, 128.0))

	# Forest Zone 1 <-> Forest Zone 3
	_create_gate("forest_zone_1", "forest_zone_3", Vector2(280.0, 970.0), Vector2(280.0, 930.0), Vector2(128.0, 16.0))
	_create_gate("forest_zone_3", "forest_zone_1", Vector2(280.0, 950.0), Vector2(280.0, 990.0), Vector2(128.0, 16.0))

	# Forest Zone 1 <-> Forest Zone 4
	_create_gate("forest_zone_1", "forest_zone_4", Vector2(500.0, 970.0), Vector2(840.0, -20.0), Vector2(64.0, 16.0))
	_create_gate("forest_zone_4", "forest_zone_1", Vector2(840.0, -10.0), Vector2(500.0, 1000.0), Vector2(64.0, 16.0))

	# Forest Zone 2 <-> Forest Zone 5
	_create_gate("forest_zone_2", "forest_zone_5", Vector2(-280.0, 970.0), Vector2(-280.0, 930.0), Vector2(128.0, 16.0))
	_create_gate("forest_zone_5", "forest_zone_2", Vector2(-280.0, 950.0), Vector2(-280.0, 990.0), Vector2(128.0, 16.0))

	# Forest Zone 3 <-> Forest Zone 5
	_create_gate("forest_zone_3", "forest_zone_5", Vector2(10.0, 720.0), Vector2(-30.0, 720.0), Vector2(16.0, 128.0))
	_create_gate("forest_zone_5", "forest_zone_3", Vector2(-10.0, 720.0), Vector2(30.0, 720.0), Vector2(16.0, 128.0))

	# Forest Zone 3 <-> Forest Zone 4
	_create_gate("forest_zone_3", "forest_zone_4", Vector2(550.0, 600.0), Vector2(600.0, -240.0), Vector2(16.0, 128.0))
	_create_gate("forest_zone_4", "forest_zone_3", Vector2(580.0, -240.0), Vector2(530.0, 600.0), Vector2(16.0, 128.0))

	# Forest Zone 3 <-> Forest Zone 6
	_create_gate("forest_zone_3", "forest_zone_6", Vector2(280.0, 490.0), Vector2(280.0, 450.0), Vector2(128.0, 16.0))
	_create_gate("forest_zone_6", "forest_zone_3", Vector2(280.0, 470.0), Vector2(280.0, 510.0), Vector2(128.0, 16.0))

	# Forest Zone 5 <-> Forest Zone 6
	_create_gate("forest_zone_5", "forest_zone_6", Vector2(-50.0, 490.0), Vector2(50.0, 450.0), Vector2(64.0, 16.0))
	_create_gate("forest_zone_6", "forest_zone_5", Vector2(50.0, 470.0), Vector2(-50.0, 510.0), Vector2(64.0, 16.0))


func _create_gate(
	source_id: String,
	target_id: String,
	gate_pos: Vector2,
	spawn_pos: Vector2,
	shape_size: Vector2 = Vector2(32.0, 32.0)
) -> ZoneGate2D:
	var gate := ZoneGate2D.new()
	gate.name = "Gate_%s_to_%s" % [source_id, target_id]
	gate.source_zone_id = source_id
	gate.target_zone_id = target_id
	gate.target_spawn_position = spawn_pos
	gate.position = gate_pos

	var col := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = shape_size
	col.shape = rect_shape
	gate.add_child(col)

	gate.gate_triggered.connect(_on_gate_triggered)
	_zone_gates.append(gate)
	add_child(gate)
	return gate


func _update_fallen_tree_barriers() -> void:
	var is_unlocked := false
	if _game_state != null and "is_deep_forest_unlocked" in _game_state:
		is_unlocked = _game_state.is_deep_forest_unlocked
	elif has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if "is_deep_forest_unlocked" in gs:
			is_unlocked = gs.is_deep_forest_unlocked

	for gate in _zone_gates:
		if gate.target_zone_id == "forest_zone_6" or gate.target_zone_id == "forest_zone_5":
			gate.is_blocked = not is_unlocked
			gate.blocked_dialog_key = "fallen_tree_barrier"


func is_near_bed(player_position: Vector2) -> bool:
	return player_position.distance_to(BED_POSITION) <= BED_INTERACTION_RADIUS


func is_near_cooking_station(player_position: Vector2) -> bool:
	return (
		player_position.distance_to(COOKING_STATION_POSITION)
		<= COOKING_STATION_INTERACTION_RADIUS
	)


func get_closest_named_npc(player_position: Vector2, radius: float) -> HearthwoodNPC:
	var closest: HearthwoodNPC
	var closest_distance := radius
	for npc in _named_npcs:
		if not npc.can_interact():
			continue
		var distance := player_position.distance_to(npc.global_position)
		if distance <= closest_distance:
			closest = npc
			closest_distance = distance
	return closest


func get_closest_item_pickup(
	player_position: Vector2, radius: float
) -> HearthwoodItemPickup:
	var closest: HearthwoodItemPickup
	var closest_distance := radius
	for pickup in _item_pickups:
		if not is_instance_valid(pickup) or not pickup.visible:
			continue
		var distance := player_position.distance_to(pickup.global_position)
		if distance <= closest_distance:
			closest = pickup
			closest_distance = distance
	return closest


func collect_item_pickup(pickup: HearthwoodItemPickup) -> bool:
	if not is_instance_valid(pickup) or not _item_pickups.has(pickup):
		return false
	if not pickup.collect():
		return false
	var game_state = get_node("/root/GameState")
	if (
		not pickup.spawn_id.is_empty()
		and not game_state.collected_forage_today.has(pickup.spawn_id)
	):
		game_state.collected_forage_today.append(pickup.spawn_id)
	_item_pickups.erase(pickup)
	pickup.queue_free()
	return true


func get_named_npc_count() -> int:
	return _named_npcs.size()


func get_named_npc(npc_id: String) -> HearthwoodNPC:
	for npc in _named_npcs:
		if is_instance_valid(npc) and npc.npc_id == npc_id:
			return npc
	return null


func _update_npc_positions_for_hour(hour: int) -> void:
	for npc in _named_npcs:
		if is_instance_valid(npc):
			if npc.has_method("refresh_schedule"):
				npc.refresh_schedule(hour, 0)
			elif npc.has_method("_refresh_schedule"):
				npc.call("_refresh_schedule", hour, 0)


func get_named_npc_name(npc_id: String) -> String:
	for npc in _named_npcs:
		if npc.npc_id == npc_id:
			return npc.get_display_name()
	return ""


func get_ambient_npc_count() -> int:
	return _ambient_npcs.size()


func _create_tileset() -> void:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TILESET_TEXTURE
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for tile_index in TILE_COUNT:
		atlas.create_tile(Vector2i(tile_index, 0))

	var terrain := TileSet.new()
	terrain.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	terrain.add_source(atlas, 0)
	_ground.tile_set = terrain


func _paint_ground() -> void:
	var columns := WORLD_SIZE.x / TILE_SIZE
	var rows := WORLD_SIZE.y / TILE_SIZE
	for y in rows:
		for x in columns:
			var tile_index := _random.randi_range(0, 1)
			var path_center := 27.0 + sin(float(x) * 0.085) * 2.0
			if x < 15 and y > 35:
				tile_index = 4
			elif x >= 61 and x <= 91 and (y >= 22 and y <= 33 or x <= 66):
				tile_index = 3
			elif x >= 18 and x <= 70 and absf(float(y) - path_center) <= 2.0:
				tile_index = 2
			_ground.set_cell(Vector2i(x, y), 0, Vector2i(tile_index, 0))


func _place_trees() -> void:
	for index in 32:
		var tree_position := Vector2(
			_random.randf_range(42.0, FOREST_END_X - 42.0),
			_random.randf_range(54.0, WORLD_SIZE.y - 54.0)
		)
		if tree_position.distance_to(GREAT_TREE_POSITION) < 70.0:
			continue
		var path_center := 432.0 + sin(tree_position.x / 16.0 * 0.085) * 32.0
		if absf(tree_position.y - path_center) < 82.0:
			continue
		_tree_positions.append(tree_position)
		_add_obstacle(Rect2(tree_position.x - 7.0, tree_position.y - 2.0, 14.0, 16.0))
	_add_obstacle(Rect2(
		GREAT_TREE_POSITION.x - 9.0,
		GREAT_TREE_POSITION.y - 5.0,
		18.0,
		26.0
	))


func _add_building_collisions() -> void:
	for building in _building_rects:
		_add_obstacle(Rect2(building.position.x, building.position.y + 20.0, building.size.x, 18.0))


func _spawn_named_npcs() -> void:
	var schedules := _load_schedule_data()
	for npc_id in NAMED_NPC_IDS:
		if not schedules.has(npc_id):
			push_error("Missing daily schedule for NPC: %s" % npc_id)
			continue
		var segments: Variant = schedules[npc_id]
		if typeof(segments) != TYPE_ARRAY:
			push_error("NPC schedule must be an array: %s" % npc_id)
			continue
		if not _validate_schedule_segments(npc_id, segments):
			continue
		var npc_scene: PackedScene = NPC_SCENE
		if npc_id == "giral" or npc_id == "talia":
			npc_scene = SHOP_NPC_SCENE
		var npc := npc_scene.instantiate() as HearthwoodNPC
		npc.configure_named(
			npc_id,
			"res://data/npcs/%s.json" % npc_id,
			segments
		)
		add_child(npc)
		_named_npcs.append(npc)
	_update_npc_positions_for_hour(6)


func _spawn_ambient_npcs() -> void:
	for index in 32:
		var spawn_position := Vector2(
			_random.randf_range(VILLAGE_AMBIENT_RECT.position.x, VILLAGE_AMBIENT_RECT.end.x),
			_random.randf_range(VILLAGE_AMBIENT_RECT.position.y, VILLAGE_AMBIENT_RECT.end.y)
		)
		var zone_size := Vector2(72.0, 52.0)
		var movement_zone := Rect2(spawn_position - zone_size * 0.5, zone_size)
		movement_zone.position.x = maxf(movement_zone.position.x, 560.0)
		var npc := NPC_SCENE.instantiate() as HearthwoodNPC
		npc.configure_ambient(index, spawn_position, movement_zone)
		add_child(npc)
		_ambient_npcs.append(npc)


func _spawn_forage_items() -> void:
	for pickup in _item_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_item_pickups.clear()

	var game_state = get_node("/root/GameState")
	var spawn_points: Array[Dictionary] = FORAGE_SPAWN_POINTS.duplicate()
	# Rain speeds up regrowth with one extra forage spot for the day.
	if game_state.is_raining():
		spawn_points.append(RAIN_FORAGE_SPAWN)
	for spawn_point in spawn_points:
		var spawn_id := str(spawn_point["spawn_id"])
		if game_state.collected_forage_today.has(spawn_id):
			continue
		var pickup := ITEM_PICKUP_SCENE.instantiate() as HearthwoodItemPickup
		pickup.configure(str(spawn_point["id"]), spawn_point["position"], spawn_id)
		add_child(pickup)
		_item_pickups.append(pickup)


func _on_day_changed(_day: int) -> void:
	_spawn_forage_items()


func _on_state_changed() -> void:
	queue_redraw()


func _validate_schedule_segments(npc_id: String, segments: Array) -> bool:
	if segments.is_empty():
		push_error("NPC schedule must contain at least one segment: %s" % npc_id)
		return false

	for segment in segments:
		if typeof(segment) != TYPE_DICTIONARY:
			push_error("NPC schedule segments must be objects: %s" % npc_id)
			return false
		for key in ["mulai", "selesai", "posisi", "zona"]:
			if not segment.has(key):
				push_error("NPC schedule is missing '%s': %s" % [key, npc_id])
				return false

		var start_type: int = typeof(segment["mulai"])
		var end_type: int = typeof(segment["selesai"])
		if (
			start_type != TYPE_INT
			and start_type != TYPE_FLOAT
			or end_type != TYPE_INT
			and end_type != TYPE_FLOAT
			or float(segment["mulai"]) >= float(segment["selesai"])
		):
			push_error("NPC schedule has an invalid time range: %s" % npc_id)
			return false

		if (
			typeof(segment["posisi"]) != TYPE_ARRAY
			or segment["posisi"].size() != 2
			or typeof(segment["zona"]) != TYPE_ARRAY
			or segment["zona"].size() != 2
			or float(segment["zona"][0]) <= 0.0
			or float(segment["zona"][1]) <= 0.0
		):
			push_error("NPC schedule has an invalid position or zone: %s" % npc_id)
			return false

	return true


func _load_schedule_data() -> Dictionary:
	var path := "res://data/schedules.json"
	if not FileAccess.file_exists(path):
		push_error("NPC schedule file not found: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not read NPC schedule file: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("NPC schedule must be a JSON object: %s" % path)
		return {}
	return parsed


func _add_obstacle(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	_draw_great_tree()
	for tree_position in _tree_positions:
		draw_rect(
			Rect2(tree_position.x - 5.0, tree_position.y - 3.0, 10.0, 21.0),
			Color("#76513a")
		)
		draw_rect(
			Rect2(tree_position.x - 17.0, tree_position.y - 25.0, 34.0, 27.0),
			Color("#294d35")
		)
		draw_rect(
			Rect2(tree_position.x - 12.0, tree_position.y - 31.0, 24.0, 15.0),
			Color("#4e7943")
		)
		draw_rect(
			Rect2(tree_position.x - 8.0, tree_position.y - 21.0, 8.0, 5.0),
			Color("#75934f")
		)

	for index in _building_rects.size():
		_draw_building(_building_rects[index], index == _building_rects.size() - 1)

	draw_line(
		COOKING_STATION_POSITION + Vector2(-14.0, 12.0),
		COOKING_STATION_POSITION + Vector2(14.0, 12.0),
		Color("#76513a"),
		5.0
	)
	draw_circle(COOKING_STATION_POSITION, 12.0, Color("#76513a"))
	draw_circle(COOKING_STATION_POSITION + Vector2(0.0, -2.0), 8.0, Color("#e38b49"))
	draw_circle(COOKING_STATION_POSITION + Vector2(0.0, -4.0), 4.0, Color("#ffd26b"))
	draw_rect(Rect2(1310.0, 465.0, 20.0, 8.0), Color("#d4b481"))
	draw_rect(Rect2(1312.0, 467.0, 16.0, 3.0), Color("#76513a"))


func _draw_great_tree() -> void:
	draw_rect(
		Rect2(GREAT_TREE_POSITION.x - 9.0, GREAT_TREE_POSITION.y - 4.0, 18.0, 29.0),
		Color("#654321")
	)
	draw_rect(
		Rect2(GREAT_TREE_POSITION.x - 34.0, GREAT_TREE_POSITION.y - 43.0, 68.0, 43.0),
		Color("#294d35")
	)
	draw_rect(
		Rect2(GREAT_TREE_POSITION.x - 24.0, GREAT_TREE_POSITION.y - 54.0, 48.0, 27.0),
		Color("#4e7943")
	)
	draw_rect(
		Rect2(GREAT_TREE_POSITION.x - 20.0, GREAT_TREE_POSITION.y - 37.0, 15.0, 7.0),
		Color("#75934f")
	)


func _draw_building(building: Rect2, is_warung: bool = false) -> void:
	var wall_color := Color("#d2b48c")
	if is_warung:
		match int(get_node("/root/GameState").warung_tier):
			1:
				wall_color = Color("#cba77b")
			2:
				wall_color = Color("#e0c99d")
			3:
				wall_color = Color("#f0dcae")
	draw_rect(
		Rect2(building.position.x - 7.0, building.position.y - 16.0, building.size.x + 14.0, 30.0),
		Color("#76513a")
	)
	draw_rect(
		Rect2(building.position.x, building.position.y, building.size.x, building.size.y),
		wall_color
	)
	draw_rect(
		Rect2(building.position.x - 7.0, building.position.y - 18.0, building.size.x + 14.0, 13.0),
		Color("#8b5a3c")
	)
	draw_rect(
		Rect2(building.position.x + building.size.x * 0.5 - 8.0, building.end.y - 25.0, 16.0, 25.0),
		Color("#654321")
	)
	if is_warung:
		var tier: int = get_node("/root/GameState").warung_tier
		draw_rect(
			Rect2(building.position.x + 8.0, building.position.y - 5.0, 20.0, 11.0),
			Color("#8fbc8f")
		)
		if tier >= 1:
			draw_rect(
				Rect2(building.position.x - 18.0, building.end.y - 7.0, 26.0, 6.0),
				Color("#76513a")
			)
			draw_rect(
				Rect2(building.end.x - 8.0, building.end.y - 7.0, 26.0, 6.0),
				Color("#76513a")
			)
		if tier >= 2:
			draw_rect(
				Rect2(building.position.x + 14.0, building.position.y + 18.0, 15.0, 15.0),
				Color("#87ceeb")
			)
			draw_rect(
				Rect2(building.end.x - 29.0, building.position.y + 18.0, 15.0, 15.0),
				Color("#87ceeb")
			)
		if tier >= 3:
			draw_rect(
				Rect2(building.position.x - 14.0, building.position.y - 24.0, 34.0, 8.0),
				Color("#b8860b")
			)
			draw_rect(
				Rect2(building.end.x - 20.0, building.position.y - 24.0, 34.0, 8.0),
				Color("#b8860b")
			)
