# scripts/ui/OrderBubble.gd
extends Node2D
class_name HearthwoodOrderBubble

signal order_clicked(recipe_id: String)

@export var current_recipe_id: String = ""
@export var current_recipe_name: String = ""
@export var bubble_width: float = 76.0
@export var bubble_height: float = 26.0

var _base_y: float = -42.0
var _bob_timer: float = 0.0
var _label: Label


func _init() -> void:
	_setup_nodes()


func _ready() -> void:
	_setup_nodes()
	queue_redraw()


func _setup_nodes() -> void:
	if _label == null:
		_label = get_node_or_null("RecipeLabel") as Label
		if _label == null:
			_label = Label.new()
			_label.name = "RecipeLabel"
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_label.add_theme_color_override("font_color", Color(0.24, 0.15, 0.08)) # Dark walnut
			_label.add_theme_font_size_override("font_size", 10)
			_label.position = Vector2(-bubble_width * 0.5 + 4.0, -bubble_height * 0.5 - 2.0)
			_label.size = Vector2(bubble_width - 8.0, bubble_height)
			_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(_label)


func _process(delta: float) -> void:
	if not visible:
		return
	_bob_timer += delta * 2.8
	position.y = _base_y + sin(_bob_timer) * 3.0


func show_order(recipe_id: String, recipe_name: String = "") -> void:
	current_recipe_id = recipe_id
	if recipe_name.is_empty():
		current_recipe_name = _lookup_recipe_name(recipe_id)
	else:
		current_recipe_name = recipe_name

	_setup_nodes()
	if _label != null:
		_label.text = current_recipe_name
	visible = true
	queue_redraw()


func hide_order() -> void:
	current_recipe_id = ""
	current_recipe_name = ""
	if _label != null:
		_label.text = ""
	visible = false
	queue_redraw()


func _lookup_recipe_name(recipe_id: String) -> String:
	var path := "res://data/recipes/%s.json" % recipe_id
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				return json.data.get("nama", recipe_id.replace("_", " ").capitalize())
	return recipe_id.replace("_", " ").capitalize()


func _draw() -> void:
	if not visible:
		return

	var half_w: float = bubble_width * 0.5
	var half_h: float = bubble_height * 0.5
	var bubble_rect := Rect2(-half_w, -half_h - 2.0, bubble_width, bubble_height)

	# Soft shadow
	var shadow_rect := Rect2(-half_w + 1.5, -half_h, bubble_width, bubble_height)
	draw_rect(shadow_rect, Color(0.12, 0.08, 0.03, 0.22), true)

	# Parchment body
	var parchment_color := Color("#FFF8E7")
	draw_rect(bubble_rect, parchment_color, true)

	# Subtle inner parchment tint
	draw_rect(Rect2(-half_w + 1.0, -half_h - 1.0, bubble_width - 2.0, bubble_height - 2.0), Color("#FAF0D7"), true)

	# Rustic border
	var border_color := Color("#7C4B24")
	draw_rect(bubble_rect, border_color, false, 1.5)

	# Downward speech pointer triangle pointing to table
	var pointer_top := half_h - 2.0
	var pointer_pts: PackedVector2Array = [
		Vector2(-5.0, pointer_top),
		Vector2(5.0, pointer_top),
		Vector2(0.0, pointer_top + 6.0)
	]
	draw_colored_polygon(pointer_pts, parchment_color)
	draw_line(Vector2(-5.0, pointer_top), Vector2(0.0, pointer_top + 6.0), border_color, 1.5)
	draw_line(Vector2(5.0, pointer_top), Vector2(0.0, pointer_top + 6.0), border_color, 1.5)
