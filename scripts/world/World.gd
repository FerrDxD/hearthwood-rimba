extends Node2D
class_name HearthwoodWorld

const TILE_SIZE: int = 16
const WORLD_SIZE: Vector2i = Vector2i(1600, 880)
const FOREST_END_X: float = 560.0
const BED_POSITION: Vector2 = Vector2(1320.0, 476.0)
const BED_INTERACTION_RADIUS: float = 76.0
const NPC_SCENE: PackedScene = preload("res://scenes/NPC.tscn")
const SHOP_NPC_SCENE: PackedScene = preload("res://scenes/ShopNPC.tscn")
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
]

var _ground: TileMapLayer
var _random := RandomNumberGenerator.new()
var _tree_positions: Array[Vector2] = []
var _named_npcs: Array[HearthwoodNPC] = []
var _ambient_npcs: Array[HearthwoodNPC] = []
var _building_rects: Array[Rect2] = [
	Rect2(970.0, 246.0, 92.0, 72.0),
	Rect2(1102.0, 246.0, 92.0, 72.0),
	Rect2(1268.0, 380.0, 104.0, 76.0),
]


func _ready() -> void:
	_random.seed = 713
	_ground = TileMapLayer.new()
	_ground.name = "ground"
	_ground.z_index = -1
	add_child(_ground)
	_create_tileset()
	_paint_ground()
	_place_trees()
	_add_building_collisions()
	_spawn_named_npcs()
	_spawn_ambient_npcs()
	queue_redraw()


func is_near_bed(player_position: Vector2) -> bool:
	return player_position.distance_to(BED_POSITION) <= BED_INTERACTION_RADIUS


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


func get_named_npc_count() -> int:
	return _named_npcs.size()


func get_ambient_npc_count() -> int:
	return _ambient_npcs.size()


func _create_tileset() -> void:
	var image := Image.create(80, TILE_SIZE, false, Image.FORMAT_RGBA8)
	var base_colors: Array[Color] = [
		Color("#597c45"),
		Color("#64894b"),
		Color("#9a7950"),
		Color("#b19a70"),
		Color("#527b82"),
	]
	for tile_index in base_colors.size():
		for y in TILE_SIZE:
			for x in TILE_SIZE:
				var color := base_colors[tile_index]
				if (x + y * 3 + tile_index) % 11 == 0:
					color = color.lightened(0.11)
				elif (x * 2 + y + tile_index) % 13 == 0:
					color = color.darkened(0.09)
				image.set_pixel(tile_index * TILE_SIZE + x, y, color)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = ImageTexture.create_from_image(image)
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for tile_index in base_colors.size():
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
		var path_center := 432.0 + sin(tree_position.x / 16.0 * 0.085) * 32.0
		if absf(tree_position.y - path_center) < 82.0:
			continue
		_tree_positions.append(tree_position)
		_add_obstacle(Rect2(tree_position.x - 7.0, tree_position.y - 2.0, 14.0, 16.0))


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


func _spawn_ambient_npcs() -> void:
	for index in 32:
		var spawn_position: Vector2
		if index < 12:
			spawn_position = Vector2(
				_random.randf_range(92.0, FOREST_END_X - 24.0),
				_random.randf_range(120.0, WORLD_SIZE.y - 100.0)
			)
		else:
			spawn_position = Vector2(
				_random.randf_range(820.0, 1500.0),
				_random.randf_range(350.0, 650.0)
			)
		var zone_size := Vector2(72.0, 52.0)
		var movement_zone := Rect2(spawn_position - zone_size * 0.5, zone_size)
		var npc := NPC_SCENE.instantiate() as HearthwoodNPC
		npc.configure_ambient(index, spawn_position, movement_zone)
		add_child(npc)
		_ambient_npcs.append(npc)


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

	for building in _building_rects:
		_draw_building(building)

	draw_rect(Rect2(1310.0, 465.0, 20.0, 8.0), Color("#d4b481"))
	draw_rect(Rect2(1312.0, 467.0, 16.0, 3.0), Color("#76513a"))


func _draw_building(building: Rect2) -> void:
	draw_rect(
		Rect2(building.position.x - 7.0, building.position.y - 16.0, building.size.x + 14.0, 30.0),
		Color("#76513a")
	)
	draw_rect(
		Rect2(building.position.x, building.position.y, building.size.x, building.size.y),
		Color("#d2b48c")
	)
	draw_rect(
		Rect2(building.position.x - 7.0, building.position.y - 18.0, building.size.x + 14.0, 13.0),
		Color("#8b5a3c")
	)
	draw_rect(
		Rect2(building.position.x + building.size.x * 0.5 - 8.0, building.end.y - 25.0, 16.0, 25.0),
		Color("#654321")
	)
