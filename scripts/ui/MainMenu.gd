extends CanvasLayer
class_name HearthwoodMainMenu

const GAME_SCENE_PATH: String = "res://scenes/Main.tscn"
const SETTINGS_PATH: String = "user://settings.cfg"
const AUDIO_DIRECTOR_SCRIPT: Script = preload("res://scripts/systems/AudioDirector.gd")
const DEFAULT_SAVE_FILE_PATH: String = "user://savegame.json"

class MenuLandscape extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		var sky_height := size.y * 0.62
		for y in range(0, ceili(sky_height), 8):
			var blend := float(y) / maxf(1.0, sky_height)
			var band_height := mini(8, ceili(sky_height) - y)
			draw_rect(
				Rect2(0.0, float(y), size.x, float(band_height)),
				Color("#9bb98a").lerp(Color("#e7c98f"), blend * 0.45)
			)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(0.0, size.y * 0.48),
				Vector2(size.x * 0.36, size.y * 0.32),
				Vector2(size.x * 0.72, size.y * 0.47),
				Vector2(size.x, size.y * 0.34),
				Vector2(size.x, size.y),
				Vector2.ZERO + Vector2(0.0, size.y),
			]),
			Color("#617f58")
		)
		draw_rect(
			Rect2(0.0, size.y * 0.64, size.x, size.y * 0.36),
			Color("#56754c")
		)
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(size.x * 0.44, size.y),
				Vector2(size.x * 0.56, size.y),
				Vector2(size.x * 0.68, size.y * 0.61),
				Vector2(size.x * 0.62, size.y * 0.59),
				Vector2(size.x * 0.5, size.y * 0.82),
				Vector2(size.x * 0.4, size.y * 0.81),
			]),
			Color("#c7a773")
		)
		_draw_tree(size.x * 0.12, size.y * 0.58, 1.0)
		_draw_tree(size.x * 0.84, size.y * 0.57, 0.9)
		_draw_tree(size.x * 0.94, size.y * 0.68, 0.65)
		_draw_cottage(size.x * 0.53, size.y * 0.53)
		draw_circle(Vector2(size.x * 0.74, size.y * 0.23), 19.0, Color("#f4df9b"))

	func _draw_tree(x: float, y: float, scale_value: float) -> void:
		draw_rect(
			Rect2(x - 5.0 * scale_value, y - 25.0 * scale_value, 10.0 * scale_value, 34.0 * scale_value),
			Color("#76513a")
		)
		draw_rect(
			Rect2(x - 20.0 * scale_value, y - 52.0 * scale_value, 40.0 * scale_value, 32.0 * scale_value),
			Color("#36583f")
		)
		draw_rect(
			Rect2(x - 14.0 * scale_value, y - 63.0 * scale_value, 28.0 * scale_value, 22.0 * scale_value),
			Color("#64894b")
		)
		draw_rect(
			Rect2(x - 11.0 * scale_value, y - 51.0 * scale_value, 7.0 * scale_value, 5.0 * scale_value),
			Color("#91a96a")
		)

	func _draw_cottage(x: float, y: float) -> void:
		draw_rect(Rect2(x - 48.0, y - 39.0, 96.0, 63.0), Color("#d2b48c"))
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(x - 58.0, y - 38.0),
				Vector2(x, y - 82.0),
				Vector2(x + 58.0, y - 38.0),
			]),
			Color("#8b5a3c")
		)
		draw_rect(Rect2(x - 10.0, y - 5.0, 21.0, 29.0), Color("#654321"))
		draw_rect(Rect2(x - 37.0, y - 23.0, 14.0, 13.0), Color("#f0d99a"))
		draw_rect(Rect2(x + 23.0, y - 23.0, 14.0, 13.0), Color("#f0d99a"))
		draw_rect(Rect2(x + 26.0, y - 74.0, 10.0, 24.0), Color("#76513a"))
		draw_circle(Vector2(x + 31.0, y - 82.0), 6.0, Color(0.95, 0.92, 0.82, 0.45))
		draw_circle(Vector2(x + 39.0, y - 94.0), 8.0, Color(0.95, 0.92, 0.82, 0.25))


var _save_file_path: String = DEFAULT_SAVE_FILE_PATH
var _interface: Control
var _continue_button: Button
var _load_button: Button
var _name_input: LineEdit
var _slot_label: Label
var _status_label: Label
var _confirmation_dialog: ConfirmationDialog
var _settings_panel: Control
var _volume_slider: HSlider
var _fullscreen_toggle: CheckButton
var _pending_confirmation: String = ""
var _audio_director: HearthwoodAudioDirector


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_create_interface()
	_create_audio_director()
	_load_settings()
	_refresh_save_slot()


func configure_save_file_path(path: String) -> void:
	if path.is_empty():
		push_error("Main menu save path cannot be empty.")
		return
	_save_file_path = path
	if is_node_ready():
		_refresh_save_slot()


func _create_interface() -> void:
	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_interface)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("#20382f")
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(backdrop)

	var content_panel := PanelContainer.new()
	content_panel.name = "contentPanel"
	content_panel.anchor_left = 0.035
	content_panel.anchor_top = 0.055
	content_panel.anchor_right = 0.52
	content_panel.anchor_bottom = 0.945
	_interface.add_child(content_panel)
	content_panel.add_theme_stylebox_override(
		"panel",
		_create_panel_style(Color("#f5f0d9"), Color("#8fbc8f"))
	)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 18)
	content_margin.add_theme_constant_override("margin_top", 14)
	content_margin.add_theme_constant_override("margin_right", 18)
	content_margin.add_theme_constant_override("margin_bottom", 14)
	content_panel.add_child(content_margin)

	var menu_layout := VBoxContainer.new()
	menu_layout.add_theme_constant_override("separation", 6)
	content_margin.add_child(menu_layout)

	var title := Label.new()
	title.text = "Hearthwood"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#5d422c"))
	menu_layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Warung Rimba"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("#6b8050"))
	menu_layout.add_child(subtitle)

	var name_label := Label.new()
	name_label.text = "Nama pemain"
	menu_layout.add_child(name_label)
	_name_input = LineEdit.new()
	_name_input.name = "playerName"
	_name_input.text = "Pengelana"
	_name_input.placeholder_text = "Masukkan nama"
	_name_input.custom_minimum_size = Vector2(0.0, 48.0)
	menu_layout.add_child(_name_input)

	_continue_button = _create_button("Lanjutkan")
	_continue_button.name = "continueButton"
	_continue_button.pressed.connect(_load_saved_game)
	menu_layout.add_child(_continue_button)

	var new_game_button := _create_button("Permainan baru")
	new_game_button.name = "newGameButton"
	new_game_button.pressed.connect(_on_new_game_pressed)
	menu_layout.add_child(new_game_button)

	_load_button = _create_button("Muat game")
	_load_button.name = "loadButton"
	_load_button.pressed.connect(_on_load_pressed)
	menu_layout.add_child(_load_button)

	var settings_button := _create_button("Pengaturan")
	settings_button.name = "settingsButton"
	settings_button.pressed.connect(_open_settings)
	menu_layout.add_child(settings_button)

	var exit_button := _create_button("Keluar")
	exit_button.name = "exitButton"
	exit_button.pressed.connect(_on_exit_pressed)
	menu_layout.add_child(exit_button)

	_slot_label = Label.new()
	_slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_layout.add_child(_slot_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("#8b5a3c"))
	menu_layout.add_child(_status_label)

	var art_panel := PanelContainer.new()
	art_panel.name = "artPanel"
	art_panel.anchor_left = 0.55
	art_panel.anchor_top = 0.08
	art_panel.anchor_right = 0.965
	art_panel.anchor_bottom = 0.92
	_interface.add_child(art_panel)
	art_panel.add_theme_stylebox_override(
		"panel",
		_create_panel_style(Color("#f5f0d9"), Color("#8fbc8f"))
	)
	var art_layout := VBoxContainer.new()
	art_layout.add_theme_constant_override("separation", 8)
	art_panel.add_child(art_layout)
	var art_title := Label.new()
	art_title.text = "Hari yang tenang menanti"
	art_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_title.add_theme_font_size_override("font_size", 22)
	art_title.add_theme_color_override("font_color", Color("#5d422c"))
	art_layout.add_child(art_title)
	var landscape := MenuLandscape.new()
	landscape.custom_minimum_size = Vector2(0.0, 340.0)
	landscape.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_layout.add_child(landscape)
	var art_caption := Label.new()
	art_caption.text = "Jelajahi hutan · masak bersama · bangun warung"
	art_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	art_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	art_layout.add_child(art_caption)

	_create_confirmation_dialog()
	_create_settings_panel()


func _create_confirmation_dialog() -> void:
	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.name = "confirmationDialog"
	_confirmation_dialog.title = "Konfirmasi"
	_confirmation_dialog.confirmed.connect(_confirm_pending_action)
	_confirmation_dialog.get_ok_button().custom_minimum_size = Vector2(112.0, 48.0)
	_confirmation_dialog.get_cancel_button().custom_minimum_size = Vector2(112.0, 48.0)
	add_child(_confirmation_dialog)


func _create_settings_panel() -> void:
	_settings_panel = Control.new()
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_interface.add_child(_settings_panel)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.08, 0.1, 0.08, 0.68)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_panel.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.25
	panel.anchor_top = 0.22
	panel.anchor_right = 0.75
	panel.anchor_bottom = 0.78
	_settings_panel.add_child(panel)
	panel.add_theme_stylebox_override(
		"panel",
		_create_panel_style(Color("#f5f0d9"), Color("#8fbc8f"))
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Pengaturan"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(title)

	var volume_caption := Label.new()
	volume_caption.text = "Volume"
	layout.add_child(volume_caption)
	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 5.0
	_volume_slider.custom_minimum_size = Vector2(0.0, 48.0)
	_volume_slider.value_changed.connect(_on_volume_changed)
	layout.add_child(_volume_slider)

	_fullscreen_toggle = CheckButton.new()
	_fullscreen_toggle.text = "Layar penuh"
	_fullscreen_toggle.custom_minimum_size = Vector2(0.0, 48.0)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	layout.add_child(_fullscreen_toggle)

	var close_button := _create_button("Kembali")
	close_button.pressed.connect(func() -> void: _settings_panel.visible = false)
	layout.add_child(close_button)


func _create_audio_director() -> void:
	_audio_director = AUDIO_DIRECTOR_SCRIPT.new()
	_audio_director.name = "AudioDirector"
	_audio_director.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_audio_director)
	_audio_director.play_music("forest")


func _refresh_save_slot() -> void:
	var game_state = get_node("/root/GameState")
	var summary: Dictionary = game_state.inspect_save_game(_save_file_path)
	var save_exists := bool(summary.get("exists", false))
	_continue_button.disabled = not save_exists
	_load_button.disabled = not save_exists
	if not save_exists:
		_slot_label.text = "Slot tunggal: belum ada save."
	elif bool(summary.get("valid", false)):
		_slot_label.text = "Slot tunggal: %s · hari %d · warung tier %d" % [
			str(summary["nama_pemain"]),
			int(summary["hari"]),
			int(summary["tier_warung"]),
		]
	else:
		_slot_label.text = "Save tidak dapat dibaca: %s" % str(summary.get("pesan", ""))


func _create_button(button_text: String) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("#4b3b2d"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#eadbb6")
	normal.border_color = Color("#b99863")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#f0dfb8")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#d3b27e")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	return button


func _create_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_top = 12.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 12.0
	return style


func _on_new_game_pressed() -> void:
	if bool(get_node("/root/GameState").has_save_game(_save_file_path)):
		_pending_confirmation = "new"
		_confirmation_dialog.dialog_text = (
			"Permainan baru akan memakai slot tunggal yang sama. "
			+ "Progres lama akan tergantikan saat game menyimpan otomatis."
		)
		_confirmation_dialog.popup_centered()
	else:
		_start_new_game()


func _on_load_pressed() -> void:
	_pending_confirmation = "load"
	_confirmation_dialog.dialog_text = "Muat progres dari slot save tunggal?"
	_confirmation_dialog.popup_centered()


func _confirm_pending_action() -> void:
	var action := _pending_confirmation
	_pending_confirmation = ""
	if action == "new":
		_start_new_game()
	elif action == "load":
		_load_saved_game()


func _start_new_game() -> void:
	var game_state = get_node("/root/GameState")
	if not game_state.start_new_game(_name_input.text):
		_status_label.text = "Masukkan nama pemain sebelum memulai."
		return
	_enter_game()


func _load_saved_game() -> void:
	var game_state = get_node("/root/GameState")
	var result: Dictionary = game_state.load_game(_save_file_path, GAME_SCENE_PATH)
	if not bool(result.get("valid", false)):
		_status_label.text = str(result.get("pesan", "Game tidak dapat dimuat."))
		_refresh_save_slot()
		return
	game_state.pending_player_position = result["posisi"]
	get_node("/root/TimeSystem").sync_from_game_state()
	_enter_game()


func _enter_game() -> void:
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if error != OK:
		push_error("Could not open the game scene (code %d)." % error)
		_status_label.text = "Game tidak dapat dibuka."
		get_tree().paused = true


func _open_settings() -> void:
	_settings_panel.visible = true


func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_save_settings()


func _apply_volume(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		push_error("Master audio bus is unavailable.")
		return
	AudioServer.set_bus_volume_db(
		master_bus,
		linear_to_db(maxf(value / 100.0, 0.001))
	)


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if enabled
		else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_save_settings()


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		push_error("Could not load settings (code %d)." % error)
	_volume_slider.set_value_no_signal(float(config.get_value("audio", "volume", 80.0)))
	_fullscreen_toggle.set_pressed_no_signal(
		bool(config.get_value("display", "fullscreen", false))
	)
	_apply_volume(_volume_slider.value)
	if _fullscreen_toggle.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "volume", _volume_slider.value)
	config.set_value("display", "fullscreen", _fullscreen_toggle.button_pressed)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Could not save settings (code %d)." % error)


func _on_exit_pressed() -> void:
	get_tree().quit()
