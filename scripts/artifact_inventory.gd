extends Node
class_name ArtifactInventory

signal inventory_changed
signal inventory_message(message: String)

const INITIAL_BATTLE_SLOT_COUNT: int = 5
const BAG_SLOT_COUNT: int = 8

var battle_slots: Array = []
var bag_slots: Array = []
var battle_slot_count: int = INITIAL_BATTLE_SLOT_COUNT

func _ready() -> void:
	_initialize_slots()

func _initialize_slots() -> void:
	var battle_slot_count := get_battle_slot_count()
	if battle_slots.size() != battle_slot_count:
		battle_slots.resize(battle_slot_count)
	if bag_slots.size() != BAG_SLOT_COUNT:
		bag_slots.resize(BAG_SLOT_COUNT)

func get_battle_slot_count() -> int:
	return battle_slot_count

func set_battle_slot_count(next_count: int) -> void:
	var normalized_count: int = maxi(INITIAL_BATTLE_SLOT_COUNT, next_count)
	if battle_slot_count == normalized_count:
		return
	battle_slot_count = normalized_count
	_initialize_slots()
	inventory_changed.emit()

func add_artifact(data: ArtifactData) -> bool:
	_initialize_slots()
	var stack: ArtifactStack = ArtifactStack.new(data, 1)
	var index := _first_empty_index(battle_slots)
	if index >= 0:
		battle_slots[index] = stack
		_after_inventory_changed()
		return true
	index = _first_empty_index(bag_slots)
	if index >= 0:
		bag_slots[index] = stack
		_after_inventory_changed()
		return true
	if _merge_incoming_stack(stack):
		_after_inventory_changed()
		return true
	inventory_message.emit("出战区和储物袋已满")
	return false

func move_stack(from_area: String, from_index: int, to_area: String, to_index: int) -> void:
	var from_slots := _slots_for_area(from_area)
	var to_slots := _slots_for_area(to_area)
	if from_slots.is_empty() or to_slots.is_empty():
		return
	if from_index < 0 or from_index >= from_slots.size() or to_index < 0 or to_index >= to_slots.size():
		return
	var moving = from_slots[from_index]
	from_slots[from_index] = to_slots[to_index]
	to_slots[to_index] = moving
	_after_inventory_changed()

func sell_stack(area: String, index: int) -> int:
	var slots := _slots_for_area(area)
	if slots.is_empty() or index < 0 or index >= slots.size():
		return 0
	var stack: ArtifactStack = slots[index] as ArtifactStack
	if stack == null:
		return 0
	var sell_value: int = stack.get_sell_value()
	slots[index] = null
	_after_inventory_changed()
	return sell_value

func clear_inventory() -> void:
	_initialize_slots()
	for index in range(battle_slots.size()):
		battle_slots[index] = null
	for index in range(bag_slots.size()):
		bag_slots[index] = null
	_after_inventory_changed()

func _after_inventory_changed() -> void:
	_auto_merge_all()
	inventory_changed.emit()

func _auto_merge_all() -> void:
	var merged := true
	while merged:
		merged = false
		var all_slots := _all_slot_refs()
		for first_index in range(all_slots.size()):
			var first: ArtifactStack = all_slots[first_index]["slots"][all_slots[first_index]["index"]] as ArtifactStack
			if first == null or first.star_level >= 3:
				continue
			var matches: Array = [all_slots[first_index]]
			for next_index in range(first_index + 1, all_slots.size()):
				var candidate: ArtifactStack = all_slots[next_index]["slots"][all_slots[next_index]["index"]] as ArtifactStack
				if first.is_same_artifact_and_star(candidate):
					matches.append(all_slots[next_index])
					if matches.size() >= 3:
						break
			if matches.size() >= 3:
				first.star_level += 1
				for remove_index in range(1, 3):
					matches[remove_index]["slots"][matches[remove_index]["index"]] = null
				merged = true
				break

func _merge_incoming_stack(incoming: ArtifactStack) -> bool:
	if incoming == null or incoming.artifact_data == null or incoming.star_level >= 3:
		return false
	var all_slots := _all_slot_refs()
	var matches: Array = []
	for slot_ref in all_slots:
		var candidate: ArtifactStack = slot_ref["slots"][slot_ref["index"]] as ArtifactStack
		if incoming.is_same_artifact_and_star(candidate):
			matches.append(slot_ref)
			if matches.size() >= 2:
				break
	if matches.size() < 2:
		return false
	var first: ArtifactStack = matches[0]["slots"][matches[0]["index"]] as ArtifactStack
	if first == null:
		return false
	first.star_level += 1
	matches[1]["slots"][matches[1]["index"]] = null
	return true

func _all_slot_refs() -> Array:
	var refs: Array = []
	for index in range(battle_slots.size()):
		refs.append({"area": "battle", "index": index, "slots": battle_slots})
	for index in range(bag_slots.size()):
		refs.append({"area": "bag", "index": index, "slots": bag_slots})
	return refs

func _first_empty_index(slots: Array) -> int:
	for index in range(slots.size()):
		if slots[index] == null:
			return index
	return -1

func _slots_for_area(area: String) -> Array:
	match area:
		"battle":
			return battle_slots
		"bag":
			return bag_slots
		_:
			return []
