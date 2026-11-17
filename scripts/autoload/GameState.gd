extends Node

signal energy_changed(new_value: int)
signal state_changed

const MAX_ENERGY: int = 100

var player_name: String = "Pengelana"
var current_day: int = 1
var current_hour: int = 6
var current_minute: int = 0
var energy: int = MAX_ENERGY
var reputation: int = 0
var warung_tier: int = 0


func change_energy(amount: int) -> void:
	var previous_energy := energy
	energy = clampi(energy + amount, 0, MAX_ENERGY)
	if energy != previous_energy:
		energy_changed.emit(energy)


func sleep(wake_hour: int, recovery_ratio: float) -> void:
	current_day += 1
	current_hour = wake_hour
	current_minute = 0
	energy = roundi(MAX_ENERGY * recovery_ratio)
	energy_changed.emit(energy)
	state_changed.emit()
