extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var cases: Array[Vector3i] = [
		Vector3i(21, 6, 100),
		Vector3i(22, 8, 80),
		Vector3i(23, 8, 80),
		Vector3i(24, 10, 60),
		Vector3i(26, 10, 60),
		Vector3i(27, 12, 40),
		Vector3i(30, 12, 40),
	]
	var time_system = root.get_node("TimeSystem")
	var game_state = root.get_node("GameState")

	for test_case in cases:
		game_state.current_day = 4
		game_state.current_hour = test_case.x
		game_state.current_minute = 37
		game_state.energy = 0
		time_system.sleep()

		if (
			game_state.current_day != 5
			or game_state.current_hour != test_case.y
			or game_state.current_minute != 0
			or game_state.energy != test_case.z
		):
			push_error("Sleep recovery failed for hour %d." % test_case.x)
			quit(1)
			return

	print("TimeSystem sleep boundary tests passed.")
	quit(0)
