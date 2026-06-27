extends Node2D
class_name TargetAoeAttackNode

var player: Node2D
var data: ArtifactData
var target_position: Vector2

func setup(owner_player: Node2D, artifact_data: ArtifactData, target: Node2D) -> void:
	player = owner_player
	data = artifact_data
	target_position = target.global_position if target != null else owner_player.global_position
	if data.id == "divine_thunder":
		target_position = _best_thunder_center(target_position)
	global_position = target_position
	if data.id == "divine_thunder":
		_run_divine_thunder()
	else:
		_strike()

func _run_divine_thunder() -> void:
	_spawn_warning(maxf(8.0, data.radius))
	await get_tree().create_timer(maxf(0.04, data.windup_time)).timeout
	var radius: float = maxf(8.0, data.radius)
	if int(data.get_meta("star_level", 1)) >= 3:
		radius *= maxf(1.0, data.secondary_radius)
	_strike_radius(radius, data.damage)
	_chain_lightning(radius)
	if int(data.get_meta("star_level", 1)) >= 3:
		await _run_thunder_judgement(radius)
	get_tree().create_timer(maxf(0.08, data.duration)).timeout.connect(queue_free)

func _strike() -> void:
	var radius: float = maxf(8.0, data.radius)
	_strike_radius(radius, data.damage)
	get_tree().create_timer(maxf(0.08, data.duration)).timeout.connect(queue_free)

func _strike_radius(radius: float, base_damage: float) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			var enemy := candidate as Node2D
			if enemy.global_position.distance_to(target_position) <= radius:
				var hit_damage: float = _get_damage(base_damage)
				var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(candidate)
				candidate.call("take_damage", hit_damage, player)
				_notify_artifact_damage()
				_apply_attribute_on_hit(candidate, hit_damage, enemy.global_position, pre_hit_hp_ratio)
	_spawn_visual(radius)

func _chain_lightning(radius: float, chain_count_override: int = -1) -> void:
	var max_count: int = chain_count_override if chain_count_override >= 0 else maxi(0, data.count)
	if max_count <= 0:
		return
	var candidates: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.has_method("take_damage") and target_position.distance_to((enemy as Node2D).global_position) <= maxf(radius, data.bounce_range):
			candidates.append(enemy as Node2D)
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return target_position.distance_squared_to(a.global_position) < target_position.distance_squared_to(b.global_position)
	)
	for i in mini(max_count, candidates.size()):
		var enemy := candidates[i]
		var hit_damage := _get_damage(data.damage * maxf(0.0, data.secondary_damage_mult))
		var pre := _pre_hit_hp_ratio(enemy)
		enemy.call("take_damage", hit_damage, player)
		_notify_artifact_damage()
		_apply_attribute_on_hit(enemy, hit_damage, enemy.global_position, pre)
		_spawn_chain_line(target_position, enemy.global_position)

func _run_thunder_judgement(radius: float) -> void:
	var field := Line2D.new()
	field.width = 4.0
	field.default_color = Color(0.58, 0.82, 1.0, 0.28)
	field.closed = true
	field.points = _circle_points(radius, 64)
	add_child(field)
	var struck: Dictionary = {}
	for index in maxi(0, data.delayed_strike_count):
		await get_tree().create_timer(maxf(0.06, data.delayed_strike_interval)).timeout
		var target := _next_judgement_target(radius, struck)
		var pos := target.global_position if target != null else target_position + Vector2.RIGHT.rotated(TAU * float(index) / maxf(1.0, data.delayed_strike_count)) * radius * 0.45
		if target != null:
			struck[target] = true
		var old_pos := target_position
		target_position = pos
		_strike_radius(data.explosion_radius if data.explosion_radius > 0.0 else radius * 0.32, data.damage * maxf(0.0, data.poison_explosion_damage_mult))
		_chain_lightning(radius, maxi(0, data.projectile_bounce))
		target_position = old_pos
	var tween := get_tree().create_tween()
	tween.tween_property(field, "modulate:a", 0.0, 0.12)
	tween.tween_callback(field.queue_free)

func _next_judgement_target(radius: float, struck: Dictionary) -> Node2D:
	var fallback: Node2D
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.has_method("take_damage") and target_position.distance_to((enemy as Node2D).global_position) <= radius:
			if fallback == null:
				fallback = enemy as Node2D
			if not struck.has(enemy):
				return enemy as Node2D
	return fallback

func _best_thunder_center(fallback: Vector2) -> Vector2:
	var best := fallback
	var best_count := -1
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		var center := (enemy as Node2D).global_position
		var count := 0
		for other in get_tree().get_nodes_in_group("enemies"):
			if other is Node2D and center.distance_to((other as Node2D).global_position) <= data.radius:
				count += 1
		var dist := player.global_position.distance_squared_to(center)
		if count > best_count or (count == best_count and dist < best_dist):
			best_count = count
			best_dist = dist
			best = center
	return best

func _spawn_warning(radius: float) -> void:
	var ring := Line2D.new()
	ring.width = maxf(2.0, radius * 0.025)
	ring.default_color = Color(0.72, 0.9, 1.0, 0.45)
	ring.closed = true
	ring.points = _circle_points(radius, 56)
	add_child(ring)
	var tween := get_tree().create_tween()
	tween.tween_property(ring, "scale", Vector2(1.08, 1.08), maxf(0.04, data.windup_time))
	tween.parallel().tween_property(ring, "modulate:a", 0.0, maxf(0.04, data.windup_time))
	tween.tween_callback(ring.queue_free)

func _spawn_chain_line(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.75, 0.95, 1.0, 0.72)
	line.points = PackedVector2Array([from, from.lerp(to, 0.5) + Vector2(randf_range(-8, 8), randf_range(-8, 8)), to])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

func _spawn_visual(radius: float) -> void:
	var bolt := Line2D.new()
	bolt.width = maxf(5.0, radius * 0.06)
	bolt.default_color = Color(0.68, 0.94, 1.0, 0.95)
	bolt.points = PackedVector2Array([
		Vector2(0.0, -radius * 1.35),
		Vector2(-radius * 0.12, -radius * 0.62),
		Vector2(radius * 0.1, -radius * 0.18),
		Vector2(0.0, 0.0),
	])
	add_child(bolt)
	HitEffectManager.spawn_hit(get_tree(), target_position, "lightning", Vector2.DOWN, radius)
	var ring := Line2D.new()
	ring.width = maxf(3.0, radius * 0.025)
	ring.default_color = Color(0.45, 0.84, 1.0, 0.42)
	ring.closed = true
	ring.points = _circle_points(radius, 56)
	add_child(ring)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, maxf(0.08, data.duration))

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

func _get_damage(base_damage: float = -1.0) -> float:
	var value: float = data.damage if base_damage < 0.0 else base_damage
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, value))
	return value

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
