extends CanvasLayer
class_name HearthwoodPauseMenu

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")

signal save_requested
signal load_requested
signal main_menu_requested

var _interface: Control
var _status_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_interface()


func open_menu() -> void:
	_interface.visible = true
	get_tree().paused = true


func close_menu() -> void:
	_interface.visible = false
	get_tree().paused = false


func is_open() -> bool:
	return _interface.visible


func show_status(message: String) -> void:
	_status_label.text = message


func _create_interface() -> void:
	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_STOP
	_interface.visible = false
	add_child(_interface)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.07, 0.04, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.28
	panel.anchor_top = 0.08
	panel.anchor_right = 0.72
	panel.anchor_bottom = 0.92
	_interface.add_child(panel)

	panel.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_tavern_panel_style(
			HearthwoodThemeHelper.COLOR_PAUSE_WOOD,
			HearthwoodThemeHelper.COLOR_BROWN,
			10,
			3
		)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "⏸ PERMAINAN DIJEDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "~ Waktu berhenti di tepian rimba ~"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_GOLD_AMBER)
	layout.add_child(subtitle)

	var status_card := PanelContainer.new()
	status_card.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style()
	)
	layout.add_child(status_card)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 10)
	status_margin.add_theme_constant_override("margin_top", 6)
	status_margin.add_theme_constant_override("margin_right", 10)
	status_margin.add_theme_constant_override("margin_bottom", 6)
	status_card.add_child(status_margin)

	_status_label = Label.new()
	_status_label.text = "Simpan progres atau lanjutkan petualangan."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM_MUTED)
	status_margin.add_child(_status_label)

	var resume_button := _create_button("Lanjutkan", "hero", 48.0)
	resume_button.pressed.connect(close_menu)
	layout.add_child(resume_button)

	var save_button := _create_button("Simpan game", "secondary", 46.0)
	save_button.pressed.connect(_on_save_pressed)
	layout.add_child(save_button)

	var load_button := _create_button("Muat game", "secondary", 46.0)
	load_button.pressed.connect(_on_load_pressed)
	layout.add_child(load_button)

	var main_menu_button := _create_button("Ke menu utama", "danger", 46.0)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	layout.add_child(main_menu_button)


func _create_button(button_text: String, type: String = "secondary", min_h: float = 46.0) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(260.0, min_h)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	HearthwoodThemeHelper.apply_3d_button(button, type, min_h, 13)
	return button


func _on_save_pressed() -> void:
	save_requested.emit()


func _on_load_pressed() -> void:
	load_requested.emit()


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
