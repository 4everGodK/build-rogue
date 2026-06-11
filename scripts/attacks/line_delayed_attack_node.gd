extends Node2D
class_name LineDelayedAttackNode

var player: Node2D
var data: ArtifactData
var direction: Vector2
var warning_line: Line2D
var ink_edge_line: Line2D

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	warning_line = Line2D.new()
	warning_line.width = maxf(2.0, data.width * 0.2) if data.id != "brush" else maxf(8.0, data.width * 0.45)
	warning_line.default_color = Color(0.015, 0.012, 0.01, 0.62) if data.id == "brush" else Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.3)
	warning_line.points = PackedVector2Array([player.global_position, player.global_position + direction * data.length])
	add_child(warning_line)
	if data.id == "brush":
		_add_brush_edge()
		_run_brush_stroke()
	else:
		_run_sequence()

func _add_brush_edge() -> void:
	ink_edge_line = Line2D.new()
	ink_edge_line.width = maxf(2.0, data.width * 0.12)
	ink_edge_line.default_color = Color(0.0, 0.0, 0.0, 0.86)
	ink_edge_line.points = warning_line.points
	add_child(ink_edge_line)

func _run_sequence() -> void:
	await get_tree().create_timer(data.delayed_strike_delay).timeout
	if is_instance_valid(warning_line):
		warning_line.queue_free()
	for index in maxi(1, data.delayed_strike_count):
		if not is_instance_valid(player):
			queue_free()
			return
		var center: Vector2 = player.global_position + direction * data.length * (float(index) + 0.5) / float(maxi(1, data.delayed_strike_count))
		_strike(center)
		await get_tree().create_timer(data.delayed_strike_interval).timeout
	queue_free()

func _run_brush_stroke() -> void:
	await get_tree().create_timer(maxf(0.05, data.delayed_strike_delay)).timeout
	if not is_instance_valid(warning_line):
		queue_free()
		return
	_damage_brush_line()
	_burst_brush_ink()
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(warning_line, "width", maxf(2.0, data.width * 0.18), maxf(0.05, data.duration))
	tween.parallel().tween_property(warning_line, "modulate:a", 0.0, maxf(0.05, data.duration))
	if is_instance_valid(ink_edge_line):
		tween.parallel().tween_property(ink_edge_line, "modulate:a", 0.0, maxf(0.05, data.duration))
	tween.tween_callback(queue_free)

func _strike(center: Vector2) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if center.distance_to((candidate as Node2D).global_position) <= data.radius:
				candidate.call("take_damage", _get_damage(), player)
				_notify_artifact_damage()
	if data.id == "brush":
		HitEffectManager.spawn_hit(get_tree(), center, "ink", direction, data.radius)
	else:
		var visual: Polygon2D = Polygon2D.new()
		visual.polygon = _circle_points(data.radius)
		visual.color = data.visual_color
		visual.global_position = center
		get_tree().current_scene.add_child(visual)
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(visual, "modulate:a", 0.0, 0.12)
		tween.tween_callback(visual.queue_free)

func _damage_brush_line() -> void:
	var start: Vector2 = warning_line.points[0]
	var end: Vector2 = warning_line.points[1]
	var hit_radius: float = maxf(8.0, data.width * 0.5)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			var enemy: Node2D = candidate as Node2D
			if _distance_to_segment(enemy.global_position, start, end) <= hit_radius:
				candidate.call("take_damage", _get_damage(), player)
				_notify_artifact_damage()
				HitEffectManager.spawn_hit(get_tree(), enemy.global_position, "ink", direction, maxf(10.0, hit_radius * 0.7))

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.001:
		return point.distance_to(start)
	var t: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * t)

func _burst_brush_ink() -> void:
	var start: Vector2 = warning_line.points[0]
	var end: Vector2 = warning_line.points[1]
	var midpoint: Vector2 = start.lerp(end, 0.5)
	HitEffectManager.spawn_hit(get_tree(), midpoint, "ink", direction, maxf(18.0, data.width))
	for index in 5:
		var t: float = (float(index) + 0.5) / 5.0
		var offset: Vector2 = direction.orthogonal() * randf_range(-data.width * 0.35, data.width * 0.35)
		HitEffectManager.spawn_hit(get_tree(), start.lerp(end, t) + offset, "ink", direction, maxf(8.0, data.width * 0.35))

func _circle_points(circle_radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 18:
		var angle: float = TAU * float(index) / 18.0
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _get_damage() -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, data.damage))
	return data.damage
