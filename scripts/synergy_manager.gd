extends Node
class_name SynergyManager

signal synergies_changed(active_synergies: Dictionary, tag_counts: Dictionary)

var tag_counts: Dictionary = {}
var active_synergies: Dictionary = {}
var attribute_counts: Dictionary = {}
var type_counts: Dictionary = {}
var type_modifier: TypeSynergyModifier = TypeSynergyModifier.new()
var attribute_modifier: AttributeSynergyModifier = AttributeSynergyModifier.new()
var wood_growth_timer: float = 0.0

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

	attribute_modifier.setup(attribute_counts)
	var active_attribute_entries: Dictionary = attribute_modifier.get_active_entries()
	for name in active_attribute_entries.keys():
		active_synergies[name] = active_attribute_entries[name]

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

func get_attribute_modifier() -> AttributeSynergyModifier:
	return attribute_modifier

func _process(delta: float) -> void:
	if attribute_modifier.get_tier("木") <= 0:
		wood_growth_timer = 0.0
		return

	wood_growth_timer += delta
	if wood_growth_timer >= 30.0:
		wood_growth_timer -= 30.0
		attribute_modifier.add_growth_stack()

func describe_active() -> Array[String]:
	var lines: Array[String] = []
	for name in active_synergies.keys():
		lines.append(name)
	return lines
