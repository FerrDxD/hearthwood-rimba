extends SceneTree

const UI_SCENE_PATHS: Array[String] = [
	"res://scenes/CookingUI.tscn",
	"res://scenes/InventoryUI.tscn",
	"res://scenes/DialogUI.tscn",
	"res://scenes/ShopUI.tscn",
	"res://scenes/GiftUI.tscn",
	"res://scenes/WarungUI.tscn",
	"res://scenes/PauseMenu.tscn",
]

var _ui_scenes: Array[Node] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var game_state = root.get_node("GameState")
	if (
		not game_state.start_new_game("Sentuh")
		or not game_state.add_item("sup_sayur_bening", 1, game_state.current_day, 2)
	):
		push_error("Could not initialize touch-target test state.")
		quit(1)
		return

	for scene_path in UI_SCENE_PATHS:
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene == null:
			push_error("Could not load UI scene for touch-target testing: %s" % scene_path)
			quit(1)
			return
		var ui_scene := packed_scene.instantiate()
		root.add_child(ui_scene)
		_ui_scenes.append(ui_scene)
	await process_frame

	var shop_ui := root.find_child("ShopUI", true, false) as HearthwoodShopUI
	if shop_ui == null or not shop_ui.open_shop("giral", "Giral", 0):
		push_error("Could not open the shop UI touch-target fixture.")
		quit(1)
		return
	var gift_ui := root.find_child("GiftUI", true, false) as HearthwoodGiftUI
	if gift_ui == null:
		push_error("Could not open the gift UI touch-target fixture.")
		quit(1)
		return
	gift_ui.open_gifts("rast", "Rast")
	var dialog_ui := root.find_child("DialogUI", true, false) as HearthwoodDialogUI
	if dialog_ui == null:
		push_error("Could not open the dialog UI touch-target fixture.")
		quit(1)
		return
	dialog_ui.open_dialog("Rast", "Penebang kayu", "Ayo kita berbincang.")

	var button_count := 0
	for ui_scene in _ui_scenes:
		var result := _verify_button_targets(ui_scene)
		if not bool(result.get("valid", false)):
			push_error(str(result.get("pesan", "UI touch target failed.")))
			quit(1)
			return
		button_count += int(result["button_count"])
	if button_count == 0:
		push_error("Touch-target test did not inspect any UI buttons.")
		quit(1)
		return

	print("%d UI buttons meet the minimum 44x44 touch target." % button_count)
	quit(0)


func _verify_button_targets(parent: Node) -> Dictionary:
	var button_count := 0
	for child in parent.get_children():
		if child is Button:
			button_count += 1
			var button := child as Button
			var minimum_size: Vector2 = button.get_combined_minimum_size()
			if minimum_size.x < 44.0 or minimum_size.y < 44.0:
				return {
					"valid": false,
					"pesan": "Button '%s' is smaller than 44x44 (%.1fx%.1f)." % [
						child.get_path(),
						minimum_size.x,
						minimum_size.y,
					],
				}
		var nested_result := _verify_button_targets(child)
		if not bool(nested_result.get("valid", false)):
			return nested_result
		button_count += int(nested_result.get("button_count", 0))
	return {"valid": true, "button_count": button_count}
