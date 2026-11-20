extends CanvasLayer
class_name HearthwoodQuestUI

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")

var _interface: Control
var _quest_list: VBoxContainer
var _clue_list: VBoxContainer
var _clue_empty_label: Label
var _quest_system: HearthwoodQuestSystem


func _ready() -> void:
	_create_interface()


func set_quest_system(quest_system: HearthwoodQuestSystem) -> void:
	_quest_system = quest_system
	if is_open():
		_refresh()


func toggle_quests() -> void:
	if is_open():
		close_quests()
		return
	open_quests()


func open_quests() -> void:
	_interface.visible = true
	_refresh()


func close_quests() -> void:
	_interface.visible = false


func is_open() -> bool:
	return is_instance_valid(_interface) and _interface.visible


func _create_interface() -> void:
	_interface = Control.new()
	_interface.name = "QuestInterface"
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
	panel.anchor_left = 0.1
	panel.anchor_top = 0.06
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.94
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

	var title := Label.new()
	title.text = "📖 BUKU CATATAN — JURNAL QUEST"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#4a2e18"))
	layout.add_child(title)

	var scroll_container := ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll_container)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll_container.add_child(content)

	_quest_list = VBoxContainer.new()
	_quest_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_list.add_theme_constant_override("separation", 10)
	content.add_child(_quest_list)

	var clue_title := Label.new()
	clue_title.text = "Petunjuk Misteri Asap"
	clue_title.add_theme_font_size_override("font_size", 16)
	clue_title.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_BROWN)
	content.add_child(clue_title)

	_clue_empty_label = Label.new()
	_clue_empty_label.text = "Belum ada petunjuk asap yang terkumpul."
	_clue_empty_label.add_theme_color_override("font_color", Color("#6e4d35"))
	_clue_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_clue_empty_label)

	_clue_list = VBoxContainer.new()
	_clue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clue_list.add_theme_constant_override("separation", 6)
	content.add_child(_clue_list)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	var close_button := Button.new()
	close_button.text = "Tutup Jurnal"
	close_button.custom_minimum_size = Vector2(130.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(close_button, "secondary", 48.0, 13)
	close_button.pressed.connect(close_quests)
	footer.add_child(close_button)


func _refresh() -> void:
	if _quest_list == null:
		return
	_clear_children(_quest_list)
	_clear_children(_clue_list)

	if _quest_system == null:
		_quest_list.add_child(_create_label("Data quest belum tersedia.", 14))
		_clue_empty_label.visible = true
		return

	var quest_ids: Array[String] = _quest_system.get_quest_ids()
	if quest_ids.is_empty():
		_quest_list.add_child(_create_label("Belum ada quest yang terbuka.", 14))
	for npc_id in quest_ids:
		_quest_list.add_child(_create_quest_card(_quest_system.get_quest_summary(npc_id)))

	var clues: Array[String] = _quest_system.get_smoke_clues()
	_clue_empty_label.visible = clues.is_empty()
	for clue in clues:
		var clue_label := _create_label("• %s" % clue, 13)
		clue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_clue_list.add_child(clue_label)


func _create_quest_card(summary: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0.0, 96.0)
	card.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style(
			Color("#fffcf5"),
			Color("#c4a47c"),
			6
		)
	)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	card.add_child(layout)

	var header := _create_label("%s  ·  Hati %d/3" % [
		str(summary.get("nama", "")),
		int(summary.get("hati", 0)),
	], 17)
	header.add_theme_color_override("font_color", Color("#4a2e18"))
	layout.add_child(header)

	var chapter_line := "Selesai"
	if not bool(summary.get("selesai", false)):
		chapter_line = "Bab %d/%d: %s" % [
			int(summary.get("chapter_index", 0)) + 1,
			int(summary.get("total_chapter", 0)),
			str(summary.get("judul", "")),
		]
	var chapter_label := _create_label(chapter_line, 14)
	chapter_label.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_BROWN)
	layout.add_child(chapter_label)

	if not bool(summary.get("selesai", false)):
		var objective := _create_label(str(summary.get("objective", "")), 13)
		objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(objective)

		var requirement := _create_label("Syarat: %s" % str(summary.get("kebutuhan", "")), 13)
		requirement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		requirement.add_theme_color_override("font_color", Color("#8b5a3c"))
		layout.add_child(requirement)

		var reward := _create_label("Hadiah berikutnya: %s" % str(summary.get("hadiah", "")), 12)
		reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		reward.add_theme_color_override("font_color", HearthwoodThemeHelper.COLOR_GOLD)
		layout.add_child(reward)

	return card


func _create_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#4a2e18"))
	return label


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
