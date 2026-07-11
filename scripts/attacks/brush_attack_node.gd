extends Node2D
class_name BrushAttackNode

var player: Node2D
var data: ArtifactData
var center: Vector2
var aim_direction := Vector2.RIGHT

func setup(owner_player: Node2D, artifact_data: ArtifactData, direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	aim_direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	center = _best_center()
	global_position = center
	_run()

func _run() -> void:
	_spawn_brush()
	var strokes: Array[Line2D] = []
	for i in 3:
		var stroke := _make_stroke(i)
		strokes.append(stroke)
		add_child(stroke)
		stroke.modulate.a = 0.0
		var tween := get_tree().create_tween()
		tween.tween_property(stroke, "modulate:a", 0.9, maxf(0.04, data.delayed_strike_interval))
		await tween.finished
	await get_tree().create_timer(maxf(0.04, data.secondary_delay)).timeout
	for stroke in strokes:
		stroke.default_color = Color(0.15, 0.8, 0.35, 0.75)
	_damage_area(data.damage, data.radius, "ink")
	if int(data.get_meta("star_level", 1)) >= 3:
		_start_ink_field()
	else:
		_fade_and_free(strokes)

func _start_ink_field() -> void:
	var elapsed := 0.0
	while elapsed < data.duration:
		_damage_area(data.damage * maxf(0.0, data.secondary_damage_mult), maxf(8.0, data.secondary_radius), "ink")
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Node2D and enemy.has_method("apply_slow") and (enemy as Node2D).global_position.distance_to(center) <= data.secondary_radius:
				enemy.call("apply_slow", data.slow_percent, maxf(0.08, data.tick_interval + 0.03), self)
		await get_tree().create_timer(maxf(0.08, data.tick_interval)).timeout
		elapsed += maxf(0.08, data.tick_interval)
	queue_free()

func _damage_area(base_damage: float, radius: float, kind: String) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.has_method("take_damage") and (enemy as Node2D).global_position.distance_to(center) <= radius:
			var body := enemy as Node2D
			var hit_damage := _get_damage(base_damage)
			var pre := _pre_hit_hp_ratio(body)
			HitFeedbackManager.deal_damage(body, hit_damage, player, data, self, {"hit_origin": center, "effect_origin": center})
			_notify()
			_apply_attr(body, hit_damage, body.global_position, pre)
	HitEffectManager.spawn_hit(get_tree(), center, kind, Vector2.RIGHT, radius)

func _best_center() -> Vector2:
	var select_range := _select_range()
	var best := player.global_position + aim_direction * minf(select_range, data.radius * 1.35)
	var best_count := -1
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D:
			continue
		var c := (candidate as Node2D).global_position
		var player_distance := player.global_position.distance_to(c)
		if player_distance > select_range:
			continue
		var count := 0
		for other in get_tree().get_nodes_in_group("enemies"):
			if other is Node2D and c.distance_to((other as Node2D).global_position) <= data.radius:
				count += 1
		if count > best_count or (count == best_count and player_distance < best_distance):
			best_count = count
			best_distance = player_distance
			best = c
	return best

func _select_range() -> float:
	return maxf(data.radius, data.length if data.length > 0.0 else data.radius * 3.0)

func _spawn_brush() -> void:
	var brush := Line2D.new()
	brush.width = 5.0
	brush.default_color = Color(0.02, 0.018, 0.015, 0.75)
	brush.points = PackedVector2Array([Vector2(-18, -28), Vector2(18, -12)])
	add_child(brush)
	var tween := get_tree().create_tween()
	tween.tween_property(brush, "modulate:a", 0.0, maxf(0.2, data.delayed_strike_interval * 3.0))
	tween.tween_callback(brush.queue_free)

func _make_stroke(index: int) -> Line2D:
	var line := Line2D.new()
	line.width = maxf(5.0, data.width * 0.12)
	line.default_color = Color(0.0, 0.0, 0.0, 0.72)
	match index:
		0:
			line.points = PackedVector2Array([Vector2(-data.radius * 0.65, -data.radius * 0.1), Vector2(data.radius * 0.45, -data.radius * 0.35)])
		1:
			line.points = PackedVector2Array([Vector2(-data.radius * 0.2, -data.radius * 0.65), Vector2(data.radius * 0.15, data.radius * 0.5)])
		_:
			line.points = PackedVector2Array([Vector2(-data.radius * 0.5, data.radius * 0.28), Vector2(-data.radius * 0.1, data.radius * 0.6), Vector2(data.radius * 0.55, data.radius * 0.18)])
	return line

func _fade_and_free(strokes: Array[Line2D]) -> void:
	var tween := get_tree().create_tween()
	for stroke in strokes:
		tween.parallel().tween_property(stroke, "scale", Vector2(1.25, 1.25), maxf(0.08, data.duration))
		tween.parallel().tween_property(stroke, "modulate:a", 0.0, maxf(0.08, data.duration))
	tween.tween_callback(queue_free)

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
