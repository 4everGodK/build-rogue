extends Node2D
class_name BloodSwordAttackNode

var player: Node2D
var data: ArtifactData
var direction := Vector2.RIGHT
var hit_enemies: Dictionary = {}

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized() if attack_direction.length_squared() > 0.001 else Vector2.RIGHT
	global_position = player.global_position
	_run()

func _run() -> void:
	_spawn_life_draw(player.global_position, player.global_position + direction.orthogonal() * 24.0)
	var blade := _make_blade()
	blade.global_position = player.global_position + direction.orthogonal() * 18.0
	blade.rotation = direction.angle()
	get_tree().current_scene.add_child(blade)
	var gather := get_tree().create_tween()
	blade.scale = Vector2(0.2, 0.2)
	gather.tween_property(blade, "scale", Vector2.ONE, maxf(0.04, data.windup_time))
	await gather.finished
	_spawn_slash_visual()
	_damage_swing()
	var fade := get_tree().create_tween()
	fade.tween_property(blade, "modulate:a", 0.0, maxf(0.08, data.duration))
	fade.tween_callback(blade.queue_free)
	queue_free()

func _damage_swing() -> void:
	var half_width: float = maxf(18.0, data.width * 0.5)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		var offset: Vector2 = enemy.global_position - player.global_position
		var forward: float = offset.dot(direction)
		var lateral: float = abs(offset.cross(direction))
		if forward < 0.0 or forward > data.length or lateral > half_width * (0.35 + 0.65 * forward / maxf(1.0, data.length)):
			continue
		if hit_enemies.has(enemy):
			continue
		hit_enemies[enemy] = true
		var hit_damage: float = _get_damage(data.damage)
		var pre: float = _pre_hit_hp_ratio(enemy)
		var killed: bool = HitFeedbackManager.deal_damage(enemy, hit_damage, player, data, self, {"hit_origin": player.global_position})
		_notify()
		_apply_attr(enemy, hit_damage, enemy.global_position, pre)
		_apply_kill_heal(killed, enemy.global_position)
		_spawn_blood_scar(enemy.global_position, direction)
		if int(data.get_meta("star_level", 1)) >= 3:
			_spawn_delayed_scar_burst(enemy.global_position)

func _spawn_delayed_scar_burst(center: Vector2) -> void:
	get_tree().create_timer(maxf(0.04, data.secondary_delay)).timeout.connect(func() -> void:
		var radius: float = maxf(8.0, data.secondary_radius)
		var blast_damage: float = _get_damage(data.damage * maxf(0.0, data.secondary_damage_mult))
		for candidate in get_tree().get_nodes_in_group("enemies"):
			if candidate is Node2D and candidate.has_method("take_damage") and center.distance_to((candidate as Node2D).global_position) <= radius:
				var enemy := candidate as Node2D
				var pre: float = _pre_hit_hp_ratio(enemy)
				var killed: bool = HitFeedbackManager.deal_damage(enemy, blast_damage, player, data, self, {
					"profile": "explosion",
					"hit_origin": center,
					"effect_origin": center,
				})
				_notify()
				_apply_attr(enemy, blast_damage, enemy.global_position, pre)
				_apply_kill_heal(killed, enemy.global_position)
	)

func _make_blade() -> Node2D:
	var root := Node2D.new()
	var blade := Polygon2D.new()
	blade.polygon = PackedVector2Array([Vector2(data.length * 0.28, 0), Vector2(-18, -8), Vector2(-8, 0), Vector2(-18, 8)])
	blade.color = Color(0.75, 0.0, 0.06, 0.82)
	root.add_child(blade)
	var edge := Line2D.new()
	edge.width = 2.0
	edge.default_color = Color(1.0, 0.08, 0.12, 0.88)
	edge.closed = true
	edge.points = blade.polygon
	root.add_child(edge)
	return root

func _spawn_slash_visual() -> void:
	var slash := Line2D.new()
	slash.width = maxf(10.0, data.width * 0.22)
	slash.default_color = Color(1.0, 0.02, 0.08, 0.6)
	slash.points = PackedVector2Array([Vector2(12, data.width * 0.45), Vector2(data.length * 0.45, 0), Vector2(data.length, -data.width * 0.42)])
	slash.global_position = player.global_position
	slash.rotation = direction.angle()
	get_tree().current_scene.add_child(slash)
	var tween := get_tree().create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, maxf(0.1, data.duration))
	tween.tween_callback(slash.queue_free)

func _spawn_blood_scar(center: Vector2, scar_direction: Vector2) -> void:
	var scar := Line2D.new()
	scar.width = 4.0
	scar.default_color = Color(0.9, 0.0, 0.05, 0.74)
	scar.points = PackedVector2Array([Vector2(-12, 0), Vector2(12, 0)])
	scar.global_position = center
	scar.rotation = scar_direction.angle() + randf_range(-0.35, 0.35)
	get_tree().current_scene.add_child(scar)
	var tween := get_tree().create_tween()
	tween.tween_property(scar, "modulate:a", 0.0, maxf(0.14, data.hit_flash_duration))
	tween.tween_callback(scar.queue_free)

func _spawn_life_draw(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.9, 0.0, 0.06, 0.6)
	line.points = PackedVector2Array([from, to])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)

func _apply_kill_heal(killed: bool, from_position: Vector2) -> void:
	if not killed or data.kill_heal_amount <= 0.0 or player == null or not player.has_method("heal"):
		return
	player.call("heal", data.kill_heal_amount, data)
	_spawn_life_return(from_position)

func _spawn_life_return(from_position: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(1.0, 0.08, 0.12, 0.72)
	line.points = PackedVector2Array([from_position, player.global_position])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
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
