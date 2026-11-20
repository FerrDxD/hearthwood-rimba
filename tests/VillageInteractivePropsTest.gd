# tests/VillageInteractivePropsTest.gd
extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- Running VillageInteractivePropsTest ---")
	test_village_well()
	test_notice_board()
	test_village_props_daily_cycle()
	print("VillageInteractivePropsTest passed.")
	quit(0)


func test_village_well() -> void:
	print("Testing VillageWell...")
	var well_script = load("res://scripts/world/VillageWell.gd")
	assert(well_script != null, "VillageWell.gd must exist")

	var well = well_script.new()
	assert(well is Area2D, "VillageWell must extend Area2D")
	assert(well is HearthwoodInteractiveProp, "VillageWell must extend HearthwoodInteractiveProp")
	assert(well.prop_id == "village_well", "Default prop_id must be village_well")
	assert(well.prop_type == "village_well", "Default prop_type must be village_well")
	assert(well.interaction_prompt == "Timba Air", "Default interaction_prompt must be 'Timba Air'")
	assert(is_equal_approx(well.interaction_radius, 48.0), "Default interaction_radius must be 48.0")
	assert(well.energy_restore == 5, "Default energy_restore must be 5")
	assert(well.water_item_id == "air_bersih", "Default water_item_id must be 'air_bersih'")
	assert(well.daily_interacted == false, "VillageWell must not be interacted initially")
	assert(well.can_interact() == true, "VillageWell must be interactable initially")

	root.add_child(well)
	var col_shape = well.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert(col_shape != null, "CollisionShape2D must exist on VillageWell")
	assert(col_shape.shape is CircleShape2D, "Collision shape must be CircleShape2D")
	assert(is_equal_approx((col_shape.shape as CircleShape2D).radius, 48.0), "Radius must match 48.0")

	var game_state = root.get_node_or_null("GameState")
	assert(game_state != null, "GameState must be present")
	game_state.energy = 50
	var initial_water: int = game_state.get_item_count("air_bersih") if game_state.has_method("get_item_count") else 0

	var interacted_signal_events: Array = []
	well.interacted.connect(func(res: Dictionary): interacted_signal_events.append(res))

	# First interaction of the day
	var res = well.interact()
	assert(res["success"] == true, "First well interaction must succeed")
	assert(res["message"] == "Kamu menimba seember air bersih yang segar dan membasuh wajahmu. Energi bertambah +5!", "Success message must match specification")
	assert(res["data"]["energy_restored"] == 5, "Data energy_restored must be 5")
	assert(res["data"]["item_awarded"] == "air_bersih", "Data item_awarded must be air_bersih")
	assert(well.daily_interacted == true, "daily_interacted must be true after interaction")
	assert(well.can_interact() == false, "can_interact must be false after interaction")
	assert(interacted_signal_events.size() == 1, "interacted signal must be emitted")
	assert(interacted_signal_events[0]["success"] == true, "Signal payload must match result")

	assert(game_state.energy == 55, "GameState energy must increase by +5 (from 50 to 55)")
	if game_state.has_method("get_item_count"):
		assert(game_state.get_item_count("air_bersih") == initial_water + 1, "Inventory must receive 1 air_bersih")

	# Second interaction on the same day (must be rejected)
	var repeat_res = well.interact()
	assert(repeat_res["success"] == false, "Repeat well interaction on same day must fail")
	assert(repeat_res["message"] == "Air sumur masih tenang beriak di kedalaman. Kamu sudah mengambil air untuk hari ini.", "Repeat failure message must match specification")
	assert(game_state.energy == 55, "Energy must not increase again on repeat interaction")
	if game_state.has_method("get_item_count"):
		assert(game_state.get_item_count("air_bersih") == initial_water + 1, "Water item must not be awarded again on repeat interaction")

	# Daily reset
	var reset_events: Array = [false]
	well.daily_reset.connect(func(): reset_events[0] = true)
	well.reset_daily()
	assert(well.daily_interacted == false, "daily_interacted must be false after reset_daily()")
	assert(well.can_interact() == true, "can_interact must be true after reset_daily()")
	assert(reset_events[0] == true, "daily_reset signal must be emitted")

	# Re-interaction after reset
	var next_day_res = well.interact()
	assert(next_day_res["success"] == true, "Well must be interactable again after daily reset")
	assert(game_state.energy == 60, "Energy must increase to 60 on next day interaction")

	root.remove_child(well)
	well.free()
	print("VillageWell passed.")


func test_notice_board() -> void:
	print("Testing NoticeBoard...")
	var board_script = load("res://scripts/world/NoticeBoard.gd")
	assert(board_script != null, "NoticeBoard.gd must exist")

	var board = board_script.new()
	assert(board is Area2D, "NoticeBoard must extend Area2D")
	assert(board is HearthwoodInteractiveProp, "NoticeBoard must extend HearthwoodInteractiveProp")
	assert(board.prop_id == "notice_board", "Default prop_id must be notice_board")
	assert(board.prop_type == "notice_board", "Default prop_type must be notice_board")
	assert(board.interaction_prompt == "Baca Pengumuman", "Default interaction_prompt must be 'Baca Pengumuman'")
	assert(is_equal_approx(board.interaction_radius, 48.0), "Default interaction_radius must be 48.0")
	assert(board.can_interact() == true, "NoticeBoard can_interact must be true initially")

	root.add_child(board)
	var col_shape = board.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert(col_shape != null, "CollisionShape2D must exist on NoticeBoard")
	assert(col_shape.shape is CircleShape2D, "Collision shape must be CircleShape2D")
	assert(is_equal_approx((col_shape.shape as CircleShape2D).radius, 48.0), "Radius must match 48.0")

	# Notice data structure
	var notice = board.get_daily_notice()
	assert(notice is Dictionary, "get_daily_notice() must return a Dictionary")
	assert("weather" in notice, "Notice must contain 'weather'")
	assert(str(notice["weather"]).length() > 0, "Weather info must not be empty")
	assert("craving_hint" in notice, "Notice must contain 'craving_hint'")
	assert(str(notice["craving_hint"]).length() > 0, "Craving hint must not be empty")
	assert("mayor_note" in notice, "Notice must contain 'mayor_note'")
	assert(notice["mayor_note"] == "Pesan Kepala Desa Veral: Selamat datang di Hearthwood. Jagalah kebersihan dan kehangatan desa kita.", "Mayor note must match specification")

	# Interaction
	var interacted_signal_events: Array = []
	board.interacted.connect(func(res: Dictionary): interacted_signal_events.append(res))

	var res = board.interact()
	assert(res["success"] == true, "NoticeBoard interaction must succeed")
	assert(res["message"] == "Warta Desa Hearthwood", "Message must be 'Warta Desa Hearthwood'")
	assert(res["data"] is Dictionary, "Result data must be the notice dictionary")
	assert(res["data"]["craving_hint"] == notice["craving_hint"], "Data craving_hint must match get_daily_notice()")
	assert(interacted_signal_events.size() == 1, "interacted signal must be emitted")

	# Multiple interactions allowed on the notice board
	assert(board.can_interact() == true, "Notice board can_interact must remain true")
	var second_res = board.interact()
	assert(second_res["success"] == true, "Notice board must allow repeated reads on the same day")
	assert(second_res["message"] == "Warta Desa Hearthwood", "Second read must return valid notice")

	root.remove_child(board)
	board.free()
	print("NoticeBoard passed.")


func test_village_props_daily_cycle() -> void:
	print("Testing Village Props Daily Cycle...")
	var well_script = load("res://scripts/world/VillageWell.gd")
	var board_script = load("res://scripts/world/NoticeBoard.gd")

	var well = well_script.new()
	var board = board_script.new()
	root.add_child(well)
	root.add_child(board)

	well.interact()
	board.interact()

	assert(well.daily_interacted == true, "Well daily_interacted must be true")
	assert(well.can_interact() == false, "Well cannot interact again on same day")
	assert(board.can_interact() == true, "Board can always interact")

	well.reset_daily()
	board.reset_daily()

	assert(well.daily_interacted == false, "Well must reset daily")
	assert(well.can_interact() == true, "Well must be interactable after reset")

	root.remove_child(well)
	root.remove_child(board)
	well.free()
	board.free()
	print("Village Props Daily Cycle passed.")
