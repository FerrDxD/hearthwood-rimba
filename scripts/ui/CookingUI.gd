extends CanvasLayer
class_name HearthwoodCookingUI

class TimingTrack extends Control:
	const GREEN_ZONE_BY_WEATHER: Dictionary = {
		"cerah": 0.16,
		"hujan": 0.10,
		"badai": 0.06,
	}
	var active: bool = false
	var _marker: float = 0.0
	var _direction: float = 1.0

	func _ready() -> void:
		custom_minimum_size = Vector2(0.0, 40.0)
		set_process(false)

	func start_timing() -> void:
		active = true
		set_process(true)

	func get_green_zone_size() -> float:
		var weather := str(get_node("/root/GameState").current_weather)
		return float(GREEN_ZONE_BY_WEATHER.get(weather, GREEN_ZONE_BY_WEATHER["cerah"]))

	func get_green_zone_start() -> float:
		return 0.5 - get_green_zone_size() * 0.5

	func stop_timing() -> String:
		active = false
		set_process(false)
		var green_start := get_green_zone_start()
		if _marker >= green_start and _marker <= green_start + get_green_zone_size():
			return "green"
		if _marker >= 0.2 and _marker <= 0.8:
			return "yellow"
		return "red"

	func _process(delta: float) -> void:
		_marker += delta * 0.8 * _direction
		if _marker >= 1.0:
			_marker = 1.0
			_direction = -1.0
		elif _marker <= 0.0:
			_marker = 0.0
			_direction = 1.0
		queue_redraw()

	func _draw() -> void:
		var green_start := get_green_zone_start()
		draw_rect(Rect2(Vector2.ZERO, size), Color("#b95845"))
		draw_rect(Rect2(size.x * 0.2, 0.0, size.x * 0.6, size.y), Color("#d5aa4b"))
		draw_rect(
			Rect2(size.x * green_start, 0.0, size.x * get_green_zone_size(), size.y),
			Color("#6a9c59")
		)
		var marker_x := size.x * _marker
		draw_line(
			Vector2(marker_x, 0.0),
			Vector2(marker_x, size.y),
			Color("#fff9e7"),
			3.0
		)


var _interface: Control
var _cooking_system: HearthwoodCookingSystem
var _recipe_option: OptionButton
var _tool_option: OptionButton
var _portion_input: SpinBox
var _ingredient_label: Label
var _preview_label: Label
var _status_label: Label
var _timing_track: TimingTrack
var _timing_button: Button
var _selected_timing_result: String = "skip"


func _ready() -> void:
	_create_interface()


func set_cooking_system(cooking_system: HearthwoodCookingSystem) -> void:
	_cooking_system = cooking_system
	if not _cooking_system.recipes_unlocked.is_connected(_on_recipes_unlocked):
		_cooking_system.recipes_unlocked.connect(_on_recipes_unlocked)
	_refresh_recipes()
	_refresh_tools()


func open_cooking(cooking_system: HearthwoodCookingSystem) -> void:
	if _cooking_system != cooking_system:
		set_cooking_system(cooking_system)
	_selected_timing_result = "skip"
	_timing_button.text = "Mulai timing"
	_interface.visible = true
	_refresh_recipe_details()


func close_cooking() -> void:
	_timing_track.active = false
	_timing_track.set_process(false)
	_selected_timing_result = "skip"
	_timing_button.text = "Mulai timing"
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
	panel.anchor_top = 0.06
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.94
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
	layout.add_theme_constant_override("separation", 8)
	panel.add_child(layout)

	var title := Label.new()
	title.text = "Dapur Api Unggun"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(title)

	var recipe_caption := Label.new()
	recipe_caption.text = "Resep"
	layout.add_child(recipe_caption)
	_recipe_option = OptionButton.new()
	_recipe_option.custom_minimum_size = Vector2(48.0, 48.0)
	_recipe_option.item_selected.connect(_on_recipe_selected)
	layout.add_child(_recipe_option)

	var recipe_caption_row := HBoxContainer.new()
	recipe_caption_row.add_theme_constant_override("separation", 10)
	layout.add_child(recipe_caption_row)
	var tool_column := VBoxContainer.new()
	tool_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_caption_row.add_child(tool_column)
	var tool_caption := Label.new()
	tool_caption.text = "Alat"
	tool_column.add_child(tool_caption)
	_tool_option = OptionButton.new()
	_tool_option.custom_minimum_size = Vector2(48.0, 48.0)
	_tool_option.item_selected.connect(_on_tool_selected)
	tool_column.add_child(_tool_option)

	var portion_column := VBoxContainer.new()
	portion_column.custom_minimum_size = Vector2(130.0, 0.0)
	recipe_caption_row.add_child(portion_column)
	var portion_caption := Label.new()
	portion_caption.text = "Porsi"
	portion_column.add_child(portion_caption)
	_portion_input = SpinBox.new()
	_portion_input.min_value = 1
	_portion_input.max_value = 2
	_portion_input.step = 1
	_portion_input.value = 1
	_portion_input.custom_minimum_size = Vector2(120.0, 48.0)
	_portion_input.value_changed.connect(_on_portion_changed)
	portion_column.add_child(_portion_input)

	_ingredient_label = Label.new()
	_ingredient_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ingredient_label.custom_minimum_size = Vector2(0.0, 42.0)
	layout.add_child(_ingredient_label)

	_preview_label = Label.new()
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_preview_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(_status_label)

	var timing_caption := Label.new()
	timing_caption.text = "Timing opsional: hijau bagus, kuning sedang, merah kurang tepat."
	timing_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(timing_caption)

	_timing_track = TimingTrack.new()
	_timing_track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(_timing_track)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	layout.add_child(footer)
	_timing_button = Button.new()
	_timing_button.text = "Mulai timing"
	_timing_button.custom_minimum_size = Vector2(144.0, 48.0)
	_timing_button.pressed.connect(_on_timing_pressed)
	footer.add_child(_timing_button)

	var footer_spacer := Control.new()
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(footer_spacer)

	var cook_button := Button.new()
	cook_button.text = "Masak"
	cook_button.custom_minimum_size = Vector2(112.0, 48.0)
	cook_button.pressed.connect(_on_cook_pressed)
	footer.add_child(cook_button)

	var close_button := Button.new()
	close_button.text = "Batal"
	close_button.custom_minimum_size = Vector2(112.0, 48.0)
	close_button.pressed.connect(close_cooking)
	footer.add_child(close_button)


func _refresh_recipes() -> void:
	if _recipe_option == null or _cooking_system == null:
		return
	var selected_recipe := _get_selected_recipe_id()
	_recipe_option.clear()
	for recipe_id in _cooking_system.get_unlocked_recipe_ids():
		var recipe: Dictionary = _cooking_system.get_recipe(recipe_id)
		_recipe_option.add_item(str(recipe.get("nama", recipe_id)))
		_recipe_option.set_item_metadata(_recipe_option.item_count - 1, recipe_id)
	var selected_index := -1
	for index in _recipe_option.item_count:
		if str(_recipe_option.get_item_metadata(index)) == selected_recipe:
			selected_index = index
			break
	if selected_index < 0 and _recipe_option.item_count > 0:
		selected_index = 0
	if selected_index >= 0:
		_recipe_option.select(selected_index)
	_refresh_recipe_details()


func _refresh_tools() -> void:
	if _tool_option == null or _cooking_system == null:
		return
	var selected_tool := _get_selected_tool_id()
	_tool_option.clear()
	for tool_id in _cooking_system.get_available_tool_ids():
		_tool_option.add_item(_get_tool_name(tool_id))
		_tool_option.set_item_metadata(_tool_option.item_count - 1, tool_id)
	var selected_index := 0
	for index in _tool_option.item_count:
		if str(_tool_option.get_item_metadata(index)) == selected_tool:
			selected_index = index
			break
	if _tool_option.item_count > 0:
		_tool_option.select(selected_index)
	_refresh_recipe_details()


func _refresh_recipe_details() -> void:
	if _cooking_system == null or _ingredient_label == null:
		return
	var recipe_id := _get_selected_recipe_id()
	var recipe: Dictionary = _cooking_system.get_recipe(recipe_id)
	if recipe.is_empty():
		_ingredient_label.text = "Belum ada resep yang terbuka."
		_preview_label.text = ""
		return

	var game_state = get_node("/root/GameState")
	var tool_id := _get_selected_tool_id()
	var max_portions := _cooking_system.get_max_portions(tool_id)
	_portion_input.max_value = maxi(1, max_portions)
	_portion_input.value = clampf(_portion_input.value, 1.0, float(maxi(1, max_portions)))
	var portion_count := int(_portion_input.value)
	var ingredient_lines := PackedStringArray()
	for item_id in recipe["bahan_per_porsi"]:
		var definition: Dictionary = game_state.get_item_definition(str(item_id))
		var required_count := int(recipe["bahan_per_porsi"][item_id]) * portion_count
		var owned_count: int = game_state.get_item_count(str(item_id))
		ingredient_lines.append("%s %d/%d" % [
			str(definition.get("nama", item_id)),
			owned_count,
			required_count,
		])
	_ingredient_label.text = "Bahan dimiliki/dibutuhkan: %s" % ", ".join(ingredient_lines)

	var preview := _cooking_system.preview_cooking(
		recipe_id,
		portion_count,
		tool_id
	)
	_preview_label.text = str(preview.get("pesan", ""))


func _on_recipe_selected(_index: int) -> void:
	_refresh_recipe_details()


func _on_tool_selected(_index: int) -> void:
	_refresh_recipe_details()


func _on_portion_changed(_value: float) -> void:
	_refresh_recipe_details()


func _on_timing_pressed() -> void:
	if _timing_track.active:
		_selected_timing_result = _timing_track.stop_timing()
		_timing_button.text = "Ulang timing"
		_status_label.text = "Timing tercatat: %s." % _get_timing_name(_selected_timing_result)
	else:
		_selected_timing_result = "skip"
		_timing_track.start_timing()
		_timing_button.text = "Hentikan timing"
		_status_label.text = "Tekan Masak untuk menangkap timing."


func _on_cook_pressed() -> void:
	var timing_result := _selected_timing_result
	if _timing_track.active:
		timing_result = _timing_track.stop_timing()
		_timing_button.text = "Mulai timing"
	_selected_timing_result = "skip"
	var outcome := _cooking_system.cook(
		_get_selected_recipe_id(),
		int(_portion_input.value),
		_get_selected_tool_id(),
		timing_result
	)
	if not bool(outcome.get("valid", false)):
		_status_label.text = str(outcome.get("pesan", "Masakan gagal dibuat."))
		return
	_status_label.text = "%s siap: %d porsi, %d bintang." % [
		str(_cooking_system.get_recipe(str(outcome["resep"])).get("nama", outcome["resep"])),
		int(outcome["porsi"]),
		int(outcome["kualitas"]),
	]
	_refresh_recipe_details()


func _on_recipes_unlocked() -> void:
	_refresh_recipes()


func _get_selected_recipe_id() -> String:
	if _recipe_option == null or _recipe_option.selected < 0:
		return ""
	return str(_recipe_option.get_item_metadata(_recipe_option.selected))


func _get_selected_tool_id() -> String:
	if _tool_option == null or _tool_option.selected < 0:
		return ""
	return str(_tool_option.get_item_metadata(_tool_option.selected))


func _get_tool_name(tool_id: String) -> String:
	match tool_id:
		"api_unggun":
			return "Api unggun"
		"tungku":
			return "Tungku"
		"dapur_warteg":
			return "Dapur warteg"
	return tool_id


func _get_timing_name(timing_result: String) -> String:
	match timing_result:
		"green":
			return "bagus"
		"yellow":
			return "sedang"
		"red":
			return "kurang tepat"
	return "acak"
