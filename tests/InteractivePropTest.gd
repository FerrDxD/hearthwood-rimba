# tests/InteractivePropTest.gd
extends SceneTree


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- Running InteractivePropTest ---")
	test_base_interactive_prop()
	test_fruit_tree()
	test_fresh_spring()
	test_inspectable_hollow()
	test_daily_reset_across_props()
	print("InteractivePropTest passed.")
	quit(0)


func test_base_interactive_prop() -> void:
	print("Testing Base InteractiveProp...")
	var prop_script = load("res://scripts/world/InteractiveProp.gd")
	assert(prop_script != null, "InteractiveProp.gd must exist")
	
	var prop = prop_script.new()
	assert(prop is Area2D, "InteractiveProp must extend Area2D")
	assert("prop_id" in prop, "Prop must have prop_id")
	assert("prop_type" in prop, "Prop must have prop_type")
	assert("daily_interacted" in prop, "Prop must have daily_interacted")
	assert("interaction_prompt" in prop, "Prop must have interaction_prompt")
	assert("interaction_radius" in prop, "Prop must have interaction_radius")
	
	prop.prop_id = "test_prop_1"
	prop.prop_type = "generic"
	assert(prop.can_interact() == true, "New prop should be interactable")
	
	var signal_received: Array = []
	prop.interacted.connect(func(res: Dictionary): signal_received.append(res))
	
	var res = prop.interact()
	assert(res["success"] == true, "Base interact should succeed")
	assert(prop.daily_interacted == true, "daily_interacted must be true after interaction")
	assert(prop.can_interact() == false, "can_interact must be false after interaction")
	assert(signal_received.size() == 1, "interacted signal must be emitted")
	assert(signal_received[0]["success"] == true, "signal payload must match result")
	
	# Repeat interaction on same day
	var res_repeat = prop.interact()
	assert(res_repeat["success"] == false, "Repeat interact should fail")
	
	# Daily reset
	var reset_received: Array = [false]
	prop.daily_reset.connect(func(): reset_received[0] = true)
	prop.reset_daily()
	assert(prop.daily_interacted == false, "daily_interacted must reset to false")
	assert(prop.can_interact() == true, "can_interact must be true after reset")
	assert(reset_received[0] == true, "daily_reset signal must be emitted")
	
	# Collision setup
	root.add_child(prop)
	assert(prop.get_node_or_null("CollisionShape2D") != null, "Area2D must have a CollisionShape2D on ready")
	var col_shape = prop.get_node("CollisionShape2D") as CollisionShape2D
	assert(col_shape.shape is CircleShape2D, "Collision shape should be CircleShape2D")
	assert(is_equal_approx((col_shape.shape as CircleShape2D).radius, prop.interaction_radius), "Radius should match interaction_radius")
	
	root.remove_child(prop)
	prop.free()
	print("Base InteractiveProp passed.")


func test_fruit_tree() -> void:
	print("Testing FruitTree...")
	var tree_script = load("res://scripts/world/FruitTree.gd")
	assert(tree_script != null, "FruitTree.gd must exist")
	
	var tree = tree_script.new()
	assert("fruit_item_id" in tree, "FruitTree must have fruit_item_id")
	assert("min_drop" in tree, "FruitTree must have min_drop")
	assert("max_drop" in tree, "FruitTree must have max_drop")
	assert("has_fruit" in tree, "FruitTree must have has_fruit")
	
	tree.fruit_item_id = "buah_liar"
	tree.min_drop = 2
	tree.max_drop = 4
	assert(tree.has_fruit == true, "Tree must have fruit initially")
	assert(tree.can_interact() == true, "Tree must be interactable initially")
	
	var harvested_event: Array = []
	tree.fruit_harvested.connect(func(item_id: String, count: int):
		harvested_event.append({"item_id": item_id, "count": count})
	)
	
	root.add_child(tree)
	var res = tree.interact()
	assert(res["success"] == true, "First fruit harvest must succeed")
	assert(tree.daily_interacted == true, "daily_interacted must be true")
	assert(tree.has_fruit == false, "has_fruit must be false after harvest")
	assert(tree.can_interact() == false, "can_interact must be false after harvest")
	
	assert(harvested_event.size() == 1, "fruit_harvested signal must be emitted")
	assert(harvested_event[0]["item_id"] == "buah_liar", "Harvested item ID must be buah_liar")
	assert(harvested_event[0]["count"] >= 2 and harvested_event[0]["count"] <= 4, "Harvest count must be between min and max")
	assert(res["data"]["count"] == harvested_event[0]["count"], "Result count must match signal")
	
	# Attempt to harvest again on same day
	var repeat_res = tree.interact()
	assert(repeat_res["success"] == false, "Harvesting again on same day must fail")
	assert(repeat_res["message"] == "Pohon ini sudah dipetik hari ini. Tunggu esok hari.", "Failure message must match spec")
	
	# Daily reset
	tree.reset_daily()
	assert(tree.daily_interacted == false, "daily_interacted must be false after reset")
	assert(tree.has_fruit == true, "has_fruit must be restored to true after reset")
	assert(tree.can_interact() == true, "Tree can_interact must be true after reset")
	
	root.remove_child(tree)
	tree.free()
	print("FruitTree passed.")


func test_fresh_spring() -> void:
	print("Testing FreshSpring...")
	var spring_script = load("res://scripts/world/FreshSpring.gd")
	assert(spring_script != null, "FreshSpring.gd must exist")
	
	var spring = spring_script.new()
	assert("energy_restore" in spring, "FreshSpring must have energy_restore")
	assert(spring.energy_restore == 10, "Default energy_restore must be 10")
	
	root.add_child(spring)
	
	var game_state = root.get_node_or_null("GameState")
	assert(game_state != null, "GameState must be present")
	game_state.energy = 50
	
	var spring_used_events: Array = []
	spring.spring_used.connect(func(amount: int): spring_used_events.append(amount))
	
	var res = spring.interact()
	assert(res["success"] == true, "FreshSpring interaction must succeed")
	assert(spring.daily_interacted == true, "FreshSpring daily_interacted must be true")
	assert(game_state.energy == 60, "GameState energy must increase by 10 (from 50 to 60)")
	assert(spring_used_events.size() == 1 and spring_used_events[0] == 10, "spring_used signal must be emitted with 10")
	
	# Repeat interaction on same day
	var repeat_res = spring.interact()
	assert(repeat_res["success"] == false, "Repeat spring use must fail on same day")
	assert(repeat_res["message"] == "Kamu sudah membasuh muka hari ini. Airnya terasa sejuk mengalir.", "Spring repeat message must match spec")
	assert(game_state.energy == 60, "Energy must not increase again on repeat interaction")
	
	# Daily reset
	spring.reset_daily()
	assert(spring.daily_interacted == false, "daily_interacted must be reset")
	assert(spring.can_interact() == true, "Spring must be interactable after reset")
	
	root.remove_child(spring)
	spring.free()
	print("FreshSpring passed.")


func test_inspectable_hollow() -> void:
	print("Testing InspectableHollow...")
	var hollow_script = load("res://scripts/world/InspectableHollow.gd")
	assert(hollow_script != null, "InspectableHollow.gd must exist")
	
	var hollow = hollow_script.new()
	assert("possible_loot" in hollow, "InspectableHollow must have possible_loot")
	assert("hollow_name" in hollow, "InspectableHollow must have hollow_name")
	assert(hollow.possible_loot == ["jamur_hutan", "akar_rempah", "kayu"], "Default possible loot must match spec")
	assert(hollow.hollow_name == "Tunggul Berongga", "Default hollow name must match spec")
	
	root.add_child(hollow)
	
	var loot_events: Array = []
	hollow.loot_found.connect(func(item_id: String): loot_events.append(item_id))
	
	var res = hollow.interact()
	assert(res["success"] == true, "First inspection must succeed")
	assert(hollow.daily_interacted == true, "daily_interacted must be true")
	assert(loot_events.size() == 1, "loot_found signal must be emitted")
	assert(loot_events[0] in hollow.possible_loot, "Found loot must be from possible_loot")
	assert(res["data"]["item_id"] == loot_events[0], "Result data item_id must match loot")
	
	# Repeat inspection on same day
	var repeat_res = hollow.interact()
	assert(repeat_res["success"] == false, "Repeat inspection must fail on same day")
	assert(repeat_res["message"] == "Ceruk ini sudah kosong untuk hari ini.", "Hollow repeat message must match spec")
	
	# Daily reset
	hollow.reset_daily()
	assert(hollow.daily_interacted == false, "daily_interacted must be false after reset")
	assert(hollow.can_interact() == true, "Hollow must be interactable after reset")
	
	root.remove_child(hollow)
	hollow.free()
	print("InspectableHollow passed.")


func test_daily_reset_across_props() -> void:
	print("Testing Daily Reset Across Props...")
	var tree_script = load("res://scripts/world/FruitTree.gd")
	var spring_script = load("res://scripts/world/FreshSpring.gd")
	var hollow_script = load("res://scripts/world/InspectableHollow.gd")
	
	var tree = tree_script.new()
	var spring = spring_script.new()
	var hollow = hollow_script.new()
	
	root.add_child(tree)
	root.add_child(spring)
	root.add_child(hollow)
	
	tree.interact()
	spring.interact()
	hollow.interact()
	
	assert(tree.daily_interacted == true, "Tree interacted")
	assert(spring.daily_interacted == true, "Spring interacted")
	assert(hollow.daily_interacted == true, "Hollow interacted")
	
	var props = [tree, spring, hollow]
	for p in props:
		p.reset_daily()
		assert(p.daily_interacted == false, "Prop must be reset")
		assert(p.can_interact() == true, "Prop can interact after reset")
	
	root.remove_child(tree)
	root.remove_child(spring)
	root.remove_child(hollow)
	tree.free()
	spring.free()
	hollow.free()
	print("Daily Reset Across Props passed.")
