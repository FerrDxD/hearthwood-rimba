extends CanvasLayer
class_name HearthwoodGiftUI

var _interface: Control
var _title_label: Label
var _status_label: Label
var _empty_label: Label
var _food_list: VBoxContainer
var _npc_id: String = ""
var _npc_name: String = ""
var _affection_system: HearthwoodAffectionSystem


func _ready() -> void:
	_create_interface()
	var game_state = get_node("/root/GameState")
	game_state.inventory_changed.connect(_refresh_food_list)
	get_node("/root/TimeSystem").day_changed.connect(_on_day_changed)


func set_affection_system(affection_system: HearthwoodAffectionSystem) -> void:
	_affection_system = affection_system


func open_gifts(npc_id: String, npc_name: String) -> void:
	_npc_id = npc_id
	_npc_name = npc_name
	_status_label.text = (
		"Kamu sudah memberi masakan kepada NPC ini hari ini."
		if get_node("/root/GameState").gifts_given_today.has(_npc_id)
		else ""
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
	shade.color = Color(0.08, 0.1, 0.08, 0.52)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.1
	panel.anchor_top = 0.08
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.92
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
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(_title_label)

	var instructions := Label.new()
	instructions.text = "Pilih satu masakan untuk diberikan. Kualitas dan tanggal masak ditampilkan."
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(instructions)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(_status_label)

	_empty_label = Label.new()
	_empty_label.text = "Belum ada masakan. Masak dulu di api unggun."
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
	close_button.custom_minimum_size = Vector2(112.0, 52.0)
	close_button.pressed.connect(close_gifts)
	footer.add_child(close_button)


func _refresh_food_list() -> void:
	if _food_list == null:
		return
	for child in _food_list.get_children():
		child.queue_free()

	var game_state = get_node("/root/GameState")
	var heart_level: int = game_state.get_npc_heart_level(_npc_id)
	_title_label.text = "Beri masakan ke %s — hati %d" % [_npc_name, heart_level]
	var already_gifted: bool = game_state.gifts_given_today.has(_npc_id)
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
	button.text = "%s  ×%d  ·  %d bintang  ·  dimasak hari %d" % [
		str(definition.get("nama", item_id)),
		int(stack.get("jumlah", 0)),
		quality,
		cooked_on_day,
	]
	button.custom_minimum_size = Vector2(0.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = already_gifted or _affection_system == null
	button.pressed.connect(_on_food_selected.bind(item_id, cooked_on_day, quality))
	return button


func _on_food_selected(item_id: String, cooked_on_day: int, quality: int) -> void:
	if _affection_system == null:
		push_error("Gift UI opened without an affection system.")
		return
	var result := _affection_system.give_food(
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
