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
	{"spawn_id": "sayur_liar_1", "id": "sayur_liar", "position": Vector2(104.0, 1178.0)},
	{"spawn_id": "daun_hutan_1", "id": "daun_hutan", "position": Vector2(420.0, 1120.0)},
	{"spawn_id": "ikan_sungai_1", "id": "ikan_sungai", "position": Vector2(-280.0, 1200.0)},
	{"spawn_id": "batu_1", "id": "batu", "position": Vector2(-150.0, 1050.0)},
	{"spawn_id": "kayu_1", "id": "kayu", "position": Vector2(160.0, 680.0)},
	{"spawn_id": "sayur_liar_2", "id": "sayur_liar", "position": Vector2(380.0, 720.0)},
	{"spawn_id": "jamur_hutan_1", "id": "jamur_hutan", "position": Vector2(750.0, -250.0)},
	{"spawn_id": "buah_liar_1", "id": "buah_liar", "position": Vector2(850.0, -320.0)},
	{"spawn_id": "daun_hutan_2", "id": "daun_hutan", "position": Vector2(680.0, -180.0)},
	{"spawn_id": "akar_rempah_1", "id": "akar_rempah", "position": Vector2(-320.0, 680.0)},
	{"spawn_id": "jamur_hutan_2", "id": "jamur_hutan", "position": Vector2(-180.0, 750.0)},
	{"spawn_id": "buah_liar_2", "id": "buah_liar", "position": Vector2(350.0, 220.0)},
]
const RAIN_FORAGE_SPAWN: Dictionary = {
	"spawn_id": "hujan_jamur_1",
	"id": "jamur_hutan",
	"position": Vector2(900.0, -200.0),
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
signal gate_blocked_attempted(gate: ZoneGate2D, dialog_key: String)

const DEFAULT_BLOCKED_DIALOGS: Dictionary = {
	"fallen_tree_blocked": "Batang pohon besar tumbang menutup jalan kembali ke pohon raksasa itu... Jalurnya buntu.",
	"fallen_tree_barrier": "Batang pohon besar tumbang menutup jalan kembali ke pohon raksasa itu... Jalurnya buntu.",
}

var current_zone_id: String = "village"
var _zone_gates: Array[ZoneGate2D] = []
var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false
var _game_state: Node = null:
	set(value):
		if _game_state != null and _game_state.has_signal("deep_forest_unlocked_changed"):
			if _game_state.deep_forest_unlocked_changed.is_connected(_on_deep_forest_unlocked_changed):
				_game_state.deep_forest_unlocked_changed.disconnect(_on_deep_forest_unlocked_changed)
		_game_state = value
		if _game_state != null and _game_state.has_signal("deep_forest_unlocked_changed"):
			if not _game_state.deep_forest_unlocked_changed.is_connected(_on_deep_forest_unlocked_changed):
				_game_state.deep_forest_unlocked_changed.connect(_on_deep_forest_unlocked_changed)
		_update_fallen_tree_barriers()
var _ground: TileMapLayer
var _random := RandomNumberGenerator.new()
var _tree_positions: Array[Vector2] = []
var _named_npcs: Array[HearthwoodNPC] = []
var _ambient_npcs: Array[HearthwoodNPC] = []
var _item_pickups: Array[HearthwoodItemPickup] = []
var _landmarks: Dictionary = {}
var _obstacle_rects: Array[Rect2] = []
var _building_rects: Array[Rect2] = [
	Rect2(970.0, 246.0, 92.0, 72.0),
	Rect2(1102.0, 246.0, 92.0, 72.0),
	Rect2(1268.0, 380.0, 104.0, 76.0),
]


func _init() -> void:
	_random.seed = 713
	_load_forest_zones_data()
	if _zone_gates.is_empty():
		_setup_zones_and_gates()
	_update_fallen_tree_barriers()
	if _obstacle_rects.is_empty():
		_build_forest_landmarks()
		_place_zone_trees()
		_add_building_collisions()
	if _named_npcs.is_empty():
		_spawn_named_npcs()
	if _ambient_npcs.is_empty():
		_spawn_ambient_npcs()


func _ready() -> void:
	_random.seed = 713
	_setup_fade_layer()
	if _landmarks.is_empty():
		_load_forest_zones_data()
	if _zone_gates.is_empty():
		_setup_zones_and_gates()
	if _game_state == null and has_node("/root/GameState"):
		self._game_state = get_node("/root/GameState")
	else:
		_update_fallen_tree_barriers()
	_ground = TileMapLayer.new()
	_ground.name = "ground"
	_ground.z_index = -1
	add_child(_ground)
	_create_tileset()
	_paint_ground()
	if _obstacle_rects.is_empty():
		_build_forest_landmarks()
		_place_zone_trees()
		_add_building_collisions()
	if _named_npcs.is_empty():
		_spawn_named_npcs()
	if _ambient_npcs.is_empty():
		_spawn_ambient_npcs()
	_spawn_forage_items()
	if has_node("/root/TimeSystem"):
		get_node("/root/TimeSystem").day_changed.connect(_on_day_changed)
	if has_node("/root/GameState"):
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
	_create_gate("forest_zone_1", "forest_zone_4", Vector2(500.0, 970.0), Vector2(840.0, -40.0), Vector2(64.0, 16.0))
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
	gate.blocked_attempted.connect(_on_gate_blocked_attempted)
	_zone_gates.append(gate)
	add_child(gate)
	return gate


func _on_gate_blocked_attempted(gate: ZoneGate2D, dialog_key: String) -> void:
	gate_blocked_attempted.emit(gate, dialog_key)
	_show_blocked_feedback(dialog_key)


func _get_is_deep_forest_unlocked() -> bool:
	if _game_state != null and "is_deep_forest_unlocked" in _game_state:
		return bool(_game_state.is_deep_forest_unlocked)
	if is_inside_tree() and has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if "is_deep_forest_unlocked" in gs:
			return bool(gs.is_deep_forest_unlocked)
	return false


func _on_deep_forest_unlocked_changed(_unlocked: bool) -> void:
	_update_fallen_tree_barriers()


func _update_fallen_tree_barriers() -> void:
	var unlocked: bool = _get_is_deep_forest_unlocked()
	var barrier_pairs = [
		["forest_zone_3", "forest_zone_6"],
		["forest_zone_3", "forest_zone_5"],
		["forest_zone_2", "forest_zone_5"],
	]
	for pair in barrier_pairs:
		var gate := get_zone_gate(pair[0], pair[1])
		if gate != null:
			gate.is_blocked = not unlocked
			gate.blocked_dialog_key = "fallen_tree_blocked"


func get_blocked_dialog_text(dialog_key: String) -> String:
	if FileAccess.file_exists("res://data/dialogs/barriers.json"):
		var f := FileAccess.open("res://data/dialogs/barriers.json", FileAccess.READ)
		if f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY and parsed.has(dialog_key):
				return str(parsed[dialog_key])
	return DEFAULT_BLOCKED_DIALOGS.get(dialog_key, "Jalan ini terhalang rintangan.")


func _show_blocked_feedback(dialog_key: String) -> void:
	var text := get_blocked_dialog_text(dialog_key)
	if not is_inside_tree():
		return
	var main = get_parent()
	if main != null:
		var dui = main.get_node_or_null("DialogUI")
		if dui != null and dui.has_method("open_dialog"):
			dui.open_dialog("", "", text)
			return
		if "_dialog_ui" in main and main._dialog_ui != null:
			main._dialog_ui.open_dialog("", "", text)
			return
	var root_dui = get_tree().root.find_child("DialogUI", true, false)
	if root_dui != null and root_dui.has_method("open_dialog"):
		root_dui.open_dialog("", "", text)


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


func _load_forest_zones_data() -> void:
	if not _landmarks.is_empty():
		return
	var path := "res://data/world/forest_zones.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for zid in parsed:
					var zdict: Dictionary = parsed[zid]
					_landmarks[zid] = zdict.get("landmarks", [])
				return
	_landmarks = {
		"forest_zone_1": [
			{"id": "wooden_boundary_arch", "name": "Gapura Kayu Perbatasan", "type": "boundary_arch", "position": [520.0, 1200.0], "size": [32.0, 64.0]},
			{"id": "gravel_pathways", "name": "Jalan Setapak Kerikil", "type": "pathway", "position": [280.0, 1200.0], "size": [160.0, 24.0]},
			{"id": "forest_signpost_z1", "name": "Papan Penunjuk Arah Rimba", "type": "signpost", "position": [460.0, 1170.0], "size": [24.0, 24.0]},
		],
		"forest_zone_2": [
			{"id": "rocky_riverbed", "name": "Aliran Sungai Bebatuan", "type": "river", "position": [-280.0, 1200.0], "size": [320.0, 72.0]},
			{"id": "stepping_stones_crossing", "name": "Batu Loncatan Sungai", "type": "stepping_stones", "position": [-280.0, 1200.0], "size": [64.0, 48.0]},
			{"id": "weathered_wood_bridge", "name": "Jembatan Kayu Lapuk", "type": "bridge", "position": [-140.0, 1200.0], "size": [48.0, 32.0]},
			{"id": "wet_sand_bank", "name": "Tepian Pasir Basah", "type": "sand_bank", "position": [-420.0, 1260.0], "size": [96.0, 48.0]},
		],
		"forest_zone_3": [
			{"id": "rast_canvas_camp", "name": "Tenda Kanvas Rast", "type": "camp_tent", "position": [200.0, 620.0], "size": [64.0, 48.0]},
			{"id": "warm_stone_campfire", "name": "Perapian Batu Hangat", "type": "campfire", "position": [260.0, 640.0], "size": [24.0, 24.0]},
			{"id": "timber_log_pile", "name": "Tumpukan Kayu Gelondongan", "type": "log_pile", "position": [140.0, 720.0], "size": [64.0, 36.0]},
			{"id": "ancient_woodcutter_stump", "name": "Tunggul Penebang Tua", "type": "woodcutter_stump", "position": [340.0, 650.0], "size": [32.0, 32.0]},
		],
		"forest_zone_4": [
			{"id": "mossy_marsh_pond", "name": "Rawa Kecil Berlumut", "type": "marsh_pond", "position": [780.0, -220.0], "size": [112.0, 64.0]},
			{"id": "dense_canopy_thicket", "name": "Rerimbunan Semak Lembab", "type": "canopy_thicket", "position": [920.0, -340.0], "size": [128.0, 96.0]},
			{"id": "abundant_berry_grove", "name": "Gerombolan Pohon Beri Rimba", "type": "berry_grove", "position": [860.0, -280.0], "size": [48.0, 48.0]},
		],
		"forest_zone_5": [
			{"id": "ancient_root_archways", "name": "Lorong Lengkung Akar Purba", "type": "root_archway", "position": [-260.0, 670.0], "size": [96.0, 72.0]},
			{"id": "mossy_fossil_boulder", "name": "Fosil Batu Lumut Purba", "type": "fossil_boulder", "position": [-420.0, 720.0], "size": [64.0, 54.0]},
			{"id": "ancient_root_cleft", "name": "Celah Berongga Akar Purba", "type": "root_cleft", "position": [-310.0, 600.0], "size": [36.0, 36.0]},
		],
		"forest_zone_6": [
			{"id": "great_sanctuary_tree", "name": "Pohon Raksasa Purba", "type": "great_tree", "position": [210.0, 260.0], "size": [112.0, 128.0]},
			{"id": "ancient_inscribed_altar", "name": "Altar Batu Bertulis Misterius", "type": "altar", "position": [300.0, 310.0], "size": [48.0, 32.0]},
			{"id": "sanctuary_lantern_pedestal", "name": "Lentera Pilar Suaka", "type": "lantern_pedestal", "position": [140.0, 310.0], "size": [24.0, 24.0]},
		],
	}


func get_zone_landmarks(zone_id: String) -> Array:
	return _landmarks.get(zone_id, [])


func get_all_landmarks() -> Dictionary:
	return _landmarks


func get_zone_gates() -> Array[ZoneGate2D]:
	return _zone_gates


func get_obstacle_rects() -> Array[Rect2]:
	return _obstacle_rects


func _build_forest_landmarks() -> void:
	# Zona 1: Gapura pillars (leaving wide central walkway open) & wooden signpost
	_add_obstacle(Rect2(500.0, 1120.0, 14.0, 24.0))
	_add_obstacle(Rect2(500.0, 1256.0, 14.0, 24.0))
	_add_obstacle(Rect2(456.0, 1166.0, 8.0, 8.0))

	# Zona 2: River boulders (leaving stepping stones and bridge open)
	_add_obstacle(Rect2(-360.0, 1160.0, 24.0, 20.0))
	_add_obstacle(Rect2(-190.0, 1220.0, 24.0, 20.0))

	# Zona 3: Rast's camp tent, firepit, log pile, woodcutter stump
	_add_obstacle(Rect2(174.0, 604.0, 52.0, 32.0))
	_add_obstacle(Rect2(253.0, 633.0, 14.0, 14.0))
	_add_obstacle(Rect2(116.0, 706.0, 48.0, 26.0))
	_add_obstacle(Rect2(330.0, 640.0, 20.0, 20.0))

	# Zona 4: Marsh pond & dense canopy thicket cores
	_add_obstacle(Rect2(744.0, -236.0, 72.0, 32.0))
	_add_obstacle(Rect2(876.0, -366.0, 88.0, 52.0))

	# Zona 5: Ancient root arch pillars, fossil boulder, root cleft
	_add_obstacle(Rect2(-300.0, 654.0, 18.0, 32.0))
	_add_obstacle(Rect2(-238.0, 654.0, 18.0, 32.0))
	_add_obstacle(Rect2(-442.0, 702.0, 44.0, 36.0))
	_add_obstacle(Rect2(-322.0, 588.0, 24.0, 24.0))

	# Zona 6: Great tree southern trunk, sanctuary tree upper trunk, altar, lantern pedestal
	_add_obstacle(Rect2(GREAT_TREE_POSITION.x - 9.0, GREAT_TREE_POSITION.y - 5.0, 18.0, 26.0))
	_add_obstacle(Rect2(200.0, 248.0, 20.0, 24.0))
	_add_obstacle(Rect2(282.0, 298.0, 36.0, 24.0))
	_add_obstacle(Rect2(134.0, 304.0, 12.0, 14.0))


func _place_zone_trees() -> void:
	var candidate_positions: Array[Vector2] = [
		# Zona 1: Border trees framing path
		Vector2(60.0, 1040.0),
		Vector2(140.0, 1020.0),
		Vector2(230.0, 1050.0),
		Vector2(380.0, 1040.0),
		Vector2(70.0, 1340.0),
		Vector2(150.0, 1360.0),
		Vector2(320.0, 1350.0),
		Vector2(450.0, 1340.0),
		# Zona 2: Riverbank outer trees
		Vector2(-480.0, 1030.0),
		Vector2(-390.0, 1040.0),
		Vector2(-80.0, 1040.0),
		Vector2(-490.0, 1360.0),
		Vector2(-200.0, 1370.0),
		Vector2(-80.0, 1360.0),
		# Zona 3: Woodcutter grove trees
		Vector2(60.0, 540.0),
		Vector2(160.0, 530.0),
		Vector2(420.0, 540.0),
		Vector2(480.0, 720.0),
		Vector2(70.0, 860.0),
		Vector2(440.0, 860.0),
		# Zona 4: Dense wet thicket trees
		Vector2(630.0, -410.0),
		Vector2(730.0, -420.0),
		Vector2(620.0, -120.0),
		Vector2(770.0, -90.0),
		Vector2(1000.0, -420.0),
		Vector2(1050.0, -150.0),
		# Zona 5: Ancient valley trees
		Vector2(-490.0, 540.0),
		Vector2(-140.0, 540.0),
		Vector2(-490.0, 850.0),
		Vector2(-120.0, 840.0),
		Vector2(-370.0, 870.0),
		# Zona 6: Sacred grove trees
		Vector2(80.0, 90.0),
		Vector2(210.0, 80.0),
		Vector2(350.0, 90.0),
		Vector2(480.0, 90.0),
		Vector2(80.0, 380.0),
		Vector2(450.0, 220.0),
		Vector2(450.0, 380.0),
	]

	for pos in candidate_positions:
		var tree_obs := Rect2(pos.x - 7.0, pos.y - 2.0, 14.0, 16.0)
		if _is_tree_position_valid(pos, tree_obs):
			_tree_positions.append(pos)
			_add_obstacle(tree_obs)


func _is_tree_position_valid(tree_pos: Vector2, tree_obs: Rect2) -> bool:
	var veg_rect := Rect2(104.0 - 24.0, 1178.0 - 24.0, 48.0, 48.0)
	if tree_obs.intersects(veg_rect):
		return false
	if tree_pos.distance_to(Vector2(210.0, 462.0)) < 40.0:
		return false
	if tree_pos.distance_to(GREAT_TREE_POSITION) < 55.0:
		return false
	if tree_pos.distance_to(Vector2(210.0, 260.0)) < 55.0:
		return false
	for gate in _zone_gates:
		var col: CollisionShape2D = null
		for c in gate.get_children():
			if c is CollisionShape2D:
				col = c
				break
		if col != null and col.shape is RectangleShape2D:
			var g_rect: Rect2 = Rect2(gate.position - col.shape.size * 0.5 - Vector2(24.0, 24.0), col.shape.size + Vector2(48.0, 48.0))
			if tree_obs.intersects(g_rect):
				return false
		if tree_pos.distance_to(gate.target_spawn_position) < 40.0:
			return false
	for f in FORAGE_SPAWN_POINTS:
		if tree_pos.distance_to(f["position"]) < 28.0:
			return false
	if tree_pos.distance_to(RAIN_FORAGE_SPAWN["position"]) < 28.0:
		return false
	for obs in _obstacle_rects:
		if tree_obs.intersects(obs.grow(8.0)):
			return false
	for existing in _tree_positions:
		if tree_pos.distance_to(existing) < 28.0:
			return false
	return true


func _place_trees() -> void:
	_place_zone_trees()


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
	_obstacle_rects.append(rect)
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	_draw_zone_1_landmarks()
	_draw_zone_2_landmarks()
	_draw_zone_3_landmarks()
	_draw_zone_4_landmarks()
	_draw_zone_5_landmarks()
	_draw_zone_6_landmarks()
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


func _draw_zone_1_landmarks() -> void:
	# Gravel trail
	draw_rect(Rect2(80.0, 1188.0, 440.0, 24.0), Color("#705335"))
	draw_rect(Rect2(90.0, 1192.0, 420.0, 16.0), Color("#8b7355"))
	draw_rect(Rect2(120.0, 1195.0, 360.0, 10.0), Color("#a89f91"))
	for offset_x in [140.0, 200.0, 270.0, 330.0, 400.0, 470.0]:
		draw_circle(Vector2(offset_x, 1198.0), 3.0, Color("#c2b280"))
		draw_circle(Vector2(offset_x + 25.0, 1204.0), 2.0, Color("#695843"))

	# Wooden boundary arch at (520, 1200)
	# North Pillar: stone foot + wood post + iron strap
	draw_rect(Rect2(498.0, 1140.0, 18.0, 6.0), Color("#6b736e"))
	draw_rect(Rect2(500.0, 1120.0, 14.0, 20.0), Color("#5a3d28"))
	draw_rect(Rect2(500.0, 1124.0, 14.0, 3.0), Color("#333333"))

	# South Pillar: stone foot + wood post + iron strap
	draw_rect(Rect2(498.0, 1254.0, 18.0, 6.0), Color("#6b736e"))
	draw_rect(Rect2(500.0, 1260.0, 14.0, 20.0), Color("#5a3d28"))
	draw_rect(Rect2(500.0, 1272.0, 14.0, 3.0), Color("#333333"))

	# Overhead crossbeam and lintel
	draw_line(Vector2(507.0, 1120.0), Vector2(507.0, 1280.0), Color("#76513a"), 8.0)
	draw_line(Vector2(507.0, 1122.0), Vector2(507.0, 1278.0), Color("#8b5a3c"), 4.0)
	draw_rect(Rect2(503.0, 1192.0, 8.0, 16.0), Color("#d2b48c"))

	# Forest signpost at (460, 1170)
	draw_rect(Rect2(458.0, 1162.0, 4.0, 16.0), Color("#5a3d28"))
	draw_rect(Rect2(462.0, 1164.0, 14.0, 5.0), Color("#d2b48c"))
	draw_rect(Rect2(446.0, 1170.0, 14.0, 5.0), Color("#cba77b"))


func _draw_zone_2_landmarks() -> void:
	# River bed, banks, and water ribbon
	draw_rect(Rect2(-560.0, 1162.0, 560.0, 76.0), Color("#695843"))
	draw_rect(Rect2(-560.0, 1166.0, 560.0, 68.0), Color("#b5a274"))
	draw_rect(Rect2(-560.0, 1172.0, 560.0, 56.0), Color("#588b9c"))
	draw_rect(Rect2(-560.0, 1184.0, 560.0, 32.0), Color("#3d6674"))

	# River ripples & foam
	for rx in [-500.0, -420.0, -340.0, -220.0, -100.0]:
		draw_line(Vector2(rx, 1192.0), Vector2(rx + 36.0, 1192.0), Color("#85b4c4"), 2.0)
		draw_line(Vector2(rx + 15.0, 1204.0), Vector2(rx + 45.0, 1204.0), Color("#c6e2ed"), 1.5)

	# Wet sand bank at (-420, 1260)
	draw_circle(Vector2(-420.0, 1235.0), 28.0, Color("#c2b280"))
	draw_circle(Vector2(-415.0, 1238.0), 18.0, Color("#b5a274"))
	draw_circle(Vector2(-430.0, 1230.0), 8.0, Color("#5b8a54"))

	# Stepping stones crossing at (-280, 1200)
	draw_circle(Vector2(-280.0, 1180.0), 8.0, Color("#7d8c82"))
	draw_circle(Vector2(-281.0, 1179.0), 5.0, Color("#a6b5ab"))
	draw_circle(Vector2(-276.0, 1194.0), 9.0, Color("#6e7d73"))
	draw_circle(Vector2(-277.0, 1193.0), 6.0, Color("#96a59b"))
	draw_circle(Vector2(-282.0, 1208.0), 8.5, Color("#7d8c82"))
	draw_circle(Vector2(-283.0, 1207.0), 5.0, Color("#a6b5ab"))
	draw_circle(Vector2(-278.0, 1220.0), 8.0, Color("#6e7d73"))
	draw_circle(Vector2(-279.0, 1219.0), 5.0, Color("#96a59b"))

	# Weathered wooden bridge at (-140, 1200)
	draw_rect(Rect2(-146.0, 1170.0, 6.0, 60.0), Color("#4a2e1b"))
	draw_rect(Rect2(-120.0, 1170.0, 6.0, 60.0), Color("#4a2e1b"))
	draw_rect(Rect2(-152.0, 1172.0, 38.0, 56.0), Color("#6e4b30"))
	for by in range(1174, 1226, 6):
		draw_line(Vector2(-152.0, float(by)), Vector2(-114.0, float(by)), Color("#4a2e1b"), 1.0)
	draw_rect(Rect2(-152.0, 1172.0, 4.0, 56.0), Color("#b8860b"))
	draw_rect(Rect2(-118.0, 1172.0, 4.0, 56.0), Color("#b8860b"))

	# River boulders
	draw_circle(Vector2(-348.0, 1170.0), 12.0, Color("#5a665d"))
	draw_circle(Vector2(-350.0, 1168.0), 7.0, Color("#7d8c82"))
	draw_circle(Vector2(-178.0, 1230.0), 11.0, Color("#5a665d"))
	draw_circle(Vector2(-180.0, 1228.0), 6.0, Color("#7d8c82"))


func _draw_zone_3_landmarks() -> void:
	# Rast's canvas camp tent at (200, 620)
	draw_rect(Rect2(170.0, 614.0, 60.0, 24.0), Color("#d4af37"))
	var tent_pts: PackedVector2Array = [
		Vector2(174.0, 636.0),
		Vector2(200.0, 604.0),
		Vector2(226.0, 636.0)
	]
	draw_colored_polygon(tent_pts, Color("#e5d2ad"))
	var fold_pts: PackedVector2Array = [
		Vector2(174.0, 636.0),
		Vector2(200.0, 604.0),
		Vector2(200.0, 636.0)
	]
	draw_colored_polygon(fold_pts, Color("#c8b48c"))
	draw_line(Vector2(200.0, 604.0), Vector2(200.0, 636.0), Color("#76513a"), 2.0)
	draw_rect(Rect2(195.0, 620.0, 10.0, 16.0), Color("#3a2312"))

	# Campfire at (260, 640)
	for i in 8:
		var angle := float(i) * PI / 4.0
		var stone_pos := Vector2(260.0 + cos(angle) * 11.0, 640.0 + sin(angle) * 11.0)
		draw_circle(stone_pos, 3.5, Color("#696969"))
	draw_circle(Vector2(260.0, 640.0), 8.0, Color("#3a2312"))
	draw_circle(Vector2(260.0, 640.0), 5.0, Color("#d35400"))
	draw_circle(Vector2(260.0, 639.0), 2.5, Color("#f39c12"))

	# Timber log pile at (140, 720)
	draw_rect(Rect2(116.0, 712.0, 48.0, 10.0), Color("#5a3d28"))
	draw_circle(Vector2(116.0, 717.0), 5.0, Color("#c29b62"))
	draw_circle(Vector2(116.0, 717.0), 2.0, Color("#8b5a2b"))
	draw_rect(Rect2(120.0, 722.0, 44.0, 10.0), Color("#76513a"))
	draw_circle(Vector2(120.0, 727.0), 5.0, Color("#c29b62"))
	draw_circle(Vector2(120.0, 727.0), 2.0, Color("#8b5a2b"))
	draw_rect(Rect2(124.0, 706.0, 40.0, 9.0), Color("#5a3d28"))
	draw_circle(Vector2(124.0, 710.0), 4.5, Color("#c29b62"))
	draw_circle(Vector2(124.0, 710.0), 2.0, Color("#8b5a2b"))

	# Ancient woodcutter stump at (340, 650)
	draw_circle(Vector2(340.0, 650.0), 12.0, Color("#654321"))
	draw_circle(Vector2(340.0, 650.0), 9.0, Color("#8b6239"))
	draw_circle(Vector2(340.0, 650.0), 4.0, Color("#5a3825"))
	draw_rect(Rect2(338.0, 646.0, 5.0, 6.0), Color("#708090"))
	draw_line(Vector2(339.0, 646.0), Vector2(346.0, 638.0), Color("#8b4513"), 2.0)


func _draw_zone_4_landmarks() -> void:
	# Mossy marsh pond at (780, -220)
	draw_circle(Vector2(780.0, -220.0), 42.0, Color("#263824"))
	draw_circle(Vector2(780.0, -220.0), 34.0, Color("#3b5738"))
	draw_circle(Vector2(778.0, -220.0), 22.0, Color("#2d482a"))
	# Lily pads
	draw_circle(Vector2(765.0, -230.0), 6.0, Color("#557a46"))
	draw_circle(Vector2(795.0, -215.0), 7.0, Color("#557a46"))
	draw_circle(Vector2(775.0, -208.0), 5.0, Color("#557a46"))
	draw_circle(Vector2(790.0, -232.0), 4.0, Color("#75934f"))
	# Cattails
	draw_line(Vector2(746.0, -210.0), Vector2(746.0, -230.0), Color("#5a3d28"), 2.0)
	draw_rect(Rect2(744.0, -228.0, 4.0, 10.0), Color("#3a2312"))
	draw_line(Vector2(812.0, -215.0), Vector2(812.0, -235.0), Color("#5a3d28"), 2.0)
	draw_rect(Rect2(810.0, -233.0, 4.0, 10.0), Color("#3a2312"))

	# Dense canopy thicket at (920, -340)
	draw_circle(Vector2(920.0, -340.0), 48.0, Color("#1e3f20"))
	draw_circle(Vector2(905.0, -350.0), 38.0, Color("#294d35"))
	draw_circle(Vector2(935.0, -330.0), 36.0, Color("#3d6e3f"))
	draw_circle(Vector2(918.0, -335.0), 28.0, Color("#4e7943"))
	draw_circle(Vector2(912.0, -340.0), 16.0, Color("#75934f"))

	# Abundant berry grove at (860, -280)
	draw_circle(Vector2(860.0, -280.0), 20.0, Color("#27ae60"))
	draw_circle(Vector2(852.0, -284.0), 14.0, Color("#2ecc71"))
	for b_off in [Vector2(-8.0, -6.0), Vector2(6.0, -10.0), Vector2(4.0, 4.0), Vector2(-6.0, 6.0), Vector2(10.0, -2.0)]:
		draw_circle(Vector2(860.0, -280.0) + b_off, 2.5, Color("#e74c3c"))


func _draw_zone_5_landmarks() -> void:
	# Ancient root archways at (-260, 670)
	# Left root pillar
	draw_rect(Rect2(-298.0, 654.0, 16.0, 32.0), Color("#4a2e1b"))
	draw_rect(Rect2(-296.0, 656.0, 12.0, 28.0), Color("#382013"))
	# Right root pillar
	draw_rect(Rect2(-236.0, 654.0, 16.0, 32.0), Color("#4a2e1b"))
	draw_rect(Rect2(-234.0, 656.0, 12.0, 28.0), Color("#382013"))
	# Overhead arch curve
	draw_line(Vector2(-290.0, 656.0), Vector2(-260.0, 636.0), Color("#5a3d28"), 8.0)
	draw_line(Vector2(-260.0, 636.0), Vector2(-230.0, 656.0), Color("#5a3d28"), 8.0)
	draw_line(Vector2(-290.0, 658.0), Vector2(-260.0, 638.0), Color("#4a2e1b"), 4.0)
	draw_line(Vector2(-260.0, 638.0), Vector2(-230.0, 658.0), Color("#4a2e1b"), 4.0)
	# Hanging moss strands
	draw_line(Vector2(-275.0, 642.0), Vector2(-275.0, 655.0), Color("#556b2f"), 2.0)
	draw_line(Vector2(-248.0, 644.0), Vector2(-248.0, 658.0), Color("#6b8e23"), 2.0)

	# Mossy fossil boulder at (-420, 720)
	draw_rect(Rect2(-442.0, 702.0, 44.0, 36.0), Color("#3f523d"))
	draw_rect(Rect2(-438.0, 705.0, 36.0, 28.0), Color("#4e654c"))
	draw_circle(Vector2(-420.0, 719.0), 8.0, Color("#7d8c7c"))
	draw_circle(Vector2(-420.0, 719.0), 5.0, Color("#4e654c"))
	draw_circle(Vector2(-420.0, 719.0), 2.0, Color("#7d8c7c"))
	draw_rect(Rect2(-444.0, 699.0, 48.0, 6.0), Color("#5b8a54"))

	# Ancient root cleft at (-310, 600)
	draw_circle(Vector2(-310.0, 600.0), 16.0, Color("#4a2e1b"))
	draw_circle(Vector2(-310.0, 600.0), 9.0, Color("#1c1008"))
	draw_circle(Vector2(-312.0, 599.0), 2.0, Color("#cd853f"))


func _draw_zone_6_landmarks() -> void:
	# Enhanced Sanctuary Great Tree upper canopy & trunk at (210, 260)
	draw_rect(Rect2(198.0, 240.0, 24.0, 60.0), Color("#3e2615"))
	draw_line(Vector2(204.0, 242.0), Vector2(204.0, 298.0), Color("#8a9a86"), 1.5)
	draw_line(Vector2(216.0, 244.0), Vector2(216.0, 296.0), Color("#5a3d28"), 2.0)
	# Sprawling buttress roots
	draw_line(Vector2(198.0, 290.0), Vector2(174.0, 316.0), Color("#4a2e1b"), 6.0)
	draw_line(Vector2(222.0, 290.0), Vector2(246.0, 316.0), Color("#4a2e1b"), 6.0)
	# Massive sacred canopy crown
	draw_circle(Vector2(210.0, 220.0), 52.0, Color("#1e3f20"))
	draw_circle(Vector2(182.0, 235.0), 38.0, Color("#294d35"))
	draw_circle(Vector2(238.0, 235.0), 38.0, Color("#294d35"))
	draw_circle(Vector2(210.0, 208.0), 36.0, Color("#4e7943"))
	draw_circle(Vector2(198.0, 202.0), 18.0, Color("#75934f"))

	# Ancient inscribed stone altar at (300, 310)
	draw_rect(Rect2(280.0, 314.0, 40.0, 8.0), Color("#404743"))
	draw_rect(Rect2(284.0, 300.0, 32.0, 16.0), Color("#525b56"))
	draw_rect(Rect2(282.0, 298.0, 36.0, 6.0), Color("#6b736e"))
	# Glowing ancient glyph carvings
	draw_line(Vector2(290.0, 308.0), Vector2(300.0, 308.0), Color("#cd853f"), 2.0)
	draw_line(Vector2(295.0, 304.0), Vector2(295.0, 312.0), Color("#ffd26b"), 2.0)
	draw_line(Vector2(304.0, 305.0), Vector2(310.0, 311.0), Color("#cd853f"), 1.5)

	# Sanctuary lantern pedestal at (140, 310)
	draw_rect(Rect2(136.0, 306.0, 8.0, 14.0), Color("#6b736e"))
	draw_rect(Rect2(134.0, 298.0, 12.0, 10.0), Color("#2a2a2a"))
	draw_circle(Vector2(140.0, 303.0), 8.0, Color(1.0, 0.82, 0.42, 0.25))
	draw_circle(Vector2(140.0, 303.0), 4.0, Color("#ffd26b"))
	draw_circle(Vector2(140.0, 303.0), 2.0, Color("#ffffff"))


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
