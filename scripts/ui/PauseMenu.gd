extends CanvasLayer
class_name HearthwoodPauseMenu

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
	shade.color = Color(0.08, 0.1, 0.08, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.25
	panel.anchor_top = 0.1
	panel.anchor_right = 0.75
	panel.anchor_bottom = 0.9
	_interface.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#f5f5dc")
	panel_style.border_color = Color("#8fbc8f")
	panel_style.set_border_width_all(3)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 20.0
	panel_style.content_margin_top = 18.0
	panel_style.content_margin_right = 20.0
	panel_style.content_margin_bottom = 18.0
	panel.add_theme_stylebox_override("panel", panel_style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "Permainan dijeda"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(title)

	_status_label = Label.new()
	_status_label.text = "Simpan progres atau lanjut bermain."
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_status_label)

	var resume_button := _create_button("Lanjutkan")
	resume_button.pressed.connect(close_menu)
	layout.add_child(resume_button)

	var save_button := _create_button("Simpan game")
	save_button.pressed.connect(_on_save_pressed)
	layout.add_child(save_button)

	var load_button := _create_button("Muat game")
	load_button.pressed.connect(_on_load_pressed)
	layout.add_child(load_button)

	var main_menu_button := _create_button("Ke menu utama")
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	layout.add_child(main_menu_button)


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(220.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return button


func _on_save_pressed() -> void:
	save_requested.emit()


func _on_load_pressed() -> void:
	load_requested.emit()


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
