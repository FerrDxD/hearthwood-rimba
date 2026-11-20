class_name HearthwoodThemeHelper
extends RefCounted

# Palet Resmi DESIGN.md & FigCraft v0.5.2
const COLOR_CREAM: Color = Color("#f5f5dc")
const COLOR_CREAM_LIGHT: Color = Color("#fff9f0")
const COLOR_CREAM_MUTED: Color = Color("#d4c5a9")
const COLOR_BROWN: Color = Color("#8b4513")
const COLOR_BROWN_LIGHT: Color = Color("#a85e28")
const COLOR_BROWN_DARK: Color = Color("#4a250e")
const COLOR_SADDLE_WOOD: Color = Color("#7d4218")
const COLOR_TAVERN_WOOD: Color = Color("#361e10")
const COLOR_PAUSE_WOOD: Color = Color("#5c3a1e")
const COLOR_DARK_WOOD: Color = Color("#2e1e14")
const COLOR_SLOT_RECESSED: Color = Color("#25140a")
const COLOR_GOLD: Color = Color("#cd853f")
const COLOR_GOLD_AMBER: Color = Color("#e5a858")
const COLOR_GOLD_HIGHLIGHT: Color = Color("#f5c58a")
const COLOR_GOLD_LIP: Color = Color("#6e3911")
const COLOR_SAGE: Color = Color("#8fbc8f")
const COLOR_SAGE_DARK: Color = Color("#192e17")
const COLOR_TERRACOTTA: Color = Color("#b8482d")
const COLOR_TERRACOTTA_LIGHT: Color = Color("#dc6e55")
const COLOR_TERRACOTTA_LIP: Color = Color("#561b0e")
const COLOR_DARK_TEXT: Color = Color("#333333")
const COLOR_FOREST_DARK: Color = Color("#142413")
const COLOR_FOREST_MIST: Color = Color("#1e3a1a")

# Builder Gaya Panel Kayu Kedai Taktil
static func create_tavern_panel_style(
	bg: Color = COLOR_TAVERN_WOOD,
	border: Color = Color("#1b0e07"),
	corner: int = 10,
	border_w: int = 3
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(corner)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	return style


# Builder Gaya Panel Kertas Pergamen (Journal)
static func create_parchment_panel_style(
	bg: Color = COLOR_CREAM,
	border: Color = COLOR_SAGE,
	corner: int = 8,
	border_w: int = 3
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_w)
	style.set_corner_radius_all(corner)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 14.0
	style.content_margin_top = 14.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 14.0
	return style


# Builder Ceruk Slot Inventori Retro (48x48)
static func create_sunken_slot_style(
	bg: Color = COLOR_SLOT_RECESSED,
	border: Color = Color("#4a2810"),
	corner: int = 4
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 4.0
	style.content_margin_top = 4.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 4.0
	return style


# Builder Badge Plat Kuningan / Aksen
static func create_brass_badge_style(
	bg: Color = Color("#22120a"),
	border: Color = Color("#6b3b18"),
	corner: int = 4
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(corner)
	style.content_margin_left = 8.0
	style.content_margin_top = 3.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 3.0
	return style


# Terapkan Gaya Tombol 3D Beveled (Hero, Secondary, Danger, Muted)
static func apply_3d_button(
	button: Button,
	type: String = "secondary",
	min_height: float = 46.0,
	font_size: int = 14
) -> void:
	button.custom_minimum_size = Vector2(maxf(button.custom_minimum_size.x, 48.0), min_height)
	button.add_theme_font_size_override("font_size", font_size)

	var bg_col: Color
	var border_col: Color
	var shadow_col: Color
	var text_col: Color
	var shadow_y: float = 3.0

	match type:
		"hero":
			bg_col = COLOR_GOLD
			border_col = COLOR_GOLD_HIGHLIGHT
			shadow_col = COLOR_GOLD_LIP
			text_col = COLOR_CREAM_LIGHT
			shadow_y = 4.0
		"danger":
			bg_col = COLOR_TERRACOTTA
			border_col = COLOR_TERRACOTTA_LIGHT
			shadow_col = COLOR_TERRACOTTA_LIP
			text_col = Color("#fff0ec")
			shadow_y = 3.0
		"muted":
			bg_col = Color("#4a3324")
			border_col = Color("#6e4d35")
			shadow_col = Color("#281a10")
			text_col = COLOR_CREAM_MUTED
			shadow_y = 2.0
		_: # "secondary" (kayu kedai)
			bg_col = COLOR_SADDLE_WOOD
			border_col = COLOR_BROWN_LIGHT
			shadow_col = COLOR_BROWN_DARK
			text_col = COLOR_CREAM
			shadow_y = 3.0

	button.add_theme_color_override("font_color", text_col)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", text_col.darkened(0.15))
	button.add_theme_color_override("font_disabled_color", Color(0.65, 0.6, 0.55, 0.6))

	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_col
	normal.border_color = border_col
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.shadow_color = shadow_col
	normal.shadow_size = 0
	normal.shadow_offset = Vector2(0, shadow_y)
	normal.content_margin_left = 12.0
	normal.content_margin_top = 8.0
	normal.content_margin_right = 12.0
	normal.content_margin_bottom = 8.0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_col.lightened(0.1)
	hover.border_color = border_col.lightened(0.15)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_col.darkened(0.1)
	pressed.shadow_offset = Vector2(0, 1.0)
	pressed.content_margin_top = 10.0
	pressed.content_margin_bottom = 6.0

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = bg_col.darkened(0.4)
	disabled.border_color = border_col.darkened(0.4)
	disabled.shadow_size = 0
	disabled.shadow_offset = Vector2.ZERO

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
