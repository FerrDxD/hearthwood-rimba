extends Node

signal minute_changed(day: int, hour: int, minute: int)
signal hour_changed(hour: int, minute: int)
signal day_changed(day: int)
signal sleep_started(wake_hour: int)

const SECONDS_PER_GAME_MINUTE: float = 1.5
const FIRST_HOUR_OF_NEXT_DAY: int = 30

var _elapsed_seconds: float = 0.0


func _process(delta: float) -> void:
	_elapsed_seconds += delta
	while _elapsed_seconds >= SECONDS_PER_GAME_MINUTE:
		_elapsed_seconds -= SECONDS_PER_GAME_MINUTE
		_advance_minute()


func sleep() -> void:
	var game_state = get_node("/root/GameState")
	var wake_hour := 6
	var recovery_ratio := 1.0

	if game_state.current_hour >= 27:
		wake_hour = 12
		recovery_ratio = 0.4
	elif game_state.current_hour >= 24:
		wake_hour = 10
		recovery_ratio = 0.6
	elif game_state.current_hour >= 22:
		wake_hour = 8
		recovery_ratio = 0.8

	sleep_started.emit(wake_hour)
	game_state.sleep(wake_hour, recovery_ratio)
	_elapsed_seconds = 0.0
	day_changed.emit(game_state.current_day)
	hour_changed.emit(game_state.current_hour, game_state.current_minute)
	minute_changed.emit(
		game_state.current_day,
		game_state.current_hour,
		game_state.current_minute
	)


func _advance_minute() -> void:
	var game_state = get_node("/root/GameState")
	game_state.current_minute += 1

	if game_state.current_minute >= 60:
		game_state.current_minute = 0
		game_state.current_hour += 1
		hour_changed.emit(game_state.current_hour % 24, game_state.current_minute)

	if game_state.current_hour >= FIRST_HOUR_OF_NEXT_DAY:
		sleep()
		return

	minute_changed.emit(
		game_state.current_day,
		game_state.current_hour,
		game_state.current_minute
	)
