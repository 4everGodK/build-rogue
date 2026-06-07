extends Button
class_name InventorySlotButton

signal slot_drop_requested(from_area: String, from_index: int, to_area: String, to_index: int)

var slot_area: String = ""
var slot_index: int = -1
var stack: ArtifactStack
var _is_drag_source: bool = false
var icon_size: Vector2 = Vector2(52, 52)

func setup(area: String, index: int, next_stack: ArtifactStack) -> void:
	slot_area = area
	slot_index = index
	stack = next_stack
	text = ""
	tooltip_text = "" if stack == null else stack.get_upgrade_tooltip()
	if slot_area == "battle":
		custom_minimum_size = Vector2(168, 72)
		icon_size = Vector2(52, 52)
	else:
		custom_minimum_size = Vector2(112, 60)
		icon_size = Vector2(34, 34)
	focus_mode = Control.FOCUS_NONE
	theme_type_variation = "InventorySlotButton"
	_clear_children()
	_apply_style(false)
	_build_slot_content()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack == null:
		return null
	_is_drag_source = true
	modulate.a = 0.45
	var preview: Control = _make_drag_preview()
	set_drag_preview(preview)
	return {"from_area": slot_area, "from_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop: bool = data is Dictionary and data.has("from_area") and data.has("from_index")
	_apply_style(can_drop)
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_apply_style(false)
	slot_drop_requested.emit(str(data["from_area"]), int(data["from_index"]), slot_area, slot_index)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _is_drag_source:
		_is_drag_source = false
		modulate.a = 1.0
	elif what == NOTIFICATION_MOUSE_EXIT:
		_apply_style(false)

func _clear_children() -> void:
	for child in get_children():
		child.queue_free()

func _build_slot_content() -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.anchor_right = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 7.0
	row.offset_top = 5.0
	row.offset_right = -7.0
	row.offset_bottom = -5.0
	row.add_theme_constant_override("separation", 8 if slot_area == "battle" else 6)
	add_child(row)

	if stack == null or stack.artifact_data == null:
		var empty_label: Label = Label.new()
		empty_label.text = "空"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_label.add_theme_color_override("font_color", Color(0.38, 0.43, 0.48) if slot_area == "battle" else Color(0.30, 0.30, 0.32))
		row.add_child(empty_label)
		return

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = stack.artifact_data.icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = icon_size
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 1)
	row.add_child(text_box)

	var name_label: Label = Label.new()
	name_label.text = stack.artifact_data.display_name
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 14 if slot_area == "battle" else 12)
	name_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.78) if slot_area == "battle" else Color(0.72, 0.70, 0.62))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var tag_label: Label = Label.new()
	tag_label.text = "%s / %s" % [stack.artifact_data.system_tag, stack.artifact_data.attribute_tag]
	tag_label.clip_text = true
	tag_label.add_theme_font_size_override("font_size", 12 if slot_area == "battle" else 10)
	tag_label.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0) if slot_area == "battle" else Color(0.46, 0.50, 0.56))
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(tag_label)

	var star_label: Label = Label.new()
	star_label.text = stack.get_star_text()
	star_label.add_theme_font_size_override("font_size", 14 if slot_area == "battle" else 12)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(star_label)

func _make_drag_preview() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 96)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.10, 0.12, 0.18, 0.92), Color(1.0, 0.82, 0.32), 3))
	var box: VBoxContainer = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = stack.artifact_data.icon if stack != null and stack.artifact_data != null else null
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(64, 64)
	box.add_child(icon_rect)
	var label: Label = Label.new()
	label.text = stack.get_display_name()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	return panel

func _apply_style(is_drop_target: bool) -> void:
	var base_border: Color = Color(0.32, 0.72, 1.0) if slot_area == "battle" else Color(0.31, 0.30, 0.28)
	var filled_bg: Color = Color(0.11, 0.16, 0.21, 0.97) if slot_area == "battle" else Color(0.09, 0.09, 0.10, 0.82)
	var empty_bg: Color = Color(0.055, 0.09, 0.12, 0.86) if slot_area == "battle" else Color(0.055, 0.055, 0.06, 0.70)
	var border: Color = Color(1.0, 0.82, 0.32) if is_drop_target else base_border
	var bg: Color = filled_bg if stack != null else empty_bg
	add_theme_stylebox_override("normal", _make_style(bg, border, 2))
	add_theme_stylebox_override("hover", _make_style(bg.lightened(0.08), Color(0.78, 0.9, 1.0), 2))
	add_theme_stylebox_override("pressed", _make_style(bg.darkened(0.08), Color(1.0, 0.82, 0.32), 3))
	add_theme_stylebox_override("disabled", _make_style(Color(0.06, 0.06, 0.08, 0.8), Color(0.24, 0.26, 0.32), 1))

func _make_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style
