extends "res://scripts/npc/NPC.gd"
class_name HearthwoodShopNPC

signal shop_hours_changed(is_open: bool)

const HEART_TWO_DISCOUNT_PERCENT: int = 5
const HEART_THREE_DISCOUNT_PERCENT: int = 15

var _shop_hours: Dictionary = {}
var _valid_shop_hours: bool = false
var _closed_weathers: Array[String] = []
var _previous_open_state: bool = false


func _ready() -> void:
	super._ready()
	var hours: Variant = get_npc_data().get("jam_buka")
	if typeof(hours) != TYPE_DICTIONARY:
		push_error("Shop NPC is missing valid jam_buka data: %s" % npc_id)
		return
	if not hours.has("mulai") or not hours.has("selesai"):
		push_error("Shop NPC jam_buka must include mulai and selesai: %s" % npc_id)
		return

	var closed_weathers: Variant = get_npc_data().get("tutup_cuaca", [])
	if typeof(closed_weathers) == TYPE_ARRAY:
		for weather_id in closed_weathers:
			if str(weather_id) in ["cerah", "hujan", "badai"]:
				_closed_weathers.append(str(weather_id))

	_shop_hours = hours
	_valid_shop_hours = true
	_previous_open_state = is_shop_open()
	get_node("/root/TimeSystem").minute_changed.connect(_on_shop_clock_changed)


func can_interact() -> bool:
	return super.can_interact() and is_shop_open()


func is_shop_open() -> bool:
	if not _valid_shop_hours:
		return false
	var game_state = get_node("/root/GameState")
	if _closed_weathers.has(str(game_state.current_weather)):
		return false
	var time_of_day := float(game_state.current_hour % 24) + float(game_state.current_minute) / 60.0
	return (
		time_of_day >= float(_shop_hours["mulai"])
		and time_of_day < float(_shop_hours["selesai"])
	)


func get_discount_percent() -> int:
	var heart_level: int = get_node("/root/GameState").get_npc_heart_level(npc_id)
	if heart_level >= 3:
		return HEART_THREE_DISCOUNT_PERCENT
	if heart_level >= 2:
		return HEART_TWO_DISCOUNT_PERCENT
	return 0


func _on_shop_clock_changed(_day: int, _hour: int, _minute: int) -> void:
	var current_open_state := is_shop_open()
	if current_open_state != _previous_open_state:
		_previous_open_state = current_open_state
		shop_hours_changed.emit(current_open_state)
