extends CanvasLayer
class_name HearthwoodInventoryUI

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")

var _interface: Control
var _items_grid: GridContainer
var _empty_label: Label


func _ready() -> void:
	_create_interface()
	get_node("/root/GameState").inventory_changed.connect(_refresh_inventory)
	get_node("/root/TimeSystem").day_changed.connect(_on_day_changed)
	_refresh_inventory()


func toggle_inventory() -> void:
	_interface.visible = not _interface.visible
	if _interface.visible:
		_refresh_inventory()


func is_open() -> bool:
	return _interface.visible


func close_inventory() -> void:
	_interface.visible = false


func _create_interface() -> void:
	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_STOP
	_interface.visible = false
	add_child(_interface)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.07, 0.04, 0.65)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.1
	panel.anchor_top = 0.06
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.94
	_interface.add_child(panel)

	panel.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_parchment_panel_style(
			HearthwoodThemeHelper.COLOR_CREAM,
			HearthwoodThemeHelper.COLOR_BROWN,
			8,
			3
		)
	)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	var title_box := HBoxContainer.new()
	layout.add_child(title_box)

	var title := Label.new()
	title.text = "📖 BUKU CATATAN — INVENTORI"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#4a2e18"))
	title_box.add_child(title)

	var capacity_badge := Label.new()
	capacity_badge.text = "Kapasitas: 20 Slot"
	capacity_badge.add_theme_font_size_override("font_size", 11)
	capacity_badge.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_SADDLE_WOOD)
	capacity_badge.add_theme_stylebox_override("normal", HearthwoodThemeHelper.create_brass_badge_style())
	title_box.add_child(capacity_badge)

	_empty_label = Label.new()
	_empty_label.text = "Belum ada barang di kantong. Jelajahi rimba untuk mengumpulkan bahan segar."
	_empty_label.add_theme_color_override("font_color", Color("#6e4d35"))
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_empty_label)

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll_container)

	_items_grid = GridContainer.new()
	_items_grid.columns = 2
	_items_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_grid.add_theme_constant_override("h_separation", 10)
	_items_grid.add_theme_constant_override("v_separation", 10)
	scroll_container.add_child(_items_grid)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	var close_button := Button.new()
	close_button.text = "Tutup Catatan"
	close_button.custom_minimum_size = Vector2(130.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(close_button, "secondary", 48.0, 13)
	close_button.pressed.connect(close_inventory)
	footer.add_child(close_button)


func _refresh_inventory() -> void:
	if _items_grid == null:
		return
	for child in _items_grid.get_children():
		child.queue_free()

	var game_state = get_node("/root/GameState")
	_empty_label.visible = game_state.inventory.is_empty()
	for stack in game_state.inventory:
		var item_id := str(stack.get("id", ""))
		var definition: Dictionary = game_state.get_item_definition(item_id)
		if definition.is_empty():
			push_error("Inventory contains an unknown item: %s" % item_id)
			continue
		_items_grid.add_child(_create_item_card(stack, definition, game_state))


func _on_day_changed(_day: int) -> void:
	_refresh_inventory()


func _create_item_card(
	stack: Dictionary, definition: Dictionary, game_state: Variant
) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250.0, 88.0)
	card.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style(
			Color("#fffcf5"),
			Color("#c4a47c"),
			6
		)
	)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 3)
	card.add_child(layout)

	var item_header := HBoxContainer.new()
	item_header.add_theme_constant_override("separation", 8)
	layout.add_child(item_header)

	var slot_frame := PanelContainer.new()
	slot_frame.custom_minimum_size = Vector2(28.0, 28.0)
	slot_frame.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style(
			HearthwoodThemeHelper.COLOR_SLOT_RECESSED,
			Color("#502c12"),
			4
		)
	)
	item_header.add_child(slot_frame)

	var item_icon := ColorRect.new()
	item_icon.custom_minimum_size = Vector2(16.0, 16.0)
	item_icon.color = Color(str(definition.get("warna", "#9a7950")))
	slot_frame.add_child(item_icon)

	var item_label := Label.new()
	item_label.text = "%s  ×%d" % [str(definition["nama"]), int(stack.get("jumlah", 0))]
	item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_label.add_theme_font_size_override("font_size", 16)
	item_label.add_theme_color_override("font_color", Color("#4a2e18"))
	item_header.add_child(item_label)

	if str(definition.get("kategori", "")) == "masakan":
		var quality := int(stack.get("kualitas", 0))
		var energy: int = game_state.get_item_energy(str(stack["id"]), quality)
		var quality_label := Label.new()
		quality_label.text = "Kualitas: %d bintang  ·  Energi +%d" % [quality, energy]
		quality_label.add_theme_font_size_override("font_size", 12)
		quality_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_BROWN)
		layout.add_child(quality_label)

		var cooked_on_day := int(stack.get("tanggal_masak", 0))
		var cooked_date_label := Label.new()
		var shelf_life := int(definition.get("masa_simpan_hari", 3))
		var age := maxi(0, game_state.current_day - cooked_on_day)
		cooked_date_label.text = "Dimasak hari %d  ·  Tersisa %d hari" % [cooked_on_day, maxi(0, shelf_life - age)]
		cooked_date_label.add_theme_font_size_override("font_size", 11)
		cooked_date_label.add_theme_color_override("font_color", Color("#8b5a3c"))
		layout.add_child(cooked_date_label)
	else:
		var category_label := Label.new()
		category_label.text = str(definition.get("kategori", "bahan rimba")).capitalize()
		category_label.add_theme_font_size_override("font_size", 12)
		category_label.add_theme_color_override("font_color", Color("#6e4d35"))
		layout.add_child(category_label)

	return card
