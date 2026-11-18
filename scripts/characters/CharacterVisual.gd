extends Node2D
class_name HearthwoodCharacterVisual

const SKIN_TEXTURE: Texture2D = preload("res://assets/sprites/characters/skin.png")
const SHIRT_TEXTURE: Texture2D = preload("res://assets/sprites/characters/shirt.png")
const PANTS_TEXTURE: Texture2D = preload("res://assets/sprites/characters/pants.png")
const SHOES_TEXTURE: Texture2D = preload("res://assets/sprites/characters/shoes.png")
const HAIR_TEXTURE: Texture2D = preload("res://assets/sprites/characters/hair.png")

class AccessoryLayer extends Node2D:
	var kind: String = "tanpa"

	func _draw() -> void:
		match kind:
			"keranjang":
				draw_rect(Rect2(7.0, 0.0, 6.0, 7.0), Color("#9a7950"))
				draw_line(Vector2(7.0, 2.0), Vector2(13.0, 2.0), Color("#d2b48c"), 1.0)
				draw_rect(Rect2(8.0, 1.0, 3.0, 2.0), Color("#64894b"))
			"palu_kecil":
				draw_rect(Rect2(9.0, 1.0, 2.0, 8.0), Color("#76513a"))
				draw_rect(Rect2(7.0, 0.0, 7.0, 3.0), Color("#b0b0b0"))
			"adonan":
				draw_rect(Rect2(7.0, 0.0, 6.0, 6.0), Color("#f0d7b5"))
				draw_rect(Rect2(8.0, 1.0, 3.0, 2.0), Color("#db7093"))
			"jarum_kain":
				draw_rect(Rect2(7.0, 0.0, 6.0, 7.0), Color("#c8a2c8"))
				draw_line(Vector2(8.0, -2.0), Vector2(13.0, 5.0), Color("#f5f5dc"), 1.0)
			"tombak":
				draw_line(Vector2(11.0, 10.0), Vector2(14.0, -19.0), Color("#76513a"), 2.0)
				draw_line(Vector2(14.0, -19.0), Vector2(16.0, -14.0), Color("#b0b0b0"), 1.0)
			"tongkat", "tongkat_tua":
				draw_line(Vector2(10.0, 11.0), Vector2(14.0, -13.0), Color("#76513a"), 2.0)
			"palu_besar":
				draw_rect(Rect2(9.0, 2.0, 3.0, 10.0), Color("#76513a"))
				draw_rect(Rect2(6.0, -2.0, 9.0, 5.0), Color("#555555"))
			"tali":
				draw_rect(Rect2(7.0, 1.0, 3.0, 8.0), Color("#b19a70"))
				draw_line(Vector2(8.0, 1.0), Vector2(11.0, 5.0), Color("#76513a"), 1.0)


var _hair_color: Color = Color("#8b4513")
var _shirt_color: Color = Color("#556b2f")
var _pants_color: Color = Color("#654321")
var _accessory_layer: AccessoryLayer
var _layers: Dictionary = {}


func configure(
	hair_color: Color,
	shirt_color: Color,
	pants_color: Color,
	accessory: String = "tanpa"
) -> void:
	_hair_color = hair_color
	_shirt_color = shirt_color
	_pants_color = pants_color
	if is_node_ready():
		_apply_palette()
	if is_instance_valid(_accessory_layer):
		_accessory_layer.kind = accessory
		_accessory_layer.queue_redraw()


func _ready() -> void:
	_add_layer("shoes", SHOES_TEXTURE, Color("#a56b3f"))
	_add_layer("pants", PANTS_TEXTURE, _pants_color)
	_add_layer("shirt", SHIRT_TEXTURE, _shirt_color)
	_add_layer("skin", SKIN_TEXTURE, Color("#f0c49a"))
	_add_layer("hair", HAIR_TEXTURE, _hair_color)
	_accessory_layer = AccessoryLayer.new()
	_accessory_layer.name = "accessoryLayer"
	add_child(_accessory_layer)
	_apply_palette()


func _draw() -> void:
	draw_circle(Vector2(0.0, 12.0), 8.0, Color(0.12, 0.13, 0.1, 0.25))


func _add_layer(layer_name: String, texture: Texture2D, tint: Color) -> void:
	var sprite := Sprite2D.new()
	sprite.name = layer_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint
	add_child(sprite)
	_layers[layer_name] = sprite


func _apply_palette() -> void:
	if _layers.is_empty():
		return
	_layers["pants"].modulate = _pants_color
	_layers["shirt"].modulate = _shirt_color
	_layers["hair"].modulate = _hair_color
