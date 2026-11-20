extends CanvasLayer
class_name HearthwoodGiftUI

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")

var _interface: Control
var _title_label: Label
var _instructions_label: Label
var _status_label: Label
var _empty_label: Label
var _food_list: VBoxContainer
var _npc_id: String = ""
var _npc_name: String = ""
var _is_customer_service: bool = false
var _affection_system: HearthwoodAffectionSystem
var _warung_system: HearthwoodWarungSystem


func _ready() -> void:
	_create_interface()
	var game_state = get_node("/root/GameState")
	game_state.inventory_changed.connect(_refresh_food_list)
	get_node("/root/TimeSystem").day_changed.connect(_on_day_changed)


func set_affection_system(affection_system: HearthwoodAffectionSystem) -> void:
	_affection_system = affection_system


func set_warung_system(warung_system: HearthwoodWarungSystem) -> void:
	_warung_system = warung_system


func open_gifts(npc_id: String, npc_name: String, is_customer_service: bool = false) -> void:
	_npc_id = npc_id
	_npc_name = npc_name
	_is_customer_service = is_customer_service
	var daily_records: Dictionary = (
		get_node("/root/GameState").customers_served_today
		if is_customer_service
		else get_node("/root/GameState").gifts_given_today
	)
	_status_label.text = (
		"Interaksi dengan NPC ini sudah dilakukan hari ini."
		if daily_records.has(_npc_id)
		else ""
	)
	_instructions_label.text = (
		"Pilih masakan yang disukai pelanggan. Hanya pesanan yang memuaskan memberi reputasi."
		if is_customer_service
		else "Pilih satu masakan untuk diberikan. Kualitas dan tanggal masak ditampilkan."
	)
	_interface.visible = true
	_refresh_food_list()


func close_gifts() -> void:
	_interface.visible = false


func is_open() -> bool:
	return _interface.visible


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
	panel.anchor_left = 0.12
	panel.anchor_top = 0.08
	panel.anchor_right = 0.88
	panel.anchor_bottom = 0.92
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

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.add_theme_color_override("font_color", Color("#4a2e18"))
	layout.add_child(_title_label)

	_instructions_label = Label.new()
	_instructions_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instructions_label.add_theme_font_size_override("font_size", 13)
	_instructions_label.add_theme_color_override("font_color", Color("#6e4d35"))
	layout.add_child(_instructions_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 12)
	_status_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_BROWN)
	layout.add_child(_status_label)

	_empty_label = Label.new()
	_empty_label.text = "Belum ada masakan di inventori. Masak dulu di perapian rimba."
	_empty_label.add_theme_color_override("font_color", Color("#8b5a3c"))
	_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_empty_label)

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll_container)

	_food_list = VBoxContainer.new()
	_food_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_food_list.add_theme_constant_override("separation", 8)
	scroll_container.add_child(_food_list)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	var close_button := Button.new()
	close_button.text = "Batal"
	close_button.custom_minimum_size = Vector2(112.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(close_button, "secondary", 48.0, 13)
	close_button.pressed.connect(close_gifts)
	footer.add_child(close_button)


func _refresh_food_list() -> void:
	if _food_list == null:
		return
	for child in _food_list.get_children():
		child.queue_free()

	var game_state = get_node("/root/GameState")
	var heart_level: int = game_state.get_npc_heart_level(_npc_id)
	_title_label.text = "%s ke %s — Hati %d" % [
		"Layani Pelanggan" if _is_customer_service else "Beri Masakan",
		_npc_name,
		heart_level,
	]
	var daily_records: Dictionary = (
		game_state.customers_served_today
		if _is_customer_service
		else game_state.gifts_given_today
	)
	var already_gifted: bool = daily_records.has(_npc_id)
	var cooked_stacks: Array[Dictionary] = []
	for stack in game_state.inventory:
		var definition: Dictionary = game_state.get_item_definition(str(stack.get("id", "")))
		if str(definition.get("kategori", "")) == "masakan":
			cooked_stacks.append(stack)
	_empty_label.visible = cooked_stacks.is_empty()
	for stack in cooked_stacks:
		_food_list.add_child(_create_food_button(stack, game_state, already_gifted))


func _create_food_button(
	stack: Dictionary, game_state: Variant, already_gifted: bool
) -> Button:
	var item_id := str(stack.get("id", ""))
	var definition: Dictionary = game_state.get_item_definition(item_id)
	var quality := int(stack.get("kualitas", 0))
	var cooked_on_day := int(stack.get("tanggal_masak", 0))
	var button := Button.new()
	button.text = "%s  ×%d  ·  %d Bintang  ·  Dimasak Hari %d" % [
		str(definition.get("nama", item_id)),
		int(stack.get("jumlah", 0)),
		quality,
		cooked_on_day,
	]
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	HearthwoodThemeHelper.apply_3d_button(button, "hero" if not already_gifted else "muted", 48.0, 13)
	button.disabled = (
		already_gifted
		or _affection_system == null
		or (_is_customer_service and _warung_system == null)
	)
	button.pressed.connect(_on_food_selected.bind(item_id, cooked_on_day, quality))
	return button


func _on_food_selected(item_id: String, cooked_on_day: int, quality: int) -> void:
	if _affection_system == null:
		push_error("Gift UI opened without an affection system.")
		return
	var result: Dictionary
	if _is_customer_service:
		result = _warung_system.serve_customer(
			_npc_id,
			item_id,
			cooked_on_day,
			quality
		)
	else:
		result = _affection_system.give_food(
			_npc_id,
			item_id,
			cooked_on_day,
			quality
		)
	_status_label.text = str(result.get("pesan", ""))
	_refresh_food_list()


func _on_day_changed(_day: int) -> void:
	_status_label.text = ""
	_refresh_food_list()
