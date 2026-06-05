extends Button
class_name InventorySlotButton

signal slot_drop_requested(from_area: String, from_index: int, to_area: String, to_index: int)

var slot_area: String = ""
var slot_index: int = -1
var stack: ArtifactStack

func setup(area: String, index: int, next_stack: ArtifactStack) -> void:
	slot_area = area
	slot_index = index
	stack = next_stack
	text = "空" if stack == null else stack.get_display_name()
	custom_minimum_size = Vector2(88, 54)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if stack == null:
		return null
	var preview := Label.new()
	preview.text = stack.get_display_name()
	set_drag_preview(preview)
	return {"from_area": slot_area, "from_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("from_area") and data.has("from_index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	slot_drop_requested.emit(str(data["from_area"]), int(data["from_index"]), slot_area, slot_index)
