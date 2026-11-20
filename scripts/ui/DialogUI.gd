extends CanvasLayer
class_name HearthwoodDialogUI

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")

signal closed
signal gift_requested(npc_id: String, npc_name: String)
signal service_requested(npc_id: String, npc_name: String)
signal upgrade_requested

var _interface: Control
var _name_label: Label
var _role_label: Label
var _dialogue_label: Label
var _gift_button: Button
var _serve_button: Button
var _upgrade_button: Button
var _continue_button: Button
var _npc_id: String = ""


func _ready() -> void:
	_create_interface()


func open_dialog(
	npc_name: String,
	npc_role: String,
	dialogue: String,
	npc_id: String = "",
	can_serve: bool = false,
	can_upgrade: bool = false
) -> void:
	_name_label.text = npc_name
	_role_label.text = " — %s" % npc_role if not npc_role.is_empty() else ""
	_dialogue_label.text = dialogue
	_npc_id = npc_id
	_gift_button.visible = not npc_id.is_empty()
	_serve_button.visible = can_serve
	_upgrade_button.visible = can_upgrade
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
	panel.anchor_top = 0.65
	panel.anchor_right = 0.96
	panel.anchor_bottom = 0.97
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
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)

	var heading := HBoxContainer.new()
	layout.add_child(heading)

	var name_badge := PanelContainer.new()
	name_badge.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_brass_badge_style(
			HearthwoodThemeHelper.COLOR_SADDLE_WOOD,
			HearthwoodThemeHelper.COLOR_BROWN_LIGHT,
			4
		)
	)
	heading.add_child(name_badge)

	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 16)
	_name_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	name_badge.add_child(_name_label)

	_role_label = Label.new()
	_role_label.add_theme_font_size_override("font_size", 14)
	_role_label.add_theme_color_override("font_color", Color("#6e4d35"))
	heading.add_child(_role_label)

	_dialogue_label = Label.new()
	_dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_label.add_theme_font_size_override("font_size", 16)
	_dialogue_label.add_theme_color_override("font_color", Color("#333333"))
	layout.add_child(_dialogue_label)

	var footer := GridContainer.new()
	footer.columns = 2
	footer.add_theme_constant_override("h_separation", 8)
	footer.add_theme_constant_override("v_separation", 6)
	layout.add_child(footer)

	_gift_button = Button.new()
	_gift_button.text = "Beri masakan"
	_gift_button.custom_minimum_size = Vector2(156.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(_gift_button, "secondary", 48.0, 13)
	_gift_button.pressed.connect(_on_gift_pressed)
	footer.add_child(_gift_button)

	_serve_button = Button.new()
	_serve_button.text = "Layani pelanggan"
	_serve_button.custom_minimum_size = Vector2(156.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(_serve_button, "secondary", 48.0, 13)
	_serve_button.pressed.connect(_on_serve_pressed)
	footer.add_child(_serve_button)

	_upgrade_button = Button.new()
	_upgrade_button.text = "Izin & upgrade warung"
	_upgrade_button.custom_minimum_size = Vector2(176.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(_upgrade_button, "hero", 48.0, 13)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	footer.add_child(_upgrade_button)

	_continue_button = Button.new()
	_continue_button.text = "Lanjutkan"
	_continue_button.custom_minimum_size = Vector2(176.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(_continue_button, "hero", 48.0, 14)
	_continue_button.pressed.connect(close_dialog)
	footer.add_child(_continue_button)


func _on_gift_pressed() -> void:
	gift_requested.emit(_npc_id, _name_label.text)
	close_dialog()


func _on_serve_pressed() -> void:
	service_requested.emit(_npc_id, _name_label.text)
	close_dialog()


func _on_upgrade_pressed() -> void:
	upgrade_requested.emit()
	close_dialog()
