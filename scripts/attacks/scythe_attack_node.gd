extends Node2D
class_name ScytheAttackNode

var player: Node2D
var data: ArtifactData
var direction := Vector2.RIGHT
var heal_this_attack := 0.0

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized() if attack_direction.length_squared() > 0.001 else Vector2.RIGHT
	global_position = player.global_position
	_run()

func _run() -> void:
	await _sweep(direction, data.damage, 1.0)
	if int(data.get_meta("star_level", 1)) >= 3 and data.secondary_damage_mult > 0.0:
		await get_tree().create_timer(maxf(0.03, data.secondary_delay)).timeout
		await _sweep(-direction, data.damage * data.secondary_damage_mult, -1.0)
	queue_free()

func _sweep(base_direction: Vector2, base_damage: float, sweep_sign: float) -> void:
	heal_this_attack = 0.0
	var visual := _make_scythe_visual()
	visual.global_position = player.global_position
	visual.rotation = base_direction.angle() - sweep_sign * deg_to_rad(maxf(45.0, data.fan_angle) * 0.5)
	get_tree().current_scene.add_child(visual)
	var tween := get_tree().create_tween()
	tween.tween_property(visual, "rotation", base_direction.angle() + sweep_sign * deg_to_rad(maxf(45.0, data.fan_angle) * 0.5), maxf(0.08, data.duration))
	tween.parallel().tween_property(visual, "modulate:a", 0.0, maxf(0.08, data.duration)).set_delay(maxf(0.02, data.duration * 0.55))
	_damage_sweep(base_direction, base_damage)
	await tween.finished
	visual.queue_free()

func _damage_sweep(base_direction: Vector2, base_damage: float) -> void:
	var outer_radius: float = maxf(20.0, data.length)
	var inner_radius: float = maxf(0.0, outer_radius - maxf(10.0, data.width))
	var arc: float = deg_to_rad(maxf(45.0, data.fan_angle))
	var hits: Dictionary = {}
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage") or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		var offset: Vector2 = enemy.global_position - player.global_position
		var distance: float = offset.length()
		if distance < inner_radius or distance > outer_radius + 12.0:
			continue
		var angle: float = abs(base_direction.angle_to(offset.normalized()))
		if angle > arc * 0.5:
			continue
		hits[enemy] = true
		var hit_damage: float = _get_damage(base_damage)
		var pre: float = _pre_hit_hp_ratio(enemy)
		var killed: bool = HitFeedbackManager.deal_damage(enemy, hit_damage, player, data, self, {"hit_origin": player.global_position})
		_notify()
		_apply_attr(enemy, hit_damage, enemy.global_position, pre)
		_heal_from_damage(hit_damage, enemy.global_position)
		if killed and data.kill_heal_amount > 0.0 and player.has_method("heal"):
			player.call("heal", data.kill_heal_amount, data)

func _heal_from_damage(dealt_damage: float, from_position: Vector2) -> void:
	if data.heal_amount <= 0.0 or player == null or not player.has_method("heal"):
		return
	var cap: float = maxf(1.0, data.shield_max if data.shield_max > 0.0 else float(player.get("max_hp")) * 0.25)
	var heal_value: float = minf(dealt_damage * data.heal_amount, maxf(0.0, cap - heal_this_attack))
	if heal_value <= 0.0:
		return
	heal_this_attack += heal_value
	player.call("heal", heal_value, data)
	_spawn_life_thread(from_position)

func _make_scythe_visual() -> Node2D:
	var root := Node2D.new()
	var handle := Line2D.new()
	handle.width = 5.0
	handle.default_color = Color(0.32, 0.18, 0.2, 0.78)
	handle.points = PackedVector2Array([Vector2(18, 0), Vector2(data.length * 0.82, 0)])
	root.add_child(handle)
	var blade := Line2D.new()
	blade.width = maxf(8.0, data.width * 0.22)
	blade.default_color = Color(0.82, 0.96, 1.0, 0.72)
	blade.points = PackedVector2Array([
		Vector2(data.length * 0.64, data.width * 0.45),
		Vector2(data.length * 0.88, 0.0),
		Vector2(data.length * 0.66, -data.width * 0.46),
	])
	root.add_child(blade)
	var arc := Line2D.new()
	arc.width = maxf(10.0, data.width * 0.2)
	arc.default_color = Color(0.75, 0.98, 1.0, 0.34)
	var points := PackedVector2Array()
	var sweep_arc: float = deg_to_rad(maxf(45.0, data.fan_angle))
	for index in 18:
		var t: float = -sweep_arc * 0.5 + sweep_arc * float(index) / 17.0
		points.append(Vector2(cos(t), sin(t)) * data.length)
	arc.points = points
	root.add_child(arc)
	return root

func _spawn_life_thread(from_position: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.92, 0.0, 0.08, 0.62)
	line.points = PackedVector2Array([from_position, player.global_position])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.22)
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
