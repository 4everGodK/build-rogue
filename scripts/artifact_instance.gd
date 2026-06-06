extends RefCounted
class_name ArtifactInstance

var data: ArtifactData
var source_data: ArtifactData
var star_level: int = 1
var synergy_manager: SynergyManager
var cooldown_remaining: float = 0.0
var persistent_node: Node

func _init(artifact_data: ArtifactData = null, star: int = 1, manager: SynergyManager = null) -> void:
	source_data = artifact_data
	star_level = clampi(star, 1, 3)
	synergy_manager = manager
	data = _make_effective_data(artifact_data, star_level)
	if data != null:
		cooldown_remaining = randf_range(0.05, maxf(0.05, data.cooldown))

func start(player: Node2D, attack_container: Node) -> void:
	if data == null or is_instance_valid(persistent_node):
		return
	match data.attack_template:
		"orbit":
			persistent_node = OrbitAttackTemplate.create(player, attack_container, data)
		"formation":
			persistent_node = FormationAttackTemplate.create(player, attack_container, data)
		"summon":
			persistent_node = SummonAttackTemplate.create(player, attack_container, data)

func update(delta: float, player: Node2D, attack_container: Node, target_reservations: Dictionary = {}) -> void:
	if data == null:
		return
	if data.attack_template in ["orbit", "formation", "summon"]:
		start(player, attack_container)
		return

	cooldown_remaining -= delta
	if cooldown_remaining > 0.0:
		return

	var estimated_damage: float = _estimate_attack_damage(player)
	var target: Node2D = find_nearest_enemy(player, _get_target_search_range(), estimated_damage, target_reservations)
	if target == null:
		return

	var direction: Vector2 = player.global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	if data.life_cost_percent > 0.0 and player.has_method("spend_life_percent"):
		player.call("spend_life_percent", data.life_cost_percent)
	var runtime_data := _make_runtime_data(player)
	match data.attack_template:
		"melee":
			MeleeAttackTemplate.execute(player, attack_container, runtime_data, direction)
		"projectile":
			ProjectileAttackTemplate.execute(player, attack_container, runtime_data, direction, _projectile_extra_count(), _projectile_extra_damage_multiplier())
		"beam":
			BeamAttackTemplate.execute(player, attack_container, runtime_data, target)
		"line_delayed":
			LineDelayedAttackTemplate.execute(player, attack_container, runtime_data, direction)
	if source_data != null and source_data.system_tag == "剑修" and randf() < _sword_double_chance():
		match data.attack_template:
			"melee":
				MeleeAttackTemplate.execute(player, attack_container, runtime_data, direction)
			"projectile":
				ProjectileAttackTemplate.execute(player, attack_container, runtime_data, direction, _projectile_extra_count(), _projectile_extra_damage_multiplier())
			"beam":
				BeamAttackTemplate.execute(player, attack_container, runtime_data, target)
			"line_delayed":
				LineDelayedAttackTemplate.execute(player, attack_container, runtime_data, direction)
	_reserve_target_damage(target, estimated_damage, target_reservations)
	var cooldown_multiplier := 1.0
	if player.has_method("get_artifact_cooldown_multiplier"):
		cooldown_multiplier = float(player.call("get_artifact_cooldown_multiplier"))
	cooldown_remaining = maxf(0.05, data.cooldown * cooldown_multiplier)

func dispose() -> void:
	if is_instance_valid(persistent_node):
		persistent_node.queue_free()
	persistent_node = null

static func find_nearest_enemy(player: Node2D, max_range: float = INF, estimated_damage: float = 0.0, target_reservations: Dictionary = {}) -> Node2D:
	var nearest_viable: Node2D
	var nearest_viable_distance_squared: float = INF
	var nearest_any: Node2D
	var nearest_any_distance_squared: float = INF
	var max_distance_squared: float = max_range * max_range
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		if enemy.is_queued_for_deletion() or bool(enemy.get("dying")):
			continue
		var distance_squared := player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared > max_distance_squared:
			continue
		if distance_squared < nearest_any_distance_squared:
			nearest_any = enemy
			nearest_any_distance_squared = distance_squared
		var reserved_damage: float = float(target_reservations.get(enemy.get_instance_id(), 0.0))
		var remaining_after_reserved: float = _get_enemy_hp(enemy) - reserved_damage
		if remaining_after_reserved <= 0.0:
			continue
		if distance_squared < nearest_viable_distance_squared:
			nearest_viable = enemy
			nearest_viable_distance_squared = distance_squared
	return nearest_viable if nearest_viable != null else nearest_any

static func _get_enemy_hp(enemy: Node2D) -> float:
	var hp_value: Variant = enemy.get("hp")
	if hp_value is int or hp_value is float:
		return float(hp_value)
	return INF

static func _reserve_target_damage(target: Node2D, estimated_damage: float, target_reservations: Dictionary) -> void:
	if target == null or estimated_damage <= 0.0:
		return
	var key: int = target.get_instance_id()
	target_reservations[key] = float(target_reservations.get(key, 0.0)) + estimated_damage

func _get_target_search_range() -> float:
	match data.attack_template:
		"melee":
			if data.attack_shape == "circle":
				return maxf(1.0, data.radius)
			return maxf(1.0, data.length)
		"line_delayed":
			return maxf(1.0, data.length)
		_:
			return maxf(1.0, data.range)

func _estimate_attack_damage(player: Node2D) -> float:
	var runtime := _make_runtime_data(player)
	var estimate: float = runtime.damage
	if source_data != null and source_data.system_tag == "剑修":
		estimate *= 1.0 + _sword_double_chance()
	return maxf(0.0, estimate)

func _make_effective_data(artifact_data: ArtifactData, star: int) -> ArtifactData:
	if artifact_data == null:
		return null
	var effective := artifact_data.duplicate(true) as ArtifactData
	match star:
		2:
			effective.damage *= 1.5
			effective.cooldown *= 0.85
		3:
			effective.damage *= 2.2
			effective.cooldown *= 0.7
	if synergy_manager != null and effective.attack_template == "formation":
		effective.radius *= float(synergy_manager.get_effect_value("formation_radius_multiplier", 1.0))
	return effective

func _make_runtime_data(player: Node2D) -> ArtifactData:
	var runtime := data.duplicate(true) as ArtifactData
	if synergy_manager != null:
		var low_hp: bool = player.has_method("get_hp_ratio") and float(player.call("get_hp_ratio")) < 0.5
		if low_hp:
			runtime.damage *= float(synergy_manager.get_effect_value("demon_low_hp_all_damage_multiplier", 1.0))
			if source_data != null and source_data.system_tag == "魔修":
				runtime.damage *= float(synergy_manager.get_effect_value("demon_low_hp_magic_damage_multiplier", 1.0))
	return runtime

func _sword_double_chance() -> float:
	if synergy_manager == null:
		return 0.0
	return float(synergy_manager.get_effect_value("sword_double_chance", 0.0))

func _projectile_extra_count() -> int:
	if synergy_manager == null or source_data == null or source_data.system_tag != "法修":
		return 0
	return int(synergy_manager.get_effect_value("projectile_extra_count", 0))

func _projectile_extra_damage_multiplier() -> float:
	if synergy_manager == null or source_data == null or source_data.system_tag != "法修":
		return 0.0
	return float(synergy_manager.get_effect_value("projectile_extra_damage_multiplier", 0.0))
