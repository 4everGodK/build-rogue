extends Node
class_name SynergyManager

signal synergies_changed(active_synergies: Dictionary, tag_counts: Dictionary)

var tag_counts: Dictionary = {}
var active_synergies: Dictionary = {}
var attribute_counts: Dictionary = {}
var type_counts: Dictionary = {}
var type_modifier: TypeSynergyModifier = TypeSynergyModifier.new()

func recalculate(artifacts: Array) -> void:
	tag_counts.clear()
	active_synergies.clear()
	attribute_counts.clear()
	type_counts.clear()
	var counted_artifact_ids: Dictionary = {}

	# Count each artifact id once. Duplicate copies are for fusion, not tag inflation.
	for artifact in artifacts:
		var artifact_id: String = str(artifact.get("id", ""))
		if artifact_id.is_empty() or counted_artifact_ids.has(artifact_id):
			continue
		counted_artifact_ids[artifact_id] = true
		for tag in artifact.get("tags", []):
			tag_counts[tag] = tag_counts.get(tag, 0) + 1
			if ArtifactTag.is_attribute_tag(tag):
				attribute_counts[tag] = int(attribute_counts.get(tag, 0)) + 1
			elif ArtifactTag.is_type_tag(tag):
				type_counts[tag] = int(type_counts.get(tag, 0)) + 1

	for tag in attribute_counts.keys():
		var count: int = int(attribute_counts[tag])
		if count >= 2:
			active_synergies["%s 2" % tag] = {"category": "属性", "tag": tag, "count": count, "threshold": 2}

	type_modifier.setup(type_counts)
	var active_type_entries: Dictionary = type_modifier.get_active_entries()
	for name in active_type_entries.keys():
		active_synergies[name] = active_type_entries[name]

	synergies_changed.emit(active_synergies.duplicate(true), tag_counts.duplicate(true))

func projectile_damage_multiplier() -> float:
	return type_modifier.projectile_damage_multiplier()

func explosion_radius_multiplier() -> float:
	return 1.0

func chain_bonus() -> int:
	return 0

func get_type_modifier() -> TypeSynergyModifier:
	return type_modifier

func describe_active() -> Array[String]:
	var lines: Array[String] = []
	for name in active_synergies.keys():
		lines.append(name)
	return lines
