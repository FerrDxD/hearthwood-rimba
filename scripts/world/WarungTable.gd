# scripts/world/WarungTable.gd
extends Area2D
class_name HearthwoodWarungTable

enum TableState {
	EMPTY,
	OCCUPIED,
	WAITING_FOOD,
	EATING,
	DIRTY
}

signal table_state_changed(new_state: TableState, table_id: String)
signal customer_seated(table_id: String, npc_id: String, recipe_id: String)
signal food_served(table_id: String, item_id: String, quality: int)
signal eating_finished(table_id: String, coins: int)
signal table_cleared(table_id: String, coins: int)

const ORDER_BUBBLE_SCRIPT = preload("res://scripts/ui/OrderBubble.gd")

@export var table_id: String = ""
@export var current_state: TableState = TableState.EMPTY
@export var current_customer_id: String = ""
@export var requested_recipe_id: String = ""
@export var uncollected_coins: int = 0
@export var interaction_radius: float = 48.0:
	set(val):
		interaction_radius = val
		_update_collision_shape()

var order_bubble: Node2D


func _init() -> void:
	_ensure_collision_shape()
	_ensure_order_bubble()


func _ready() -> void:
	_ensure_collision_shape()
	_ensure_order_bubble()
	queue_redraw()


func _ensure_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var circle := CircleShape2D.new()
		circle.radius = interaction_radius
		col.shape = circle
		add_child(col)
	elif col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = interaction_radius


func _update_collision_shape() -> void:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col != null and col.shape is CircleShape2D:
		(col.shape as CircleShape2D).radius = interaction_radius


func _ensure_order_bubble() -> void:
	order_bubble = get_node_or_null("OrderBubble") as Node2D
	if order_bubble == null:
		order_bubble = ORDER_BUBBLE_SCRIPT.new()
		order_bubble.name = "OrderBubble"
		order_bubble.position = Vector2(0.0, -36.0)
		order_bubble.visible = false
		add_child(order_bubble)


func is_available() -> bool:
	return current_state == TableState.EMPTY


func seat_customer(npc_id: String, recipe_id: String) -> void:
	current_customer_id = npc_id
	requested_recipe_id = recipe_id
	current_state = TableState.WAITING_FOOD
	_ensure_order_bubble()
	if order_bubble != null:
		order_bubble.show_order(recipe_id)
	queue_redraw()
	customer_seated.emit(table_id, npc_id, recipe_id)
	table_state_changed.emit(current_state, table_id)


func serve_food(item_id: String, quality: int = 2) -> bool:
	if current_state != TableState.WAITING_FOOD:
		return false
	if item_id != requested_recipe_id:
		return false

	current_state = TableState.EATING
	var base_coins: int = _get_dish_base_price(item_id)
	var quality_bonus: int = max(0, quality - 1) * 5
	uncollected_coins = base_coins + quality_bonus

	_ensure_order_bubble()
	if order_bubble != null:
		order_bubble.hide_order()

	queue_redraw()
	food_served.emit(table_id, item_id, quality)
	table_state_changed.emit(current_state, table_id)
	return true


func finish_eating() -> void:
	current_state = TableState.DIRTY
	if uncollected_coins <= 0:
		uncollected_coins = 25
	_ensure_order_bubble()
	if order_bubble != null:
		order_bubble.hide_order()
	queue_redraw()
	eating_finished.emit(table_id, uncollected_coins)
	table_state_changed.emit(current_state, table_id)


func clear_table() -> int:
	var collected: int = uncollected_coins
	uncollected_coins = 0
	current_customer_id = ""
	requested_recipe_id = ""
	current_state = TableState.EMPTY
	_ensure_order_bubble()
	if order_bubble != null:
		order_bubble.hide_order()
	queue_redraw()
	table_cleared.emit(table_id, collected)
	table_state_changed.emit(current_state, table_id)
	return collected


func get_seat_position(side: int = 0) -> Vector2:
	# side 0: left bench, side 1: right bench
	if side == 0:
		return global_position + Vector2(-30.0, 0.0)
	return global_position + Vector2(30.0, 0.0)


func _get_dish_base_price(item_id: String) -> int:
	var path := "res://data/items/items.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				var items_arr = json.data.get("items", [])
				for item in items_arr:
					if item is Dictionary and item.get("id") == item_id:
						return int(item.get("harga_jual", 40))
	return 40


func _draw() -> void:
	# 1. Soft ground shadow under table & benches
	draw_rect(Rect2(-38.0, -15.0, 76.0, 32.0), Color(0.08, 0.05, 0.02, 0.25), true)

	# 2. Side benches (#8B5A2B)
	var bench_color := Color("#8B5A2B")
	var bench_shadow := Color("#5A3716")
	var bench_border := Color("#452A11")

	# Left bench
	draw_rect(Rect2(-33.0, -13.0, 8.0, 26.0), bench_color, true)
	draw_line(Vector2(-33.0, 13.0), Vector2(-25.0, 13.0), bench_shadow, 1.5)
	draw_rect(Rect2(-33.0, -13.0, 8.0, 26.0), bench_border, false, 1.0)

	# Right bench
	draw_rect(Rect2(25.0, -13.0, 8.0, 26.0), bench_color, true)
	draw_line(Vector2(25.0, 13.0), Vector2(33.0, 13.0), bench_shadow, 1.5)
	draw_rect(Rect2(25.0, -13.0, 8.0, 26.0), bench_border, false, 1.0)

	# 3. Main wooden table top (#6B4226)
	var table_rect := Rect2(-23.0, -15.0, 46.0, 30.0)
	var table_wood := Color("#6B4226")
	var table_border_col := Color("#452812")
	var woodgrain_col := Color("#52321C")

	draw_rect(table_rect, table_wood, true)
	# Woodgrain horizontal lines
	draw_line(Vector2(-21.0, -9.0), Vector2(21.0, -9.0), woodgrain_col, 1.0)
	draw_line(Vector2(-21.0, -3.0), Vector2(21.0, -3.0), woodgrain_col, 1.0)
	draw_line(Vector2(-21.0, 3.0), Vector2(21.0, 3.0), woodgrain_col, 1.0)
	draw_line(Vector2(-21.0, 9.0), Vector2(21.0, 9.0), woodgrain_col, 1.0)
	# Outer border & bottom lip shadow
	draw_rect(table_rect, table_border_col, false, 1.5)
	draw_line(Vector2(-23.0, 15.0), Vector2(23.0, 15.0), Color("#2E190A"), 2.0)

	# 4. Linen table runner (#E8DCC4)
	var runner_rect := Rect2(-9.0, -16.0, 18.0, 32.0)
	var runner_color := Color("#E8DCC4")
	var runner_stitch := Color("#C4B496")
	draw_rect(runner_rect, runner_color, true)
	draw_line(Vector2(-8.0, -16.0), Vector2(-8.0, 16.0), runner_stitch, 1.0)
	draw_line(Vector2(8.0, -16.0), Vector2(8.0, 16.0), runner_stitch, 1.0)

	# 5. Table tableware / state props
	match current_state:
		TableState.EMPTY:
			# Neat wooden seasoning pot / small wildflower cup
			draw_circle(Vector2(0.0, 0.0), 3.5, Color("#8B5A2B"))
			draw_circle(Vector2(0.0, 0.0), 2.0, Color("#C49A6C"))
			draw_circle(Vector2(11.0, -5.0), 2.5, Color("#C27D53")) # Clean clay cup

		TableState.WAITING_FOOD:
			# Clean earthenware plate set, awaiting dish
			draw_circle(Vector2(0.0, 0.0), 6.5, Color("#F5EBE1"))
			draw_circle(Vector2(0.0, 0.0), 5.5, Color("#E3D5C5"))
			# Wooden spoon
			draw_line(Vector2(-12.0, -4.0), Vector2(-12.0, 4.0), Color("#8B5A2B"), 1.5)
			draw_circle(Vector2(-12.0, -4.0), 2.0, Color("#8B5A2B"))
			# Mug
			draw_circle(Vector2(12.0, -5.0), 3.0, Color("#A95232"))

		TableState.EATING:
			# Ceramic bowl with steaming food
			draw_circle(Vector2(0.0, 0.0), 7.0, Color("#EFE5D8"))
			draw_circle(Vector2(0.0, 0.0), 5.5, Color("#D49B43")) # Warm rich broth
			draw_circle(Vector2(-1.5, -1.0), 1.5, Color("#5F8538")) # Herb garnish
			draw_circle(Vector2(1.5, 1.0), 1.2, Color("#C04828")) # Carrot dot
			# Spoon dipped in bowl
			draw_line(Vector2(-2.0, 2.0), Vector2(-10.0, 6.0), Color("#7B4E26"), 1.5)
			# Terracotta beverage mug
			draw_circle(Vector2(12.0, -5.0), 3.5, Color("#A95232"))
			draw_circle(Vector2(12.0, -5.0), 2.0, Color("#75331C"))

		TableState.DIRTY:
			# Dirty empty dish with leftovers
			draw_circle(Vector2(-2.0, 1.0), 6.5, Color("#DFD4C4"))
			draw_circle(Vector2(-2.0, 1.0), 4.5, Color("#BBA37D"))
			draw_line(Vector2(-4.0, 0.0), Vector2(-6.0, 4.0), Color("#7B4E26"), 1.5) # Discarded spoon
			# Scattered crumbs
			draw_circle(Vector2(4.0, -3.0), 1.0, Color("#7A4924"))
			draw_circle(Vector2(6.0, 2.0), 1.2, Color("#8F5A2F"))
			draw_circle(Vector2(-8.0, -4.0), 1.0, Color("#6B3B18"))
			# Tilted cup
			draw_circle(Vector2(12.0, -6.0), 3.0, Color("#A95232"))
			# Golden coins pouch / stack of coins (#FFD700)
			draw_circle(Vector2(10.0, 5.0), 4.5, Color("#FFD700")) # Main gold coin
			draw_circle(Vector2(13.0, 3.5), 3.5, Color("#E6B800")) # Stacked coin
			draw_circle(Vector2(9.0, 4.0), 1.5, Color("#FFF7A8")) # Gleam highlight
