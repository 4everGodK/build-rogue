extends Control
class_name DestinyPanel

signal destiny_selected(destiny_id: String)

@onready var title_label: Label = $Panel/MarginContainer/Root/TitleLabel
@onready var card_row: HBoxContainer = $Panel/MarginContainer/Root/CardRow

var current_choices: Array[Dictionary] = []

func _ready() -> void:
	hide()
	_apply_styles()

func open_choices(choices: Array[Dictionary]) -> void:
	current_choices = choices.duplicate(true)
	_render_cards()
	show()
	call_deferred("_focus_first_card")

func close_panel() -> void:
	hide()

func _render_cards() -> void:
	if not is_node_ready():
		return
	for child in card_row.get_children():
		child.queue_free()
	for choice in current_choices:
		card_row.add_child(_make_card(choice))

func _make_card(choice: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(230.0, 260.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.text = ""
	button.pressed.connect(func() -> void:
		destiny_selected.emit(str(choice.get("id", "")))
	)
	button.add_theme_stylebox_override("normal", _make_card_style(Color(0.09, 0.105, 0.13, 0.96), Color(0.72, 0.52, 0.22), 2))
	button.add_theme_stylebox_override("hover", _make_card_style(Color(0.13, 0.15, 0.18, 0.98), Color(1.0, 0.76, 0.32), 3))
	button.add_theme_stylebox_override("pressed", _make_card_style(Color(0.07, 0.08, 0.10, 0.98), Color(1.0, 0.86, 0.42), 3))

	var box := VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 16.0
	box.offset_top = 18.0
	box.offset_right = -16.0
	box.offset_bottom = -18.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 14)
	button.add_child(box)

	var name_label := Label.new()
	name_label.text = str(choice.get("name", "未知天命"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.42))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)

	var desc_label := Label.new()
	desc_label.text = str(choice.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.86, 0.9, 0.96))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc_label)

	var action_label := Label.new()
	action_label.text = "选择"
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 18)
	action_label.add_theme_color_override("font_color", Color(0.58, 0.9, 1.0))
	action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(action_label)
	return button

func _focus_first_card() -> void:
	for child in card_row.get_children():
		if child is Button and not child.disabled:
			(child as Button).grab_focus()
			return

func _apply_styles() -> void:
	title_label.text = "选择天命"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.48))

func _make_card_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	return style
