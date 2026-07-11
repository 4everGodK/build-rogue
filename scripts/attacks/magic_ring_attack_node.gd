extends Node2D
class_name MagicRingAttackNode

var player: Node2D
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT
var hit_enemies: Dictionary = {}

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position = player.global_position
	_play_sequence()

func _play_sequence() -> void:
	var ring := _make_ring()
	add_child(ring)
	var tween := get_tree().create_tween()
	ring.scale = Vector2(0.25, 0.25)
	ring.modulate.a = 0.0
	tween.tween_property(ring, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(ring, "scale", Vector2.ONE, maxf(0.08, data.windup_time * 0.55))
	tween.tween_interval(maxf(0.04, data.windup_time * 0.45))
	await tween.finished
	if not is_instance_valid(self):
		return
	_fire_beam(data.damage, data.width, Color(0.5, 0.82, 1.0, 0.88))
	if int(data.get_meta("star_level", 1)) >= 3 and data.secondary_damage_mult > 0.0:
		_spawn_aftertrace()
		await get_tree().create_timer(maxf(0.03, data.secondary_delay)).timeout
		if is_instance_valid(self):
			hit_enemies.clear()
			_fire_beam(data.damage * data.secondary_damage_mult, maxf(data.width, data.secondary_radius), Color(0.62, 0.95, 1.0, 0.42))
	await get_tree().create_timer(maxf(0.08, data.duration)).timeout
	queue_free()

func _fire_beam(base_damage: float, beam_width: float, color: Color) -> void:
	var start := global_position + direction * 24.0
	var end := start + direction * data.range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.has_method("take_damage"):
			var body := enemy as Node2D
			if hit_enemies.has(body) or _distance_to_segment(body.global_position, start, end) > beam_width * 0.5:
				continue
			hit_enemies[body] = true
			var hit_damage := _get_damage(base_damage)
			var pre := _pre_hit_hp_ratio(body)
			HitFeedbackManager.deal_damage(body, hit_damage, player, data, self, {"hit_origin": player.global_position})
			_notify()
			_apply_attr(body, hit_damage, body.global_position, pre)
	var outer := Line2D.new()
	outer.width = beam_width
	outer.default_color = Color(color.r, color.g, color.b, color.a * 0.36)
	outer.points = PackedVector2Array([start, end])
	get_tree().current_scene.add_child(outer)
	var inner := Line2D.new()
	inner.width = maxf(3.0, beam_width * 0.34)
	inner.default_color = color
	inner.points = PackedVector2Array([start, end])
	get_tree().current_scene.add_child(inner)
	var tween := get_tree().create_tween()
	tween.tween_property(outer, "modulate:a", 0.0, maxf(0.06, data.duration))
	tween.parallel().tween_property(inner, "modulate:a", 0.0, maxf(0.06, data.duration))
	tween.tween_callback(outer.queue_free)
	tween.tween_callback(inner.queue_free)

func _spawn_aftertrace() -> void:
	var trace := Line2D.new()
	trace.width = maxf(data.width, data.secondary_radius)
	trace.default_color = Color(0.65, 0.92, 1.0, 0.22)
	trace.points = PackedVector2Array([global_position + direction * 24.0, global_position + direction * (data.range + 24.0)])
	get_tree().current_scene.add_child(trace)
	var tween := get_tree().create_tween()
	tween.tween_property(trace, "modulate:a", 0.0, maxf(0.1, data.secondary_delay + data.duration))
	tween.tween_callback(trace.queue_free)

func _make_ring() -> Node2D:
	var root := Node2D.new()
	root.rotation = direction.angle()
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(0.55, 0.85, 1.0, 0.9)
	ring.closed = true
	ring.points = _circle_points(maxf(16.0, data.width * 0.55), 48)
	root.add_child(ring)
	for i in 8:
		var rune := Line2D.new()
		rune.width = 2.0
		rune.default_color = Color(0.85, 0.96, 1.0, 0.75)
		rune.points = PackedVector2Array([Vector2(13, 0), Vector2(20, 0)])
		rune.rotation = TAU * float(i) / 8.0
		root.add_child(rune)
	root.position = direction * 28.0
	return root

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t := clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)

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
