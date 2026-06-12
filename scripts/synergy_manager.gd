extends Node
class_name SynergyManager

signal synergies_changed(system_counts: Dictionary, attribute_counts: Dictionary)

const SWORD_ATTACK_SPEED_TIERS: Array[Dictionary] = [
	{"required": 9, "per_stack": 0.04, "max_stacks": 60},
	{"required": 6, "per_stack": 0.03, "max_stacks": 40},
	{"required": 3, "per_stack": 0.02, "max_stacks": 20},
]

const BODY_GROWTH_TIERS: Array[Dictionary] = [
	{"required": 9, "max_hp_multiplier": 2.5, "size_multiplier": 1.5},
	{"required": 6, "max_hp_multiplier": 1.8, "size_multiplier": 1.25},
	{"required": 3, "max_hp_multiplier": 1.3, "size_multiplier": 1.1},
]

const METAL_LOW_HP_TIERS: Array[Dictionary] = [
	{"required": 6, "hp_ratio": 0.3, "damage_multiplier": 1.0},
	{"required": 4, "hp_ratio": 0.5, "damage_multiplier": 0.45},
	{"required": 2, "hp_ratio": 0.5, "damage_multiplier": 0.25},
]
const WOOD_ROOT_TIERS: Array[Dictionary] = [
	{"required": 6, "duration": 1.5, "damage_taken_bonus": 0.2},
	{"required": 4, "duration": 1.0, "damage_taken_bonus": 0.0},
	{"required": 2, "duration": 0.5, "damage_taken_bonus": 0.0},
]
const WOOD_ROOT_INTERNAL_COOLDOWN: float = 1.2
const WATER_HEAL_TIERS: Array[Dictionary] = [
	{"required": 6, "heal": 4.0, "overflow_to_shield": true, "shield_max_ratio": 0.35},
	{"required": 4, "heal": 4.0, "overflow_to_shield": false, "shield_max_ratio": 0.0},
	{"required": 2, "heal": 2.0, "overflow_to_shield": false, "shield_max_ratio": 0.0},
]
const FIRE_EXPLOSION_TIERS: Array[Dictionary] = [
	{"required": 6, "radius": 92.0, "damage_multiplier": 0.75},
	{"required": 4, "radius": 92.0, "damage_multiplier": 0.45},
	{"required": 2, "radius": 56.0, "damage_multiplier": 0.35},
]
const EARTH_SHOCKWAVE_TIERS: Array[Dictionary] = [
	{"required": 6, "radius": 112.0, "damage_multiplier": 0.65, "stun": 0.6},
	{"required": 4, "radius": 112.0, "damage_multiplier": 0.45, "stun": 0.0},
	{"required": 2, "radius": 72.0, "damage_multiplier": 0.35, "stun": 0.0},
]
const EARTH_STUN_INTERNAL_COOLDOWN: float = 1.5
const LIGHTNING_CHAIN_TIERS: Array[Dictionary] = [
	{"required": 6, "targets": 6, "damage_multiplier": 0.7},
	{"required": 4, "targets": 4, "damage_multiplier": 0.7},
	{"required": 2, "targets": 2, "damage_multiplier": 0.7},
]
const LIGHTNING_CHAIN_RANGE: float = 220.0
const LIGHTNING_CHAIN_FALLOFF: float = 0.75
const POISON_TIERS: Array[Dictionary] = [
	{"required": 6, "dps_multiplier": 0.35, "duration": 4.0, "burst_radius": 84.0, "burst_damage_multiplier": 0.9},
	{"required": 4, "dps_multiplier": 0.35, "duration": 4.0, "burst_radius": 0.0, "burst_damage_multiplier": 0.0},
	{"required": 2, "dps_multiplier": 0.22, "duration": 4.0, "burst_radius": 0.0, "burst_damage_multiplier": 0.0},
]

var system_counts: Dictionary = {}
var attribute_counts: Dictionary = {}
var effects: Dictionary = {}
var sword_attack_speed_stacks: int = 0

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
	var sword_per_stack: float = 0.0
	var sword_max_stacks: int = 0
	for tier in SWORD_ATTACK_SPEED_TIERS:
		if sword_count >= int(tier["required"]):
			sword_per_stack = float(tier["per_stack"])
			sword_max_stacks = int(tier["max_stacks"])
			break
	sword_attack_speed_stacks = mini(sword_attack_speed_stacks, sword_max_stacks)
	effects["sword_attack_speed_per_stack"] = sword_per_stack
	effects["sword_attack_speed_max_stacks"] = sword_max_stacks

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
	var body_max_hp_multiplier: float = 1.0
	var body_size_multiplier: float = 1.0
	for tier in BODY_GROWTH_TIERS:
		if body_count >= int(tier["required"]):
			body_max_hp_multiplier = float(tier["max_hp_multiplier"])
			body_size_multiplier = float(tier["size_multiplier"])
			break
	effects["body_max_hp_multiplier"] = body_max_hp_multiplier
	effects["body_size_multiplier"] = body_size_multiplier

	var demon_count: int = int(system_counts.get("魔修", 0))
	effects["demon_low_hp_magic_damage_multiplier"] = 1.3 if demon_count >= 2 else 1.0
	effects["demon_low_hp_all_damage_multiplier"] = 1.2 if demon_count >= 4 else 1.0
	_update_attribute_effects()

func _update_attribute_effects() -> void:
	var metal_tier := _attribute_tier("金", METAL_LOW_HP_TIERS)
	effects["metal_low_hp_ratio"] = float(metal_tier.get("hp_ratio", 0.0))
	effects["metal_damage_multiplier"] = float(metal_tier.get("damage_multiplier", 0.0))

	var wood_tier := _attribute_tier("木", WOOD_ROOT_TIERS)
	effects["wood_root_duration"] = float(wood_tier.get("duration", 0.0))
	effects["wood_damage_taken_bonus"] = float(wood_tier.get("damage_taken_bonus", 0.0))
	effects["wood_root_internal_cooldown"] = WOOD_ROOT_INTERNAL_COOLDOWN

	var water_tier := _attribute_tier("水", WATER_HEAL_TIERS)
	effects["water_heal"] = float(water_tier.get("heal", 0.0))
	effects["water_overflow_to_shield"] = bool(water_tier.get("overflow_to_shield", false))
	effects["water_shield_max_ratio"] = float(water_tier.get("shield_max_ratio", 0.0))

	var fire_tier := _attribute_tier("火", FIRE_EXPLOSION_TIERS)
	effects["fire_explosion_radius"] = float(fire_tier.get("radius", 0.0))
	effects["fire_explosion_damage_multiplier"] = float(fire_tier.get("damage_multiplier", 0.0))

	var earth_tier := _attribute_tier("土", EARTH_SHOCKWAVE_TIERS)
	effects["earth_shockwave_radius"] = float(earth_tier.get("radius", 0.0))
	effects["earth_shockwave_damage_multiplier"] = float(earth_tier.get("damage_multiplier", 0.0))
	effects["earth_center_stun"] = float(earth_tier.get("stun", 0.0))
	effects["earth_stun_internal_cooldown"] = EARTH_STUN_INTERNAL_COOLDOWN

	var lightning_tier := _attribute_tier("雷", LIGHTNING_CHAIN_TIERS)
	effects["lightning_chain_targets"] = int(lightning_tier.get("targets", 0))
	effects["lightning_chain_damage_multiplier"] = float(lightning_tier.get("damage_multiplier", 0.0))
	effects["lightning_chain_range"] = LIGHTNING_CHAIN_RANGE
	effects["lightning_chain_falloff"] = LIGHTNING_CHAIN_FALLOFF

	var poison_tier := _attribute_tier("毒", POISON_TIERS)
	effects["poison_dps_multiplier"] = float(poison_tier.get("dps_multiplier", 0.0))
	effects["poison_duration"] = float(poison_tier.get("duration", 0.0))
	effects["poison_burst_radius"] = float(poison_tier.get("burst_radius", 0.0))
	effects["poison_burst_damage_multiplier"] = float(poison_tier.get("burst_damage_multiplier", 0.0))

func _attribute_tier(attribute_tag: String, tiers: Array[Dictionary]) -> Dictionary:
	var count: int = int(attribute_counts.get(attribute_tag, 0))
	for tier in tiers:
		if count >= int(tier["required"]):
			return tier
	return {}

func get_effect_value(key: String, default_value = null):
	return effects.get(key, default_value)

func reset_battle_effects() -> void:
	sword_attack_speed_stacks = 0

func notify_artifact_damage(data: ArtifactData) -> void:
	if data == null or data.system_tag != "剑修":
		return
	var max_stacks: int = int(effects.get("sword_attack_speed_max_stacks", 0))
	if max_stacks <= 0:
		return
	sword_attack_speed_stacks = mini(max_stacks, sword_attack_speed_stacks + 1)

func get_sword_attack_speed_bonus() -> float:
	return sword_attack_speed_stacks * float(effects.get("sword_attack_speed_per_stack", 0.0))

func get_sword_cooldown_multiplier() -> float:
	return 1.0 / (1.0 + get_sword_attack_speed_bonus())

func apply_attribute_on_hit(data: ArtifactData, target: Node, base_damage: float, source: Node = null, hit_position: Vector2 = Vector2.ZERO, pre_hit_hp_ratio: float = -1.0) -> void:
	if data == null or target == null:
		return
	match data.get_attribute_tag():
		"金":
			_apply_metal_on_hit(target, base_damage, source, pre_hit_hp_ratio)
		"木":
			_apply_wood_on_hit(target)
		"水":
			_apply_water_on_hit(source)
		"火":
			_apply_fire_on_hit(target, base_damage, source, hit_position)
		"土":
			_apply_earth_on_hit(target, base_damage, source)
		"雷":
			_apply_lightning_on_hit(target, base_damage, source)
		"毒":
			_apply_poison_on_hit(target, base_damage, source)

func _apply_metal_on_hit(target: Node, base_damage: float, source: Node, pre_hit_hp_ratio: float) -> void:
	var hp_ratio_limit: float = float(effects.get("metal_low_hp_ratio", 0.0))
	var multiplier: float = float(effects.get("metal_damage_multiplier", 0.0))
	if hp_ratio_limit <= 0.0 or multiplier <= 0.0 or base_damage <= 0.0:
		return
	var hp_ratio: float = pre_hit_hp_ratio
	if hp_ratio < 0.0 and target.has_method("get_hp_ratio"):
		hp_ratio = float(target.call("get_hp_ratio"))
	if hp_ratio >= 0.0 and hp_ratio < hp_ratio_limit:
		_damage_enemy(target, base_damage * multiplier, source)

func _apply_wood_on_hit(target: Node) -> void:
	var duration: float = float(effects.get("wood_root_duration", 0.0))
	if duration <= 0.0:
		return
	var applied: bool = true
	if target.has_method("apply_root"):
		applied = bool(target.call("apply_root", duration, "attribute_wood", float(effects.get("wood_root_internal_cooldown", 0.0))))
	var damage_taken_bonus: float = float(effects.get("wood_damage_taken_bonus", 0.0))
	if applied and damage_taken_bonus > 0.0 and target.has_method("apply_damage_taken_multiplier"):
		target.call("apply_damage_taken_multiplier", damage_taken_bonus, duration, "attribute_wood")

func _apply_water_on_hit(source: Node) -> void:
	if source == null:
		return
	var heal_amount: float = float(effects.get("water_heal", 0.0))
	if heal_amount <= 0.0:
		return
	var hp_ratio: float = 0.0
	if source.has_method("get_hp_ratio"):
		hp_ratio = float(source.call("get_hp_ratio"))
	if hp_ratio >= 1.0 and bool(effects.get("water_overflow_to_shield", false)) and source.has_method("add_shield"):
		var max_hp: float = float(source.get("max_hp"))
		source.call("add_shield", heal_amount, max_hp * float(effects.get("water_shield_max_ratio", 0.0)))
	elif source.has_method("heal"):
		source.call("heal", heal_amount)

func _apply_fire_on_hit(target: Node, base_damage: float, source: Node, hit_position: Vector2) -> void:
	var radius: float = float(effects.get("fire_explosion_radius", 0.0))
	var multiplier: float = float(effects.get("fire_explosion_damage_multiplier", 0.0))
	if radius <= 0.0 or multiplier <= 0.0 or base_damage <= 0.0:
		return
	var origin: Vector2 = _hit_origin(target, hit_position)
	_damage_enemies_in_radius(origin, radius, base_damage * multiplier, source, target)
	HitEffectManager.spawn_hit(get_tree(), origin, "fire", Vector2.UP, radius)

func _apply_earth_on_hit(target: Node, base_damage: float, source: Node) -> void:
	var radius: float = float(effects.get("earth_shockwave_radius", 0.0))
	var multiplier: float = float(effects.get("earth_shockwave_damage_multiplier", 0.0))
	if radius <= 0.0 or multiplier <= 0.0 or base_damage <= 0.0:
		return
	if target.has_method("apply_stun"):
		var stun_duration: float = float(effects.get("earth_center_stun", 0.0))
		if stun_duration > 0.0:
			target.call("apply_stun", stun_duration, "attribute_earth", float(effects.get("earth_stun_internal_cooldown", 0.0)))
	var origin: Vector2 = _hit_origin(target)
	_damage_enemies_in_radius(origin, radius, base_damage * multiplier, source, target)
	HitEffectManager.spawn_hit(get_tree(), origin, "earth", Vector2.UP, radius)

func _apply_lightning_on_hit(target: Node, base_damage: float, source: Node) -> void:
	var remaining: int = int(effects.get("lightning_chain_targets", 0))
	var multiplier: float = float(effects.get("lightning_chain_damage_multiplier", 0.0))
	if remaining <= 0 or multiplier <= 0.0 or base_damage <= 0.0:
		return
	var chain_range: float = float(effects.get("lightning_chain_range", LIGHTNING_CHAIN_RANGE))
	var falloff: float = float(effects.get("lightning_chain_falloff", LIGHTNING_CHAIN_FALLOFF))
	var current: Node = target
	var hit: Dictionary = {}
	if current != null:
		hit[current.get_instance_id()] = true
	var chain_damage: float = base_damage * multiplier
	while remaining > 0 and current is Node2D:
		var next_target := _nearest_unhit_enemy((current as Node2D).global_position, chain_range, hit)
		if next_target == null:
			return
		hit[next_target.get_instance_id()] = true
		HitEffectManager.spawn_coin_path(get_tree(), (current as Node2D).global_position, next_target.global_position)
		_damage_enemy(next_target, chain_damage, source)
		chain_damage *= falloff
		current = next_target
		remaining -= 1

func _apply_poison_on_hit(target: Node, base_damage: float, source: Node) -> void:
	var dps_multiplier: float = float(effects.get("poison_dps_multiplier", 0.0))
	var duration: float = float(effects.get("poison_duration", 0.0))
	if dps_multiplier <= 0.0 or duration <= 0.0 or base_damage <= 0.0 or not target.has_method("apply_poison"):
		return
	var burst_radius: float = float(effects.get("poison_burst_radius", 0.0))
	var burst_damage: float = base_damage * float(effects.get("poison_burst_damage_multiplier", 0.0))
	target.call("apply_poison", base_damage * dps_multiplier, duration, true, source, burst_radius, burst_damage)

func _damage_enemies_in_radius(origin: Vector2, radius: float, damage: float, source: Node, excluded: Node = null) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == excluded:
			continue
		if candidate is Node2D and candidate.has_method("take_damage"):
			if origin.distance_to((candidate as Node2D).global_position) <= radius:
				_damage_enemy(candidate, damage, source)

func _damage_enemy(target: Node, damage: float, source: Node) -> void:
	if damage <= 0.0 or target == null or not target.has_method("take_damage"):
		return
	target.call("take_damage", damage, source)

func _nearest_unhit_enemy(origin: Vector2, max_range: float, hit: Dictionary) -> Node2D:
	var nearest: Node2D
	var nearest_distance: float = INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		if hit.has(candidate.get_instance_id()) or bool(candidate.get("dying")):
			continue
		var distance: float = origin.distance_to((candidate as Node2D).global_position)
		if distance <= max_range and distance < nearest_distance:
			nearest = candidate as Node2D
			nearest_distance = distance
	return nearest

func _hit_origin(target: Node, fallback: Vector2 = Vector2.ZERO) -> Vector2:
	if target is Node2D:
		return (target as Node2D).global_position
	return fallback
