extends Node2D
class_name FireGourdAttackNode

var player: Node2D
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT

func setup(owner_player: Node2D, artifact_data: ArtifactData, fallback_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = _dense_direction(fallback_direction)
	global_position = player.global_position
	_run()

func _run() -> void:
	_spawn_gourd()
	await get_tree().create_timer(maxf(0.04, data.windup_time)).timeout
	var elapsed := 0.0
	while elapsed < data.duration:
		_pulse_flame()
		await get_tree().create_timer(maxf(0.05, data.tick_interval)).timeout
		elapsed += maxf(0.05, data.tick_interval)
	if int(data.get_meta("star_level", 1)) >= 3:
		_spawn_fire_seed()
	await get_tree().create_timer(0.18).timeout
	queue_free()

func _pulse_flame() -> void:
	var hits := {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.has_method("take_damage"):
			var body := enemy as Node2D
			var offset: Vector2 = body.global_position - global_position
			var angle: float = abs(direction.angle_to(offset.normalized())) if offset.length() > 0.01 else 0.0
			if offset.length() > data.length or angle > deg_to_rad(data.fan_angle if data.fan_angle > 0.0 else 34.0) or hits.has(body):
				continue
			hits[body] = true
			var hit_damage: float = _get_damage(data.damage * maxf(0.1, data.secondary_damage_mult))
			var pre: float = _pre_hit_hp_ratio(body)
			body.call("take_damage", hit_damage, player)
			_notify()
			_apply_attr(body, hit_damage, body.global_position, pre)
			if data.poison_dps > 0.0 and body.has_method("apply_poison"):
				body.call("apply_poison", data.poison_dps, maxf(0.1, data.poison_duration), false, self)
			HitEffectManager.spawn_hit(get_tree(), body.global_position, "fire", direction, 12.0)
	_spawn_flame_visual()

func _spawn_fire_seed() -> void:
	var end := global_position + direction * data.length
	_spawn_burning_area(end, maxf(12.0, data.explosion_radius), maxf(0.1, data.secondary_damage_mult))

func _spawn_burning_area(pos: Vector2, radius: float, damage_mult: float) -> void:
	var ring := Polygon2D.new()
	ring.polygon = _circle_points(radius, 32)
	ring.color = Color(1.0, 0.28, 0.04, 0.28)
	ring.global_position = pos
	get_tree().current_scene.add_child(ring)
	var elapsed := 0.0
	while elapsed < data.secondary_delay:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Node2D and enemy.has_method("take_damage") and (enemy as Node2D).global_position.distance_to(pos) <= radius:
				var body := enemy as Node2D
				var hit_damage := _get_damage(data.damage * damage_mult)
				var pre := _pre_hit_hp_ratio(body)
				body.call("take_damage", hit_damage, player)
				_notify()
				_apply_attr(body, hit_damage, body.global_position, pre)
		await get_tree().create_timer(maxf(0.08, data.delayed_strike_interval)).timeout
		elapsed += maxf(0.08, data.delayed_strike_interval)
	ring.queue_free()

func _spawn_gourd() -> void:
	var gourd := Polygon2D.new()
	gourd.polygon = PackedVector2Array([Vector2(-10, -16), Vector2(8, -18), Vector2(16, -4), Vector2(10, 16), Vector2(-8, 18), Vector2(-16, 4)])
	gourd.color = Color(0.75, 0.26, 0.08, 0.78)
	gourd.position = direction.orthogonal() * -20.0 + Vector2(0, -18)
	gourd.rotation = direction.angle()
	add_child(gourd)

func _spawn_flame_visual() -> void:
	var poly := Polygon2D.new()
	var half := deg_to_rad(data.fan_angle if data.fan_angle > 0.0 else 34.0)
	poly.polygon = PackedVector2Array([Vector2.ZERO, direction.rotated(-half) * data.length, direction * data.length * randf_range(0.86, 1.0), direction.rotated(half) * data.length])
	poly.color = Color(1.0, randf_range(0.24, 0.46), 0.04, 0.28)
	poly.global_position = global_position
	get_tree().current_scene.add_child(poly)
	var tween := get_tree().create_tween()
	tween.tween_property(poly, "modulate:a", 0.0, maxf(0.08, data.tick_interval))
	tween.tween_callback(poly.queue_free)

func _dense_direction(fallback: Vector2) -> Vector2:
	var best := fallback.normalized()
	if best == Vector2.ZERO:
		best = Vector2.RIGHT
	var score_best := -1
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		var dir := player.global_position.direction_to((enemy as Node2D).global_position)
		var score := 0
		for other in get_tree().get_nodes_in_group("enemies"):
			if other is Node2D:
				var offset := (other as Node2D).global_position - player.global_position
				if offset.length() <= data.length and abs(dir.angle_to(offset.normalized())) <= deg_to_rad(data.fan_angle if data.fan_angle > 0.0 else 34.0):
					score += 1
		if score > score_best:
			score_best = score
			best = dir
	return best

func _get_damage(base_damage: float) -> float:
	return float(player.call("get_artifact_damage", data, base_damage)) if player != null and player.has_method("get_artifact_damage") else base_damage

func _notify() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attr(target: Node, damage: float, pos: Vector2, pre: float) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, target, damage, pos, pre)

func _pre_hit_hp_ratio(target: Node) -> float:
	return float(target.call("get_hp_ratio")) if target != null and target.has_method("get_hp_ratio") else -1.0

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments:
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / float(segments)) * radius)
	return points
