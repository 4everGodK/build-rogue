extends PanelContainer
class_name SellDropZone

signal sell_drop_requested(from_area: String, from_index: int)

@onready var label: Label = $Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	label.text = "拖到这里出售法宝"
	_apply_style(false)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop: bool = data is Dictionary and data.has("from_area") and data.has("from_index")
	_apply_style(can_drop)
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_apply_style(false)
	sell_drop_requested.emit(str(data["from_area"]), int(data["from_index"]))

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_apply_style(false)

func _apply_style(is_hover: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.075, 0.07, 0.96) if is_hover else Color(0.10, 0.06, 0.055, 0.90)
	style.border_color = Color(1.0, 0.50, 0.30, 1.0) if is_hover else Color(0.58, 0.22, 0.18, 0.86)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
