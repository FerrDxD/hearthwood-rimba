extends SceneTree

const AFFECTION_SYSTEM_SCENE: PackedScene = preload("res://scenes/AffectionSystem.tscn")
const COOKING_SYSTEM_SCENE: PackedScene = preload("res://scenes/CookingSystem.tscn")
const DIALOG_UI_SCENE: PackedScene = preload("res://scenes/DialogUI.tscn")
const GIFT_UI_SCENE: PackedScene = preload("res://scenes/GiftUI.tscn")
const WARUNG_SYSTEM_SCENE: PackedScene = preload("res://scenes/WarungSystem.tscn")
const WARUNG_UI_SCENE: PackedScene = preload("res://scenes/WarungUI.tscn")
const WORLD_SCENE: PackedScene = preload("res://scenes/tilemap/MainTileset.tscn")
const WOOD_PICKUP_POSITION: Vector2 = Vector2(160.0, 680.0)
const STONE_PICKUP_POSITION: Vector2 = Vector2(-150.0, 1050.0)


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	game_state.inventory.clear()
	game_state.unlocked_recipes.clear()
	for recipe_id in [
		"sup_sayur_bening",
		"bubur_hangat_hutan",
		"ikan_bakar_rempah",
		"nasi_goreng_hutan",
		"sambal_tumisan_pedas",
		"sayur_asam_segar",
		"kue_manis_liar",
		"hidangan_rempah_khusus",
	]:
		game_state.unlocked_recipes.append(recipe_id)
	game_state.warung_tier = 0
	game_state.reputation = 0
	game_state.coins = 499
	game_state.business_permits.clear()
	game_state.customers_served_today.clear()
	game_state.gifts_given_today.clear()
	game_state.affection_points.clear()
	game_state.npc_heart_levels.clear()
	game_state.npc_gift_history.clear()
	game_state.disliked_gift_streaks.clear()
	game_state.current_day = 1
	game_state.current_hour = 6
	game_state.current_minute = 0
	game_state.energy = game_state.MAX_ENERGY

	var cooking_system := COOKING_SYSTEM_SCENE.instantiate() as HearthwoodCookingSystem
	root.add_child(cooking_system)
	var affection_system := AFFECTION_SYSTEM_SCENE.instantiate() as HearthwoodAffectionSystem
	affection_system.set_cooking_system(cooking_system)
	root.add_child(affection_system)
	var warung_system := WARUNG_SYSTEM_SCENE.instantiate() as HearthwoodWarungSystem
	warung_system.set_systems(cooking_system, affection_system)
	root.add_child(warung_system)
	var world := WORLD_SCENE.instantiate() as HearthwoodWorld
	root.add_child(world)
	await process_frame

	var initial_tier := warung_system.get_current_tier()
	if (
		int(initial_tier.get("kapasitas_pelanggan", 0)) != 2
		or cooking_system.get_available_tool_ids() != ["api_unggun"]
		or cooking_system.get_max_portions("api_unggun") != 2
		or cooking_system.is_recipe_available("sayur_asam_segar")
		or not warung_system.is_customer_available("vea")
		or not warung_system.is_customer_available("gil")
		or warung_system.is_customer_available("jev")
	):
		push_error("Tier zero should expose its tools, recipes, and two starting customers.")
		quit(1)
		return

	var wood_pickup := world.get_closest_item_pickup(WOOD_PICKUP_POSITION, 2.0)
	var stone_pickup := world.get_closest_item_pickup(STONE_PICKUP_POSITION, 2.0)
	if (
		wood_pickup == null
		or stone_pickup == null
		or not world.collect_item_pickup(wood_pickup)
		or not world.collect_item_pickup(stone_pickup)
		or game_state.get_item_count("kayu") != 1
		or game_state.get_item_count("batu") != 1
	):
		push_error("Wood and stone upgrade materials should be collectible in the forest.")
		quit(1)
		return

	if bool(warung_system.upgrade_tier().get("valid", true)):
		push_error("A tier upgrade should fail without its reputation requirement.")
		quit(1)
		return
	game_state.reputation = 10
	if bool(warung_system.upgrade_tier().get("valid", true)) or game_state.coins != 499:
		push_error("A tier upgrade should fail without its coin requirement.")
		quit(1)
		return
	game_state.coins = 500
	game_state.remove_item("kayu")
	if (
		bool(warung_system.upgrade_tier().get("valid", true))
		or game_state.coins != 500
		or game_state.get_item_count("batu") != 1
	):
		push_error("A failed material check should preserve upgrade resources.")
		quit(1)
		return
	game_state.add_item("kayu")

	game_state.add_item("nasi_goreng_hutan", 1, game_state.current_day, 3)
	var gift_ui := GIFT_UI_SCENE.instantiate() as HearthwoodGiftUI
	gift_ui.set_affection_system(affection_system)
	gift_ui.set_warung_system(warung_system)
	root.add_child(gift_ui)
	await process_frame
	gift_ui.open_gifts("vea", "Vea", true)
	if not _contains_text(gift_ui, "Pilih masakan yang disukai pelanggan"):
		push_error("Customer service UI should explain that customers need a liked dish.")
		quit(1)
		return
	var refused_food_button := _find_button(gift_ui, "Nasi Goreng Hutan")
	if refused_food_button == null:
		push_error("Customer service UI should list cooked inventory.")
		quit(1)
		return
	refused_food_button.pressed.emit()
	if (
		game_state.get_item_count("nasi_goreng_hutan") != 1
		or game_state.customers_served_today.has("vea")
		or game_state.coins != 500
		or game_state.reputation != 10
	):
		push_error("A disliked customer order should be rejected without consuming food or rewards.")
		quit(1)
		return

	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 3)
	var soup_button := _find_button(gift_ui, "Sup Sayur Bening")
	if soup_button == null:
		push_error("Customer service UI should refresh when cooked food is added.")
		quit(1)
		return
	soup_button.pressed.emit()
	if (
		game_state.get_item_count("sup_sayur_bening") != 0
		or game_state.get_item_count("nasi_goreng_hutan") != 1
		or not game_state.customers_served_today.has("vea")
		or game_state.coins != 560
		or game_state.reputation != 11
		or int(game_state.affection_points.get("vea", 0)) != 3
	):
		push_error("A liked order should consume one portion and award its sale and affection.")
		quit(1)
		return

	game_state.add_item("bubur_hangat_hutan", 1, game_state.current_day, 2)
	var gil_order := warung_system.serve_customer(
		"gil",
		"bubur_hangat_hutan",
		game_state.current_day,
		2
	)
	if (
		not bool(gil_order.get("valid", false))
		or game_state.get_item_count("bubur_hangat_hutan") != 0
		or game_state.coins != 600
		or game_state.reputation != 12
		or game_state.customers_served_today.size() != 2
	):
		push_error("Tier zero should serve two satisfied customers within its daily capacity.")
		quit(1)
		return

	var tier_one_result := warung_system.upgrade_tier()
	if (
		not bool(tier_one_result.get("valid", false))
		or game_state.warung_tier != 1
		or not game_state.business_permits.has(1)
		or game_state.coins != 100
		or game_state.get_item_count("kayu") != 0
		or game_state.get_item_count("batu") != 1
		or cooking_system.get_available_tool_ids() != ["api_unggun", "tungku"]
		or cooking_system.get_max_portions("tungku") != 3
		or not cooking_system.is_recipe_available("sayur_asam_segar")
		or cooking_system.is_recipe_available("hidangan_rempah_khusus")
		or not warung_system.is_customer_available("jev")
		or not warung_system.is_customer_available("nue")
		or not warung_system.is_customer_available("rave")
	):
		push_error("Tier one should grant its permit, tool, recipe access, and new customers.")
		quit(1)
		return

	var warung_ui := WARUNG_UI_SCENE.instantiate() as HearthwoodWarungUI
	warung_ui.set_warung_system(warung_system)
	root.add_child(warung_ui)
	warung_ui.open_upgrade()
	if not _contains_text(warung_ui, "maks. 5 porsi") or not _contains_text(
		warung_ui, "Pelanggan baru: 2"
	):
		push_error("Upgrade UI should preview the next tool, portions, and customers.")
		quit(1)
		return
	warung_ui.close_upgrade()
	var dialog_ui := DIALOG_UI_SCENE.instantiate() as HearthwoodDialogUI
	root.add_child(dialog_ui)
	await process_frame
	dialog_ui.upgrade_requested.connect(warung_ui.open_upgrade)
	dialog_ui.open_dialog("Veral", "Kepala Desa", "Izin usaha siap diproses.", "veral", false, true)
	var permit_button := _find_button(dialog_ui, "Izin & upgrade warung")
	if permit_button == null or not permit_button.visible:
		push_error("Veral's dialogue should expose the business-permit action.")
		quit(1)
		return
	permit_button.pressed.emit()
	if dialog_ui.is_open() or not warung_ui.is_open():
		push_error("Veral's permit action should open the warung upgrade interface.")
		quit(1)
		return
	warung_ui.close_upgrade()

	time_system.sleep()
	await process_frame
	if not game_state.customers_served_today.is_empty():
		push_error("Daily customer service records should reset after sleep.")
		quit(1)
		return
	var second_wood_pickup := world.get_closest_item_pickup(WOOD_PICKUP_POSITION, 2.0)
	if (
		second_wood_pickup == null
		or not world.collect_item_pickup(second_wood_pickup)
		or game_state.get_item_count("kayu") != 1
	):
		push_error("Upgrade wood should respawn in the forest after sleeping.")
		quit(1)
		return

	game_state.add_item("nasi_goreng_hutan", 1, game_state.current_day, 3)
	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 3)
	var second_day_refusal := warung_system.serve_customer(
		"vea",
		"nasi_goreng_hutan",
		game_state.current_day,
		3
	)
	if (
		bool(second_day_refusal.get("valid", true))
		or game_state.get_item_count("nasi_goreng_hutan") != 2
		or game_state.customers_served_today.has("vea")
	):
		push_error("Tier-one customer service should reject disliked food without consuming it.")
		quit(1)
		return
	var tier_one_orders := [
		{"npc": "vea", "item": "sup_sayur_bening", "quality": 3},
		{"npc": "jev", "item": "ikan_bakar_rempah", "quality": 2},
		{"npc": "nue", "item": "sayur_asam_segar", "quality": 2},
		{"npc": "rave", "item": "sambal_tumisan_pedas", "quality": 2},
	]
	for order in tier_one_orders:
		var item_id := str(order["item"])
		var quality := int(order["quality"])
		if not _has_stack(game_state, item_id, game_state.current_day, quality):
			game_state.add_item(item_id, 1, game_state.current_day, quality)
		var outcome: Dictionary = warung_system.serve_customer(
			str(order["npc"]),
			item_id,
			game_state.current_day,
			quality
		)
		if not bool(outcome.get("valid", false)):
			push_error("Tier-one customer order failed: %s (%s)" % [
				str(order["npc"]),
				str(outcome.get("pesan", "")),
			])
			quit(1)
			return
	if (
		game_state.customers_served_today.size() != 4
		or warung_system.is_customer_available("gil")
	):
		push_error("Tier one should enforce its four-customer daily service capacity.")
		quit(1)
		return

	game_state.reputation = 24
	game_state.coins = 1499
	if bool(warung_system.get_upgrade_preview().get("valid", true)):
		push_error("Tier two should require its full reputation and coin thresholds.")
		quit(1)
		return
	game_state.reputation = 25
	if bool(warung_system.get_upgrade_preview().get("valid", true)):
		push_error("Tier two should not proceed below its coin cost.")
		quit(1)
		return
	game_state.coins = 1500
	var tier_two_result := warung_system.upgrade_tier()
	if (
		not bool(tier_two_result.get("valid", false))
		or game_state.warung_tier != 2
		or not game_state.business_permits.has(2)
		or game_state.coins != 0
		or game_state.get_item_count("kayu") != 0
		or game_state.get_item_count("batu") != 0
		or cooking_system.get_available_tool_ids() != [
			"api_unggun",
			"tungku",
			"dapur_warteg",
		]
		or cooking_system.get_max_portions("dapur_warteg") != 5
		or not cooking_system.is_recipe_available("hidangan_rempah_khusus")
		or not warung_system.is_customer_available("casha")
		or not warung_system.is_customer_available("kila")
		or int(warung_system.get_upgrade_preview().get("tier", {}).get("id", -1)) != 3
	):
		push_error("Tier two should unlock its permit, tools, and customers while tier three remains open.")
		quit(1)
		return

	var tier_two_orders := [
		{"npc": "casha", "item": "hidangan_rempah_khusus"},
		{"npc": "kila", "item": "kue_manis_liar"},
		{"npc": "gil", "item": "bubur_hangat_hutan"},
	]
	for order in tier_two_orders:
		var item_id := str(order["item"])
		game_state.add_item(item_id, 1, game_state.current_day, 2)
		var outcome: Dictionary = warung_system.serve_customer(
			str(order["npc"]),
			item_id,
			game_state.current_day,
			2
		)
		if not bool(outcome.get("valid", false)):
			push_error("Tier-two customer order failed: %s (%s)" % [
				str(order["npc"]),
				str(outcome.get("pesan", "")),
			])
			quit(1)
			return
	if (
		game_state.customers_served_today.size() != 7
		or warung_system.is_customer_available("gil")
		or int(warung_system.get_current_tier().get("kapasitas_pelanggan", 0)) != 7
	):
		push_error("Tier two should serve at most seven customers per day.")
		quit(1)
		return

	# Tier three: Warung Besar.
	game_state.reputation = 39
	game_state.coins = 3000
	game_state.add_item("kayu", 2)
	game_state.add_item("batu", 1)
	if bool(warung_system.get_upgrade_preview().get("valid", true)):
		push_error("Tier three should require forty reputation.")
		quit(1)
		return
	game_state.reputation = 40
	var tier_three_result := warung_system.upgrade_tier()
	if (
		not bool(tier_three_result.get("valid", false))
		or game_state.warung_tier != 3
		or not game_state.business_permits.has(3)
		or game_state.coins != 0
		or game_state.get_item_count("kayu") != 0
		or game_state.get_item_count("batu") != 0
		or cooking_system.get_available_tool_ids() != [
			"api_unggun",
			"tungku",
			"dapur_warteg",
			"dapur_besar",
		]
		or cooking_system.get_max_portions("dapur_besar") != 8
		or int(warung_system.get_current_tier().get("kapasitas_pelanggan", 0)) != 8
		or not warung_system.is_customer_available("rast")
		or not warung_system.is_customer_available("veral")
		or not warung_system.is_customer_available("arin")
		or bool(warung_system.get_upgrade_preview().get("valid", true))
	):
		push_error("Tier three should unlock dapur besar, eight portions, and quest customers.")
		quit(1)
		return

	game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 2)
	var eighth_order: Dictionary = warung_system.serve_customer(
		"rast",
		"sup_sayur_bening",
		game_state.current_day,
		2
	)
	if (
		not bool(eighth_order.get("valid", false))
		or game_state.customers_served_today.size() != 8
		or warung_system.is_customer_available("veral")
	):
		push_error("Tier three should sell eight portions and then close for the day.")
		quit(1)
		return

	time_system.sleep()
	if not game_state.customers_served_today.is_empty():
		push_error("Tier-two customer capacity should reset on the next day.")
		quit(1)
		return

	print("Warung upgrades, permits, tools, customer unlocks, sales, and daily limits passed.")
	quit(0)


func _find_button(parent: Node, button_text: String) -> Button:
	for child in parent.get_children():
		if child is Button and button_text in child.text:
			return child
		var nested_button := _find_button(child, button_text)
		if nested_button != null:
			return nested_button
	return null


func _contains_text(parent: Node, expected_text: String) -> bool:
	for child in parent.get_children():
		if child is Label and expected_text in child.text:
			return true
		if _contains_text(child, expected_text):
			return true
	return false


func _has_stack(game_state: Variant, item_id: String, cooked_on_day: int, quality: int) -> bool:
	for stack in game_state.inventory:
		if (
			str(stack.get("id", "")) == item_id
			and int(stack.get("tanggal_masak", -1)) == cooked_on_day
			and int(stack.get("kualitas", 0)) == quality
			and int(stack.get("jumlah", 0)) > 0
		):
			return true
	return false
