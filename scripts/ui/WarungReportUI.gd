# scripts/ui/WarungReportUI.gd
extends CanvasLayer
class_name HearthwoodWarungReportUI

signal closed()

const HearthwoodThemeHelper := preload("res://scripts/ui/UIThemeHelper.gd")

var _interface: Control
var _title_label: Label
var _customers_label: Label
var _coins_label: Label
var _reputation_label: Label
var _review_label: Label
var _close_button: Button


func _ready() -> void:
	_create_interface()


func open_report(summary: Dictionary) -> void:
	if _interface == null:
		_create_interface()

	var customers: int = int(summary.get("customers_served", 0))
	var coins: int = int(summary.get("total_coins_earned", 0))
	var rep: int = int(summary.get("reputation_gained", 0))

	_customers_label.text = "Pelanggan Terlayani :  %d warga" % customers
	_coins_label.text = "Pendapatan Koin     :  +%d koin" % coins
	_reputation_label.text = "Peningkatan Reputasi:  +%d poin" % rep

	if customers >= 4:
		_review_label.text = "\"Malam yang ramai dan hangat! Seluruh meja penuh dengan tawa dan aroma masakan rimba yang lezat.\""
	elif customers >= 2:
		_review_label.text = "\"Santap malam yang nikmat. Warga desa pulang dengan perut kenyang dan hati gembira.\""
	elif customers >= 1:
		_review_label.text = "\"Pelanggan menyantap hidangan hangat dengan lahap. Permulaan yang baik untuk warung rimba!\""
	else:
		_review_label.text = "\"Malam berlalu dengan tenang tanpa pesanan. Esok hari warung siap dibuka kembali.\""

	_interface.visible = true


func close_report() -> void:
	if _interface != null:
		_interface.visible = false
	closed.emit()


func is_open() -> bool:
	return _interface != null and _interface.visible


func _create_interface() -> void:
	if _interface != null:
		return

	_interface = Control.new()
	_interface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_interface.mouse_filter = Control.MOUSE_FILTER_STOP
	_interface.visible = false
	add_child(_interface)

	# Dim background overlay
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.04, 0.07, 0.04, 0.65)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interface.add_child(shade)

	# Main parchment card
	var panel := PanelContainer.new()
	panel.anchor_left = 0.2
	panel.anchor_top = 0.16
	panel.anchor_right = 0.8
	panel.anchor_bottom = 0.84
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
	layout.add_theme_constant_override("separation", 14)
	panel.add_child(layout)

	# Title
	_title_label = Label.new()
	_title_label.text = "Warta Penjualan Warung"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 22)
	_title_label.add_theme_color_override("font_color", Color("#4A2E18"))
	layout.add_child(_title_label)

	# Decorative divider
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0.0, 2.0)
	divider.color = Color("#C4A47C")
	layout.add_child(divider)

	# Details card
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style(
			Color("#FFFCF5"),
			Color("#C4A47C"),
			6
		)
	)
	layout.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 20)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_right", 20)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(card_margin)

	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 10)
	card_margin.add_child(stats_box)

	_customers_label = Label.new()
	_customers_label.add_theme_font_size_override("font_size", 15)
	_customers_label.add_theme_color_override("font_color", Color("#2E190A"))
	stats_box.add_child(_customers_label)

	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 15)
	_coins_label.add_theme_color_override("font_color", Color("#9A6400"))
	stats_box.add_child(_coins_label)

	_reputation_label = Label.new()
	_reputation_label.add_theme_font_size_override("font_size", 15)
	_reputation_label.add_theme_color_override("font_color", Color("#2F6E38"))
	stats_box.add_child(_reputation_label)

	var quote_box := PanelContainer.new()
	quote_box.add_theme_stylebox_override(
		"panel",
		HearthwoodThemeHelper.create_sunken_slot_style(
			Color("#F5EDE0"),
			Color("#D8C3A5"),
			4
		)
	)
	stats_box.add_child(quote_box)

	var quote_margin := MarginContainer.new()
	quote_margin.add_theme_constant_override("margin_left", 12)
	quote_margin.add_theme_constant_override("margin_top", 8)
	quote_margin.add_theme_constant_override("margin_right", 12)
	quote_margin.add_theme_constant_override("margin_bottom", 8)
	quote_box.add_child(quote_margin)

	_review_label = Label.new()
	_review_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_review_label.add_theme_font_size_override("font_size", 13)
	_review_label.add_theme_color_override("font_color", Color("#5C3D24"))
	quote_margin.add_child(_review_label)

	# Close button (>= 44x44 dp)
	var button_container := CenterContainer.new()
	layout.add_child(button_container)

	_close_button = Button.new()
	_close_button.text = "Tutup Toko"
	_close_button.custom_minimum_size = Vector2(160.0, 48.0)
	HearthwoodThemeHelper.apply_3d_button(_close_button, "primary", 48.0)
	_close_button.pressed.connect(close_report)
	button_container.add_child(_close_button)
