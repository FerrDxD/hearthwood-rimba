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
const AMBIENT_CLUSTER_MARKET: Rect2 = Rect2(920.0, 220.0, 260.0, 160.0)
const AMBIENT_CLUSTER_PLAZA: Rect2 = Rect2(1000.0, 380.0, 240.0, 160.0)
const AMBIENT_CLUSTER_TAVERN: Rect2 = Rect2(1180.0, 380.0, 200.0, 160.0)
const AMBIENT_CLUSTER_RESIDENTIAL: Rect2 = Rect2(650.0, 560.0, 350.0, 200.0)
const CLUSTERED_AMBIENT_NPC_COUNT: int = 24
const FREE_WANDERER_NPC_COUNT: int = 8
const FREE_WANDERER_ANCHORS: Array[Vector2] = [
	Vector2(620.0, 220.0),
	Vector2(780.0, 320.0),
	Vector2(680.0, 480.0),
	Vector2(880.0, 680.0),
	Vector2(1120.0, 180.0),
	Vector2(1380.0, 280.0),
	Vector2(1440.0, 600.0),
	Vector2(1260.0, 720.0),
]
const TILESET_TEXTURE: Texture2D = preload("res://assets/sprites/tiles/main_tiles.png")
const NPC_SCENE: PackedScene = preload("res://scenes/NPC.tscn")
const SHOP_NPC_SCENE: PackedScene = preload("res://scenes/ShopNPC.tscn")
const ITEM_PICKUP_SCENE: PackedScene = preload("res://scenes/ItemPickup.tscn")
const INTERACTIVE_PROP_SCRIPT: Script = preload("res://scripts/world/InteractiveProp.gd")
const FRUIT_TREE_SCRIPT: Script = preload("res://scripts/world/FruitTree.gd")
const FRESH_SPRING_SCRIPT: Script = preload("res://scripts/world/FreshSpring.gd")
const INSPECTABLE_HOLLOW_SCRIPT: Script = preload("res://scripts/world/InspectableHollow.gd")
const RUSTLING_BUSH_SCRIPT: Script = preload("res://scripts/world/RustlingBush.gd")
const VILLAGE_WELL_SCRIPT: Script = preload("res://scripts/world/VillageWell.gd")
const NOTICE_BOARD_SCRIPT: Script = preload("res://scripts/world/NoticeBoard.gd")
const WARUNG_TABLE_SCRIPT: Script = preload("res://scripts/world/WarungTable.gd")
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
		_sync_interactive_props_state()
var _ground: TileMapLayer
var _random := RandomNumberGenerator.new()
var _tree_positions: Array[Vector2] = []
var _named_npcs: Array[HearthwoodNPC] = []
var _ambient_npcs: Array[HearthwoodNPC] = []
var _item_pickups: Array[HearthwoodItemPickup] = []
var _interactive_props: Array[HearthwoodInteractiveProp] = []
var _rustling_bushes: Array[HearthwoodRustlingBush] = []
var _village_well: VILLAGE_WELL_SCRIPT = null
var _notice_board: NOTICE_BOARD_SCRIPT = null
var _warung_tables: Array = []
var _warung_bell: Node2D = null
var _ambient_particles: Dictionary = {}
var _zone_props: Dictionary = {}
var _landmarks: Dictionary = {}
var _village_data: Dictionary = {}
var _current_ambient_clustering_hour: int = 6
var _obstacle_rects: Array[Rect2] = []
var _building_rects: Array[Rect2] = [
	Rect2(1330.0, 240.0, 130.0, 84.0), # Town Hall
	Rect2(970.0, 246.0, 92.0, 72.0),   # Giral Store
	Rect2(1102.0, 246.0, 92.0, 72.0),  # Talia Store
	Rect2(1268.0, 380.0, 104.0, 76.0), # Warung Makan Pemain
	Rect2(680.0, 640.0, 100.0, 76.0),  # Lumbung Padi Komunal
	Rect2(820.0, 640.0, 76.0, 64.0),   # Cottage Casha
	Rect2(930.0, 640.0, 80.0, 64.0),   # Cottage Jev & Gil
	Rect2(1040.0, 640.0, 76.0, 64.0),  # Cottage Pak Udin
	Rect2(1150.0, 640.0, 76.0, 64.0),  # Cottage Budi
	Rect2(1260.0, 640.0, 76.0, 64.0),  # Cottage Siti
	Rect2(1370.0, 640.0, 76.0, 64.0),  # Cottage Arin
]


func _init() -> void:
	_random.seed = 713
	_load_forest_zones_data()
	_load_village_zones_data()
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
	_setup_interactive_props()
	if _ambient_particles.is_empty():
		_setup_ambient_particles()
	_setup_warung_dining()


func _ready() -> void:
	_random.seed = 713
	_setup_fade_layer()
	if _landmarks.is_empty() or _zone_props.is_empty():
		_load_forest_zones_data()
	if _village_data.is_empty():
		_load_village_zones_data()
	if _zone_gates.is_empty():
		_setup_zones_and_gates()
	if _game_state == null and has_node("/root/GameState"):
		self._game_state = get_node("/root/GameState")
	else:
		_update_fallen_tree_barriers()
		_sync_interactive_props_state()
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
	_setup_interactive_props()
	if _ambient_particles.is_empty():
		_setup_ambient_particles()
	_setup_warung_dining()
	if has_node("/root/TimeSystem"):
		var time_system: Node = get_node("/root/TimeSystem")
		time_system.day_changed.connect(_on_day_changed)
		if time_system.has_signal("hour_changed") and not time_system.hour_changed.is_connected(_on_hour_changed):
			time_system.hour_changed.connect(_on_hour_changed)
	if has_node("/root/GameState"):
		var game_state: Node = get_node("/root/GameState")
		game_state.state_changed.connect(_on_state_changed)
		if "current_hour" in game_state:
			_update_ambient_npc_clustering(int(game_state.current_hour))
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
	var game_state := _get_active_game_state()
	if (
		game_state != null
		and not pickup.spawn_id.is_empty()
		and "collected_forage_today" in game_state
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
	_update_ambient_npc_clustering(hour)


func update_npc_positions_for_hour(hour: int) -> void:
	_update_npc_positions_for_hour(hour)


func update_ambient_clustering_for_hour(hour: int) -> void:
	_update_ambient_npc_clustering(hour)


func get_ambient_cluster_name_for_hour(hour: int) -> String:
	if hour >= 8 and hour < 12:
		return "market"
	elif hour >= 12 and hour < 16:
		return "plaza"
	elif hour >= 16 and hour < 20:
		return "tavern"
	else:
		return "residential"


func get_ambient_cluster_rect_for_hour(hour: int) -> Rect2:
	match get_ambient_cluster_name_for_hour(hour):
		"market":
			return AMBIENT_CLUSTER_MARKET
		"plaza":
			return AMBIENT_CLUSTER_PLAZA
		"tavern":
			return AMBIENT_CLUSTER_TAVERN
		"residential":
			return AMBIENT_CLUSTER_RESIDENTIAL
		_:
			return AMBIENT_CLUSTER_RESIDENTIAL


func get_ambient_clustering_info() -> Dictionary:
	var cluster_rect := get_ambient_cluster_rect_for_hour(_current_ambient_clustering_hour)
	var cluster_name := get_ambient_cluster_name_for_hour(_current_ambient_clustering_hour)
	var clustered: Array[HearthwoodNPC] = []
	var wanderers: Array[HearthwoodNPC] = []
	for i in range(_ambient_npcs.size()):
		var npc := _ambient_npcs[i]
		if i < CLUSTERED_AMBIENT_NPC_COUNT:
			clustered.append(npc)
		else:
			wanderers.append(npc)
	return {
		"current_hour": _current_ambient_clustering_hour,
		"current_cluster_name": cluster_name,
		"current_cluster_rect": cluster_rect,
		"clustered_npcs": clustered,
		"free_wanderers": wanderers,
		"clustered_count": clustered.size(),
		"free_wanderer_count": wanderers.size(),
		"cluster_rects": {
			"market": AMBIENT_CLUSTER_MARKET,
			"plaza": AMBIENT_CLUSTER_PLAZA,
			"tavern": AMBIENT_CLUSTER_TAVERN,
			"residential": AMBIENT_CLUSTER_RESIDENTIAL,
		}
	}


func get_ambient_npcs() -> Array[HearthwoodNPC]:
	return _ambient_npcs


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
	if not _landmarks.is_empty() and not _zone_props.is_empty():
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
					_zone_props[zid] = zdict.get("props", [])
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
	_zone_props = {
		"forest_zone_1": [
			{"id": "fruit_tree_apel_hutan_z1", "name": "Pohon Buah Liar Rimba", "type": "fruit_tree", "position": [160.0, 1080.0], "drop_item_id": "buah_liar", "interaction_text": "Goyang Pohon Buah"},
			{"id": "rustling_bush_z1_a", "name": "Semak Belukar Rimbun A", "type": "rustling_bush", "position": [190.0, 1220.0]},
			{"id": "rustling_bush_z1_b", "name": "Semak Belukar Rimbun B", "type": "rustling_bush", "position": [360.0, 1150.0]},
			{"id": "signpost_pintu_rimba", "name": "Papan Penunjuk Arah", "type": "signpost", "position": [460.0, 1170.0], "interaction_text": "Membaca Papan Penunjuk Rimba"},
		],
		"forest_zone_2": [
			{"id": "fresh_spring_sungai_z2", "name": "Tepian Mata Air Alami", "type": "fresh_spring", "position": [-320.0, 1120.0], "energy_heal": 10, "interaction_text": "Basuh Muka di Mata Air"},
			{"id": "rustling_bush_z2_a", "name": "Semak Tepi Sungai A", "type": "rustling_bush", "position": [-220.0, 1080.0]},
			{"id": "rustling_bush_z2_b", "name": "Semak Tepi Sungai B", "type": "rustling_bush", "position": [-390.0, 1220.0]},
		],
		"forest_zone_3": [
			{"id": "inspectable_stump_z3", "name": "Tunggul Lapuk Berongga", "type": "inspectable_hollow", "position": [340.0, 650.0], "drop_item_id": "jamur_hutan", "interaction_text": "Periksa Celah Tunggul Kayu"},
			{"id": "rustling_bush_z3_a", "name": "Semak Pos Penebang A", "type": "rustling_bush", "position": [420.0, 680.0]},
			{"id": "rustling_bush_z3_b", "name": "Semak Pos Penebang B", "type": "rustling_bush", "position": [180.0, 800.0]},
		],
		"forest_zone_4": [
			{"id": "fruit_tree_beri_z4", "name": "Pohon Buah Beri Rimbun", "type": "fruit_tree", "position": [860.0, -280.0], "drop_item_id": "buah_liar", "interaction_text": "Goyang Pohon Buah Beri"},
			{"id": "rustling_bush_z4_a", "name": "Semak Lembab Rawa A", "type": "rustling_bush", "position": [720.0, -140.0]},
			{"id": "rustling_bush_z4_b", "name": "Semak Lembab Rawa B", "type": "rustling_bush", "position": [810.0, -360.0]},
			{"id": "rustling_bush_z4_c", "name": "Semak Lembab Rawa C", "type": "rustling_bush", "position": [970.0, -210.0]},
		],
		"forest_zone_5": [
			{"id": "inspectable_root_cleft_z5", "name": "Celah Akar Purba Berongga", "type": "inspectable_hollow", "position": [-310.0, 600.0], "drop_item_id": "akar_rempah", "interaction_text": "Periksa Celah Akar Purba"},
			{"id": "rustling_bush_z5_a", "name": "Semak Belukar Purba A", "type": "rustling_bush", "position": [-160.0, 640.0]},
			{"id": "rustling_bush_z5_b", "name": "Semak Belukar Purba B", "type": "rustling_bush", "position": [-380.0, 810.0]},
		],
		"forest_zone_6": [
			{"id": "altar_batu_suaka_z6", "name": "Altar Batu Bertulis Kuno", "type": "altar", "position": [300.0, 310.0], "interaction_text": "Membaca Pahatan Altar Batu"},
			{"id": "rustling_bush_z6_a", "name": "Semak Suaka Purba A", "type": "rustling_bush", "position": [390.0, 340.0]},
			{"id": "rustling_bush_z6_b", "name": "Semak Suaka Purba B", "type": "rustling_bush", "position": [120.0, 180.0]},
		],
	}


func _load_village_zones_data() -> void:
	if not _village_data.is_empty():
		return
	var path := "res://data/world/village_zones.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				_village_data = parsed
				return
	_village_data = {
		"districts": {
			"market_district": {"id": "market_district", "bounds": [850.0, 180.0, 350.0, 360.0]},
			"civic_district": {"id": "civic_district", "bounds": [1260.0, 180.0, 320.0, 220.0]},
			"tavern_district": {"id": "tavern_district", "bounds": [1150.0, 360.0, 380.0, 280.0]},
			"residential_district": {"id": "residential_district", "bounds": [600.0, 540.0, 850.0, 300.0]},
		},
		"buildings": {
			"town_hall": {"id": "town_hall", "position": [1330.0, 240.0], "size": [130.0, 84.0]},
			"giral_store": {"id": "giral_store", "position": [970.0, 246.0], "size": [92.0, 72.0]},
			"talia_store": {"id": "talia_store", "position": [1102.0, 246.0], "size": [92.0, 72.0]},
			"player_warung": {"id": "player_warung", "position": [1268.0, 380.0], "size": [104.0, 76.0]},
			"village_granary": {"id": "village_granary", "position": [680.0, 640.0], "size": [100.0, 76.0]},
			"residential_cottages": [
				{"id": "cottage_casha", "name": "Pondok Tenun Casha", "position": [820.0, 640.0], "size": [76.0, 64.0]},
				{"id": "cottage_jev_gil", "name": "Pondok Bersama Jev & Gil", "position": [930.0, 640.0], "size": [80.0, 64.0]},
				{"id": "cottage_pak_udin", "name": "Pondok Nelayan Pak Udin", "position": [1040.0, 640.0], "size": [76.0, 64.0]},
				{"id": "cottage_budi", "name": "Pondok Petani Budi", "position": [1150.0, 640.0], "size": [76.0, 64.0]},
				{"id": "cottage_siti", "name": "Pondok Peramu Siti", "position": [1260.0, 640.0], "size": [76.0, 64.0]},
				{"id": "cottage_arin", "name": "Pondok Pengrajin Arin", "position": [1370.0, 640.0], "size": [76.0, 64.0]},
			]
		},
		"props": {
			"village_well": {
				"id": "village_well",
				"name": "Sumur Desa Tua",
				"type": "village_well",
				"position": [1050.0, 460.0],
				"interaction_radius": 48.0,
				"energy_restore": 5,
				"give_item_id": "air_bersih"
			},
			"notice_board": {
				"id": "notice_board",
				"name": "Papan Pengumuman Desa",
				"type": "notice_board",
				"position": [1130.0, 460.0],
				"interaction_radius": 48.0
			}
		}
	}


func get_zone_landmarks(zone_id: String) -> Array:
	return _landmarks.get(zone_id, [])


func get_all_landmarks() -> Dictionary:
	return _landmarks


func get_village_buildings() -> Array[Dictionary]:
	if _village_data.is_empty():
		_load_village_zones_data()
	var list: Array[Dictionary] = []
	for b_id in ["town_hall", "giral_store", "talia_store", "player_warung", "village_granary", "residential_cottages"]:
		var b := get_village_building(b_id)
		if not b.is_empty():
			list.append(b)
	return list


func get_village_building(id: String) -> Dictionary:
	if _village_data.is_empty():
		_load_village_zones_data()
	if not _village_data.has("buildings"):
		return {}
	var b_dict: Dictionary = _village_data.get("buildings", {})
	if b_dict.has(id):
		var val = b_dict[id]
		if typeof(val) == TYPE_DICTIONARY:
			return val
		elif typeof(val) == TYPE_ARRAY and id == "residential_cottages":
			return {
				"id": "residential_cottages",
				"name": "Pondok Pemukiman Warga",
				"cottages": val
			}
	# Also allow querying individual cottage by id (e.g. cottage_casha)
	if b_dict.has("residential_cottages") and typeof(b_dict["residential_cottages"]) == TYPE_ARRAY:
		for c in b_dict["residential_cottages"]:
			if typeof(c) == TYPE_DICTIONARY and c.get("id") == id:
				return c
	return {}


func get_village_districts() -> Dictionary:
	if _village_data.is_empty():
		_load_village_zones_data()
	return _village_data.get("districts", {})


func get_zone_gates() -> Array[ZoneGate2D]:
	return _zone_gates


func get_obstacle_rects() -> Array[Rect2]:
	return _obstacle_rects


func get_interactive_props() -> Array[HearthwoodInteractiveProp]:
	return _interactive_props


func get_interactive_prop(id: String) -> HearthwoodInteractiveProp:
	for prop in _interactive_props:
		if is_instance_valid(prop) and prop.prop_id == id:
			return prop
	return null


func get_village_well() -> VILLAGE_WELL_SCRIPT:
	if _village_well == null:
		for prop in _interactive_props:
			if is_instance_valid(prop) and prop.prop_id == "village_well" and prop is VILLAGE_WELL_SCRIPT:
				_village_well = prop
				break
	if _village_well == null:
		_spawn_village_props()
	return _village_well


func get_notice_board() -> NOTICE_BOARD_SCRIPT:
	if _notice_board == null:
		for prop in _interactive_props:
			if is_instance_valid(prop) and prop.prop_id == "notice_board" and prop is NOTICE_BOARD_SCRIPT:
				_notice_board = prop
				break
	if _notice_board == null:
		_spawn_village_props()
	return _notice_board


func get_warung_tables() -> Array:
	if _warung_tables.is_empty():
		_setup_warung_dining()
	return _warung_tables


func get_warung_bell() -> Node2D:
	if _warung_bell == null:
		_setup_warung_dining()
	return _warung_bell


func get_rustling_bushes() -> Array[HearthwoodRustlingBush]:
	return _rustling_bushes


func get_closest_interactive_prop(pos: Vector2, radius: float = 64.0) -> HearthwoodInteractiveProp:
	var closest: HearthwoodInteractiveProp = null
	var closest_distance := radius
	for prop in _interactive_props:
		if not is_instance_valid(prop):
			continue
		var dist := pos.distance_to(prop.global_position)
		if dist <= closest_distance:
			closest = prop
			closest_distance = dist
	return closest


func interact_with_prop(prop: HearthwoodInteractiveProp, player: Node2D = null) -> Dictionary:
	if not is_instance_valid(prop):
		return {"success": false, "message": "Objek interaktif tidak valid."}
	var res := prop.interact(player)
	if res.get("success", false) and not prop.prop_id.is_empty():
		_mark_prop_in_game_state(prop.prop_id)
	return res


func _register_interactive_prop(prop: HearthwoodInteractiveProp) -> void:
	if not _interactive_props.has(prop):
		_interactive_props.append(prop)
	prop.interacted.connect(func(res: Dictionary): _on_prop_interacted(prop, res))
	_sync_interactive_prop_state(prop)


func _on_prop_interacted(prop: HearthwoodInteractiveProp, res: Dictionary = {}) -> void:
	if (res.is_empty() or res.get("success", false)) and is_instance_valid(prop) and not prop.prop_id.is_empty():
		_mark_prop_in_game_state(prop.prop_id)


func _mark_prop_in_game_state(prop_id: String) -> void:
	var gs := _get_active_game_state()
	if gs != null:
		if gs.has_method("mark_prop_interacted"):
			gs.mark_prop_interacted(prop_id)
		elif "interacted_props_today" in gs and not gs.interacted_props_today.has(prop_id):
			gs.interacted_props_today.append(prop_id)


func _get_active_game_state() -> Node:
	if _game_state != null:
		return _game_state
	if is_inside_tree() and has_node("/root/GameState"):
		return get_node("/root/GameState")
	return null


func _sync_interactive_props_state() -> void:
	for prop in _interactive_props:
		if is_instance_valid(prop):
			_sync_interactive_prop_state(prop)


func _sync_interactive_prop_state(prop: HearthwoodInteractiveProp) -> void:
	if not is_instance_valid(prop):
		return
	var gs := _get_active_game_state()
	if gs == null:
		return
	
	var is_interacted := false
	if gs.has_method("is_prop_interacted_today"):
		is_interacted = gs.is_prop_interacted_today(prop.prop_id)
	elif "interacted_props_today" in gs:
		is_interacted = gs.interacted_props_today.has(prop.prop_id)
	
	if is_interacted:
		prop.daily_interacted = true
		if "has_fruit" in prop:
			prop.has_fruit = false
	else:
		prop.daily_interacted = false
		if "has_fruit" in prop:
			prop.has_fruit = true


func get_ambient_particles() -> Dictionary:
	return _ambient_particles


func _setup_interactive_props() -> void:
	if _rustling_bushes.is_empty():
		_spawn_forest_props()
	_spawn_village_props()


func _setup_warung_dining() -> void:
	if not _warung_tables.is_empty() and _warung_bell != null:
		return

	if _warung_tables.is_empty():
		var table1 = WARUNG_TABLE_SCRIPT.new()
		table1.name = "WarungTable_1"
		table1.table_id = "warung_table_1"
		table1.position = Vector2(1150.0, 520.0)
		add_child(table1)
		_warung_tables.append(table1)

		var table2 = WARUNG_TABLE_SCRIPT.new()
		table2.name = "WarungTable_2"
		table2.table_id = "warung_table_2"
		table2.position = Vector2(1270.0, 520.0)
		add_child(table2)
		_warung_tables.append(table2)

	if _warung_bell == null:
		var bell := WarungBell.new()
		bell.name = "WarungBell"
		bell.position = Vector2(1170.0, 470.0)
		add_child(bell)
		_warung_bell = bell


func _spawn_village_props() -> void:
	if _village_well != null and _notice_board != null:
		return
	if _village_data.is_empty():
		_load_village_zones_data()

	var props_dict: Dictionary = _village_data.get("props", {})

	if _village_well == null:
		var well_data: Dictionary = props_dict.get("village_well", {})
		var well_pos := Vector2(1050.0, 460.0)
		if well_data.has("position"):
			var p = well_data["position"]
			if typeof(p) == TYPE_VECTOR2:
				well_pos = p
			elif typeof(p) == TYPE_ARRAY and p.size() >= 2:
				well_pos = Vector2(float(p[0]), float(p[1]))

		var well: VILLAGE_WELL_SCRIPT = VILLAGE_WELL_SCRIPT.new()
		well.name = "VillageWell"
		well.prop_id = str(well_data.get("id", "village_well"))
		well.position = well_pos
		well.interaction_radius = float(well_data.get("interaction_radius", 48.0))
		well.energy_restore = int(well_data.get("energy_restore", 5))
		if well_data.has("give_item_id"):
			well.water_item_id = str(well_data["give_item_id"])
		add_child(well)
		_village_well = well
		_register_interactive_prop(well)

	if _notice_board == null:
		var board_data: Dictionary = props_dict.get("notice_board", {})
		var board_pos := Vector2(1130.0, 460.0)
		if board_data.has("position"):
			var p = board_data["position"]
			if typeof(p) == TYPE_VECTOR2:
				board_pos = p
			elif typeof(p) == TYPE_ARRAY and p.size() >= 2:
				board_pos = Vector2(float(p[0]), float(p[1]))

		var board: NOTICE_BOARD_SCRIPT = NOTICE_BOARD_SCRIPT.new()
		board.name = "NoticeBoard"
		board.prop_id = str(board_data.get("id", "notice_board"))
		board.position = board_pos
		board.interaction_radius = float(board_data.get("interaction_radius", 48.0))
		add_child(board)
		_notice_board = board
		_register_interactive_prop(board)


func _spawn_forest_props() -> void:
	if not _rustling_bushes.is_empty():
		return
	if _zone_props.is_empty():
		_load_forest_zones_data()

	for zid in _zone_props:
		var props_list: Array = _zone_props[zid]
		for pdata in props_list:
			if typeof(pdata) != TYPE_DICTIONARY:
				continue
			var p_id: String = str(pdata.get("id", ""))
			var p_type: String = str(pdata.get("type", ""))
			var pos_val = pdata.get("position", [0.0, 0.0])
			var pos: Vector2
			if typeof(pos_val) == TYPE_VECTOR2:
				pos = pos_val
			elif typeof(pos_val) == TYPE_ARRAY and pos_val.size() >= 2:
				pos = Vector2(float(pos_val[0]), float(pos_val[1]))
			else:
				pos = Vector2.ZERO
			var prompt: String = str(pdata.get("interaction_text", "Periksa"))

			if p_type == "rustling_bush":
				var bush: HearthwoodRustlingBush = RUSTLING_BUSH_SCRIPT.new()
				bush.name = "Bush_%s" % p_id
				bush.bush_id = p_id
				bush.position = pos
				add_child(bush)
				_rustling_bushes.append(bush)
			elif p_type == "fruit_tree":
				var tree: HearthwoodFruitTree = FRUIT_TREE_SCRIPT.new()
				tree.name = "FruitTree_%s" % p_id
				tree.prop_id = p_id
				tree.position = pos
				tree.fruit_item_id = str(pdata.get("drop_item_id", "buah_liar"))
				tree.interaction_prompt = prompt
				add_child(tree)
				_register_interactive_prop(tree)
			elif p_type == "fresh_spring":
				var spring: HearthwoodFreshSpring = FRESH_SPRING_SCRIPT.new()
				spring.name = "FreshSpring_%s" % p_id
				spring.prop_id = p_id
				spring.position = pos
				spring.energy_restore = int(pdata.get("energy_heal", 10))
				spring.interaction_prompt = prompt
				add_child(spring)
				_register_interactive_prop(spring)
			elif p_type == "inspectable_hollow":
				var hollow: HearthwoodInspectableHollow = INSPECTABLE_HOLLOW_SCRIPT.new()
				hollow.name = "InspectableHollow_%s" % p_id
				hollow.prop_id = p_id
				hollow.position = pos
				hollow.hollow_name = str(pdata.get("name", "Ceruk Berongga"))
				if pdata.has("drop_item_id"):
					hollow.possible_loot = [str(pdata["drop_item_id"])]
				hollow.interaction_prompt = prompt
				add_child(hollow)
				_register_interactive_prop(hollow)
			else:
				var prop: HearthwoodInteractiveProp = INTERACTIVE_PROP_SCRIPT.new()
				prop.name = "Prop_%s" % p_id
				prop.prop_id = p_id
				prop.prop_type = p_type
				prop.position = pos
				prop.interaction_prompt = prompt
				add_child(prop)
				_register_interactive_prop(prop)


func _setup_ambient_particles() -> void:
	if not _ambient_particles.is_empty():
		return

	# Zone 4: Soft creeping ground mist
	var mist := CPUParticles2D.new()
	mist.name = "MistParticles_Zone4"
	mist.position = Vector2(840.0, -240.0)
	mist.amount = 32
	mist.lifetime = 6.0
	mist.preprocess = 3.0
	mist.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	mist.emission_rect_extents = Vector2(260.0, 220.0)
	mist.direction = Vector2(1.0, 0.2)
	mist.spread = 25.0
	mist.gravity = Vector2.ZERO
	mist.initial_velocity_min = 8.0
	mist.initial_velocity_max = 16.0
	mist.scale_amount_min = 6.0
	mist.scale_amount_max = 14.0
	mist.color = Color(0.85, 0.90, 0.85, 0.18)
	mist.z_index = 0
	add_child(mist)
	_ambient_particles["mist"] = mist

	# Zone 5: Ancient dim glowing spores
	var spores := CPUParticles2D.new()
	spores.name = "SporeParticles_Zone5"
	spores.position = Vector2(-280.0, 720.0)
	spores.amount = 28
	spores.lifetime = 5.0
	spores.preprocess = 2.5
	spores.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	spores.emission_rect_extents = Vector2(260.0, 220.0)
	spores.direction = Vector2(0.0, -1.0)
	spores.spread = 35.0
	spores.gravity = Vector2(0.0, -2.0)
	spores.initial_velocity_min = 6.0
	spores.initial_velocity_max = 14.0
	spores.scale_amount_min = 2.0
	spores.scale_amount_max = 4.0
	spores.color = Color(0.70, 0.85, 0.65, 0.40)
	spores.z_index = 0
	add_child(spores)
	_ambient_particles["spores"] = spores

	# Zone 6: Warm golden fireflies around the Great Tree
	var fireflies := CPUParticles2D.new()
	fireflies.name = "FireflyParticles_Zone6"
	fireflies.position = Vector2(210.0, 280.0)
	fireflies.amount = 22
	fireflies.lifetime = 4.0
	fireflies.preprocess = 2.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(160.0, 140.0)
	fireflies.direction = Vector2.ZERO
	fireflies.spread = 180.0
	fireflies.gravity = Vector2.ZERO
	fireflies.initial_velocity_min = 4.0
	fireflies.initial_velocity_max = 10.0
	fireflies.scale_amount_min = 2.0
	fireflies.scale_amount_max = 3.5
	fireflies.color = Color(0.96, 0.77, 0.35, 0.65)
	fireflies.z_index = 1
	add_child(fireflies)
	_ambient_particles["fireflies"] = fireflies


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
		var spawn_position := Vector2(700.0, 600.0)
		var zone_size := Vector2(36.0, 28.0)
		var movement_zone := Rect2(spawn_position - zone_size * 0.5, zone_size)
		movement_zone.position.x = maxf(movement_zone.position.x, 560.0)
		var npc := NPC_SCENE.instantiate() as HearthwoodNPC
		npc.configure_ambient(index, spawn_position, movement_zone)
		add_child(npc)
		_ambient_npcs.append(npc)
	_update_ambient_npc_clustering(_current_ambient_clustering_hour)


func _on_hour_changed(hour: int, _minute: int = 0) -> void:
	_update_ambient_npc_clustering(hour)


func _update_ambient_npc_clustering(hour: int) -> void:
	_current_ambient_clustering_hour = hour
	if _ambient_npcs.is_empty():
		return
	var cluster_rect := get_ambient_cluster_rect_for_hour(hour)
	var margin_x: float = 24.0
	var margin_y: float = 20.0
	var avail_w: float = cluster_rect.size.x - margin_x * 2.0
	var avail_h: float = cluster_rect.size.y - margin_y * 2.0

	for i in range(_ambient_npcs.size()):
		var npc := _ambient_npcs[i]
		if not is_instance_valid(npc):
			continue
		if i < CLUSTERED_AMBIENT_NPC_COUNT:
			var col: int = i % 6
			var row: int = i / 6
			var t_x: float = float(col) / 5.0
			var t_y: float = float(row) / 3.0
			var base_pos := cluster_rect.position + Vector2(margin_x + t_x * avail_w, margin_y + t_y * avail_h)
			var offset_x: float = (((i * 7 + hour * 3) % 11) - 5) * 1.5
			var offset_y: float = (((i * 13 + hour * 5) % 9) - 4) * 1.5
			var pos := base_pos + Vector2(offset_x, offset_y)
			var zone_size := Vector2(36.0, 28.0)
			var mz := Rect2(pos - zone_size * 0.5, zone_size)
			var min_x: float = maxf(cluster_rect.position.x, 560.0)
			var max_x: float = cluster_rect.end.x - mz.size.x
			if max_x < min_x:
				mz.size.x = cluster_rect.size.x
				mz.position.x = min_x
			else:
				mz.position.x = clampf(mz.position.x, min_x, max_x)
			var min_y: float = cluster_rect.position.y
			var max_y: float = cluster_rect.end.y - mz.size.y
			if max_y < min_y:
				mz.size.y = cluster_rect.size.y
				mz.position.y = min_y
			else:
				mz.position.y = clampf(mz.position.y, min_y, max_y)

			pos = mz.get_center()
			npc.position = pos
			npc.global_position = pos
			npc._movement_zone = mz
			npc.velocity = Vector2.ZERO
		else:
			# Free wanderers (remain in VILLAGE_AMBIENT_RECT with hard constraint x >= 560.0)
			var wanderer_idx: int = i - CLUSTERED_AMBIENT_NPC_COUNT
			var anchor: Vector2 = FREE_WANDERER_ANCHORS[wanderer_idx % FREE_WANDERER_ANCHORS.size()]
			var zone_size := Vector2(80.0, 60.0)
			var mz: Rect2 = npc._movement_zone
			if mz.size.is_zero_approx():
				mz = Rect2(anchor - zone_size * 0.5, zone_size)
			mz.position.x = maxf(mz.position.x, 560.0)
			mz.position.x = clampf(mz.position.x, 560.0, VILLAGE_AMBIENT_RECT.end.x - mz.size.x)
			mz.position.y = clampf(mz.position.y, VILLAGE_AMBIENT_RECT.position.y, VILLAGE_AMBIENT_RECT.end.y - mz.size.y)
			npc._movement_zone = mz
			if not VILLAGE_AMBIENT_RECT.has_point(npc.position) or npc.position.x < 560.0:
				npc.position = mz.get_center()
				npc.global_position = npc.position
			npc.position.x = maxf(npc.position.x, 560.0)
			npc.global_position.x = maxf(npc.global_position.x, 560.0)


func _spawn_forage_items() -> void:
	for pickup in _item_pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	_item_pickups.clear()

	var game_state := _get_active_game_state()
	var spawn_points: Array[Dictionary] = FORAGE_SPAWN_POINTS.duplicate()
	# Rain speeds up regrowth with one extra forage spot for the day.
	if game_state != null and game_state.has_method("is_raining") and game_state.is_raining():
		spawn_points.append(RAIN_FORAGE_SPAWN)
	for spawn_point in spawn_points:
		var spawn_id := str(spawn_point["spawn_id"])
		if (
			game_state != null
			and "collected_forage_today" in game_state
			and game_state.collected_forage_today.has(spawn_id)
		):
			continue
		var pickup := ITEM_PICKUP_SCENE.instantiate() as HearthwoodItemPickup
		pickup.configure(str(spawn_point["id"]), spawn_point["position"], spawn_id)
		add_child(pickup)
		_item_pickups.append(pickup)


func _on_day_changed(_day: int = 1) -> void:
	var gs := _get_active_game_state()
	if gs != null and "interacted_props_today" in gs:
		gs.interacted_props_today.clear()
	_spawn_forage_items()
	for prop in _interactive_props:
		if is_instance_valid(prop):
			prop.reset_daily()
	if is_instance_valid(_village_well) and not _interactive_props.has(_village_well):
		_village_well.reset_daily()
	if is_instance_valid(_notice_board) and not _interactive_props.has(_notice_board):
		_notice_board.reset_daily()
	for table in _warung_tables:
		if is_instance_valid(table):
			if table.current_state != table.TableState.EMPTY:
				table.clear_table()


func _on_state_changed() -> void:
	_sync_interactive_props_state()
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

	_draw_village_landmarks()

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


func _get_warung_tier() -> int:
	if has_node("/root/GameState"):
		var gs = get_node("/root/GameState")
		if "warung_tier" in gs:
			return int(gs.warung_tier)
	if _game_state != null and "warung_tier" in _game_state:
		return int(_game_state.warung_tier)
	return 0


func _draw_village_landmarks() -> void:
	_draw_village_plaza_and_paths()
	_draw_village_granary()
	_draw_residential_cottages()
	_draw_giral_store()
	_draw_talia_store()
	_draw_town_hall()
	_draw_player_warung()


func _draw_village_plaza_and_paths() -> void:
	# Main East-West thoroughfare connecting forest gate to village center
	draw_rect(Rect2(560.0, 428.0, 400.0, 24.0), Color("#705335"))
	draw_rect(Rect2(560.0, 432.0, 400.0, 16.0), Color("#8b7355"))
	draw_rect(Rect2(570.0, 435.0, 380.0, 10.0), Color("#a89f91"))

	# East thoroughfare towards Warung and Civic district
	draw_rect(Rect2(1200.0, 428.0, 180.0, 24.0), Color("#705335"))
	draw_rect(Rect2(1200.0, 432.0, 180.0, 16.0), Color("#8b7355"))
	draw_rect(Rect2(1210.0, 435.0, 160.0, 10.0), Color("#a89f91"))

	# North spur to Market District (Giral & Talia)
	draw_rect(Rect2(1034.0, 318.0, 36.0, 80.0), Color("#705335"))
	draw_rect(Rect2(1038.0, 318.0, 28.0, 80.0), Color("#8b7355"))

	# South spur to Residential District and Granary
	draw_rect(Rect2(1034.0, 516.0, 36.0, 126.0), Color("#705335"))
	draw_rect(Rect2(1038.0, 516.0, 28.0, 126.0), Color("#8b7355"))

	# Central Plaza paving around (1050, 460)
	# Soft earth underlay
	draw_rect(Rect2(946.0, 396.0, 268.0, 132.0), Color("#5c4630"))
	# Flagstone stone plaza body
	draw_rect(Rect2(950.0, 400.0, 260.0, 124.0), Color("#8f9692"))
	draw_rect(Rect2(956.0, 406.0, 248.0, 112.0), Color("#9ca89e"))

	# Individual rounded cobbles and flagstone grid details
	for px in range(960, 1200, 24):
		for py in range(410, 510, 20):
			var stone_color := Color("#a89f91") if (px + py) % 48 == 0 else Color("#7d8c82")
			draw_rect(Rect2(float(px), float(py), 20.0, 16.0), stone_color)
			draw_rect(Rect2(float(px) + 1.0, float(py) + 1.0, 18.0, 14.0), Color("#8f9692"))

	# Subtle highlight cobble specks near well (1050, 460) and board (1130, 460)
	for off in [Vector2(-30.0, -15.0), Vector2(25.0, -20.0), Vector2(-20.0, 25.0), Vector2(40.0, 18.0), Vector2(70.0, -10.0), Vector2(90.0, 20.0)]:
		draw_circle(Vector2(1050.0, 460.0) + off, 3.5, Color("#c2b280"))
		draw_circle(Vector2(1050.0, 460.0) + off, 2.0, Color("#d2b48c"))


func _draw_town_hall() -> void:
	var base_pos := Vector2(1330.0, 240.0)
	var size := Vector2(130.0, 84.0)

	# Stone plinth foundation & wide welcoming steps
	draw_rect(Rect2(base_pos.x - 6.0, base_pos.y + size.y - 8.0, size.x + 12.0, 8.0), Color("#6b736e"))
	draw_rect(Rect2(base_pos.x - 2.0, base_pos.y + size.y - 12.0, size.x + 4.0, 4.0), Color("#8f9692"))

	# Sturdy sandstone walls
	draw_rect(Rect2(base_pos.x, base_pos.y + 12.0, size.x, size.y - 20.0), Color("#d2b48c"))

	# Timber framing corner posts
	draw_rect(Rect2(base_pos.x, base_pos.y + 12.0, 8.0, size.y - 20.0), Color("#5a3d28"))
	draw_rect(Rect2(base_pos.x + size.x - 8.0, base_pos.y + 12.0, 8.0, size.y - 20.0), Color("#5a3d28"))

	# Grand gabled roof
	draw_rect(Rect2(base_pos.x - 8.0, base_pos.y - 4.0, size.x + 16.0, 22.0), Color("#5c3a1e"))
	draw_rect(Rect2(base_pos.x - 4.0, base_pos.y - 10.0, size.x + 8.0, 10.0), Color("#4a2e1b"))
	draw_line(Vector2(base_pos.x - 8.0, base_pos.y - 10.0), Vector2(base_pos.x + size.x + 8.0, base_pos.y - 10.0), Color("#8b5a3c"), 2.0)

	# Decorative half-timbered gable pediment in center
	var gable_pts: PackedVector2Array = [
		Vector2(base_pos.x + 40.0, base_pos.y + 12.0),
		Vector2(base_pos.x + size.x * 0.5, base_pos.y - 18.0),
		Vector2(base_pos.x + size.x - 40.0, base_pos.y + 12.0)
	]
	draw_colored_polygon(gable_pts, Color("#f5f5dc"))
	draw_line(gable_pts[0], gable_pts[1], Color("#5a3d28"), 3.0)
	draw_line(gable_pts[1], gable_pts[2], Color("#5a3d28"), 3.0)
	draw_line(gable_pts[0], gable_pts[2], Color("#5a3d28"), 2.0)
	draw_line(Vector2(base_pos.x + size.x * 0.5, base_pos.y - 18.0), Vector2(base_pos.x + size.x * 0.5, base_pos.y + 12.0), Color("#5a3d28"), 2.0)

	# Timber pillared porch
	draw_rect(Rect2(base_pos.x + 2.0, base_pos.y + 36.0, size.x - 4.0, 6.0), Color("#76513a"))
	for px in [base_pos.x + 6.0, base_pos.x + 38.0, base_pos.x + size.x - 44.0, base_pos.x + size.x - 12.0]:
		draw_rect(Rect2(px, base_pos.y + 42.0, 6.0, size.y - 54.0), Color("#5a3d28"))
		draw_rect(Rect2(px + 1.0, base_pos.y + 42.0, 4.0, size.y - 54.0), Color("#76513a"))

	# Arched double doors in center
	draw_rect(Rect2(base_pos.x + 52.0, base_pos.y + 44.0, 26.0, 28.0), Color("#4a2e1b"))
	draw_circle(Vector2(base_pos.x + 65.0, base_pos.y + 44.0), 13.0, Color("#3a2012"))
	draw_line(Vector2(base_pos.x + 65.0, base_pos.y + 35.0), Vector2(base_pos.x + 65.0, base_pos.y + 72.0), Color("#333333"), 1.5)
	draw_circle(Vector2(base_pos.x + 62.0, base_pos.y + 58.0), 2.0, Color("#ffd26b"))
	draw_circle(Vector2(base_pos.x + 68.0, base_pos.y + 58.0), 2.0, Color("#ffd26b"))

	# Arched leaded windows
	for wx in [base_pos.x + 18.0, base_pos.x + size.x - 34.0]:
		draw_rect(Rect2(wx, base_pos.y + 44.0, 16.0, 18.0), Color("#87ceeb"))
		draw_circle(Vector2(wx + 8.0, base_pos.y + 44.0), 8.0, Color("#87ceeb"))
		draw_line(Vector2(wx + 8.0, base_pos.y + 36.0), Vector2(wx + 8.0, base_pos.y + 62.0), Color("#555555"), 1.0)
		draw_line(Vector2(wx, base_pos.y + 52.0), Vector2(wx + 16.0, base_pos.y + 52.0), Color("#555555"), 1.0)
		draw_rect(Rect2(wx - 2.0, base_pos.y + 62.0, 20.0, 3.0), Color("#5a3d28"))

	# Hearthwood Green Banner with Golden Spoon
	draw_rect(Rect2(base_pos.x + 55.0, base_pos.y + 14.0, 20.0, 22.0), Color("#8fbc8f"))
	draw_rect(Rect2(base_pos.x + 55.0, base_pos.y + 34.0, 20.0, 2.0), Color("#cd853f"))
	# Golden spoon crest
	draw_line(Vector2(base_pos.x + 65.0, base_pos.y + 18.0), Vector2(base_pos.x + 65.0, base_pos.y + 30.0), Color("#cd853f"), 2.0)
	draw_circle(Vector2(base_pos.x + 65.0, base_pos.y + 19.0), 3.0, Color("#ffd26b"))

	# Rooftop cupola / belfry
	draw_rect(Rect2(base_pos.x + 57.0, base_pos.y - 28.0, 16.0, 14.0), Color("#76513a"))
	draw_circle(Vector2(base_pos.x + 65.0, base_pos.y - 21.0), 3.0, Color("#ffd26b"))
	var cupola_pts: PackedVector2Array = [
		Vector2(base_pos.x + 54.0, base_pos.y - 28.0),
		Vector2(base_pos.x + 65.0, base_pos.y - 38.0),
		Vector2(base_pos.x + 76.0, base_pos.y - 28.0)
	]
	draw_colored_polygon(cupola_pts, Color("#5c3a1e"))

	# Flower planters on porch sides
	draw_rect(Rect2(base_pos.x + 4.0, base_pos.y + size.y - 12.0, 22.0, 6.0), Color("#5a3d28"))
	draw_rect(Rect2(base_pos.x + size.x - 26.0, base_pos.y + size.y - 12.0, 22.0, 6.0), Color("#5a3d28"))
	for fx in [base_pos.x + 8.0, base_pos.x + 14.0, base_pos.x + 20.0, base_pos.x + size.x - 22.0, base_pos.x + size.x - 16.0]:
		draw_circle(Vector2(fx, base_pos.y + size.y - 14.0), 2.5, Color("#db7093"))
		draw_circle(Vector2(fx + 2.0, base_pos.y + size.y - 15.0), 1.5, Color("#ffd26b"))


func _draw_giral_store() -> void:
	var base_pos := Vector2(970.0, 246.0)
	var size := Vector2(92.0, 72.0)

	# Main wall
	draw_rect(Rect2(base_pos.x, base_pos.y + 14.0, size.x, size.y - 14.0), Color("#d2b48c"))
	draw_rect(Rect2(base_pos.x, base_pos.y + 14.0, 6.0, size.y - 14.0), Color("#76513a"))
	draw_rect(Rect2(base_pos.x + size.x - 6.0, base_pos.y + 14.0, 6.0, size.y - 14.0), Color("#76513a"))

	# Roof
	draw_rect(Rect2(base_pos.x - 6.0, base_pos.y - 4.0, size.x + 12.0, 18.0), Color("#5c3a1e"))
	draw_rect(Rect2(base_pos.x - 2.0, base_pos.y - 8.0, size.x + 4.0, 6.0), Color("#4a2e1b"))
	draw_line(Vector2(base_pos.x - 6.0, base_pos.y - 8.0), Vector2(base_pos.x + size.x + 6.0, base_pos.y - 8.0), Color("#8b5a3c"), 2.0)

	# Striped canopy awning (#B8482D & #F5F5DC)
	var awning_rect := Rect2(base_pos.x - 2.0, base_pos.y + 14.0, size.x + 4.0, 16.0)
	var stripe_width := 12.0
	var num_stripes := int(ceil(awning_rect.size.x / stripe_width))
	for i in num_stripes:
		var sx := awning_rect.position.x + float(i) * stripe_width
		var sw := minf(stripe_width, awning_rect.end.x - sx)
		var scolor := Color("#b8482d") if i % 2 == 0 else Color("#f5f5dc")
		draw_rect(Rect2(sx, awning_rect.position.y, sw, awning_rect.size.y), scolor)
	# Scalloped fringe
	draw_line(Vector2(awning_rect.position.x, awning_rect.end.y), Vector2(awning_rect.end.x, awning_rect.end.y), Color("#f5f5dc"), 2.0)

	# Shop entrance door
	draw_rect(Rect2(base_pos.x + size.x - 26.0, base_pos.y + 36.0, 18.0, 36.0), Color("#4a2e1b"))
	draw_circle(Vector2(base_pos.x + size.x - 22.0, base_pos.y + 54.0), 2.0, Color("#ffd26b"))

	# Display counter
	draw_rect(Rect2(base_pos.x + 8.0, base_pos.y + 42.0, 48.0, 14.0), Color("#76513a"))
	draw_rect(Rect2(base_pos.x + 10.0, base_pos.y + 40.0, 44.0, 3.0), Color("#8b5a3c"))

	# Commodity crates & sacks
	# Vegetable crate
	draw_rect(Rect2(base_pos.x + 8.0, base_pos.y + 58.0, 14.0, 12.0), Color("#a67c52"))
	draw_circle(Vector2(base_pos.x + 13.0, base_pos.y + 62.0), 3.0, Color("#4e7943"))
	draw_circle(Vector2(base_pos.x + 17.0, base_pos.y + 64.0), 2.5, Color("#75934f"))
	# Berry crate
	draw_rect(Rect2(base_pos.x + 24.0, base_pos.y + 59.0, 14.0, 11.0), Color("#8a5e38"))
	draw_circle(Vector2(base_pos.x + 29.0, base_pos.y + 63.0), 2.5, Color("#e74c3c"))
	draw_circle(Vector2(base_pos.x + 33.0, base_pos.y + 64.0), 2.0, Color("#db7093"))
	# Grain/Salt sack
	draw_circle(Vector2(base_pos.x + 44.0, base_pos.y + 65.0), 6.0, Color("#e5d2ad"))
	draw_circle(Vector2(base_pos.x + 44.0, base_pos.y + 60.0), 2.0, Color("#8b5a2b"))

	# Hanging wooden shop sign
	draw_rect(Rect2(base_pos.x + 8.0, base_pos.y + 4.0, 18.0, 8.0), Color("#cd853f"))
	draw_circle(Vector2(base_pos.x + 17.0, base_pos.y + 8.0), 2.0, Color("#4e7943"))


func _draw_talia_store() -> void:
	var base_pos := Vector2(1102.0, 246.0)
	var size := Vector2(92.0, 72.0)

	# Workshop ashlar stone wall
	draw_rect(Rect2(base_pos.x, base_pos.y + 14.0, size.x, size.y - 14.0), Color("#8f9692"))

	# Stone chimney with soot
	draw_rect(Rect2(base_pos.x + size.x - 14.0, base_pos.y - 12.0, 12.0, 26.0), Color("#6b736e"))
	draw_rect(Rect2(base_pos.x + size.x - 15.0, base_pos.y - 14.0, 14.0, 3.0), Color("#333333"))

	# Roof
	draw_rect(Rect2(base_pos.x - 6.0, base_pos.y - 4.0, size.x + 12.0, 18.0), Color("#5c3a1e"))
	draw_rect(Rect2(base_pos.x - 2.0, base_pos.y - 8.0, size.x + 4.0, 6.0), Color("#4a2e1b"))
	draw_line(Vector2(base_pos.x - 6.0, base_pos.y - 8.0), Vector2(base_pos.x + size.x + 6.0, base_pos.y - 8.0), Color("#8b5a3c"), 2.0)

	# Workshop overhang with knee braces
	draw_rect(Rect2(base_pos.x - 2.0, base_pos.y + 14.0, size.x + 4.0, 14.0), Color("#5a3d28"))
	draw_line(Vector2(base_pos.x + 2.0, base_pos.y + 28.0), Vector2(base_pos.x + 12.0, base_pos.y + 14.0), Color("#3a2012"), 2.0)
	draw_line(Vector2(base_pos.x + size.x - 4.0, base_pos.y + 28.0), Vector2(base_pos.x + size.x - 14.0, base_pos.y + 14.0), Color("#3a2012"), 2.0)

	# Workshop entrance door
	draw_rect(Rect2(base_pos.x + 12.0, base_pos.y + 36.0, 20.0, 36.0), Color("#3a2012"))
	draw_circle(Vector2(base_pos.x + 28.0, base_pos.y + 54.0), 2.0, Color("#333333"))

	# Glowing forge window
	draw_rect(Rect2(base_pos.x + 38.0, base_pos.y + 38.0, 18.0, 16.0), Color("#d35400"))
	draw_line(Vector2(base_pos.x + 47.0, base_pos.y + 38.0), Vector2(base_pos.x + 47.0, base_pos.y + 54.0), Color("#333333"), 1.5)
	draw_line(Vector2(base_pos.x + 38.0, base_pos.y + 46.0), Vector2(base_pos.x + 56.0, base_pos.y + 46.0), Color("#333333"), 1.5)

	# Heavy Iron Anvil Prop on tree stump
	var stump_pos := Vector2(base_pos.x + size.x - 24.0, base_pos.y + 54.0)
	draw_rect(Rect2(stump_pos.x - 6.0, stump_pos.y, 14.0, 16.0), Color("#5a3d28"))
	draw_rect(Rect2(stump_pos.x - 8.0, stump_pos.y - 6.0, 18.0, 6.0), Color("#333333"))
	# Anvil horn
	draw_line(Vector2(stump_pos.x - 8.0, stump_pos.y - 3.0), Vector2(stump_pos.x - 12.0, stump_pos.y - 2.0), Color("#4a4a4a"), 2.5)
	# Anvil face highlight
	draw_rect(Rect2(stump_pos.x - 6.0, stump_pos.y - 7.0, 14.0, 2.0), Color("#666666"))

	# Hanging smithing tools beneath the overhang
	draw_line(Vector2(base_pos.x + 8.0, base_pos.y + 24.0), Vector2(base_pos.x + 32.0, base_pos.y + 24.0), Color("#333333"), 2.0)
	# Hammer
	draw_line(Vector2(base_pos.x + 14.0, base_pos.y + 25.0), Vector2(base_pos.x + 14.0, base_pos.y + 32.0), Color("#8b5a2b"), 1.5)
	draw_rect(Rect2(base_pos.x + 12.0, base_pos.y + 31.0, 4.0, 3.0), Color("#555555"))
	# Tongs
	draw_line(Vector2(base_pos.x + 24.0, base_pos.y + 25.0), Vector2(base_pos.x + 22.0, base_pos.y + 33.0), Color("#555555"), 1.5)
	draw_line(Vector2(base_pos.x + 24.0, base_pos.y + 25.0), Vector2(base_pos.x + 26.0, base_pos.y + 33.0), Color("#555555"), 1.5)


func _draw_village_granary() -> void:
	var base_pos := Vector2(680.0, 640.0)
	var size := Vector2(100.0, 76.0)

	# Raised stilts / timber pilings
	for sx in [base_pos.x + 8.0, base_pos.x + 34.0, base_pos.x + size.x - 38.0, base_pos.x + size.x - 12.0]:
		draw_rect(Rect2(sx, base_pos.y + 54.0, 6.0, 22.0), Color("#5a3d28"))
		# Anti-rodent stone disc atop stilt
		draw_rect(Rect2(sx - 3.0, base_pos.y + 52.0, 12.0, 3.0), Color("#7d8c82"))

	# Wooden access ladder
	draw_rect(Rect2(base_pos.x + 44.0, base_pos.y + 54.0, 12.0, 22.0), Color("#76513a"))
	for ly in [base_pos.y + 58.0, base_pos.y + 64.0, base_pos.y + 70.0]:
		draw_line(Vector2(base_pos.x + 44.0, ly), Vector2(base_pos.x + 56.0, ly), Color("#4a2e1b"), 1.5)

	# Granary floor platform
	draw_rect(Rect2(base_pos.x - 2.0, base_pos.y + 48.0, size.x + 4.0, 6.0), Color("#5a3d28"))

	# Granary body: ventilated timber slats (#8A5E38 & #76513a)
	draw_rect(Rect2(base_pos.x, base_pos.y + 12.0, size.x, 38.0), Color("#8a5e38"))
	for sy in [base_pos.y + 18.0, base_pos.y + 24.0, base_pos.y + 30.0, base_pos.y + 36.0, base_pos.y + 42.0]:
		draw_line(Vector2(base_pos.x, sy), Vector2(base_pos.x + size.x, sy), Color("#5a3d28"), 1.5)

	# Center wooden granary door
	draw_rect(Rect2(base_pos.x + 42.0, base_pos.y + 20.0, 16.0, 28.0), Color("#4a2e1b"))
	draw_rect(Rect2(base_pos.x + 48.0, base_pos.y + 32.0, 4.0, 4.0), Color("#d6ba68"))

	# Distinctive thatched roof (#A67C52)
	draw_rect(Rect2(base_pos.x - 6.0, base_pos.y - 6.0, size.x + 12.0, 20.0), Color("#a67c52"))
	draw_rect(Rect2(base_pos.x - 2.0, base_pos.y - 10.0, size.x + 4.0, 6.0), Color("#c29b62"))
	draw_line(Vector2(base_pos.x - 6.0, base_pos.y - 10.0), Vector2(base_pos.x + size.x + 6.0, base_pos.y - 10.0), Color("#8b5a2b"), 3.0)

	# Grain sacks & barrel near the stilts
	draw_rect(Rect2(base_pos.x + 16.0, base_pos.y + 62.0, 10.0, 14.0), Color("#76513a"))
	draw_line(Vector2(base_pos.x + 16.0, base_pos.y + 66.0), Vector2(base_pos.x + 26.0, base_pos.y + 66.0), Color("#333333"), 1.0)
	draw_line(Vector2(base_pos.x + 16.0, base_pos.y + 72.0), Vector2(base_pos.x + 26.0, base_pos.y + 72.0), Color("#333333"), 1.0)
	draw_circle(Vector2(base_pos.x + 76.0, base_pos.y + 68.0), 5.0, Color("#e5d2ad"))
	draw_circle(Vector2(base_pos.x + 82.0, base_pos.y + 70.0), 4.5, Color("#d6ba68"))


func _draw_residential_cottages() -> void:
	var cottages_data := [
		{"pos": Vector2(820.0, 640.0), "size": Vector2(76.0, 64.0), "wall": Color("#f5f5dc"), "accent": Color("#db7093")},
		{"pos": Vector2(930.0, 640.0), "size": Vector2(80.0, 64.0), "wall": Color("#d2b48c"), "accent": Color("#6b736e")},
		{"pos": Vector2(1040.0, 640.0), "size": Vector2(76.0, 64.0), "wall": Color("#cba77b"), "accent": Color("#4e7943")},
		{"pos": Vector2(1150.0, 640.0), "size": Vector2(76.0, 64.0), "wall": Color("#d2b48c"), "accent": Color("#75934f")},
		{"pos": Vector2(1260.0, 640.0), "size": Vector2(76.0, 64.0), "wall": Color("#d2b48c"), "accent": Color("#8fbc8f")},
		{"pos": Vector2(1370.0, 640.0), "size": Vector2(76.0, 64.0), "wall": Color("#cba77b"), "accent": Color("#cd853f")},
	]

	# Rustic wooden fences connecting the cottage plots
	var fence_segments := [
		[780.0, 820.0],
		[896.0, 930.0],
		[1010.0, 1040.0],
		[1116.0, 1150.0],
		[1226.0, 1260.0],
		[1336.0, 1370.0],
	]
	for seg in fence_segments:
		var x1: float = seg[0]
		var x2: float = seg[1]
		var fy := 686.0
		# Horizontal rails
		draw_line(Vector2(x1, fy), Vector2(x2, fy), Color("#76513a"), 2.0)
		draw_line(Vector2(x1, fy + 6.0), Vector2(x2, fy + 6.0), Color("#76513a"), 2.0)
		# Posts
		for px in range(int(x1), int(x2) + 1, 14):
			draw_rect(Rect2(float(px) - 1.5, fy - 4.0, 3.0, 14.0), Color("#5a3d28"))

	# Draw each residential cottage
	for c in cottages_data:
		var cpos: Vector2 = c["pos"]
		var csize: Vector2 = c["size"]
		var wall_color: Color = c["wall"]
		var accent: Color = c["accent"]

		# Stone foundation
		draw_rect(Rect2(cpos.x, cpos.y + csize.y - 4.0, csize.x, 4.0), Color("#6b736e"))

		# Wall body
		draw_rect(Rect2(cpos.x, cpos.y + 12.0, csize.x, csize.y - 16.0), wall_color)
		# Corner posts
		draw_rect(Rect2(cpos.x, cpos.y + 12.0, 4.0, csize.y - 16.0), Color("#5a3d28"))
		draw_rect(Rect2(cpos.x + csize.x - 4.0, cpos.y + 12.0, 4.0, csize.y - 16.0), Color("#5a3d28"))

		# Roof
		draw_rect(Rect2(cpos.x - 4.0, cpos.y - 4.0, csize.x + 8.0, 18.0), Color("#5c3a1e"))
		draw_rect(Rect2(cpos.x - 1.0, cpos.y - 7.0, csize.x + 2.0, 5.0), Color("#4a2e1b"))
		draw_line(Vector2(cpos.x - 4.0, cpos.y - 7.0), Vector2(cpos.x + csize.x + 4.0, cpos.y - 7.0), Color("#8b5a3c"), 1.5)

		# Entrance door
		draw_rect(Rect2(cpos.x + csize.x * 0.5 - 7.0, cpos.y + csize.y - 26.0, 14.0, 22.0), Color("#4a2e1b"))
		draw_circle(Vector2(cpos.x + csize.x * 0.5 + 3.0, cpos.y + csize.y - 15.0), 1.5, Color("#ffd26b"))

		# Warm glowing window
		draw_rect(Rect2(cpos.x + 10.0, cpos.y + 26.0, 12.0, 12.0), Color("#ffd26b"))
		draw_line(Vector2(cpos.x + 16.0, cpos.y + 26.0), Vector2(cpos.x + 16.0, cpos.y + 38.0), Color("#5a3d28"), 1.0)
		draw_line(Vector2(cpos.x + 10.0, cpos.y + 32.0), Vector2(cpos.x + 22.0, cpos.y + 32.0), Color("#5a3d28"), 1.0)

		# Garden bed in front
		draw_rect(Rect2(cpos.x + 6.0, cpos.y + csize.y, 22.0, 6.0), Color("#4a2e1b"))
		draw_circle(Vector2(cpos.x + 11.0, cpos.y + csize.y + 2.0), 2.0, accent)
		draw_circle(Vector2(cpos.x + 17.0, cpos.y + csize.y + 2.0), 2.0, Color("#4e7943"))
		draw_circle(Vector2(cpos.x + 23.0, cpos.y + csize.y + 2.0), 2.0, accent)


func _draw_player_warung() -> void:
	var base_pos := Vector2(1268.0, 380.0)
	var size := Vector2(104.0, 76.0)
	var tier := _get_warung_tier()

	var wall_color := Color("#d2b48c")
	match tier:
		1:
			wall_color = Color("#cba77b")
		2:
			wall_color = Color("#e0c99d")
		3:
			wall_color = Color("#f0dcae")

	# Base roof & walls
	draw_rect(Rect2(base_pos.x - 7.0, base_pos.y - 16.0, size.x + 14.0, 30.0), Color("#76513a"))
	draw_rect(Rect2(base_pos.x, base_pos.y, size.x, size.y), wall_color)
	draw_rect(Rect2(base_pos.x - 7.0, base_pos.y - 18.0, size.x + 14.0, 13.0), Color("#8b5a3c"))

	# Door
	draw_rect(Rect2(base_pos.x + size.x * 0.5 - 8.0, base_pos.y + size.y - 25.0, 16.0, 25.0), Color("#654321"))

	# Hearthwood green signboard
	draw_rect(Rect2(base_pos.x + 8.0, base_pos.y - 5.0, 20.0, 11.0), Color("#8fbc8f"))

	# Tier upgrades
	if tier >= 1:
		draw_rect(Rect2(base_pos.x - 18.0, base_pos.y + size.y - 7.0, 26.0, 6.0), Color("#76513a"))
		draw_rect(Rect2(base_pos.x + size.x - 8.0, base_pos.y + size.y - 7.0, 26.0, 6.0), Color("#76513a"))
	if tier >= 2:
		draw_rect(Rect2(base_pos.x + 14.0, base_pos.y + 18.0, 15.0, 15.0), Color("#87ceeb"))
		draw_rect(Rect2(base_pos.x + size.x - 29.0, base_pos.y + 18.0, 15.0, 15.0), Color("#87ceeb"))
	if tier >= 3:
		draw_rect(Rect2(base_pos.x - 14.0, base_pos.y - 24.0, 34.0, 8.0), Color("#b8860b"))
		draw_rect(Rect2(base_pos.x + size.x - 20.0, base_pos.y - 24.0, 34.0, 8.0), Color("#b8860b"))


func _draw_building(building: Rect2, is_warung: bool = false) -> void:
	var wall_color := Color("#d2b48c")
	var tier := _get_warung_tier()
	if is_warung:
		match tier:
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


class WarungBell extends Area2D:
	signal bell_rung()

	var prop_id: String = "warung_bell"
	var interaction_radius: float = 44.0

	func _init() -> void:
		_setup_collision()

	func _ready() -> void:
		_setup_collision()
		queue_redraw()

	func _setup_collision() -> void:
		var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
		if col == null:
			col = CollisionShape2D.new()
			col.name = "CollisionShape2D"
			var circle := CircleShape2D.new()
			circle.radius = interaction_radius
			col.shape = circle
			add_child(col)
		elif col.shape is CircleShape2D:
			(col.shape as CircleShape2D).radius = interaction_radius

	func ring() -> void:
		bell_rung.emit()
		queue_redraw()

	func interact(_player: Node2D = null) -> Dictionary:
		ring()
		return {
			"success": true,
			"message": "Lonceng operasional warung berdentang merdu!",
			"data": {"action": "ring_bell"}
		}

	func _draw() -> void:
		# 1. Soft ground shadow
		draw_rect(Rect2(-8.0, 10.0, 18.0, 6.0), Color(0.08, 0.05, 0.02, 0.25), true)

		# 2. Wooden mount post & bracket
		var post_col := Color("#5A3716")
		var post_border := Color("#3B220B")
		var arm_col := Color("#6B4226")
		# Vertical timber post
		draw_rect(Rect2(-3.0, -12.0, 6.0, 24.0), post_col, true)
		draw_rect(Rect2(-3.0, -12.0, 6.0, 24.0), post_border, false, 1.0)
		# Horizontal beam extending to the right to hang the bell
		draw_rect(Rect2(-2.0, -12.0, 15.0, 5.0), arm_col, true)
		draw_rect(Rect2(-2.0, -12.0, 15.0, 5.0), post_border, false, 1.0)
		# Diagonal brace
		draw_line(Vector2(-1.0, -5.0), Vector2(8.0, -11.0), Color("#452A11"), 1.5)

		# 3. Small rustic wooden sign hanging to the left ("WARUNG")
		var sign_rect := Rect2(-17.0, -5.0, 14.0, 10.0)
		draw_rect(sign_rect, Color("#7B4E26"), true)
		draw_rect(sign_rect, Color("#3E240E"), false, 1.0)
		# Hanging wires from beam to sign
		draw_line(Vector2(-13.0, -12.0), Vector2(-13.0, -5.0), Color("#888888"), 1.0)
		draw_line(Vector2(-5.0, -12.0), Vector2(-5.0, -5.0), Color("#888888"), 1.0)
		# Tiny fork/spoon rune in cream
		draw_line(Vector2(-10.0, -2.0), Vector2(-10.0, 2.0), Color("#F4ECD8"), 1.0)
		draw_line(Vector2(-11.0, -2.0), Vector2(-9.0, -2.0), Color("#F4ECD8"), 1.0)

		# 4. Brass bell
		# Eyelet link
		draw_circle(Vector2(10.0, -7.0), 2.0, Color("#A08020"))
		# Bell body flare (trapezoid-like polygon)
		var bell_poly := PackedVector2Array([
			Vector2(7.5, -5.0),
			Vector2(12.5, -5.0),
			Vector2(14.5, 3.0),
			Vector2(5.5, 3.0)
		])
		draw_colored_polygon(bell_poly, Color("#D4AF37"))
		# Bell rim lip
		draw_rect(Rect2(5.0, 3.0, 10.0, 2.5), Color("#B8860B"), true)
		# Bell gleam highlight
		draw_line(Vector2(8.0, -4.0), Vector2(7.0, 2.0), Color("#FFF8D0"), 1.2)
		# Clapper & braided rope
		draw_circle(Vector2(10.0, 5.5), 1.8, Color("#8B6508"))
		draw_line(Vector2(10.0, 6.5), Vector2(10.0, 13.0), Color("#C8B898"), 1.2)
		draw_circle(Vector2(10.0, 13.0), 1.5, Color("#6B4226"))
