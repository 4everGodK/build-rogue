extends Node
class_name SynergyManager

signal synergies_changed(system_counts: Dictionary, attribute_counts: Dictionary)

var system_counts: Dictionary = {}
var attribute_counts: Dictionary = {}

func recalculate(battle_slots: Array) -> void:
	system_counts.clear()
	attribute_counts.clear()
	var counted_ids: Dictionary = {}
	for raw_stack in battle_slots:
		var stack := raw_stack as ArtifactStack
		if stack == null or stack.artifact_data == null:
			continue
		if counted_ids.has(stack.artifact_data.id):
			continue
		counted_ids[stack.artifact_data.id] = true
		system_counts[stack.artifact_data.system_tag] = int(system_counts.get(stack.artifact_data.system_tag, 0)) + 1
		attribute_counts[stack.artifact_data.attribute_tag] = int(attribute_counts.get(stack.artifact_data.attribute_tag, 0)) + 1
	synergies_changed.emit(system_counts.duplicate(), attribute_counts.duplicate())
