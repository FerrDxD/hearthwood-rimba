extends SceneTree

const COOKING_SYSTEM_SCENE: PackedScene = preload("res://scenes/CookingSystem.tscn")
const COOKING_UI_SCENE: PackedScene = preload("res://scenes/CookingUI.tscn")
const RECIPE_IDS: Array[String] = [
	"sup_sayur_bening",
	"ikan_bakar_rempah",
	"bubur_hangat_hutan",
	"sambal_tumisan_pedas",
	"sayur_asam_segar",
	"kue_manis_liar",
	"nasi_goreng_hutan",
	"hidangan_rempah_khusus",
]


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	var time_system = root.get_node("TimeSystem")
	game_state.inventory.clear()
	game_state.unlocked_recipes.clear()
	game_state.unlocked_recipes.append("sup_sayur_bening")
	game_state.unlocked_recipes.append("bubur_hangat_hutan")
	game_state.current_day = 1
	game_state.current_hour = 6
	game_state.current_minute = 0
	game_state.energy = game_state.MAX_ENERGY
	game_state.warung_tier = 0
	game_state.coins = game_state.STARTING_COINS

	var cooking_system := COOKING_SYSTEM_SCENE.instantiate() as HearthwoodCookingSystem
	root.add_child(cooking_system)
	await process_frame
	if cooking_system.get_unlocked_recipe_ids().size() != 2:
		push_error("Only the two default recipes should be unlocked at the start.")
		quit(1)
		return
	if (
		cooking_system.get_max_portions("api_unggun") != 2
		or cooking_system.get_max_portions("tungku") != 3
		or cooking_system.get_max_portions("dapur_warteg") != 5
	):
		push_error("Cooking tool portion limits should match the milestone.")
		quit(1)
		return
	for recipe_id in RECIPE_IDS:
		if cooking_system.get_recipe(recipe_id).is_empty():
			push_error("Recipe data is missing: %s" % recipe_id)
			quit(1)
			return

	var missing_ingredients := cooking_system.preview_cooking(
		"sup_sayur_bening",
		1,
		"api_unggun"
	)
	if bool(missing_ingredients.get("valid", true)):
		push_error("Cooking should require every recipe ingredient.")
		quit(1)
		return

	game_state.add_item("sayur_liar", 4)
	game_state.add_item("garam", 4)
	if bool(cooking_system.preview_cooking("sup_sayur_bening", 3, "api_unggun").get(
		"valid", true
	)):
		push_error("A campfire should not allow more than two portions.")
		quit(1)
		return
	if bool(cooking_system.preview_cooking("sup_sayur_bening", 1, "tungku").get(
		"valid", true
	)):
		push_error("Unupgraded tools should not be available.")
		quit(1)
		return
	game_state.energy = 9
	if bool(cooking_system.preview_cooking("sup_sayur_bening", 2, "api_unggun").get(
		"valid", true
	)) or game_state.get_item_count("sayur_liar") != 4:
		push_error("Insufficient energy should prevent cooking without consuming ingredients.")
		quit(1)
		return
	game_state.energy = game_state.MAX_ENERGY

	var first_batch := cooking_system.cook("sup_sayur_bening", 2, "api_unggun", "green")
	if (
		not bool(first_batch.get("valid", false))
		or int(first_batch.get("kualitas", 0)) != 3
		or int(first_batch.get("tanggal_masak", 0)) != game_state.current_day
	):
		push_error("A successful green-timing cook should produce dated three-star food.")
		quit(1)
		return
	var second_batch := cooking_system.cook("sup_sayur_bening", 1, "api_unggun", "red")
	if (
		not bool(second_batch.get("valid", false))
		or int(second_batch.get("kualitas", 0)) != 1
	):
		push_error("A failed timing result should reduce quality to one star.")
		quit(1)
		return
	game_state.add_item("sayur_liar")
	game_state.add_item("garam")
	var third_batch := cooking_system.cook("sup_sayur_bening", 1, "api_unggun", "yellow")
	if (
		not bool(third_batch.get("valid", false))
		or int(third_batch.get("kualitas", 0)) != 2
	):
		push_error("A medium timing result should preserve the two-star base quality.")
		quit(1)
		return
	if game_state.energy != 80 or game_state.get_item_count("sup_sayur_bening") != 4:
		push_error("Cooking should consume five energy and ingredients per portion.")
		quit(1)
		return

	game_state.add_item("ikan_sungai", 2)
	game_state.add_item("akar_rempah", 2)
	game_state.add_item("daun_hutan")
	game_state.add_item("buah_liar", 2)
	game_state.add_item("sayur_liar", 4)
	game_state.add_item("garam", 4)
	game_state.add_item("beras", 2)
	game_state.add_item("telur")
	game_state.purchase_item("minyak", 20)
	game_state.add_item("minyak")
	game_state.purchase_item("tepung", 20)
	game_state.purchase_item("rempah_eksklusif", 40)
	if cooking_system.get_unlocked_recipe_ids().size() != 8:
		push_error("Finding or buying unlock ingredients should unlock all recipes.")
		quit(1)
		return
	game_state.warung_tier = 2
	for recipe_id in RECIPE_IDS:
		if recipe_id == "sup_sayur_bening":
			continue
		var recipe: Dictionary = cooking_system.get_recipe(recipe_id)
		var outcome := cooking_system.cook(
			recipe_id,
			1,
			str(recipe["alat_minimum"]),
			"green"
		)
		if not bool(outcome.get("valid", false)):
			push_error("Recipe failed with its required tool: %s (%s)" % [
				recipe_id,
				str(outcome.get("pesan", "")),
			])
			quit(1)
			return

	var cooking_ui := COOKING_UI_SCENE.instantiate() as HearthwoodCookingUI
	root.add_child(cooking_ui)
	await process_frame
	cooking_ui.set_cooking_system(cooking_system)
	cooking_ui.open_cooking(cooking_system)
	if not cooking_ui.is_open() or _find_button(cooking_ui, "Masak") == null:
		push_error("Cooking UI should open with a usable cooking action.")
		quit(1)
		return

	time_system.sleep()
	if _get_quality(game_state, "sup_sayur_bening", 3) != 0:
		push_error("Cooked food quality should decrease by one star each day.")
		quit(1)
		return
	if (
		_get_quality(game_state, "sup_sayur_bening", 2) != 2
		or _get_stack_count(game_state, "sup_sayur_bening", 2) != 1
	):
		push_error("Aging food should merge matching quality and cooking-date stacks.")
		quit(1)
		return
	time_system.sleep()
	if _get_quality(game_state, "sup_sayur_bening", 1) != 4:
		push_error("Remaining cooked food should reach one star on its third day.")
		quit(1)
		return
	time_system.sleep()
	if game_state.get_item_count("sup_sayur_bening") != 0:
		push_error("Food should be removed after three days, on day four.")
		quit(1)
		return

	print("Recipe, tool, portion, energy, unlock, quality, and freshness tests passed.")
	quit(0)


func _get_quality(game_state: Variant, item_id: String, quality: int) -> int:
	var quantity := 0
	for stack in game_state.inventory:
		if str(stack.get("id", "")) == item_id and int(stack.get("kualitas", 0)) == quality:
			quantity += int(stack.get("jumlah", 0))
	return quantity


func _get_stack_count(game_state: Variant, item_id: String, quality: int) -> int:
	var stack_count := 0
	for stack in game_state.inventory:
		if str(stack.get("id", "")) == item_id and int(stack.get("kualitas", 0)) == quality:
			stack_count += 1
	return stack_count


func _find_button(parent: Node, button_text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == button_text:
			return child
		var nested_button := _find_button(child, button_text)
		if nested_button != null:
			return nested_button
	return null
