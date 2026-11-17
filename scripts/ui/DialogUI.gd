extends CanvasLayer
class_name HearthwoodDialogUI

signal closed
signal gift_requested(npc_id: String, npc_name: String)

var _interface: Control
var _name_label: Label
var _role_label: Label
var _dialogue_label: Label
var _gift_button: Button
var _continue_button: Button
var _npc_id: String = ""


func _ready() -> void:
	_create_interface()


func open_dialog(
	npc_name: String, npc_role: String, dialogue: String, npc_id: String = ""
) -> void:
	_name_label.text = npc_name
	_role_label.text = npc_role
	_dialogue_label.text = dialogue
	_npc_id = npc_id
	_gift_button.visible = not npc_id.is_empty()
	_interface.visible = true
	_continue_button.grab_focus()


func close_dialog() -> void:
	_interface.visible = false
	closed.emit()


func is_open() -> bool:
	return _interface.visible


func _create_interface() -> void:
	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_STOP
	_interface.visible = false
	add_child(_interface)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.04
	panel.anchor_top = 0.67
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.97
	_interface.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#f5f5dc")
	panel_style.border_color = Color("#8fbc8f")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 18.0
	panel_style.content_margin_top = 12.0
	panel_style.content_margin_right = 18.0
	panel_style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	var heading := HBoxContainer.new()
	layout.add_child(heading)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 21)
	_name_label.add_theme_color_override("font_color", Color("#5d422c"))
	heading.add_child(_name_label)

	_role_label = Label.new()
	_role_label.add_theme_font_size_override("font_size", 15)
	_role_label.add_theme_color_override("font_color", Color("#6c6c5a"))
	heading.add_child(_role_label)

	_dialogue_label = Label.new()
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 18)
	_dialogue_label.add_theme_color_override("font_color", Color("#333333"))
	layout.add_child(_dialogue_label)

	var footer := HBoxContainer.new()
	layout.add_child(footer)
	_gift_button = Button.new()
	_gift_button.text = "Beri masakan"
	_gift_button.custom_minimum_size = Vector2(156.0, 52.0)
	_gift_button.pressed.connect(_on_gift_pressed)
	footer.add_child(_gift_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	_continue_button = Button.new()
	_continue_button.text = "Lanjutkan"
	_continue_button.custom_minimum_size = Vector2(176.0, 52.0)
	_continue_button.add_theme_font_size_override("font_size", 18)
	_continue_button.pressed.connect(close_dialog)
	footer.add_child(_continue_button)


func _on_gift_pressed() -> void:
	gift_requested.emit(_npc_id, _name_label.text)
	close_dialog()
