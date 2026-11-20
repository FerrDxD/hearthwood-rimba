# tests/WarungTablePropsTest.gd
extends SceneTree

const WARUNG_TABLE_SCRIPT = preload("res://scripts/world/WarungTable.gd")


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	print("--- Running WarungTablePropsTest ---")
	test_warung_table_lifecycle()
	test_order_bubble_standalone()
	print("WarungTablePropsTest passed.")
	quit(0)


func test_warung_table_lifecycle() -> void:
	var table = WARUNG_TABLE_SCRIPT.new()
	assert(table != null, "WarungTable instance must be created")
	assert(table is Area2D, "WarungTable must extend Area2D")
	
	table.table_id = "table_1"
	table.position = Vector2(1170.0, 520.0)
	root.add_child(table)
	
	# Verify collision shape
	var col_shape = table.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert(col_shape != null, "WarungTable must have a CollisionShape2D child")
	assert(col_shape.shape is CircleShape2D, "Collision shape must be CircleShape2D")
	assert(is_equal_approx((col_shape.shape as CircleShape2D).radius, 48.0), "Collision radius must be 48.0")
	
	# Check order bubble child
	var bubble = table.get_node_or_null("OrderBubble")
	assert(bubble != null, "WarungTable must have an OrderBubble child")
	assert(bubble.visible == false, "OrderBubble must be hidden initially")
	
	# Initial state
	assert(table.current_state == table.TableState.EMPTY, "Initial table state must be EMPTY")
	assert(table.is_available() == true, "Empty table must be available")
	assert(table.current_customer_id == "", "Customer ID must be empty initially")
	assert(table.requested_recipe_id == "", "Requested recipe ID must be empty initially")
	assert(table.uncollected_coins == 0, "Uncollected coins must be 0 initially")
	
	# Seating customer
	table.seat_customer("gil", "sup_sayur_bening")
	assert(table.current_state == table.TableState.WAITING_FOOD, "Table must transition to WAITING_FOOD")
	assert(table.current_customer_id == "gil", "Customer ID must match")
	assert(table.requested_recipe_id == "sup_sayur_bening", "Requested recipe must match")
	assert(table.is_available() == false, "Occupied table must not be available")
	assert(bubble.visible == true, "OrderBubble must be visible when waiting food")
	
	# Wrong food test
	var wrong_serve = table.serve_food("teh_herbal_rimba", 2)
	assert(wrong_serve == false, "Serving wrong dish must fail")
	assert(table.current_state == table.TableState.WAITING_FOOD, "Table state must remain WAITING_FOOD on wrong dish")
	
	# Correct food serving
	var serve_result = table.serve_food("sup_sayur_bening", 2)
	assert(serve_result == true, "Serving correct dish must succeed")
	assert(table.current_state == table.TableState.EATING, "Table must transition to EATING")
	assert(bubble.visible == false, "OrderBubble must be hidden when customer is eating")
	
	# Finish eating
	table.finish_eating()
	assert(table.current_state == table.TableState.DIRTY, "Table must become DIRTY after eating")
	assert(table.uncollected_coins > 0, "Dirty table must have coins to collect")
	assert(table.is_available() == false, "Dirty table must not be available")
	
	# Clear table
	var collected = table.clear_table()
	assert(collected > 0, "Clearing table must return collected coins")
	assert(table.uncollected_coins == 0, "Uncollected coins must reset to 0")
	assert(table.current_state == table.TableState.EMPTY, "Table must return to EMPTY")
	assert(table.is_available() == true, "Cleared table must be available again")
	assert(table.current_customer_id == "", "Customer ID must be cleared")
	assert(table.requested_recipe_id == "", "Requested recipe ID must be cleared")
	
	table.queue_free()


func test_order_bubble_standalone() -> void:
	var bubble_script = load("res://scripts/ui/OrderBubble.gd")
	assert(bubble_script != null, "OrderBubble.gd script must exist")
	
	var bubble = bubble_script.new()
	assert(bubble is Node2D, "OrderBubble must extend Node2D")
	root.add_child(bubble)
	
	bubble.show_order("sup_sayur_bening", "Sup Sayur Bening")
	assert(bubble.visible == true, "OrderBubble must be visible after show_order")
	assert(bubble.current_recipe_id == "sup_sayur_bening", "current_recipe_id must be set")
	
	bubble.hide_order()
	assert(bubble.visible == false, "OrderBubble must be hidden after hide_order")
	
	bubble.queue_free()
