extends CanvasLayer
class_name HearthwoodWarungUI

var _interface: Control
var _title_label: Label
var _details_label: Label
var _status_label: Label
var _upgrade_button: Button
var _warung_system: HearthwoodWarungSystem


func _ready() -> void:
	_create_interface()
	get_node("/root/GameState").state_changed.connect(_refresh_interface)


func set_warung_system(warung_system: HearthwoodWarungSystem) -> void:
	_warung_system = warung_system


func open_upgrade() -> void:
	_interface.visible = true
	_refresh_interface()


func close_upgrade() -> void:
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
	panel.anchor_top = 0.2
	panel.anchor_right = 0.9
	panel.anchor_bottom = 0.8
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

	_details_label = Label.new()
	_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(_details_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_color", Color("#5d422c"))
	layout.add_child(_status_label)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	footer.alignment = BoxContainer.ALIGNMENT_END
	layout.add_child(footer)

	_upgrade_button = Button.new()
	_upgrade_button.custom_minimum_size = Vector2(220.0, 52.0)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	footer.add_child(_upgrade_button)

	var close_button := Button.new()
	close_button.text = "Batal"
	close_button.custom_minimum_size = Vector2(112.0, 52.0)
	close_button.pressed.connect(close_upgrade)
	footer.add_child(close_button)


func _refresh_interface() -> void:
	if _title_label == null or _warung_system == null:
		return
	var current_tier := _warung_system.get_current_tier()
	if current_tier.is_empty():
		_title_label.text = "Progresi warung"
		_details_label.text = "Data tier warung tidak tersedia."
		_status_label.text = ""
		_upgrade_button.text = "Upgrade tidak tersedia"
		_upgrade_button.disabled = true
		return

	var game_state = get_node("/root/GameState")
	_title_label.text = "Izin usaha Veral — %s" % str(current_tier["nama"])
	_details_label.text = "Reputasi: %d  ·  Koin: %d  ·  Kapasitas pelayanan: %d pelanggan/hari" % [
		game_state.reputation,
		game_state.coins,
		int(current_tier["kapasitas_pelanggan"]),
	]
	var preview := _warung_system.get_upgrade_preview()
	if not preview.has("tier"):
		_upgrade_button.text = "Tier maksimal"
		_upgrade_button.disabled = true
		_status_label.text = str(preview.get("pesan", ""))
		return

	var next_tier: Dictionary = preview["tier"]
	var requirements := PackedStringArray()
	requirements.append("Reputasi %d" % int(next_tier["reputasi"]))
	requirements.append("%d koin" % int(next_tier["biaya_koin"]))
	for item_id in next_tier["bahan"]:
		var definition: Dictionary = game_state.get_item_definition(str(item_id))
		requirements.append("%s ×%d" % [
			str(definition.get("nama", item_id)),
			int(next_tier["bahan"][item_id]),
		])
	_details_label.text += "\nUpgrade ke %s: %s\nAlat: %s (maks. %d porsi) · Pelanggan baru: %d." % [
		str(next_tier["nama"]),
		", ".join(requirements),
		str(next_tier["alat"]).replace("_", " ").capitalize(),
		int(next_tier["maks_porsi"]),
		next_tier["pelanggan"].size(),
	]
	_upgrade_button.text = "Minta izin & upgrade"
	_upgrade_button.disabled = not bool(preview.get("valid", false))
	_status_label.text = (
		"Persyaratan terpenuhi. Veral siap memberi izin."
		if bool(preview.get("valid", false))
		else str(preview.get("pesan", ""))
	)


func _on_upgrade_pressed() -> void:
	if _warung_system == null:
		push_error("Warung UI opened without a warung system.")
		return
	var result := _warung_system.upgrade_tier()
	_refresh_interface()
	if bool(result.get("valid", false)):
		_status_label.text = str(result.get("pesan", ""))
	else:
		_status_label.text = str(result.get("pesan", "Upgrade tidak dapat dilakukan."))
