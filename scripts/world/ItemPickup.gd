extends Node2D
class_name HearthwoodItemPickup

var item_id: String = ""
var _display_name: String = ""
var _item_color: Color = Color("#74a653")


func configure(pickup_item_id: String, spawn_position: Vector2) -> void:
	item_id = pickup_item_id
	position = spawn_position


func _ready() -> void:
	var item_definition: Dictionary = get_node("/root/GameState").get_item_definition(item_id)
	if item_definition.is_empty():
		push_error("Cannot display pickup for unknown item: %s" % item_id)
		visible = false
		return
	_display_name = str(item_definition["nama"])
	_item_color = Color(str(item_definition.get("warna", "#74a653")))
	queue_redraw()


func get_display_name() -> String:
	return _display_name


func collect() -> bool:
	return get_node("/root/GameState").add_item(item_id)


func _draw() -> void:
	draw_circle(Vector2(0.0, 3.0), 9.0, Color(0.12, 0.13, 0.1, 0.28))
	draw_circle(Vector2.ZERO, 7.0, _item_color)
	draw_circle(Vector2(-2.0, -2.0), 2.0, _item_color.lightened(0.28))
	draw_line(Vector2(1.0, -6.0), Vector2(5.0, -10.0), Color("#426b3b"), 2.0)
