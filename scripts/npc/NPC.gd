extends CharacterBody2D
class_name HearthwoodNPC

const CHARACTER_VISUAL_SCRIPT: Script = preload("res://scripts/characters/CharacterVisual.gd")
const WALK_SPEED: float = 30.0

var npc_id: String = ""
var is_ambient: bool = false
var _data_path: String = ""
var _schedule_segments: Array[Dictionary] = []
var _npc_data: Dictionary = {}
var _display_name: String = "Penduduk"
var _role: String = ""
var _accessory: String = "tanpa"
var _hair_color: Color = Color("#654321")
var _shirt_color: Color = Color("#556B2F")
var _pants_color: Color = Color("#654321")
var _movement_zone: Rect2 = Rect2()
var _random := RandomNumberGenerator.new()
var _screen_notifier: VisibleOnScreenNotifier2D
var _move_timer: float = 0.0
var _current_segment: int = -2
var _is_available: bool = false
var _is_on_screen: bool = false


func configure_named(id: String, data_path: String, schedule_segments: Array) -> void:
	npc_id = id
	_data_path = data_path
	for segment in schedule_segments:
		if typeof(segment) == TYPE_DICTIONARY:
			_schedule_segments.append(segment)


func configure_ambient(index: int, spawn_position: Vector2, movement_zone: Rect2) -> void:
	npc_id = "ambient_%02d" % index
	is_ambient = true
	position = spawn_position
	_movement_zone = movement_zone
	var hue := fmod(float(index) * 0.137 + 0.07, 1.0)
	_hair_color = Color.from_hsv(fmod(hue + 0.48, 1.0), 0.45, 0.42)
	_shirt_color = Color.from_hsv(hue, 0.48, 0.76)
	_pants_color = Color.from_hsv(fmod(hue + 0.21, 1.0), 0.34, 0.52)


func _ready() -> void:
	_random.seed = npc_id.hash()
	_screen_notifier = VisibleOnScreenNotifier2D.new()
	_screen_notifier.rect = Rect2(-20.0, -32.0, 40.0, 48.0)
	add_child(_screen_notifier)
	_screen_notifier.screen_entered.connect(_on_screen_entered)
	_screen_notifier.screen_exited.connect(_on_screen_exited)
	call_deferred("_update_screen_state")
	if is_ambient:
		_is_available = true
		_update_physics_state()
	else:
		if not _load_npc_data():
			visible = false
			set_physics_process(false)
			return
		get_node("/root/TimeSystem").minute_changed.connect(_on_minute_changed)
		var game_state = get_node("/root/GameState")
		_refresh_schedule(game_state.current_hour, game_state.current_minute)
	_create_character_visual()


func _physics_process(delta: float) -> void:
	if not _is_available:
		return

	_move_timer -= delta
	if _move_timer <= 0.0:
		if velocity.is_zero_approx():
			var direction := Vector2(_random.randf_range(-1.0, 1.0), _random.randf_range(-1.0, 1.0))
			velocity = direction.normalized() * WALK_SPEED
			_move_timer = _random.randf_range(1.0, 2.8)
		else:
			velocity = Vector2.ZERO
			_move_timer = _random.randf_range(0.7, 2.0)

	if not _movement_zone.has_point(global_position + velocity * delta):
		velocity = global_position.direction_to(_movement_zone.get_center()) * WALK_SPEED
	move_and_slide()
	global_position = global_position.clamp(_movement_zone.position, _movement_zone.end)


func get_display_name() -> String:
	return _display_name


func get_role() -> String:
	return _role


func get_npc_data() -> Dictionary:
	return _npc_data


func get_dialogue() -> String:
	var dialog: Dictionary = _npc_data.get("dialog", {})
	var has_met: bool = get_node("/root/GameState").npc_met.get(npc_id, false)
	var dialogue_key := "dialog_2" if has_met else "dialog_1"
	return str(dialog.get(dialogue_key, ""))


func mark_met() -> void:
	var game_state = get_node("/root/GameState")
	if not bool(game_state.npc_met.get(npc_id, false)):
		game_state.npc_met[npc_id] = true
		game_state.state_changed.emit()


func can_interact() -> bool:
	return not is_ambient and _is_available


func _load_npc_data() -> bool:
	if not FileAccess.file_exists(_data_path):
		push_error("NPC data file not found: %s" % _data_path)
		return false

	var file := FileAccess.open(_data_path, FileAccess.READ)
	if file == null:
		push_error("Could not read NPC data file: %s" % _data_path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("NPC data must be a JSON object: %s" % _data_path)
		return false
	_npc_data = parsed

	for required_key in ["nama", "peran", "palet", "dialog"]:
		if not _npc_data.has(required_key):
			push_error("NPC data is missing '%s': %s" % [required_key, _data_path])
			return false
	if (
		typeof(_npc_data["palet"]) != TYPE_DICTIONARY
		or typeof(_npc_data["dialog"]) != TYPE_DICTIONARY
	):
		push_error("NPC palette and dialogue must be JSON objects: %s" % _data_path)
		return false

	var palette: Dictionary = _npc_data["palet"]
	var dialog: Dictionary = _npc_data["dialog"]
	for dialogue_key in ["dialog_1", "dialog_2"]:
		if not dialog.has(dialogue_key):
			push_error("NPC data is missing '%s': %s" % [dialogue_key, _data_path])
			return false

	_display_name = str(_npc_data["nama"])
	_role = str(_npc_data["peran"])
	_hair_color = Color(str(palette.get("rambut", "#654321")))
	_shirt_color = Color(str(palette.get("baju", "#556B2F")))
	_pants_color = Color(str(palette.get("celana", "#654321")))
	_accessory = str(palette.get("aksesori", "tanpa"))
	return true


func _refresh_schedule(hour: int, minute: int) -> void:
	var time_of_day := float(hour % 24) + float(minute) / 60.0
	var matching_segment := -1

	for index in _schedule_segments.size():
		var segment: Dictionary = _schedule_segments[index]
		if (
			time_of_day >= float(segment.get("mulai", 0.0))
			and time_of_day < float(segment.get("selesai", 0.0))
		):
			matching_segment = index
			break

	if matching_segment == _current_segment:
		return

	_current_segment = matching_segment
	_is_available = matching_segment >= 0
	visible = _is_available
	_update_physics_state()
	if not _is_available:
		velocity = Vector2.ZERO
		return

	var active_segment: Dictionary = _schedule_segments[matching_segment]
	var location: Array = active_segment.get("posisi", [])
	var zone_size: Array = active_segment.get("zona", [64, 48])
	if location.size() != 2 or zone_size.size() != 2:
		push_error("Invalid schedule location or zone for NPC: %s" % npc_id)
		_is_available = false
		visible = false
		set_physics_process(false)
		return

	position = Vector2(float(location[0]), float(location[1]))
	_movement_zone = Rect2(
		position - Vector2(float(zone_size[0]), float(zone_size[1])) * 0.5,
		Vector2(float(zone_size[0]), float(zone_size[1]))
	)
	_move_timer = _random.randf_range(0.4, 1.4)
	velocity = Vector2.ZERO


func _on_minute_changed(_day: int, hour: int, minute: int) -> void:
	_refresh_schedule(hour, minute)


func _on_screen_entered() -> void:
	_is_on_screen = true
	_update_physics_state()


func _on_screen_exited() -> void:
	_is_on_screen = false
	_update_physics_state()


func _update_screen_state() -> void:
	_is_on_screen = _screen_notifier.is_on_screen()
	_update_physics_state()


func _update_physics_state() -> void:
	set_physics_process(_is_available and _is_on_screen)


func _create_character_visual() -> void:
	var character_visual = CHARACTER_VISUAL_SCRIPT.new()
	character_visual.name = "characterVisual"
	add_child(character_visual)
	character_visual.configure(
		_hair_color,
		_shirt_color,
		_pants_color,
		_accessory
	)
