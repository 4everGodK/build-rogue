extends Area2D
class_name FormationAttackNode

var player: Node2D
var data: ArtifactData
var tick_remaining: float = 0.0
var avatar_visual: Node2D
var body_barrier_busy := false
var dragon_hand_busy := false
var avatar_busy := false
var attack_instance_id: String = ""

func setup(owner_player: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	data = artifact_data
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	global_position = player.global_position
	z_as_relative = false
	z_index = 1
	if data.id == "golden_body_avatar":
		z_index = 0
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var visual: Node2D = _make_body_idle_visual() if _is_body_formation() else ArtifactVisuals.make_formation_visual(data)
	add_child(visual)
	if data.id == "golden_body_avatar":
		avatar_visual = visual
	tick_remaining = 0.15

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	tick_remaining -= delta
	if tick_remaining > 0.0:
		return
	tick_remaining = maxf(0.08, data.tick_interval)
	match data.id:
		"body_barrier":
			_trigger_body_barrier()
		"thorn_armor":
			_trigger_dragon_hand()
		"golden_body_avatar":
			_trigger_avatar_slam()
		_:
			_trigger_generic_formation()

func _trigger_generic_formation() -> void:
	if data.effect_type == "attack_speed" and player.has_method("set_artifact_cooldown_multiplier"):
		player.call("set_artifact_cooldown_multiplier", maxf(0.1, 1.0 - data.attack_speed_bonus))
		if player.has_method("set_artifact_move_speed_multiplier"):
			player.call("set_artifact_move_speed_multiplier", 1.0 + data.movement_speed_bonus)
	elif data.effect_type == "heal" and player.has_method("heal"):
		player.call("heal", data.heal_amount, data)
	elif data.effect_type == "shield" and player.has_method("add_shield"):
		player.call("add_shield", data.shield_amount, data.shield_max, data)
		if data.shield_knockback_force > 0.0:
			_knockback_nearby_enemies()
		HitEffectManager.spawn_hit(get_tree(), player.global_position, "shield", Vector2.RIGHT, data.radius)
	_damage_overlapping_bodies(data.damage, data.radius, data.knockback_force, _formation_hit_kind(), player.global_position)

func _trigger_body_barrier() -> void:
	if body_barrier_busy:
		return
	body_barrier_busy = true
	var root := _world_visual(player.global_position)
	_spawn_barrier_sequence(root, data.radius, false)
	var first_delay: float = maxf(0.12, data.windup_time + data.duration * 0.45)
	get_tree().create_timer(first_delay).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_damage_barrier_pulse(data.damage, data.radius, data.knockback_force, data.heal_amount, maxf(data.shield_max, data.heal_amount * 5.0), "shield")
	)
	if int(data.get_meta("star_level", 1)) >= 3:
		var second_delay: float = first_delay + maxf(0.08, data.secondary_delay)
		get_tree().create_timer(second_delay).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			var radius: float = data.radius * maxf(1.0, data.secondary_radius)
			_spawn_barrier_sequence(_world_visual(player.global_position), radius, true)
			_damage_barrier_pulse(data.damage * maxf(0.0, data.secondary_damage_mult), radius, data.knockback_force * 0.55, data.heal_amount * maxf(0.0, data.secondary_damage_mult), maxf(0.0, data.shield_amount), "shield")
		)
	get_tree().create_timer(maxf(0.38, first_delay + data.secondary_delay + 0.25)).timeout.connect(func() -> void:
		body_barrier_busy = false
	)

func _trigger_dragon_hand() -> void:
	if dragon_hand_busy:
		return
	dragon_hand_busy = true
	var center: Vector2 = _choose_dense_center(data.range if data.range > 0.0 else data.length, data.radius, direction_to_target())
	var targets: Array = _collect_targets_near(center, data.radius, data.max_targets)
	_spawn_dragon_hand_visual(center, false)
	_pull_targets(targets, center, 0.18)
	var slam_delay: float = maxf(0.15, data.windup_time + 0.16)
	get_tree().create_timer(slam_delay).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_damage_specific_or_radius(targets, center, data.radius, data.damage, data.knockback_force, "earth")
	)
	if int(data.get_meta("star_level", 1)) >= 3:
		var combo_delay: float = slam_delay + maxf(0.08, data.secondary_delay)
		get_tree().create_timer(combo_delay).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			_spawn_dragon_hand_visual(center, true)
			var combo_radius: float = maxf(data.radius, data.secondary_radius)
			_damage_overlapping_at(center, combo_radius, data.damage * maxf(0.0, data.secondary_damage_mult), data.knockback_force * 0.7, "earth")
		)
	get_tree().create_timer(maxf(0.5, slam_delay + data.secondary_delay + 0.28)).timeout.connect(func() -> void:
		dragon_hand_busy = false
	)

func _trigger_avatar_slam() -> void:
	if avatar_busy:
		return
	avatar_busy = true
	var center: Vector2 = _choose_dense_center(data.range if data.range > 0.0 else data.radius * 1.5, data.radius, direction_to_target())
	_animate_avatar_windup(center, false)
	var slam_delay: float = maxf(0.18, data.windup_time)
	get_tree().create_timer(slam_delay).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_avatar_slam_at(center, data.radius, data.damage, data.knockback_force, data.screen_shake_strength)
	)
	if int(data.get_meta("star_level", 1)) >= 3:
		var second_delay: float = slam_delay + maxf(0.14, data.secondary_delay)
		var offset_dir: Vector2 = direction_to_target().rotated(PI * 0.5)
		if offset_dir == Vector2.ZERO:
			offset_dir = Vector2.RIGHT
		var second_center: Vector2 = center + offset_dir * clampf(data.radius * 0.7, 60.0, 180.0)
		get_tree().create_timer(second_delay).timeout.connect(func() -> void:
			if not is_instance_valid(self):
				return
			_animate_avatar_windup(second_center, true)
			_avatar_slam_at(second_center, data.radius * maxf(1.0, data.secondary_radius), data.damage * maxf(0.0, data.secondary_damage_mult), data.knockback_force * 0.85, data.screen_shake_strength * 0.65)
		)
	get_tree().create_timer(maxf(0.7, slam_delay + data.secondary_delay + 0.34)).timeout.connect(func() -> void:
		avatar_busy = false
		if is_instance_valid(avatar_visual):
			var tween := get_tree().create_tween()
			tween.tween_property(avatar_visual, "modulate:a", 0.28, 0.16)
	)

func _damage_overlapping_bodies(raw_damage: float, radius: float, knockback: float, hit_kind: String, knockback_origin: Vector2) -> void:
	_damage_overlapping_at(player.global_position, radius, raw_damage, knockback, hit_kind, knockback_origin)

func _damage_overlapping_at(center: Vector2, radius: float, raw_damage: float, knockback: float, hit_kind: String, knockback_origin: Vector2 = Vector2(1000000000.0, 1000000000.0)) -> void:
	var hits: Dictionary = {}
	var final_origin: Vector2 = center if knockback_origin == Vector2(1000000000.0, 1000000000.0) else knockback_origin
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(candidate) or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		if center.distance_to(enemy.global_position) <= radius:
			hits[candidate] = true
			_apply_hit(enemy, raw_damage, knockback, hit_kind, final_origin)
	HitEffectManager.spawn_hit(get_tree(), center, hit_kind, Vector2.RIGHT, radius)

func _damage_specific_or_radius(targets: Array, center: Vector2, radius: float, raw_damage: float, knockback: float, hit_kind: String) -> void:
	var hit_set: Dictionary = {}
	for enemy in targets:
		if _is_valid_enemy(enemy):
			var live_enemy := enemy as Node2D
			hit_set[live_enemy] = true
			_apply_hit(live_enemy, raw_damage, knockback, hit_kind, center)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if hit_set.has(candidate) or not _is_valid_enemy(candidate):
			continue
		var enemy := candidate as Node2D
		if center.distance_to(enemy.global_position) <= radius * 0.65:
			hit_set[enemy] = true
			_apply_hit(enemy, raw_damage, knockback, hit_kind, center)
	HitEffectManager.spawn_hit(get_tree(), center, hit_kind, Vector2.RIGHT, radius)

func _damage_barrier_pulse(raw_damage: float, radius: float, knockback: float, heal_per_hit: float, heal_cap: float, hit_kind: String) -> void:
	var healed: float = 0.0
	var hits: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(candidate) or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		if player.global_position.distance_to(enemy.global_position) <= radius:
			hits[candidate] = true
			_apply_hit(enemy, raw_damage, knockback, hit_kind, player.global_position)
			if heal_per_hit > 0.0 and player.has_method("heal") and healed < heal_cap:
				var heal_value: float = minf(heal_per_hit, heal_cap - healed)
				healed += heal_value
				player.call("heal", heal_value, data)
				_spawn_heal_line(enemy.global_position, player.global_position)
	HitEffectManager.spawn_hit(get_tree(), player.global_position, hit_kind, Vector2.RIGHT, radius)

func _apply_hit(enemy: Node2D, raw_damage: float, knockback: float, hit_kind: String, knockback_origin: Vector2) -> void:
	var hit_damage: float = _get_damage(raw_damage)
	var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(enemy)
	var killed: bool = HitFeedbackManager.deal_damage(enemy, hit_damage, player, data, self, {
		"attack_instance_id": attack_instance_id,
		"hit_origin": knockback_origin,
		"effect_origin": knockback_origin,
	})
	_notify_artifact_damage()
	_apply_attribute_on_hit(enemy, hit_damage, enemy.global_position, pre_hit_hp_ratio)
	if killed and data.kill_heal_amount > 0.0 and player.has_method("heal"):
		player.call("heal", data.kill_heal_amount, data)
	if data.effect_type == "slow" and enemy.has_method("apply_slow"):
		enemy.call("apply_slow", data.slow_percent, maxf(0.2, data.tick_interval * 1.5), self)

func _choose_dense_center(search_range: float, radius: float, base_direction: Vector2) -> Vector2:
	var origin: Vector2 = player.global_position
	var candidates: Array[Vector2] = []
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if _is_valid_enemy(enemy_node):
			var enemy := enemy_node as Node2D
			if origin.distance_to(enemy.global_position) <= maxf(search_range, radius):
				candidates.append(enemy.global_position)
	if candidates.is_empty():
		return origin + base_direction.normalized() * minf(search_range, radius * 1.4)
	var best: Vector2 = candidates[0]
	var best_score := -999999.0
	for candidate in candidates:
		var count := 0
		var distance_penalty: float = origin.distance_to(candidate) * 0.01
		for other in candidates:
			if candidate.distance_to(other) <= radius:
				count += 1
		var score: float = float(count) - distance_penalty
		if score > best_score:
			best_score = score
			best = candidate
	return best

func _collect_targets_near(center: Vector2, radius: float, limit: int) -> Array:
	var found: Array = []
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if _is_valid_enemy(candidate) and center.distance_to((candidate as Node2D).global_position) <= radius:
			found.append(candidate as Node2D)
	found.sort_custom(func(a: Variant, b: Variant) -> bool:
		if not _is_valid_enemy(a):
			return false
		if not _is_valid_enemy(b):
			return true
		return center.distance_to((a as Node2D).global_position) < center.distance_to((b as Node2D).global_position)
	)
	if limit > 0 and found.size() > limit:
		found.resize(limit)
	return found

func _pull_targets(targets: Array, center: Vector2, time: float) -> void:
	for enemy in targets:
		if not _is_valid_enemy(enemy):
			continue
		var live_enemy := enemy as Node2D
		var resistance: float = 0.35 if live_enemy.is_in_group("bosses") or live_enemy.get_class().contains("Boss") else 1.0
		var target_position: Vector2 = live_enemy.global_position.lerp(center, resistance)
		var tween := get_tree().create_tween()
		tween.tween_property(live_enemy, "global_position", target_position, time)

func _avatar_slam_at(center: Vector2, radius: float, raw_damage: float, knockback: float, shake: float) -> void:
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	_spawn_slam_visual(center, radius)
	_damage_overlapping_at(center, radius, raw_damage, knockback, "earth", center)

func direction_to_target() -> Vector2:
	var nearest: Node2D = null
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if _is_valid_enemy(candidate):
			var distance: float = player.global_position.distance_to((candidate as Node2D).global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = candidate as Node2D
	if nearest != null:
		return player.global_position.direction_to(nearest.global_position)
	return Vector2.RIGHT

func _make_body_idle_visual() -> Node2D:
	var root := Node2D.new()
	match data.id:
		"body_barrier":
			var ring := Line2D.new()
			ring.width = 4.0
			ring.closed = true
			ring.default_color = Color(0.95, 0.18, 0.16, 0.22)
			ring.points = _circle_points(data.radius * 0.55, 48)
			root.add_child(ring)
		"thorn_armor":
			var arm := Line2D.new()
			arm.width = 7.0
			arm.default_color = Color(0.95, 0.78, 0.38, 0.18)
			arm.points = PackedVector2Array([Vector2(-28, 0), Vector2(30, -12), Vector2(48, 0)])
			root.add_child(arm)
		"golden_body_avatar":
			root.position = Vector2(0, -52)
			root.modulate.a = 0.28
			var torso := Polygon2D.new()
			torso.color = Color(1.0, 0.78, 0.32, 0.22)
			torso.polygon = PackedVector2Array([Vector2(-42, -42), Vector2(42, -42), Vector2(62, 80), Vector2(-62, 80)])
			root.add_child(torso)
			var head := Line2D.new()
			head.width = 4.0
			head.closed = true
			head.default_color = Color(1.0, 0.9, 0.46, 0.32)
			head.points = _circle_points(26.0, 36)
			head.position = Vector2(0, -76)
			root.add_child(head)
			var tween := create_tween()
			tween.set_loops()
			tween.tween_property(root, "scale", Vector2(1.04, 1.04), 1.2)
			tween.tween_property(root, "scale", Vector2.ONE, 1.2)
	return root

func _spawn_barrier_sequence(root: Node2D, radius: float, pale: bool) -> void:
	root.global_position = player.global_position
	var ring := Line2D.new()
	ring.width = 8.0 if not pale else 5.0
	ring.closed = true
	ring.default_color = Color(0.95, 0.12, 0.1, 0.46 if not pale else 0.24)
	ring.points = _circle_points(radius, 64)
	root.add_child(ring)
	var inner := Polygon2D.new()
	inner.color = Color(0.95, 0.18, 0.16, 0.14 if not pale else 0.08)
	inner.polygon = _circle_points(radius * 0.85, 64)
	root.add_child(inner)
	root.scale = Vector2(0.55, 0.55)
	var tween := get_tree().create_tween()
	tween.tween_property(root, "scale", Vector2(1.0, 1.0), 0.12)
	tween.tween_property(root, "scale", Vector2(0.72, 0.72), 0.08)
	tween.tween_property(root, "scale", Vector2(1.25, 1.25), 0.08)
	tween.parallel().tween_property(root, "modulate:a", 0.0, 0.18).set_delay(0.1)
	tween.tween_callback(root.queue_free)

func _spawn_dragon_hand_visual(center: Vector2, combo: bool) -> void:
	var root := _world_visual(center)
	var hand := Polygon2D.new()
	hand.color = Color(0.95, 0.76, 0.34, 0.44 if not combo else 0.32)
	var size: float = data.radius * (0.48 if not combo else 0.62)
	hand.polygon = PackedVector2Array([Vector2(-size, -size * 0.28), Vector2(-size * 0.2, -size * 0.65), Vector2(size * 0.62, -size * 0.42), Vector2(size, 0), Vector2(size * 0.62, size * 0.42), Vector2(-size * 0.2, size * 0.65), Vector2(-size, size * 0.28)])
	root.add_child(hand)
	var tween := get_tree().create_tween()
	root.scale = Vector2(0.4, 1.2)
	tween.tween_property(root, "scale", Vector2(1.0, 1.0), 0.16)
	tween.tween_property(root, "scale", Vector2(0.72, 0.72), 0.08)
	tween.tween_property(root, "modulate:a", 0.0, 0.18)
	tween.tween_callback(root.queue_free)

func _animate_avatar_windup(center: Vector2, second: bool) -> void:
	if not is_instance_valid(avatar_visual):
		return
	var tween := get_tree().create_tween()
	tween.tween_property(avatar_visual, "modulate:a", 0.68 if not second else 0.56, 0.12)
	tween.parallel().tween_property(avatar_visual, "position", Vector2(0, -68), 0.12)
	tween.tween_property(avatar_visual, "position", Vector2(0, -52), 0.16)

func _spawn_slam_visual(center: Vector2, radius: float) -> void:
	var root := _world_visual(center)
	var ring := Line2D.new()
	ring.width = 10.0
	ring.closed = true
	ring.default_color = Color(1.0, 0.76, 0.28, 0.48)
	ring.points = _circle_points(radius, 72)
	root.add_child(ring)
	for i in 10:
		var crack := Line2D.new()
		crack.width = 3.0
		crack.default_color = Color(0.7, 0.48, 0.2, 0.48)
		var angle: float = TAU * float(i) / 10.0
		var dir := Vector2(cos(angle), sin(angle))
		crack.points = PackedVector2Array([dir * radius * 0.18, dir * radius * randf_range(0.58, 0.95)])
		root.add_child(crack)
	var tween := get_tree().create_tween()
	root.scale = Vector2(0.25, 0.25)
	tween.tween_property(root, "scale", Vector2.ONE, 0.13)
	tween.tween_property(root, "modulate:a", 0.0, 0.28)
	tween.tween_callback(root.queue_free)

func _spawn_heal_line(from_position: Vector2, to_position: Vector2) -> void:
	var root := _world_visual(Vector2.ZERO)
	root.global_position = from_position
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.18, 0.16, 0.52)
	line.points = PackedVector2Array([Vector2.ZERO, to_position - from_position])
	root.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(root, "modulate:a", 0.0, 0.18)
	tween.tween_callback(root.queue_free)

func _world_visual(position: Vector2) -> Node2D:
	var root := Node2D.new()
	root.global_position = position
	root.z_as_relative = false
	root.z_index = 4
	if get_tree().current_scene != null:
		get_tree().current_scene.add_child(root)
	else:
		add_child(root)
	return root

func _formation_hit_kind() -> String:
	match data.id:
		"thorn_armor":
			return "earth"
		"body_barrier":
			return "shield"
		"golden_body_avatar":
			return "earth"
		_:
			return "flash"

func _is_body_formation() -> bool:
	return data.id in ["body_barrier", "thorn_armor", "golden_body_avatar"]

func _is_valid_enemy(candidate: Variant) -> bool:
	return is_instance_valid(candidate) and candidate is Node2D and not candidate.is_queued_for_deletion() and candidate.has_method("take_damage") and not bool(candidate.get("dying"))

func _knockback_nearby_enemies() -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("apply_knockback"):
			if player.global_position.distance_to((candidate as Node2D).global_position) <= data.radius:
				var enemy := candidate as Node2D
				enemy.call("apply_knockback", player.global_position.direction_to(enemy.global_position), data.shield_knockback_force)

func _get_damage(raw_damage: float) -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, raw_damage))
	return raw_damage

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attribute_on_hit(target: Node, base_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float = -1.0) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, target, base_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(target: Node) -> float:
	if target != null and target.has_method("get_hp_ratio"):
		return float(target.call("get_hp_ratio"))
	return -1.0

func _circle_points(circle_radius: float, segments: int = 48) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in segments:
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points

func _exit_tree() -> void:
	if data != null and data.effect_type == "attack_speed" and is_instance_valid(player):
		if player.has_method("set_artifact_cooldown_multiplier"):
			player.call("set_artifact_cooldown_multiplier", 1.0)
		if player.has_method("set_artifact_move_speed_multiplier"):
			player.call("set_artifact_move_speed_multiplier", 1.0)
