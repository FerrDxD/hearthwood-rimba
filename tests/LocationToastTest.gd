# tests/LocationToastTest.gd
extends SceneTree

func _init() -> void:
	var script = load("res://scripts/ui/LocationToastUI.gd")
	assert(script != null, "LocationToastUI.gd must exist")
	var scene = load("res://scenes/LocationToastUI.tscn")
	assert(scene != null, "LocationToastUI.tscn must exist")
	
	var toast = scene.instantiate()
	assert(toast.has_method("show_location"), "Toast must have show_location method")
	assert(toast.has_method("get_location_text"), "Toast must have get_location_text method")
	assert(toast.has_method("is_visible_or_animating"), "Toast must have is_visible_or_animating method")
	
	toast.show_location("Pos Penebang Kayu")
	assert(toast.get_location_text() == "Pos Penebang Kayu", "Location text must match")
	assert(toast.is_visible_or_animating(), "Toast must be visible when shown")
	
	# Verify integration with Main scene
	var main_scene = load("res://scenes/Main.tscn")
	var main = main_scene.instantiate()
	var toast_node = main.get_node_or_null("UI/LocationToastUI")
	if toast_node == null:
		toast_node = main.get_node_or_null("LocationToastUI")
	assert(toast_node != null, "Main must contain LocationToastUI node")
	
	toast.free()
	main.free()
	print("LocationToastTest passed.")
	quit(0)
