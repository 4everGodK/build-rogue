extends Node
class_name SynergyManager

signal synergies_changed(system_counts: Dictionary, attribute_counts: Dictionary)

var system_counts: Dictionary = {}
var attribute_counts: Dictionary = {}
var effects: Dictionary = {}

func recalculate(battle_slots: Array) -> void:
	system_counts.clear()
	attribute_counts.clear()
	effects.clear()
	var counted_ids: Dictionary = {}
	for raw_stack in battle_slots:
		var stack: ArtifactStack = raw_stack as ArtifactStack
		if stack == null or stack.artifact_data == null:
			continue
		if counted_ids.has(stack.artifact_data.id):
			continue
		counted_ids[stack.artifact_data.id] = true
		system_counts[stack.artifact_data.system_tag] = int(system_counts.get(stack.artifact_data.system_tag, 0)) + 1
		var attribute_tag: String = stack.artifact_data.get_attribute_tag()
		attribute_counts[attribute_tag] = int(attribute_counts.get(attribute_tag, 0)) + 1
	_update_effects()
	synergies_changed.emit(system_counts.duplicate(), attribute_counts.duplicate())

func _update_effects() -> void:
	var sword_count: int = int(system_counts.get("剑修", 0))
	if sword_count >= 6:
		effects["sword_double_chance"] = 0.5
	elif sword_count >= 4:
		effects["sword_double_chance"] = 0.35
	elif sword_count >= 2:
		effects["sword_double_chance"] = 0.2
	else:
		effects["sword_double_chance"] = 0.0

	var magic_count: int = int(system_counts.get("法修", 0))
	if magic_count >= 6:
		effects["projectile_extra_count"] = 2
		effects["projectile_extra_damage_multiplier"] = 0.75
	elif magic_count >= 4:
		effects["projectile_extra_count"] = 1
		effects["projectile_extra_damage_multiplier"] = 0.75
	elif magic_count >= 2:
		effects["projectile_extra_count"] = 1
		effects["projectile_extra_damage_multiplier"] = 0.5
	else:
		effects["projectile_extra_count"] = 0
		effects["projectile_extra_damage_multiplier"] = 0.0

	var formation_count: int = int(system_counts.get("阵法", 0))
	effects["formation_radius_multiplier"] = 1.5 if formation_count >= 4 else 1.25 if formation_count >= 2 else 1.0

	var summon_count: int = int(system_counts.get("召唤", 0))
	if summon_count >= 6:
		effects["summon_extra_count"] = 4
		effects["summon_respawn_time_multiplier"] = 0.5
		effects["summon_death_burst_enabled"] = true
	elif summon_count >= 4:
		effects["summon_extra_count"] = 2
		effects["summon_respawn_time_multiplier"] = 0.5
		effects["summon_death_burst_enabled"] = false
	elif summon_count >= 2:
		effects["summon_extra_count"] = 1
		effects["summon_respawn_time_multiplier"] = 1.0
		effects["summon_death_burst_enabled"] = false
	else:
		effects["summon_extra_count"] = 0
		effects["summon_respawn_time_multiplier"] = 1.0
		effects["summon_death_burst_enabled"] = false

	var body_count: int = int(system_counts.get("体修", 0))
	effects["body_max_hp_bonus"] = 20 if body_count >= 2 else 0
	effects["body_counter_enabled"] = body_count >= 4
	effects["body_counter_damage"] = 8.0

	var demon_count: int = int(system_counts.get("魔修", 0))
	effects["demon_low_hp_magic_damage_multiplier"] = 1.3 if demon_count >= 2 else 1.0
	effects["demon_low_hp_all_damage_multiplier"] = 1.2 if demon_count >= 4 else 1.0

func get_effect_value(key: String, default_value = null):
	return effects.get(key, default_value)
