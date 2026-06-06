extends Button
class_name InventorySlotButton

signal slot_drop_requested(from_area: String, from_index: int, to_area: String, to_index: int)

var slot_area: String = ""
var slot_index: int = -1
var stack: ArtifactStack
var _is_drag_source: bool = false

func setup(area: String, index: int, next_stack: ArtifactStack) -> void:
	slot_area = area
	slot_index = index
	stack = next_stack
	text = ""
	tooltip_text = "" if stack == null else stack.get_upgrade_tooltip()
	custom_minimum_size = Vector2(96, 92)
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
	var preview := _make_drag_preview()
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
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 6.0
	box.offset_top = 5.0
	box.offset_right = -6.0
	box.offset_bottom = -5.0
	add_child(box)

	if stack == null or stack.artifact_data == null:
		var empty_label := Label.new()
		empty_label.text = "空"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(empty_label)
		return

	var icon_rect := TextureRect.new()
	icon_rect.texture = stack.artifact_data.icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(50, 50)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon_rect)

	var name_label := Label.new()
	name_label.text = stack.artifact_data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var star_label := Label.new()
	star_label.text = stack.get_star_text()
	star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(star_label)

func _make_drag_preview() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 96)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.10, 0.12, 0.18, 0.92), Color(1.0, 0.82, 0.32), 3))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var icon_rect := TextureRect.new()
	icon_rect.texture = stack.artifact_data.icon if stack != null and stack.artifact_data != null else null
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(64, 64)
	box.add_child(icon_rect)
	var label := Label.new()
	label.text = stack.get_display_name()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	return panel

func _apply_style(is_drop_target: bool) -> void:
	var border: Color = Color(1.0, 0.82, 0.32) if is_drop_target else Color(0.42, 0.46, 0.58)
	var bg: Color = Color(0.13, 0.15, 0.22, 0.95) if stack != null else Color(0.08, 0.09, 0.13, 0.82)
	add_theme_stylebox_override("normal", _make_style(bg, border, 2))
	add_theme_stylebox_override("hover", _make_style(bg.lightened(0.08), Color(0.78, 0.9, 1.0), 2))
	add_theme_stylebox_override("pressed", _make_style(bg.darkened(0.08), Color(1.0, 0.82, 0.32), 3))
	add_theme_stylebox_override("disabled", _make_style(Color(0.06, 0.06, 0.08, 0.8), Color(0.24, 0.26, 0.32), 1))

func _make_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
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
