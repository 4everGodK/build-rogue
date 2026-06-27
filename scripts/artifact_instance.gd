extends RefCounted
class_name ArtifactInstance

var data: ArtifactData
var source_data: ArtifactData
var star_level: int = 1
var synergy_manager: SynergyManager
var cooldown_remaining: float = 0.0
var persistent_node: Node
var destiny_damage_multiplier: float = 1.0
var attack_count: int = 0

func _init(artifact_data: ArtifactData = null, star: int = 1, manager: SynergyManager = null, artifact_destiny_damage_multiplier: float = 1.0) -> void:
	source_data = artifact_data
	star_level = clampi(star, 1, 3)
	synergy_manager = manager
	destiny_damage_multiplier = maxf(0.0, artifact_destiny_damage_multiplier)
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

func update(delta: float, player: Node2D, attack_container: Node, target_reservations: Dictionary = {}, same_artifact_attack_delays: Dictionary = {}) -> void:
	if data == null:
		return
	if data.attack_template in ["orbit", "formation", "summon"]:
		start(player, attack_container)
		return

	cooldown_remaining -= delta
	if cooldown_remaining > 0.0:
		return
	var artifact_id: String = source_data.id if source_data != null else data.id
	var same_artifact_delay: float = float(same_artifact_attack_delays.get(artifact_id, 0.0))
	if same_artifact_delay > 0.0:
		cooldown_remaining = maxf(cooldown_remaining, same_artifact_delay)
		return

	var estimated_damage: float = _estimate_attack_damage(player)
	var target: Node2D = find_nearest_enemy(player, _get_target_search_range(), estimated_damage, target_reservations)
	if target == null:
		return

	var direction: Vector2 = player.global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	if data.id == "giant_sword_art":
		direction = _dense_enemy_direction(player, direction)
	var spends_life_during_attack: bool = data.attack_template == "beam"
	if not spends_life_during_attack and data.life_cost_percent > 0.0 and player.has_method("spend_life_percent"):
		player.call("spend_life_percent", data.life_cost_percent)
	if not spends_life_during_attack and data.life_cost_flat > 0.0 and player.has_method("spend_life_flat"):
		player.call("spend_life_flat", data.life_cost_flat, data.life_cost_min_hp_ratio)
	var runtime_data := _make_runtime_data(player)
	attack_count += 1
	runtime_data.set_meta("attack_count", attack_count)
	var projectile_extra_count: int = _projectile_extra_count()
	var projectile_extra_directions: Array[Vector2] = _get_projectile_extra_directions(player, target, projectile_extra_count)
	if data.id == "giant_sword_art" and star_level >= 3:
		var sweep_data: ArtifactData = runtime_data.duplicate(true) as ArtifactData
		sweep_data.attack_template = "melee"
		sweep_data.attack_shape = "circle"
		sweep_data.reveal_time = maxf(0.1, data.reveal_time * 0.65)
		sweep_data.pause_time = maxf(0.08, data.pause_time)
		sweep_data.windup_time = sweep_data.reveal_time + sweep_data.pause_time
		if sweep_data.sweep_rotation_speed > 0.0:
			sweep_data.duration = maxf(sweep_data.duration, TAU / sweep_data.sweep_rotation_speed)
		MeleeAttackTemplate.execute(player, attack_container, sweep_data, direction)
		same_artifact_attack_delays[artifact_id] = 0.035
		_reserve_target_damage(target, estimated_damage, target_reservations)
		cooldown_remaining = _next_cooldown(player)
		return
	match data.attack_template:
		"melee":
			MeleeAttackTemplate.execute(player, attack_container, runtime_data, direction)
		"projectile":
			ProjectileAttackTemplate.execute(player, attack_container, runtime_data, direction, projectile_extra_count, _projectile_extra_damage_multiplier(), projectile_extra_directions)
		"beam":
			BeamAttackTemplate.execute(player, attack_container, runtime_data, target)
		"line_delayed":
			LineDelayedAttackTemplate.execute(player, attack_container, runtime_data, direction)
		"target_aoe":
			load("res://scripts/attacks/target_aoe_attack_template.gd").execute(player, attack_container, runtime_data, target)
		"soul_banner":
			load("res://scripts/attacks/soul_banner_attack_template.gd").execute(player, attack_container, runtime_data, target)
	same_artifact_attack_delays[artifact_id] = 0.035
	_reserve_target_damage(target, estimated_damage, target_reservations)
	var cooldown_multiplier := 1.0
	if player.has_method("get_artifact_cooldown_multiplier"):
		cooldown_multiplier = float(player.call("get_artifact_cooldown_multiplier"))
	if synergy_manager != null and source_data != null and source_data.system_tag == "剑修":
		cooldown_multiplier *= synergy_manager.get_sword_cooldown_multiplier()
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

static func _sort_target_candidates(a: Dictionary, b: Dictionary) -> bool:
	return float(a["distance_squared"]) < float(b["distance_squared"])

func _get_target_search_range() -> float:
	match data.attack_template:
		"melee":
			if data.attack_shape == "circle":
				return maxf(1.0, data.radius)
			return maxf(1.0, data.length)
		"line_delayed":
			return maxf(1.0, data.length)
		"target_aoe":
			return maxf(1.0, data.range)
		"soul_banner":
			return maxf(1.0, data.range)
		_:
			return maxf(1.0, data.range)

func _estimate_attack_damage(player: Node2D) -> float:
	var runtime := _make_runtime_data(player)
	var estimate: float = runtime.damage
	return maxf(0.0, estimate)

func _get_projectile_extra_directions(player: Node2D, primary_target: Node2D, extra_count: int) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	if extra_count <= 0 or data.attack_template != "projectile":
		return directions
	var candidates: Array[Dictionary] = []
	var max_distance_squared: float = _get_target_search_range() * _get_target_search_range()
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		if enemy == primary_target or enemy.is_queued_for_deletion() or bool(enemy.get("dying")):
			continue
		var distance_squared := player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared > max_distance_squared:
			continue
		candidates.append({
			"enemy": enemy,
			"distance_squared": distance_squared,
		})
	candidates.sort_custom(_sort_target_candidates)
	for item in candidates:
		var enemy := item["enemy"] as Node2D
		var extra_direction: Vector2 = player.global_position.direction_to(enemy.global_position)
		if extra_direction == Vector2.ZERO:
			continue
		directions.append(extra_direction)
		if directions.size() >= extra_count:
			break
	return directions

func _make_effective_data(artifact_data: ArtifactData, star: int) -> ArtifactData:
	if artifact_data == null:
		return null
	var effective: ArtifactData = artifact_data.duplicate(true) as ArtifactData
	effective.set_meta("destiny_damage_multiplier", destiny_damage_multiplier)
	effective.set_meta("star_level", star)
	ArtifactStarConfig.apply_numeric_growth(effective, artifact_data, star)
	if star >= 3:
		ArtifactStarConfig.apply_star3_bonus(effective)
	if synergy_manager != null and effective.system_tag == "体修":
		_apply_body_range_multiplier(effective, float(synergy_manager.get_effect_value("body_size_multiplier", 1.0)))
	if synergy_manager != null and (effective.attack_template == "summon" or effective.summon_base_count > 0):
		effective.summon_base_count += int(synergy_manager.get_effect_value("summon_extra_count", 0))
		effective.summon_respawn_time *= float(synergy_manager.get_effect_value("summon_respawn_time_multiplier", 1.0))
		effective.summon_death_burst = bool(synergy_manager.get_effect_value("summon_death_burst_enabled", false))
	return effective

func _make_runtime_data(player: Node2D) -> ArtifactData:
	var runtime: ArtifactData = data.duplicate(true) as ArtifactData
	runtime.set_meta("destiny_damage_multiplier", destiny_damage_multiplier)
	runtime.set_meta("star_level", star_level)
	if synergy_manager != null:
		var low_hp: bool = player.has_method("get_hp_ratio") and float(player.call("get_hp_ratio")) < 0.5
		if low_hp:
			runtime.damage *= float(synergy_manager.get_effect_value("demon_low_hp_all_damage_multiplier", 1.0))
			if source_data != null and source_data.system_tag == "魔修":
				runtime.damage *= float(synergy_manager.get_effect_value("demon_low_hp_magic_damage_multiplier", 1.0))
	return runtime

func _projectile_extra_count() -> int:
	if synergy_manager == null or source_data == null or source_data.system_tag != "法修":
		return 0
	return int(synergy_manager.get_effect_value("projectile_extra_count", 0))

func _projectile_extra_damage_multiplier() -> float:
	if synergy_manager == null or source_data == null or source_data.system_tag != "法修":
		return 0.0
	return float(synergy_manager.get_effect_value("projectile_extra_damage_multiplier", 0.0))

func _dense_enemy_direction(player: Node2D, fallback: Vector2) -> Vector2:
	var best_direction: Vector2 = fallback.normalized()
	var best_score: float = -INF
	var candidates: Array[Vector2] = []
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			var to_enemy: Vector2 = player.global_position.direction_to((candidate as Node2D).global_position)
			if to_enemy != Vector2.ZERO:
				candidates.append(to_enemy)
	if candidates.is_empty():
		return best_direction
	for candidate_direction in candidates:
		var score: float = 0.0
		for raw_enemy in player.get_tree().get_nodes_in_group("enemies"):
			if not raw_enemy is Node2D or not raw_enemy.has_method("take_damage"):
				continue
			var enemy := raw_enemy as Node2D
			var offset: Vector2 = enemy.global_position - player.global_position
			var projection: float = offset.dot(candidate_direction)
			if projection < 0.0 or projection > data.range:
				continue
			var lateral: float = abs(offset.cross(candidate_direction))
			if lateral <= maxf(48.0, data.width * 1.15):
				score += 1.0 + (1.0 - projection / maxf(1.0, data.range)) * 0.35
		if score > best_score:
			best_score = score
			best_direction = candidate_direction
	return best_direction

func _apply_body_range_multiplier(effective: ArtifactData, multiplier: float) -> void:
	if multiplier <= 1.0:
		return
	effective.range *= multiplier
	effective.radius *= multiplier
	effective.width *= multiplier
	effective.length *= multiplier
	effective.counter_range *= multiplier
	effective.explosion_radius *= multiplier
	effective.extra_melee_wave_range *= multiplier
	effective.extra_melee_wave_width *= multiplier

func _next_cooldown(player: Node2D) -> float:
	var cooldown_multiplier := 1.0
	if player.has_method("get_artifact_cooldown_multiplier"):
		cooldown_multiplier = float(player.call("get_artifact_cooldown_multiplier"))
	if synergy_manager != null and source_data != null and source_data.system_tag == "鍓戜慨":
		cooldown_multiplier *= synergy_manager.get_sword_cooldown_multiplier()
	return maxf(0.05, data.cooldown * cooldown_multiplier)
