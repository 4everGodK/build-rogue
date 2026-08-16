extends Control
class_name UISafeAreaControl

@export_range(0.0, 0.10, 0.005) var safe_margin_ratio: float = UITokens.SAFE_MARGIN_RATIO
@export var constrain_to_widescreen_frame: bool = true

func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_rect)
	_apply_safe_rect()

func set_safe_margin_ratio(value: float) -> void:
	safe_margin_ratio = clampf(value, 0.0, 0.10)
	_apply_safe_rect()

func _apply_safe_rect() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var frame_width := viewport_size.x
	if constrain_to_widescreen_frame:
		frame_width = minf(viewport_size.x, viewport_size.y * 16.0 / 9.0)
	var frame_gutter := maxf(0.0, (viewport_size.x - frame_width) * 0.5)
	var horizontal_margin := ceilf(frame_gutter + frame_width * safe_margin_ratio)
	var vertical_margin := ceilf(viewport_size.y * safe_margin_ratio)
	offset_left = horizontal_margin
	offset_right = -horizontal_margin
	offset_top = vertical_margin
	offset_bottom = -vertical_margin
