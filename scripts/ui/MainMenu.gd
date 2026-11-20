extends CanvasLayer
class_name HearthwoodMainMenu

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")
const GAME_SCENE_PATH: String = "res://scenes/Main.tscn"
const SETTINGS_PATH: String = "user://settings.cfg"
const AUDIO_DIRECTOR_SCRIPT: Script = preload("res://scripts/systems/AudioDirector.gd")
const DEFAULT_SAVE_FILE_PATH: String = "user://savegame.json"
const PROLOGUE_SEQUENCE_SCENE: PackedScene = preload("res://scenes/ui/PrologueSequence.tscn")
const PROLOGUE_SEQUENCE_SCRIPT: Script = preload("res://scripts/ui/PrologueSequence.gd")

# Latar Belakang Rimba & Pohon Conifer Geometris Taktil (FigCraft v0.5.2)
class MenuLandscape extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		# 1. Langit Rimba Malam Gelap
		draw_rect(Rect2(Vector2.ZERO, size), HearthwoodThemeHelper.COLOR_FOREST_DARK)

		# 2. Pendaran Lentera Kedai di Tengah
		draw_circle(
			Vector2(size.x * 0.5, size.y * 0.38),
			size.y * 0.38,
			Color(0.8, 0.52, 0.25, 0.11)
		)

		# 3. Kabut Rimba Bawah Lembut
		draw_rect(
			Rect2(0.0, size.y * 0.72, size.x, size.y * 0.28),
			Color(0.12, 0.23, 0.1, 0.45)
		)

		# 4. Hutan Conifer Kiri
		_draw_conifer(size.x * 0.08, size.y * 0.92, 1.25)
		_draw_conifer(size.x * 0.17, size.y * 0.96, 0.92)

		# 5. Hutan Conifer Kanan
		_draw_conifer(size.x * 0.92, size.y * 0.92, 1.3)
		_draw_conifer(size.x * 0.82, size.y * 0.96, 0.95)

		# 6. Partikel Kunang-kunang / Percikan Bara Api Malam
		var embers := [
			Vector2(size.x * 0.20, size.y * 0.26),
			Vector2(size.x * 0.24, size.y * 0.52),
			Vector2(size.x * 0.16, size.y * 0.76),
			Vector2(size.x * 0.11, size.y * 0.12),
			Vector2(size.x * 0.76, size.y * 0.30),
			Vector2(size.x * 0.74, size.y * 0.58),
			Vector2(size.x * 0.83, size.y * 0.82),
			Vector2(size.x * 0.91, size.y * 0.08),
		]
		for ember in embers:
			draw_circle(ember, 2.5, Color(0.96, 0.77, 0.54, 0.85))
			draw_circle(ember, 4.5, Color(0.96, 0.77, 0.54, 0.2))

	func _draw_conifer(base_x: float, base_y: float, scale_val: float) -> void:
		# Batang Pohon
		var trunk_w := 10.0 * scale_val
		var trunk_h := 160.0 * scale_val
		draw_rect(
			Rect2(base_x - trunk_w * 0.5, base_y - trunk_h, trunk_w, trunk_h),
			Color("#091208")
		)
		# 4 Tingkat Ranting Segitiga Conifer (Bawah ke Atas)
		var tiers := [
			{"w": 140.0, "h": 90.0, "offset_y": 70.0, "col": Color("#0e1c0d")},
			{"w": 110.0, "h": 80.0, "offset_y": 125.0, "col": Color("#122411")},
			{"w": 80.0, "h": 70.0, "offset_y": 175.0, "col": Color("#172f16")},
			{"w": 50.0, "h": 60.0, "offset_y": 215.0, "col": Color("#1d3b1c")},
		]
		for tier in tiers:
			var w: float = tier["w"] * scale_val
			var h: float = tier["h"] * scale_val
			var tip_y: float = base_y - (tier["offset_y"] * scale_val) - h
			var poly := PackedVector2Array([
				Vector2(base_x - w * 0.5, tip_y + h),
				Vector2(base_x, tip_y),
				Vector2(base_x + w * 0.5, tip_y + h),
			])
			draw_colored_polygon(poly, tier["col"])


var _save_file_path: String = DEFAULT_SAVE_FILE_PATH
var enable_prologue: bool = true
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
	if _save_file_path != DEFAULT_SAVE_FILE_PATH:
		enable_prologue = false
	if is_node_ready():
		_refresh_save_slot()


func _create_interface() -> void:
	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_interface)

	# 1. Kanvas Latar Belakang Rimba Malam
	var landscape := MenuLandscape.new()
	landscape.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	landscape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(landscape)

	# 2. Plang Papan Kedai Tengah (Tavern Signboard Panel)
	var content_panel := PanelContainer.new()
	content_panel.name = "contentPanel"
	content_panel.anchor_left = 0.28
	content_panel.anchor_top = 0.02
	content_panel.anchor_right = 0.72
	content_panel.anchor_bottom = 0.98
	_interface.add_child(content_panel)
	content_panel.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_tavern_panel_style()
	)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 20)
	content_margin.add_theme_constant_override("margin_top", 10)
	content_margin.add_theme_constant_override("margin_right", 20)
	content_margin.add_theme_constant_override("margin_bottom", 10)
	content_panel.add_child(content_margin)

	var menu_layout := VBoxContainer.new()
	menu_layout.add_theme_constant_override("separation", 6)
	content_margin.add_child(menu_layout)

	# 3. Header Crest & Tipografi
	var genre_badge := Label.new()
	genre_badge.text = "WARTEG MEDIEVAL"
	genre_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	genre_badge.add_theme_font_size_override("font_size", 10)
	genre_badge.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_GOLD)
	genre_badge.add_theme_stylebox_override("normal", HearthwoodThemeHelper.create_brass_badge_style())
	menu_layout.add_child(genre_badge)

	var title := Label.new()
	title.text = "HEARTHWOOD"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	menu_layout.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "WARUNG RIMBA"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_GOLD_AMBER)
	menu_layout.add_child(subtitle)

	var tagline := Label.new()
	tagline.text = "~ Kehangatan Dapur di Tepian Rimba ~"
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tagline.add_theme_font_size_override("font_size", 10)
	tagline.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM_MUTED)
	menu_layout.add_child(tagline)

	# 4. Kartu Slot Simpan Aktif (Recessed Save Slot Card)
	var slot_card := PanelContainer.new()
	slot_card.custom_minimum_size = Vector2(0.0, 36.0)
	slot_card.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style()
	)
	menu_layout.add_child(slot_card)

	var slot_margin := MarginContainer.new()
	slot_margin.add_theme_constant_override("margin_left", 8)
	slot_margin.add_theme_constant_override("margin_top", 4)
	slot_margin.add_theme_constant_override("margin_right", 8)
	slot_margin.add_theme_constant_override("margin_bottom", 4)
	slot_card.add_child(slot_margin)

	_slot_label = Label.new()
	_slot_label.name = "slotLabel"
	_slot_label.text = "Slot 1: Memuat progres..."
	_slot_label.add_theme_font_size_override("font_size", 11)
	_slot_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	_slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot_margin.add_child(_slot_label)

	# 5. Baris Input Nama Pemain (LineEdit)
	var name_box := HBoxContainer.new()
	name_box.add_theme_constant_override("separation", 8)
	menu_layout.add_child(name_box)

	var name_caption := Label.new()
	name_caption.text = "Pengelana:"
	name_caption.add_theme_font_size_override("font_size", 11)
	name_caption.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM_MUTED)
	name_box.add_child(name_caption)

	_name_input = LineEdit.new()
	_name_input.name = "playerName"
	_name_input.text = "Pengelana"
	_name_input.placeholder_text = "Nama Anda"
	_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_input.custom_minimum_size = Vector2(0.0, 34.0)
	_name_input.add_theme_font_size_override("font_size", 12)
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = HearthwoodThemeHelper.COLOR_SLOT_RECESSED
	input_style.border_color = HearthwoodThemeHelper.COLOR_BROWN_LIGHT
	input_style.set_border_width_all(1)
	input_style.set_corner_radius_all(4)
	input_style.content_margin_left = 8.0
	input_style.content_margin_right = 8.0
	_name_input.add_theme_stylebox_override("normal", input_style)
	_name_input.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	name_box.add_child(_name_input)

	# 6. Tombol Aksi 3D Beveled (5 Tombol, height >= 44)
	_continue_button = Button.new()
	_continue_button.name = "continueButton"
	_continue_button.text = "LANJUTKAN PERMAINAN"
	HearthwoodThemeHelper.apply_3d_button(_continue_button, "hero", 46.0, 13)
	_continue_button.pressed.connect(_load_saved_game)
	menu_layout.add_child(_continue_button)

	var new_game_button := Button.new()
	new_game_button.name = "newGameButton"
	new_game_button.text = "Permainan Baru"
	HearthwoodThemeHelper.apply_3d_button(new_game_button, "secondary", 44.0, 13)
	new_game_button.pressed.connect(_on_new_game_pressed)
	menu_layout.add_child(new_game_button)

	_load_button = Button.new()
	_load_button.name = "loadButton"
	_load_button.text = "Muat Game Lain"
	HearthwoodThemeHelper.apply_3d_button(_load_button, "secondary", 44.0, 13)
	_load_button.pressed.connect(_on_load_pressed)
	menu_layout.add_child(_load_button)

	var settings_button := Button.new()
	settings_button.name = "settingsButton"
	settings_button.text = "Pengaturan & Audio"
	HearthwoodThemeHelper.apply_3d_button(settings_button, "secondary", 44.0, 13)
	settings_button.pressed.connect(_open_settings)
	menu_layout.add_child(settings_button)

	var exit_button := Button.new()
	exit_button.name = "exitButton"
	exit_button.text = "Keluar Permainan"
	HearthwoodThemeHelper.apply_3d_button(exit_button, "danger", 44.0, 13)
	exit_button.pressed.connect(_on_exit_pressed)
	menu_layout.add_child(exit_button)

	# 7. Label Status / Notifikasi
	_status_label = Label.new()
	_status_label.name = "statusLabel"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_GOLD_AMBER)
	menu_layout.add_child(_status_label)

	# 8. Footer Metadata
	var version_footer := Label.new()
	version_footer.text = "Hearthwood v0.5.3 · Godot 4.x & Antigravity"
	version_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_footer.add_theme_font_size_override("font_size", 9)
	version_footer.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM_MUTED)
	menu_layout.add_child(version_footer)

	_create_confirmation_dialog()
	_create_settings_panel()


func _create_confirmation_dialog() -> void:
	_confirmation_dialog = ConfirmationDialog.new()
	_confirmation_dialog.name = "confirmationDialog"
	_confirmation_dialog.title = "Konfirmasi Kedai"
	_confirmation_dialog.confirmed.connect(_confirm_pending_action)
	_confirmation_dialog.get_ok_button().custom_minimum_size = Vector2(112.0, 48.0)
	_confirmation_dialog.get_cancel_button().custom_minimum_size = Vector2(112.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(_confirmation_dialog.get_ok_button(), "hero", 48.0, 13)
	HearthwoodThemeHelper.apply_3d_button(_confirmation_dialog.get_cancel_button(), "muted", 48.0, 13)
	add_child(_confirmation_dialog)


func _create_settings_panel() -> void:
	_settings_panel = Control.new()
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_panel.visible = false
	_interface.add_child(_settings_panel)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.05, 0.08, 0.05, 0.75)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_panel.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.28
	panel.anchor_top = 0.18
	panel.anchor_right = 0.72
	panel.anchor_bottom = 0.82
	_settings_panel.add_child(panel)
	panel.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_tavern_panel_style(HearthwoodThemeHelper.COLOR_PAUSE_WOOD)
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
	title.text = "PENGATURAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	layout.add_child(title)

	var volume_caption := Label.new()
	volume_caption.text = "Volume Musik & Efek:"
	volume_caption.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM_MUTED)
	layout.add_child(volume_caption)

	_volume_slider = HSlider.new()
	_volume_slider.min_value = 0.0
	_volume_slider.max_value = 100.0
	_volume_slider.step = 5.0
	_volume_slider.custom_minimum_size = Vector2(0.0, 48.0)
	_volume_slider.value_changed.connect(_on_volume_changed)
	layout.add_child(_volume_slider)

	_fullscreen_toggle = CheckButton.new()
	_fullscreen_toggle.text = "Mode Layar Penuh"
	_fullscreen_toggle.custom_minimum_size = Vector2(0.0, 48.0)
	_fullscreen_toggle.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_CREAM)
	_fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	layout.add_child(_fullscreen_toggle)

	var close_button := Button.new()
	close_button.text = "Kembali ke Menu"
	HearthwoodThemeHelper.apply_3d_button(close_button, "secondary", 46.0, 13)
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
		_slot_label.text = "● Belum ada riwayat petualangan tersimpan."
	elif bool(summary.get("valid", false)):
		_slot_label.text = "● Slot 1: %s · Hari %d · Warung Tier %d" % [
			str(summary["nama_pemain"]),
			int(summary["hari"]),
			int(summary["tier_warung"]),
		]
	else:
		_slot_label.text = "Save tidak dapat dibaca: %s" % str(summary.get("pesan", ""))


func _on_new_game_pressed() -> void:
	if bool(get_node("/root/GameState").has_save_game(_save_file_path)):
		_pending_confirmation = "new"
		_confirmation_dialog.dialog_text = (
			"Permainan baru akan menimpa slot save tunggal yang ada saat permainan disimpan."
		)
		_confirmation_dialog.popup_centered()
	else:
		_start_new_game()


func _on_load_pressed() -> void:
	_pending_confirmation = "load"
	_confirmation_dialog.dialog_text = "Muat petualangan dari slot save aktif?"
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
		_status_label.text = "Masukkan nama pengelana sebelum memulai."
		return
	if enable_prologue:
		var prologue = PROLOGUE_SEQUENCE_SCENE.instantiate()
		if prologue != null:
			add_child(prologue)
			prologue.sequence_completed.connect(_enter_game)
			prologue.start_sequence(_name_input.text)
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
