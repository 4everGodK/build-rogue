extends RefCounted
class_name UITokens

const INK_950 := Color("10181b")
const INK_900 := Color("172328")
const INK_800 := Color("24343a")
const PAPER_100 := Color("f3e8ce")
const PAPER_200 := Color("e2d2b4")
const PAPER_700 := Color("6e604d")
const TEXT_LIGHT := Color("f7f3e8")
const TEXT_DARK := Color("252923")
const JADE_500 := Color("4faf98")
const PLAYER_CYAN := Color("71d6d1")
const VERMILION_500 := Color("d9533f")
const AMBER_500 := Color("d89c3d")

const SPACING_XS := 4
const SPACING_SM := 8
const SPACING_MD := 12
const SPACING_LG := 16
const SPACING_XL := 24
const SPACING_2XL := 32
const SPACING_3XL := 48

const RADIUS_TAG := 4
const RADIUS_CARD := 8
const RADIUS_MODAL := 12

const FONT_CAPTION := 14
const FONT_BODY_SM := 16
const FONT_BODY := 18
const FONT_HEADING_SM := 20
const FONT_HEADING := 24
const FONT_DISPLAY := 32
const FONT_DISPLAY_LG := 44

const MIN_TARGET := Vector2(48.0, 48.0)
const SAFE_MARGIN_RATIO := 0.05
const TOOLTIP_DELAY := 0.30
const TOOLTIP_HIDE_GRACE := 0.10

static func style(
	background: Color,
	border: Color = Color.TRANSPARENT,
	border_width: int = 0,
	radius: int = RADIUS_CARD,
	content_margin: int = SPACING_MD
) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = background
	result.border_color = border
	result.border_width_left = border_width
	result.border_width_top = border_width
	result.border_width_right = border_width
	result.border_width_bottom = border_width
	result.corner_radius_top_left = radius
	result.corner_radius_top_right = radius
	result.corner_radius_bottom_left = radius
	result.corner_radius_bottom_right = radius
	result.content_margin_left = content_margin
	result.content_margin_top = content_margin
	result.content_margin_right = content_margin
	result.content_margin_bottom = content_margin
	return result

static func focus_style(radius: int = RADIUS_CARD) -> StyleBoxFlat:
	return style(Color.TRANSPARENT, PAPER_100, 3, radius, 2)

static func rarity_color(tier: String) -> Color:
	match tier:
		"凡器":
			return Color("8b9696")
		"法器":
			return Color("5fae78")
		"灵器":
			return Color("5e8fd1")
		"灵宝":
			return Color("9a6cc2")
		"仙宝":
			return Color("d89c3d")
		_:
			return INK_800

static func apply_dynamic_text_readability(control: Control, outline_size: int = 2) -> void:
	control.add_theme_color_override("font_outline_color", INK_950)
	control.add_theme_constant_override("outline_size", outline_size)

