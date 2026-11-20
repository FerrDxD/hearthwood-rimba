class_name HearthwoodPrologueSequence
extends CanvasLayer

signal sequence_completed

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")
const PROLOGUE_DATA_PATH: String = "res://data/quests/opening_prologue.json"

# Palet Visual Impeccable & UI-UX Pro Max
const COLOR_BLACKOUT: Color = Color("#0A0908")
const COLOR_FOREST_CANOPY: Color = Color("#0D1D0F")
const COLOR_PARCHMENT_TEXT: Color = Color("#F5F5DC")
const COLOR_QUESTION_GOLD: Color = Color("#E5A858")
const COLOR_HINT_MUTED: Color = Color("#D4C5A9")

# Kanvas Rimbun Kanopi Suaka Pohon Raksasa (FigCraft v0.5.2)
class CanopyBackdrop extends Control:
	func _ready() -> void:
		resized.connect(queue_redraw)

	func _draw() -> void:
		# 1. Gradasi Kanopi Hutan Rimba Pagi
		draw_rect(Rect2(Vector2.ZERO, size), COLOR_FOREST_CANOPY)

		# 2. Pendaran Sinar Mentari Menembus Ranting (God Rays)
		var rays := [
			[Vector2(size.x * 0.25, 0.0), Vector2(size.x * 0.10, size.y), 90.0, Color(0.95, 0.85, 0.55, 0.08)],
			[Vector2(size.x * 0.50, 0.0), Vector2(size.x * 0.42, size.y), 130.0, Color(0.98, 0.90, 0.65, 0.12)],
			[Vector2(size.x * 0.75, 0.0), Vector2(size.x * 0.85, size.y), 100.0, Color(0.95, 0.85, 0.55, 0.07)],
		]
		for ray in rays:
			var origin: Vector2 = ray[0]
			var dest: Vector2 = ray[1]
			var width_val: float = ray[2]
			var col: Color = ray[3]
			var poly := PackedVector2Array([
				Vector2(origin.x - width_val * 0.25, 0.0),
				Vector2(origin.x + width_val * 0.25, 0.0),
				Vector2(dest.x + width_val * 0.5, size.y),
				Vector2(dest.x - width_val * 0.5, size.y),
			])
			draw_colored_polygon(poly, col)

		# 3. Siluet Daun Kanopi Atas Rimbun
		var leaf_clusters := [
			Vector2(size.x * 0.15, 40.0),
			Vector2(size.x * 0.35, 70.0),
			Vector2(size.x * 0.65, 60.0),
			Vector2(size.x * 0.85, 45.0),
			Vector2(size.x * 0.50, 25.0),
		]
		for c in leaf_clusters:
			draw_circle(c, 80.0, Color(0.06, 0.13, 0.07, 0.75))
			draw_circle(c + Vector2(20.0, 15.0), 60.0, Color(0.09, 0.18, 0.10, 0.65))

		# 4. Partikel Butiran Debu Rimba / Spora Emas Mengambang
		var spores := [
			Vector2(size.x * 0.18, size.y * 0.45),
			Vector2(size.x * 0.32, size.y * 0.60),
			Vector2(size.x * 0.48, size.y * 0.38),
			Vector2(size.x * 0.62, size.y * 0.72),
			Vector2(size.x * 0.80, size.y * 0.50),
		]
		for s in spores:
			draw_circle(s, 2.0, Color(1.0, 0.92, 0.65, 0.75))
			draw_circle(s, 4.0, Color(1.0, 0.92, 0.65, 0.22))


var _is_running: bool = false
var _is_typing: bool = false
var _player_name: String = "Pengelana"
var _lines: Array[Dictionary] = []
var _current_step: int = -1
var _has_awakened: bool = false

var _root_control: Control
var _canopy_layer: CanopyBackdrop
var _blackout_bg: ColorRect
var _curtain_top: ColorRect
var _curtain_bottom: ColorRect
var _content_panel: PanelContainer
var _monologue_label: Label
var _hint_label: Label
var _skip_button: Button

var _typewriter_tween: Tween
var _curtain_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	if _root_control != null:
		return

	_root_control = Control.new()
	_root_control.name = "PrologueRoot"
	_root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_control.mouse_filter = Control.MOUSE_FILTER_STOP
	_root_control.gui_input.connect(_on_root_gui_input)
	add_child(_root_control)

	# 1. Lapisan Kanopi Rimba (muncul saat mengerjapkan mata)
	_canopy_layer = CanopyBackdrop.new()
	_canopy_layer.name = "CanopyBackdrop"
	_canopy_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canopy_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canopy_layer.modulate.a = 0.0
	_root_control.add_child(_canopy_layer)

	# 2. Lapisan Latar Hitam Gelap (#0A0908)
	_blackout_bg = ColorRect.new()
	_blackout_bg.name = "BlackoutBg"
	_blackout_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blackout_bg.color = COLOR_BLACKOUT
	_blackout_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_blackout_bg)

	# 3. Kelopak Mata Atas & Bawah untuk Efek Mengerjap (Blinking Eyes)
	_curtain_top = ColorRect.new()
	_curtain_top.name = "CurtainTop"
	_curtain_top.anchor_left = 0.0
	_curtain_top.anchor_right = 1.0
	_curtain_top.anchor_top = 0.0
	_curtain_top.anchor_bottom = 0.5
	_curtain_top.offset_left = 0.0
	_curtain_top.offset_right = 0.0
	_curtain_top.offset_top = 0.0
	_curtain_top.offset_bottom = 0.0
	_curtain_top.color = COLOR_BLACKOUT
	_curtain_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_curtain_top)

	_curtain_bottom = ColorRect.new()
	_curtain_bottom.name = "CurtainBottom"
	_curtain_bottom.anchor_left = 0.0
	_curtain_bottom.anchor_right = 1.0
	_curtain_bottom.anchor_top = 0.5
	_curtain_bottom.anchor_bottom = 1.0
	_curtain_bottom.offset_left = 0.0
	_curtain_bottom.offset_right = 0.0
	_curtain_bottom.offset_top = 0.0
	_curtain_bottom.offset_bottom = 0.0
	_curtain_bottom.color = COLOR_BLACKOUT
	_curtain_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_curtain_bottom)

	# 4. Wadah Teks Monolog Tengah
	_content_panel = PanelContainer.new()
	_content_panel.name = "TextPanel"
	_content_panel.anchor_left = 0.15
	_content_panel.anchor_right = 0.85
	_content_panel.anchor_top = 0.35
	_content_panel.anchor_bottom = 0.68
	_content_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_control.add_child(_content_panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.04, 0.04, 0.65)
	panel_style.border_color = Color(0.5, 0.4, 0.25, 0.3)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 28.0
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_right = 28.0
	panel_style.content_margin_bottom = 20.0
	_content_panel.add_theme_stylebox_override("panel", panel_style)

	var text_vbox := VBoxContainer.new()
	text_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_theme_constant_override("separation", 14)
	_content_panel.add_child(text_vbox)

	_monologue_label = Label.new()
	_monologue_label.name = "MonologueLabel"
	_monologue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_monologue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_monologue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_monologue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_monologue_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_monologue_label.add_theme_font_size_override("font_size", 18)
	_monologue_label.add_theme_color_override("font_color", COLOR_PARCHMENT_TEXT)
	_monologue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_vbox.add_child(_monologue_label)

	_hint_label = Label.new()
	_hint_label.name = "HintLabel"
	_hint_label.text = "Sentuh layar untuk lanjut ▶"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", COLOR_HINT_MUTED)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.visible = false
	text_vbox.add_child(_hint_label)

	# 5. Tombol Lewati (Skip Button) di Kanan Atas (>= 48x48 px touch target)
	_skip_button = Button.new()
	_skip_button.name = "SkipButton"
	_skip_button.text = "Lewati >>"
	_skip_button.anchor_left = 1.0
	_skip_button.anchor_right = 1.0
	_skip_button.anchor_top = 0.0
	_skip_button.anchor_bottom = 0.0
	_skip_button.offset_left = -140.0
	_skip_button.offset_right = -20.0
	_skip_button.offset_top = 20.0
	_skip_button.offset_bottom = 68.0
	_skip_button.custom_minimum_size = Vector2(104.0, 48.0)
	_skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	HearthwoodThemeHelper.apply_3d_button(_skip_button, "secondary", 48.0, 13)
	_skip_button.pressed.connect(skip_sequence)
	_root_control.add_child(_skip_button)


func start_sequence(player_name: String = "") -> void:
	_build_ui()
	var trimmed_name := player_name.strip_edges()
	_player_name = trimmed_name if not trimmed_name.is_empty() else "Pengelana"
	_load_prologue_data()
	_is_running = true
	_has_awakened = false
	_current_step = -1
	advance_sequence()


func _load_prologue_data() -> void:
	_lines.clear()
	var file := FileAccess.open(PROLOGUE_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("PrologueSequence could not open " + PROLOGUE_DATA_PATH)
		_lines.append({
			"id": "fallback",
			"text": "Namaku %s... Perlahan kurasakan belaian angin sejuk rimba..." % _player_name,
			"is_awakening": false,
		})
		_lines.append({
			"id": "fallback_awaken",
			"text": "Aku mengerjapkan mata di bawah kanopi suaka pohon raksasa...",
			"is_awakening": true,
		})
		return

	var raw_text := file.get_as_text()
	var data: Variant = JSON.parse_string(raw_text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("PrologueSequence data is not a Dictionary")
		return

	var dict: Dictionary = data
	if dict.has("monologues") and typeof(dict["monologues"]) == TYPE_ARRAY:
		for entry in dict["monologues"]:
			if typeof(entry) == TYPE_DICTIONARY:
				var line_dict: Dictionary = entry.duplicate()
				var formatted_text: String = str(line_dict.get("text", "")).replace("{player_name}", _player_name)
				line_dict["text"] = formatted_text
				line_dict["is_awakening"] = false
				_lines.append(line_dict)

	if dict.has("awakening") and typeof(dict["awakening"]) == TYPE_DICTIONARY:
		var awaken: Dictionary = dict["awakening"]
		if awaken.has("text"):
			_lines.append({
				"id": "awakening_text",
				"text": str(awaken["text"]),
				"is_awakening": true,
				"is_question": false,
			})
		if awaken.has("question"):
			_lines.append({
				"id": "awakening_question",
				"text": str(awaken["question"]),
				"is_awakening": true,
				"is_question": true,
			})


func advance_sequence() -> void:
	if not _is_running:
		return

	# Jika efek typewriter masih berjalan, klik mempercepat langsung selesai
	if _is_typing:
		_finish_typing_immediately()
		return

	_current_step += 1
	if _current_step >= _lines.size():
		_complete_sequence()
		return

	_display_current_step()


func _display_current_step() -> void:
	if _current_step < 0 or _current_step >= _lines.size():
		return

	var step_data: Dictionary = _lines[_current_step]
	var text_to_show: String = str(step_data.get("text", ""))
	var is_awakening: bool = bool(step_data.get("is_awakening", false))
	var is_question: bool = bool(step_data.get("is_question", false))

	# Transisi Mengerjap Mata (Blinking Eyes) saat fase awakening pertama
	if is_awakening and not _has_awakened:
		_has_awakened = true
		_play_blinking_eye_animation()

	if is_question:
		_monologue_label.add_theme_color_override("font_color", COLOR_QUESTION_GOLD)
	else:
		_monologue_label.add_theme_color_override("font_color", COLOR_PARCHMENT_TEXT)

	_monologue_label.text = text_to_show
	_monologue_label.visible_ratio = 0.0
	_hint_label.visible = false
	_is_typing = true

	if _typewriter_tween != null and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	var char_count := text_to_show.length()
	var duration := clampf(float(char_count) * 0.03, 0.6, 2.4)

	_typewriter_tween = create_tween()
	if _typewriter_tween != null:
		_typewriter_tween.tween_property(_monologue_label, "visible_ratio", 1.0, duration)
		_typewriter_tween.finished.connect(_on_typing_finished)
	else:
		_on_typing_finished()


func _finish_typing_immediately() -> void:
	if _typewriter_tween != null and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	_monologue_label.visible_ratio = 1.0
	_on_typing_finished()


func _on_typing_finished() -> void:
	_is_typing = false
	_hint_label.visible = true


func _play_blinking_eye_animation() -> void:
	# Buka pendaran kanopi rimba di belakang
	if _canopy_layer != null:
		_canopy_layer.modulate.a = 1.0
	if _blackout_bg != null:
		_blackout_bg.color = Color(0.04, 0.08, 0.05, 0.45)

	if _curtain_tween != null and _curtain_tween.is_valid():
		_curtain_tween.kill()

	_curtain_tween = create_tween()
	if _curtain_tween == null:
		return

	# Kerjipan 1: Membuka sedikit, lalu menutup cepat
	_curtain_tween.tween_property(_curtain_top, "anchor_bottom", 0.35, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_curtain_tween.parallel().tween_property(_curtain_bottom, "anchor_top", 0.65, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_curtain_tween.tween_property(_curtain_top, "anchor_bottom", 0.5, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_curtain_tween.parallel().tween_property(_curtain_bottom, "anchor_top", 0.5, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Jeda sejenak
	_curtain_tween.tween_interval(0.15)

	# Kerjipan 2: Membuka lebar sepenuhnya menampakkan kanopi Suaka Pohon Raksasa
	_curtain_tween.tween_property(_curtain_top, "anchor_bottom", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_curtain_tween.parallel().tween_property(_curtain_bottom, "anchor_top", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func skip_sequence() -> void:
	if not _is_running:
		return
	_complete_sequence()


func _complete_sequence() -> void:
	if _typewriter_tween != null and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	if _curtain_tween != null and _curtain_tween.is_valid():
		_curtain_tween.kill()

	_is_running = false
	_is_typing = false
	sequence_completed.emit()


func is_running() -> bool:
	return _is_running


func is_typing() -> bool:
	return _is_typing


func get_skip_button() -> Button:
	if _skip_button == null:
		_build_ui()
	return _skip_button


func get_current_line_text() -> String:
	if _monologue_label != null:
		return _monologue_label.text
	return ""


func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_sequence()
	elif event is InputEventScreenTouch and event.pressed:
		advance_sequence()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_running:
		return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		advance_sequence()
		get_viewport().set_input_as_handled()
