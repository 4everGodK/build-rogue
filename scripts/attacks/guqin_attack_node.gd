extends Node2D
class_name GuqinAttackNode

var player: Node2D
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	global_position = player.global_position
	_run()

func _run() -> void:
	_spawn_guqin()
	for layer in 3:
		var is_ring := layer == 2 and int(data.get_meta("star_level", 1)) >= 3
		_emit_wave(layer, is_ring)
		await get_tree().create_timer(maxf(0.04, data.delayed_strike_interval)).timeout
	await get_tree().create_timer(maxf(0.12, data.duration)).timeout
	queue_free()

func _emit_wave(layer: int, is_ring: bool) -> void:
	var wave_range := data.range * (0.55 + 0.18 * float(layer))
	var wave_width := data.width * (2.0 + float(layer))
	var hits := {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and enemy.has_method("take_damage"):
			var body := enemy as Node2D
			var offset: Vector2 = body.global_position - global_position
			var in_wave: bool = offset.length() <= wave_range
			if not is_ring:
				var angle: float = abs(direction.angle_to(offset.normalized())) if offset.length() > 0.01 else 0.0
				in_wave = in_wave and angle <= deg_to_rad(data.fan_angle if data.fan_angle > 0.0 else 70.0)
			if not in_wave or hits.has(body):
				continue
			hits[body] = true
			var hit_damage: float = _get_damage(data.damage * (0.55 if layer > 0 else 0.75))
			var pre: float = _pre_hit_hp_ratio(body)
			body.call("take_damage", hit_damage, player)
			_notify()
			_apply_attr(body, hit_damage, body.global_position, pre)
			if data.damage_reduction_percent > 0.0 and body.has_method("apply_damage_reduction"):
				body.call("apply_damage_reduction", data.damage_reduction_percent, maxf(0.2, data.debuff_duration), self)
			HitEffectManager.spawn_hit(get_tree(), body.global_position, "sound", direction, 12.0)
	_spawn_wave_visual(wave_range, wave_width, layer, is_ring)

func _spawn_guqin() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-28, -8), Vector2(28, -7), Vector2(34, 0), Vector2(28, 7), Vector2(-28, 8), Vector2(-34, 0)])
	body.color = Color(0.35, 0.22, 0.12, 0.55)
	body.position = -direction * 18.0 + Vector2(0, -26)
	body.rotation = direction.angle()
	add_child(body)
	for i in 4:
		var string := Line2D.new()
		string.width = 1.4
		string.default_color = Color(0.75, 1.0, 0.92, 0.65)
		string.points = PackedVector2Array([Vector2(-22, -5 + i * 3.3), Vector2(22, -5 + i * 3.3)])
		body.add_child(string)
	var tween := get_tree().create_tween()
	tween.tween_property(body, "modulate:a", 0.0, maxf(0.4, data.duration + data.delayed_strike_interval * 3.0))

func _spawn_wave_visual(wave_range: float, wave_width: float, layer: int, is_ring: bool) -> void:
	var line := Line2D.new()
	line.width = maxf(3.0, wave_width * 0.18)
	line.default_color = Color(0.62, 1.0, 0.86, 0.46 - 0.08 * layer)
	if is_ring:
		line.closed = true
		line.points = _circle_points(wave_range, 64)
		line.global_position = global_position
	else:
		var points := PackedVector2Array()
		var arc := deg_to_rad(data.fan_angle if data.fan_angle > 0.0 else 70.0)
		for i in 18:
			var a := -arc * 0.5 + arc * float(i) / 17.0
			points.append(direction.rotated(a) * wave_range)
		line.points = points
		line.global_position = global_position
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "scale", Vector2(1.08, 1.08), maxf(0.08, data.duration))
	tween.parallel().tween_property(line, "modulate:a", 0.0, maxf(0.08, data.duration))
	tween.tween_callback(line.queue_free)

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
