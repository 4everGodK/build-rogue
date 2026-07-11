extends Node2D
class_name BodyMeleeAttackNode

var player: Node2D
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT
var base_damage: float = 0.0
var star_level: int = 1
var attack_instance_id: String = ""

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	direction = attack_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	base_damage = data.damage
	star_level = int(data.get_meta("star_level", 1))
	global_position = player.global_position
	rotation = direction.angle()
	match data.id:
		"fist":
			_run_fist()
		"palm":
			_run_palm()
		"kick":
			_run_kick()
		"roar":
			_run_roar()
		_:
			queue_free()

func _run_fist() -> void:
	var combo_every: int = max(1, int(data.delayed_strike_count))
	var attack_count: int = int(data.get_meta("attack_count", 0))
	var is_combo: bool = star_level >= 3 and attack_count % combo_every == 0
	if is_combo:
		var interval: float = maxf(0.045, data.delayed_strike_interval)
		_schedule_pulse(0.0, "fist", base_damage * maxf(0.15, data.side_projectile_damage_mult), data.length, data.width, data.knockback_force * 0.7, false)
		_schedule_pulse(interval, "fist", base_damage * maxf(0.15, data.side_projectile_damage_mult), data.length, data.width, data.knockback_force * 0.7, false)
		_schedule_pulse(interval * 2.0, "fist_big", base_damage * maxf(1.0, data.secondary_damage_mult), data.length * 1.08, maxf(data.width * 1.35, data.secondary_radius), data.knockback_force * 1.15, true)
		_finish_after(interval * 2.0 + 0.22)
	else:
		_schedule_pulse(0.0, "fist", base_damage, data.length, data.width, data.knockback_force, false)
		_finish_after(maxf(0.12, data.duration + 0.08))

func _run_palm() -> void:
	_schedule_pulse(maxf(0.0, data.windup_time), "palm", base_damage, data.length, data.width, data.knockback_force, false)
	if star_level >= 3:
		var delay: float = maxf(0.05, data.windup_time + data.secondary_delay)
		_schedule_pulse(delay, "palm_after", base_damage * maxf(0.0, data.secondary_damage_mult), data.length * 0.95, data.width * 0.9, data.knockback_force * maxf(0.15, data.side_projectile_damage_mult), false)
		_finish_after(delay + 0.26)
	else:
		_finish_after(maxf(0.18, data.windup_time + data.duration + 0.12))

func _run_kick() -> void:
	_schedule_pulse(0.0, "kick", base_damage, data.radius, data.radius, data.knockback_force, false)
	if star_level >= 3:
		var delay: float = maxf(0.05, data.secondary_delay)
		_schedule_pulse(delay, "kick_back", base_damage * maxf(0.0, data.secondary_damage_mult), data.radius * maxf(1.0, data.secondary_radius), data.radius, data.knockback_force, false)
		_finish_after(delay + 0.26)
	else:
		_finish_after(maxf(0.18, data.duration + 0.1))

func _run_roar() -> void:
	_schedule_pulse(maxf(0.0, data.windup_time), "roar", base_damage, data.length, data.width, data.knockback_force, false)
	if star_level >= 3:
		var delay: float = maxf(0.05, data.windup_time + data.secondary_delay)
		_schedule_pulse(delay, "roar_ring", base_damage * maxf(0.0, data.secondary_damage_mult), maxf(data.secondary_radius, data.radius), data.width, data.knockback_force * 0.65, false)
		_finish_after(delay + 0.28)
	else:
		_finish_after(maxf(0.22, data.windup_time + data.duration + 0.16))

func _schedule_pulse(delay: float, kind: String, pulse_damage: float, primary: float, secondary: float, knockback: float, shockwave: bool) -> void:
	if delay <= 0.0:
		_execute_pulse(kind, pulse_damage, primary, secondary, knockback, shockwave)
		return
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if is_instance_valid(self):
			_execute_pulse(kind, pulse_damage, primary, secondary, knockback, shockwave)
	)

func _execute_pulse(kind: String, pulse_damage: float, primary: float, secondary: float, knockback: float, shockwave: bool) -> void:
	if not is_instance_valid(player):
		return
	global_position = player.global_position
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	rotation = direction.angle()
	match kind:
		"fist", "fist_big":
			_spawn_fist_visual(kind == "fist_big", int(data.get_meta("attack_count", 0)) % 2 == 0)
			_damage_forward_box(primary, secondary, pulse_damage, knockback, "fire")
			if shockwave:
				_damage_radius(global_position + direction * primary, maxf(secondary, data.secondary_radius), pulse_damage * 0.45, knockback * 0.8, "earth")
		"palm", "palm_after":
			_spawn_palm_visual(kind == "palm_after", primary, secondary)
			_damage_cone(primary, secondary, pulse_damage, knockback, "earth")
		"kick", "kick_back":
			_spawn_kick_visual(kind == "kick_back", primary)
			_damage_radius(global_position, primary, pulse_damage, knockback, "earth")
		"roar":
			_spawn_roar_visual(primary, secondary, false)
			_damage_cone(primary, secondary, pulse_damage, knockback, "sound")
		"roar_ring":
			_spawn_roar_visual(primary, secondary, true)
			_damage_radius(global_position, primary, pulse_damage, knockback, "sound")

func _damage_forward_box(length: float, width: float, pulse_damage: float, knockback: float, hit_kind: String) -> void:
	var hits: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(candidate) or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		var local: Vector2 = enemy.global_position - global_position
		var forward: float = local.dot(direction)
		var side: float = absf(local.cross(direction))
		if forward >= -4.0 and forward <= length and side <= width * 0.5:
			hits[candidate] = true
			_apply_hit(enemy, pulse_damage, knockback, hit_kind, global_position)

func _damage_cone(length: float, width: float, pulse_damage: float, knockback: float, hit_kind: String) -> void:
	var hits: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(candidate) or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		var local: Vector2 = enemy.global_position - global_position
		var forward: float = local.dot(direction)
		if forward < -6.0 or forward > length:
			continue
		var t: float = clampf(forward / maxf(1.0, length), 0.0, 1.0)
		var allowed_side: float = lerpf(width * 0.16, width * 0.5, t)
		if absf(local.cross(direction)) <= allowed_side:
			hits[candidate] = true
			_apply_hit(enemy, pulse_damage, knockback, hit_kind, global_position)

func _damage_radius(center: Vector2, radius: float, pulse_damage: float, knockback: float, hit_kind: String) -> void:
	var hits: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _is_valid_enemy(candidate) or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		if center.distance_to(enemy.global_position) <= radius:
			hits[candidate] = true
			_apply_hit(enemy, pulse_damage, knockback, hit_kind, center)

func _apply_hit(enemy: Node2D, pulse_damage: float, knockback: float, hit_kind: String, knockback_origin: Vector2) -> void:
	var hit_damage: float = _get_damage(pulse_damage)
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
	if data.slow_percent > 0.0 and enemy.has_method("apply_slow"):
		enemy.call("apply_slow", data.slow_percent, maxf(0.2, data.debuff_duration), self)

func _spawn_fist_visual(big: bool, left: bool) -> void:
	var root := _world_visual()
	root.global_position = global_position + direction.rotated(-PI * 0.5 if left else PI * 0.5) * (10.0 if not big else 14.0)
	root.rotation = direction.angle()
	var fist := Polygon2D.new()
	var length: float = data.length * (0.52 if not big else 0.72)
	var width: float = data.width * (0.8 if not big else 1.2)
	fist.color = Color(1.0, 0.32, 0.16, 0.72)
	fist.polygon = PackedVector2Array([Vector2(0, -width * 0.35), Vector2(length, -width * 0.45), Vector2(length + width * 0.35, 0), Vector2(length, width * 0.45), Vector2(0, width * 0.35)])
	root.add_child(fist)
	_tween_visual(root, direction * data.length * 0.32, 0.12)

func _spawn_palm_visual(afterwind: bool, length: float, width: float) -> void:
	var root := _world_visual()
	root.global_position = global_position
	root.rotation = direction.angle()
	var palm := Polygon2D.new()
	palm.color = Color(0.96, 0.78, 0.36, 0.28 if afterwind else 0.46)
	palm.polygon = PackedVector2Array([Vector2(0, -width * 0.08), Vector2(length, -width * 0.5), Vector2(length * 1.06, 0), Vector2(length, width * 0.5), Vector2(0, width * 0.08)])
	root.add_child(palm)
	for i in 3:
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = Color(1.0, 0.92, 0.62, 0.35 if not afterwind else 0.18)
		var y: float = lerpf(-width * 0.28, width * 0.28, float(i) / 2.0)
		line.points = PackedVector2Array([Vector2(length * 0.15, y * 0.35), Vector2(length * 0.9, y)])
		root.add_child(line)
	_tween_visual(root, direction * length * 0.22, 0.18)

func _spawn_kick_visual(reverse: bool, radius: float) -> void:
	var root := _world_visual()
	root.global_position = global_position
	var ring := Line2D.new()
	ring.width = maxf(7.0, data.width * 0.32)
	ring.default_color = Color(0.88, 0.72, 0.36, 0.55 if not reverse else 0.38)
	ring.points = _arc_points(radius, -PI * 0.8, PI * 1.1, 36)
	root.add_child(ring)
	root.rotation = PI if reverse else 0.0
	_tween_spin(root, -TAU if reverse else TAU, 0.18)

func _spawn_roar_visual(length: float, width: float, ring_mode: bool) -> void:
	var root := _world_visual()
	root.global_position = global_position
	root.rotation = 0.0 if ring_mode else direction.angle()
	for i in 4:
		var line := Line2D.new()
		line.width = 4.0
		line.default_color = Color(0.58, 0.82, 1.0, 0.32 - float(i) * 0.045)
		var r: float = length * (0.25 + float(i) * 0.21)
		line.points = _circle_points(r, 48) if ring_mode else _arc_points(r, -width / maxf(1.0, length) * 0.55, width / maxf(1.0, length) * 0.55, 24)
		if ring_mode:
			line.closed = true
		root.add_child(line)
	_tween_visual(root, Vector2.ZERO, 0.24)

func _world_visual() -> Node2D:
	var root := Node2D.new()
	root.z_as_relative = false
	root.z_index = 5
	get_tree().current_scene.add_child(root)
	return root

func _tween_visual(root: Node2D, offset: Vector2, time: float) -> void:
	root.modulate.a = 0.0
	var origin: Vector2 = root.global_position
	var tween := get_tree().create_tween()
	tween.tween_property(root, "modulate:a", 1.0, time * 0.25)
	tween.parallel().tween_property(root, "global_position", origin + offset, time)
	tween.tween_property(root, "modulate:a", 0.0, time * 0.45)
	tween.tween_callback(root.queue_free)

func _tween_spin(root: Node2D, angle: float, time: float) -> void:
	root.modulate.a = 0.0
	var tween := get_tree().create_tween()
	tween.tween_property(root, "modulate:a", 1.0, time * 0.2)
	tween.parallel().tween_property(root, "rotation", root.rotation + angle, time)
	tween.tween_property(root, "modulate:a", 0.0, time * 0.35)
	tween.tween_callback(root.queue_free)

func _arc_points(radius: float, start_angle: float, end_angle: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in segments + 1:
		var t: float = float(index) / float(segments)
		var angle: float = lerpf(start_angle, end_angle, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _circle_points(radius: float, segments: int = 48) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in segments:
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points

func _is_valid_enemy(candidate: Variant) -> bool:
	return is_instance_valid(candidate) and candidate is Node2D and not candidate.is_queued_for_deletion() and candidate.has_method("take_damage") and not bool(candidate.get("dying"))

func _get_damage(raw_damage: float) -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, raw_damage))
	return raw_damage

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attribute_on_hit(target: Node, hit_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, target, hit_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(target: Node) -> float:
	if target != null and target.has_method("get_hp_ratio"):
		return float(target.call("get_hp_ratio"))
	return -1.0

func _finish_after(delay: float) -> void:
	get_tree().create_timer(maxf(0.08, delay)).timeout.connect(func() -> void:
		if is_instance_valid(self):
			queue_free()
	)
