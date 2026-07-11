extends Node2D
class_name PoisonNeedleAttackNode

var player: Node2D
var data: ArtifactData
var direction := Vector2.RIGHT

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized() if attack_direction.length_squared() > 0.001 else Vector2.RIGHT
	global_position = player.global_position
	_run()

func _run() -> void:
	_spawn_ready_needles(maxi(1, data.count), direction, 0.0)
	for index in maxi(1, data.count):
		_fire_needle(direction.rotated(_small_spread(index)), data.damage, false)
		await get_tree().create_timer(maxf(0.015, data.delayed_strike_interval)).timeout
	if _should_fire_rain():
		await get_tree().create_timer(maxf(0.04, data.secondary_delay)).timeout
		_fire_needle_rain()
	var needle_lifetime: float = data.range / maxf(1.0, data.projectile_speed)
	await get_tree().create_timer(maxf(maxf(0.2, data.duration), needle_lifetime + 0.08)).timeout
	queue_free()

func _should_fire_rain() -> bool:
	return int(data.get_meta("star_level", 1)) >= 3 and data.delayed_strike_count > 0 and int(data.get_meta("attack_count", 0)) % data.delayed_strike_count == 0

func _fire_needle_rain() -> void:
	var rain_count: int = maxi(1, data.bounce_count)
	var arc: float = deg_to_rad(maxf(1.0, data.fan_angle))
	_spawn_ready_needles(rain_count, direction, arc)
	for index in rain_count:
		var t: float = 0.0 if rain_count == 1 else float(index) / float(rain_count - 1)
		var angle: float = lerpf(-arc * 0.5, arc * 0.5, t)
		_fire_needle(direction.rotated(angle), data.damage * maxf(0.0, data.secondary_damage_mult), true)

func _fire_needle(needle_direction: Vector2, base_damage: float, small: bool) -> void:
	var needle := Node2D.new()
	needle.global_position = player.global_position + needle_direction.orthogonal() * randf_range(-8.0, 8.0)
	needle.rotation = needle_direction.angle()
	get_tree().current_scene.add_child(needle)
	var line := Line2D.new()
	line.width = 2.0 if small else 2.8
	line.default_color = Color(0.22, 1.0, 0.18, 0.86)
	line.points = PackedVector2Array([Vector2(-data.length * 0.45, 0), Vector2(data.length * 0.55, 0)])
	needle.add_child(line)
	var hit: Dictionary = {}
	_move_needle(needle, needle_direction, base_damage, hit)

func _move_needle(needle: Node2D, needle_direction: Vector2, base_damage: float, hit: Dictionary) -> void:
	var traveled: float = 0.0
	while is_instance_valid(needle) and traveled < data.range:
		var delta: float = get_process_delta_time()
		var movement: Vector2 = needle_direction * data.projectile_speed * delta
		needle.global_position += movement
		traveled += movement.length()
		_damage_needle(needle, needle_direction, base_damage, hit)
		await get_tree().process_frame
	if is_instance_valid(needle):
		needle.queue_free()

func _damage_needle(needle: Node2D, needle_direction: Vector2, base_damage: float, hit: Dictionary) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage") or hit.has(candidate):
			continue
		var enemy := candidate as Node2D
		if needle.global_position.distance_to(enemy.global_position) > maxf(6.0, data.width * 1.8):
			continue
		hit[enemy] = true
		var hit_damage: float = _get_damage(base_damage)
		var pre: float = _pre_hit_hp_ratio(enemy)
		HitFeedbackManager.deal_damage(enemy, hit_damage, player, data, self, {"hit_origin": global_position})
		_notify()
		_apply_attr(enemy, hit_damage, enemy.global_position, pre)
		if data.poison_dps > 0.0 and enemy.has_method("apply_poison"):
			enemy.call("apply_poison", data.poison_dps, maxf(0.1, data.poison_duration), data.poison_can_stack, player, 0.0, 0.0, data)
		HitEffectManager.spawn_hit(get_tree(), enemy.global_position, "poison", needle_direction, 8.0)
		_spawn_poison_mark(enemy.global_position)
		needle.queue_free()
		return

func _spawn_ready_needles(count: int, base_direction: Vector2, arc: float) -> void:
	for index in count:
		var t: float = 0.0 if count == 1 else float(index) / float(count - 1)
		var angle: float = lerpf(-arc * 0.5, arc * 0.5, t)
		var mark := Line2D.new()
		mark.width = 2.0
		mark.default_color = Color(0.22, 1.0, 0.18, 0.35)
		mark.points = PackedVector2Array([Vector2(-10, 0), Vector2(10, 0)])
		mark.global_position = player.global_position + base_direction.orthogonal() * ((float(index) - float(count - 1) * 0.5) * 7.0)
		mark.rotation = base_direction.rotated(angle).angle()
		get_tree().current_scene.add_child(mark)
		var tween := get_tree().create_tween()
		tween.tween_property(mark, "modulate:a", 0.0, 0.18)
		tween.tween_callback(mark.queue_free)

func _spawn_poison_mark(center: Vector2) -> void:
	var ring := Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(0.22, 1.0, 0.18, 0.38)
	ring.closed = true
	ring.points = _circle_points(8.0, 16)
	ring.global_position = center
	get_tree().current_scene.add_child(ring)
	var tween := get_tree().create_tween()
	tween.tween_property(ring, "scale", Vector2(1.25, 1.25), maxf(0.2, data.poison_duration * 0.35))
	tween.parallel().tween_property(ring, "modulate:a", 0.0, maxf(0.2, data.poison_duration * 0.35))
	tween.tween_callback(ring.queue_free)

func _small_spread(index: int) -> float:
	if index == 0:
		return 0.0
	var side: float = -1.0 if index % 2 == 1 else 1.0
	return side * float((index + 1) / 2) * 0.055

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
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
