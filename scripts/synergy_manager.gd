extends Node
class_name SynergyManager

signal synergies_changed(active_synergies: Dictionary, tag_counts: Dictionary)

var tag_counts: Dictionary = {}
var active_synergies: Dictionary = {}

func recalculate(artifacts: Array) -> void:
	tag_counts.clear()
	active_synergies.clear()

	# Count tags from the current inventory, then expose small numeric modifiers.
	for artifact in artifacts:
		for tag in artifact.get("tags", []):
			tag_counts[tag] = tag_counts.get(tag, 0) + 1

	if tag_counts.get("剑", 0) >= 2:
		active_synergies["剑 2"] = {"projectile_damage_multiplier": 1.2}
	if tag_counts.get("火", 0) >= 2:
		active_synergies["火 2"] = {"explosion_radius_multiplier": 1.25}
	if tag_counts.get("雷", 0) >= 2:
		active_synergies["雷 2"] = {"chain_bonus": 1}

	synergies_changed.emit(active_synergies.duplicate(true), tag_counts.duplicate(true))

func projectile_damage_multiplier() -> float:
	return active_synergies.get("剑 2", {}).get("projectile_damage_multiplier", 1.0)

func explosion_radius_multiplier() -> float:
	return active_synergies.get("火 2", {}).get("explosion_radius_multiplier", 1.0)

func chain_bonus() -> int:
	return active_synergies.get("雷 2", {}).get("chain_bonus", 0)

func describe_active() -> Array[String]:
	var lines: Array[String] = []
	for name in active_synergies.keys():
		lines.append(name)
	return lines
