extends SceneTree

const AFFECTION_SYSTEM_SCENE: PackedScene = preload("res://scenes/AffectionSystem.tscn")
const COOKING_SYSTEM_SCENE: PackedScene = preload("res://scenes/CookingSystem.tscn")
const DIALOG_UI_SCENE: PackedScene = preload("res://scenes/DialogUI.tscn")
const GIFT_UI_SCENE: PackedScene = preload("res://scenes/GiftUI.tscn")
const SHOP_NPC_SCENE: PackedScene = preload("res://scenes/ShopNPC.tscn")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	game_state.inventory.clear()
	game_state.unlocked_recipes.clear()
	game_state.unlocked_recipes.append("sup_sayur_bening")
	game_state.unlocked_recipes.append("bubur_hangat_hutan")
	game_state.affection_points.clear()
	game_state.unlocked_quests.clear()
	game_state.npc_heart_levels.clear()
	game_state.gifts_given_today.clear()
	game_state.disliked_gift_streaks.clear()
	game_state.npc_gift_history.clear()
	game_state.npc_recently_returned_from_forest.clear()
	game_state.current_weather = "cerah"
	game_state.current_day = 1
	game_state.current_hour = 6
	game_state.current_minute = 0

	var cooking_system := COOKING_SYSTEM_SCENE.instantiate() as HearthwoodCookingSystem
	root.add_child(cooking_system)
	var affection_system := AFFECTION_SYSTEM_SCENE.instantiate() as HearthwoodAffectionSystem
	affection_system.set_cooking_system(cooking_system)
	root.add_child(affection_system)
	var dialog_ui := DIALOG_UI_SCENE.instantiate() as HearthwoodDialogUI
	root.add_child(dialog_ui)
	var gift_ui := GIFT_UI_SCENE.instantiate() as HearthwoodGiftUI
	gift_ui.set_affection_system(affection_system)
	root.add_child(gift_ui)
	dialog_ui.gift_requested.connect(gift_ui.open_gifts)
	await process_frame

	for quality_case in [
		{"quality": 1, "expected": 1},
		{"quality": 2, "expected": 2},
		{"quality": 3, "expected": 3},
		{"quality": 3, "expected": 3},
		{"quality": 3, "expected": 3},
	]:
		var quality := int(quality_case["quality"])
		game_state.add_item("ikan_bakar_rempah", 1, game_state.current_day, quality)
		if quality == 1:
			game_state.add_item("ikan_bakar_rempah", 1, game_state.current_day, 2)
		var result: Dictionary = affection_system.give_food(
			"jev",
			"ikan_bakar_rempah",
			game_state.current_day,
			quality
		)
		if (
			not bool(result.get("valid", false))
			or result.get("reaction") != "suka"
			or int(result.get("points_gained", 0)) != int(quality_case["expected"])
		):
			push_error("Like reaction or quality penalty was calculated incorrectly.")
			quit(1)
			return
		var remaining_same_day_quality_two := _get_stack_count(
			game_state,
			"ikan_bakar_rempah",
			game_state.current_day,
			2
		)
		if (
			(quality == 1 and remaining_same_day_quality_two != 1)
			or (quality != 1 and _get_stack_count(
				game_state,
				"ikan_bakar_rempah",
				game_state.current_day,
				quality
			) != 0)
		):
			push_error("A successful gift should consume exactly one cooked portion.")
			quit(1)
			return
		if game_state.gifts_given_today.has("jev"):
			var duplicate_gift: Dictionary = affection_system.give_food(
				"jev",
				"ikan_bakar_rempah",
				game_state.current_day,
				quality
			)
			if bool(duplicate_gift.get("valid", true)):
				push_error("The same NPC should only accept one gift per day.")
				quit(1)
				return
		if int(game_state.affection_points.get("jev", 0)) >= 10:
			break
		time_system.sleep()

	if (
		game_state.get_npc_heart_level("jev") != 1
		or int(game_state.affection_points.get("jev", 0)) != 12
	):
		push_error("Five daily liked gifts should reach the first heart at ten cumulative points.")
		quit(1)
		return

	game_state.add_item("bubur_hangat_hutan", 1, game_state.current_day, 2)
	dialog_ui.open_dialog("Gil", "Petani", "Terima kasih.", "gil")
	var give_button := _find_button(dialog_ui, "Beri masakan")
	if give_button == null or not give_button.visible:
		push_error("Named NPC dialogue should expose the cooked-food gift option.")
		quit(1)
		return
	give_button.pressed.emit()
	if not gift_ui.is_open():
		push_error("The dialogue gift option should open cooked-food selection.")
		quit(1)
		return
	var food_button := _find_button(gift_ui, "Bubur Hangat Hutan")
	if food_button == null:
		push_error("Gift selection should list available cooked portions.")
		quit(1)
		return
	food_button.pressed.emit()
	if (
		game_state.get_item_count("bubur_hangat_hutan") != 0
		or int(game_state.affection_points.get("gil", 0)) != 2
		or not game_state.gifts_given_today.has("gil")
	):
		push_error("Selecting a cooked stack should deliver the gift and apply its reaction.")
		quit(1)
		return

	game_state.affection_points["casha"] = 10
	game_state.npc_heart_levels["casha"] = 1
	game_state.add_item("sayur_asam_segar", 1, game_state.current_day, 3)
	var new_menu: Dictionary = affection_system.give_food(
		"casha",
		"sayur_asam_segar",
		game_state.current_day,
		3
	)
	if new_menu.get("reaction") != "suka" or int(new_menu.get("points_gained", 0)) != 3:
		push_error("Casha should like a menu she has not received before.")
		quit(1)
		return
	for expected_reaction in ["tidak_suka", "tidak_suka", "benci"]:
		time_system.sleep()
		game_state.add_item("sayur_asam_segar", 1, game_state.current_day, 3)
		var repeated_menu: Dictionary = affection_system.give_food(
			"casha",
			"sayur_asam_segar",
			game_state.current_day,
			3
		)
		if repeated_menu.get("reaction") != expected_reaction:
			push_error("Repeated menu dislike streak should progress to hate.")
			quit(1)
			return
	if int(game_state.affection_points.get("casha", 0)) != 10:
		push_error("Hate should deduct three points without crossing the current heart floor.")
		quit(1)
		return

	game_state.affection_points["giral"] = 39
	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 3)
	var giral_second_heart: Dictionary = affection_system.give_food(
		"giral",
		"sup_sayur_bening",
		game_state.current_day,
		3,
		true
	)
	if (
		int(giral_second_heart.get("heart_level", 0)) != 2
		or int(game_state.affection_points.get("giral", 0)) != 47
		or int(game_state.get_npc_heart_level("giral")) != 2
	):
		push_error("A special gift should apply +8 and unlock cumulative heart rewards.")
		quit(1)
		return
	var giral := SHOP_NPC_SCENE.instantiate() as HearthwoodShopNPC
	giral.configure_named("giral", "res://data/npcs/giral.json", [])
	root.add_child(giral)
	await process_frame
	if giral.get_discount_percent() != 5:
		push_error("A merchant should receive the five-percent heart-two discount.")
		quit(1)
		return

	time_system.sleep()
	game_state.affection_points["giral"] = 82
	game_state.npc_heart_levels["giral"] = 2
	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 3)
	var giral_third_heart: Dictionary = affection_system.give_food(
		"giral",
		"sup_sayur_bening",
		game_state.current_day,
		3,
		true
	)
	if (
		int(giral_third_heart.get("heart_level", 0)) != 3
		or int(game_state.affection_points.get("giral", 0)) != 90
		or not game_state.unlocked_recipes.has("ikan_bakar_rempah")
		or giral.get_discount_percent() != 15
	):
		push_error("Heart three should unlock the recipe and merchant discount.")
		quit(1)
		return

	game_state.affection_points["vea"] = 5
	for expected_reaction in ["tidak_suka", "tidak_suka", "benci"]:
		time_system.sleep()
		game_state.add_item("nasi_goreng_hutan", 1, game_state.current_day, 3)
		var disliked_dish: Dictionary = affection_system.give_food(
			"vea",
			"nasi_goreng_hutan",
			game_state.current_day,
			3
		)
		if disliked_dish.get("reaction") != expected_reaction:
			push_error("Disliked food should trigger hate after three consecutive gifts.")
			quit(1)
			return
	if int(game_state.affection_points.get("vea", 0)) != 2:
		push_error("Hate should deduct three points without dropping below the current heart floor.")
		quit(1)
		return

	game_state.current_weather = "dingin"
	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 3)
	var cold_weather_gift: Dictionary = affection_system.give_food(
		"nue",
		"sup_sayur_bening",
		game_state.current_day,
		3
	)
	if cold_weather_gift.get("reaction") != "spesial" or int(
		cold_weather_gift.get("points_gained", 0)
	) != 8:
		push_error("Warm food should be special during cold weather.")
		quit(1)
		return

	time_system.sleep()
	game_state.current_weather = "cerah"
	game_state.npc_recently_returned_from_forest["rast"] = true
	game_state.add_item("nasi_goreng_hutan", 1, game_state.current_day, 3)
	var rast_return_gift: Dictionary = affection_system.give_food(
		"rast",
		"nasi_goreng_hutan",
		game_state.current_day,
		3
	)
	if (
		rast_return_gift.get("reaction") != "spesial"
		or int(rast_return_gift.get("points_gained", 0)) != 8
		or game_state.npc_recently_returned_from_forest.has("rast")
	):
		push_error("Any food should be special once after Rast returns from the forest.")
		quit(1)
		return

	time_system.sleep()
	game_state.affection_points["rast"] = 82
	game_state.npc_heart_levels["rast"] = 2
	game_state.npc_recently_returned_from_forest["rast"] = true
	game_state.add_item("nasi_goreng_hutan", 1, game_state.current_day, 3)
	var rast_quest_reward: Dictionary = affection_system.give_food(
		"rast",
		"nasi_goreng_hutan",
		game_state.current_day,
		3
	)
	if (
		int(rast_quest_reward.get("heart_level", 0)) != 3
		or not str(rast_quest_reward.get("pesan", "")).contains("ekspedisi kayu")
	):
		push_error("Heart three should reveal Rast's expedition story reward.")
		quit(1)
		return

	print("Gift flow, daily limits, reactions, quality, hearts, rewards, and discounts passed.")
	quit(0)


func _find_button(parent: Node, button_text: String) -> Button:
	for child in parent.get_children():
		if child is Button and button_text in child.text:
			return child
		var nested_button := _find_button(child, button_text)
		if nested_button != null:
			return nested_button
	return null


func _get_stack_count(game_state: Variant, item_id: String, cooked_on_day: int, quality: int) -> int:
	for stack in game_state.inventory:
		if (
			str(stack.get("id", "")) == item_id
			and int(stack.get("tanggal_masak", -1)) == cooked_on_day
			and int(stack.get("kualitas", 0)) == quality
		):
			return int(stack.get("jumlah", 0))
	return 0
