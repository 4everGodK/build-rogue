extends Button
class_name SellDropZone

signal sell_drop_requested(from_area: String, from_index: int)
signal keyboard_sell_requested

@onready var label: Label = $Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "出售区（选择法宝后确认）"
	pressed.connect(func() -> void: keyboard_sell_requested.emit())
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
	var background := Color(0.18, 0.075, 0.07, 0.96) if is_hover else Color(0.10, 0.06, 0.055, 0.94)
	var border := Color(1.0, 0.50, 0.30, 1.0) if is_hover else UITokens.VERMILION_500.darkened(0.28)
	add_theme_stylebox_override("normal", UITokens.style(background, border, 2))
	add_theme_stylebox_override("hover", UITokens.style(background.lightened(0.08), UITokens.VERMILION_500, 2))
	add_theme_stylebox_override("pressed", UITokens.style(background.darkened(0.08), UITokens.PAPER_100, 3))
	add_theme_stylebox_override("focus", UITokens.focus_style())
