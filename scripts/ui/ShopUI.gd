extends CanvasLayer
class_name HearthwoodShopUI

signal talk_requested(shop_id: String)
signal closed

const HEART_TWO_DISCOUNT_PERCENT: int = 5
const HEART_THREE_DISCOUNT_PERCENT: int = 15
const CATALOG_PATH: String = "res://data/shops.json"

var _interface: Control
var _title_label: Label
var _wallet_label: Label
var _discount_label: Label
var _status_label: Label
var _goods_container: VBoxContainer
var _shop_id: String = ""
var _discount_percent: int = 0
var _goods: Array[Dictionary] = []


func _ready() -> void:
	_create_interface()
	var game_state = get_node("/root/GameState")
	game_state.coins_changed.connect(_update_wallet)
	game_state.inventory_changed.connect(_refresh_goods)


func open_shop(shop_id: String, merchant_name: String, discount_percent: int) -> bool:
	var catalog := _load_catalog()
	if not catalog.has(shop_id):
		push_error("Shop catalog entry not found: %s" % shop_id)
		return false

	var store: Variant = catalog[shop_id]
	if typeof(store) != TYPE_DICTIONARY:
		push_error("Shop catalog entry must be an object: %s" % shop_id)
		return false
	var goods: Variant = store.get("barang")
	if typeof(goods) != TYPE_ARRAY or goods.is_empty():
		push_error("Shop catalog entry has no goods: %s" % shop_id)
		return false
	if not _validate_goods(shop_id, goods):
		return false

	_shop_id = shop_id
	_discount_percent = clampi(discount_percent, 0, HEART_THREE_DISCOUNT_PERCENT)
	_goods.clear()
	for item in goods:
		_goods.append(item)

	_title_label.text = "Toko %s - %s" % [str(store.get("kategori", "")), merchant_name]
	_discount_label.text = "Diskon kedekatan: %d%%" % _discount_percent
	_status_label.text = ""
	_update_wallet()
	_refresh_goods()
	_interface.visible = true
	return true


func close_shop() -> void:
	if not _interface.visible:
		return
	_interface.visible = false
	closed.emit()


func is_open() -> bool:
	return _interface.visible


func _load_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		push_error("Shop catalog file not found: %s" % CATALOG_PATH)
		return {}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read shop catalog file: %s" % CATALOG_PATH)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Shop catalog must be a JSON object: %s" % CATALOG_PATH)
		return {}
	return parsed


func _validate_goods(shop_id: String, goods: Array) -> bool:
	for item in goods:
		if typeof(item) != TYPE_DICTIONARY:
			push_error("Shop goods must be JSON objects: %s" % shop_id)
			return false
		for key in ["id", "nama", "harga"]:
			if not item.has(key):
				push_error("Shop item is missing '%s': %s" % [key, shop_id])
				return false
		var price_type: int = typeof(item["harga"])
		if (
			typeof(item["id"]) != TYPE_STRING
			or typeof(item["nama"]) != TYPE_STRING
			or str(item["id"]).is_empty()
			or str(item["nama"]).is_empty()
			or price_type != TYPE_INT
			and price_type != TYPE_FLOAT
			or float(item["harga"]) <= 0.0
		):
			push_error("Shop item has invalid id, name, or price: %s" % shop_id)
			return false
	return true


func _create_interface() -> void:
	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_STOP
	_interface.visible = false
	add_child(_interface)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.08, 0.1, 0.08, 0.52)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.12
	panel.anchor_top = 0.1
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.9
	_interface.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#f5f5dc")
	panel_style.border_color = Color("#8fbc8f")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_top = 14.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(_title_label)

	var summary := HBoxContainer.new()
	layout.add_child(summary)

	_wallet_label = Label.new()
	_wallet_label.add_theme_font_size_override("font_size", 17)
	summary.add_child(_wallet_label)

	var summary_spacer := Control.new()
	summary_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(summary_spacer)

	_discount_label = Label.new()
	_discount_label.add_theme_font_size_override("font_size", 16)
	summary.add_child(_discount_label)

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(0.0, 170.0)
	layout.add_child(scroll_container)

	_goods_container = VBoxContainer.new()
	_goods_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(_goods_container)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 15)
	layout.add_child(_status_label)

	var footer := HBoxContainer.new()
	layout.add_child(footer)

	var talk_button := Button.new()
	talk_button.text = "Bicara"
	talk_button.custom_minimum_size = Vector2(112.0, 48.0)
	talk_button.pressed.connect(_talk_to_merchant)
	footer.add_child(talk_button)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)

	var close_button := Button.new()
	close_button.text = "Batal"
	close_button.custom_minimum_size = Vector2(112.0, 48.0)
	close_button.pressed.connect(close_shop)
	footer.add_child(close_button)


func _refresh_goods() -> void:
	if _goods_container == null:
		return
	for child in _goods_container.get_children():
		child.queue_free()

	var game_state = get_node("/root/GameState")
	for item in _goods:
		var row := HBoxContainer.new()
		_goods_container.add_child(row)

		var item_label := Label.new()
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_label.add_theme_font_size_override("font_size", 17)
		var base_price := int(item["harga"])
		var final_price := _calculate_price(base_price, _discount_percent)
		var owned_count: int = game_state.get_item_count(str(item["id"]))
		if _discount_percent > 0:
			item_label.text = "%s  %d -> %d koin  (milik: %d)" % [
				str(item["nama"]),
				base_price,
				final_price,
				owned_count,
			]
		else:
			item_label.text = "%s  %d koin  (milik: %d)" % [
				str(item["nama"]),
				final_price,
				owned_count,
			]
		row.add_child(item_label)

		var buy_button := Button.new()
		buy_button.text = "Beli"
		buy_button.custom_minimum_size = Vector2(92.0, 48.0)
		buy_button.pressed.connect(_buy_item.bind(item))
		row.add_child(buy_button)


func _update_wallet(_new_value: int = 0) -> void:
	_wallet_label.text = "Koin: %d" % get_node("/root/GameState").coins


func _calculate_price(base_price: int, discount_percent: int) -> int:
	return maxi(1, floori(float(base_price) * (100.0 - discount_percent) / 100.0))


func _buy_item(item: Dictionary) -> void:
	var final_price := _calculate_price(int(item["harga"]), _discount_percent)
	var game_state = get_node("/root/GameState")
	if not game_state.purchase_item(str(item["id"]), final_price):
		_status_label.text = "Koin tidak cukup untuk membeli %s." % str(item["nama"])
		return
	_status_label.text = "%s dibeli seharga %d koin." % [str(item["nama"]), final_price]


func _talk_to_merchant() -> void:
	var shop_id := _shop_id
	talk_requested.emit(shop_id)
	close_shop()
