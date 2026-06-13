extends Node2D
class_name SoulBannerAttackNode

var player: Node2D
var data: ArtifactData
var targets: Array = []
var time_left: float = 0.0
var tick_remaining: float = 0.0
var lines_root: Node2D

func setup(owner_player: Node2D, artifact_data: ArtifactData, primary_target: Node2D) -> void:
	player = owner_player
	data = artifact_data
	global_position = player.global_position
	time_left = maxf(0.2, data.duration)
	lines_root = Node2D.new()
	add_child(lines_root)
	_collect_targets(primary_target)
	_spawn_banner_visual()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	time_left -= delta
	tick_remaining -= delta
	_redraw_links()
	if tick_remaining <= 0.0:
		tick_remaining = maxf(0.05, data.tick_interval)
		_tick_damage()
	if time_left <= 0.0 or targets.is_empty():
		queue_free()

func _collect_targets(primary_target: Node2D) -> void:
	var candidates: Array[Dictionary] = []
	var radius_squared: float = data.range * data.range
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		if enemy.is_queued_for_deletion() or bool(enemy.get("dying")):
			continue
		var distance_squared: float = player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= radius_squared:
			candidates.append({"enemy": enemy, "distance_squared": distance_squared})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance_squared"]) < float(b["distance_squared"])
	)
	if _target_valid(primary_target) and primary_target in get_tree().get_nodes_in_group("enemies"):
		targets.append(primary_target)
	var target_count: int = data.max_targets if data.max_targets > 0 else candidates.size()
	for item in candidates:
		var enemy := item["enemy"] as Node2D
		if not _target_valid(enemy) or enemy in targets:
			continue
		targets.append(enemy)
		if targets.size() >= target_count:
			break

func _tick_damage() -> void:
	for index in range(targets.size() - 1, -1, -1):
		var enemy: Variant = targets[index]
		if not _target_valid(enemy):
			targets.remove_at(index)
			continue
		var enemy_node := enemy as Node2D
		if data.slow_percent > 0.0 and enemy_node.has_method("apply_slow"):
			enemy_node.call("apply_slow", data.slow_percent, maxf(data.tick_interval * 1.5, 0.3), self)
		if data.damage_reduction_percent > 0.0 and enemy_node.has_method("apply_damage_reduction"):
			enemy_node.call("apply_damage_reduction", data.damage_reduction_percent, maxf(data.tick_interval * 1.5, 0.3), self)
		var hit_damage: float = _get_damage()
		var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(enemy_node)
		var killed: bool = bool(enemy_node.call("take_damage", hit_damage, player))
		_notify_artifact_damage()
		_apply_attribute_on_hit(enemy_node, hit_damage, enemy_node.global_position, pre_hit_hp_ratio)
		HitEffectManager.spawn_hit(get_tree(), enemy_node.global_position, "blood", player.global_position.direction_to(enemy_node.global_position), 14.0)
		if killed:
			var origin: Vector2 = enemy_node.global_position
			targets.remove_at(index)
			_spawn_soul(origin)

func _spawn_soul(origin: Vector2) -> void:
	var target := _nearest_enemy(origin)
	if target == null:
		HitEffectManager.spawn_hit(get_tree(), origin, "blood", Vector2.UP, data.explosion_radius)
		return
	var soul := Area2D.new()
	soul.collision_layer = 0
	soul.collision_mask = 2
	soul.monitoring = true
	soul.global_position = origin
	get_tree().current_scene.add_child(soul)
	var shape := CircleShape2D.new()
	shape.radius = maxf(8.0, data.width * 0.45)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	soul.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = _circle_points(maxf(8.0, data.width * 0.55), 18)
	visual.color = Color(0.68, 1.0, 0.82, 0.75)
	soul.add_child(visual)
	var exploded := {"done": false}
	soul.body_entered.connect(func(body: Node) -> void:
		if bool(exploded["done"]) or not body.has_method("take_damage"):
			return
		exploded["done"] = true
		_explode_soul(soul.global_position)
		soul.queue_free()
	)
	var tween := get_tree().create_tween()
	tween.tween_property(soul, "global_position", target.global_position, maxf(0.12, origin.distance_to(target.global_position) / maxf(1.0, data.counter_speed)))
	tween.tween_callback(func() -> void:
		if is_instance_valid(soul) and not bool(exploded["done"]):
			exploded["done"] = true
			_explode_soul(soul.global_position)
			soul.queue_free()
	)

func _explode_soul(origin: Vector2) -> void:
	var radius: float = maxf(24.0, data.explosion_radius)
	var soul_damage: float = maxf(1.0, data.damage * 2.0)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if _target_valid(candidate):
			if origin.distance_to((candidate as Node2D).global_position) <= radius:
				var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(candidate)
				candidate.call("take_damage", soul_damage, player)
				_notify_artifact_damage()
				_apply_attribute_on_hit(candidate, soul_damage, (candidate as Node2D).global_position, pre_hit_hp_ratio)
	HitEffectManager.spawn_hit(get_tree(), origin, "poison", Vector2.UP, radius)

func _nearest_enemy(origin: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_distance: float = INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		if bool(candidate.get("dying")):
			continue
		var distance: float = origin.distance_to((candidate as Node2D).global_position)
		if distance < nearest_distance:
			nearest = candidate as Node2D
			nearest_distance = distance
	return nearest

func _redraw_links() -> void:
	for child in lines_root.get_children():
		child.queue_free()
	for enemy in targets:
		if not _target_valid(enemy):
			continue
		enemy = enemy as Node2D
		var line := Line2D.new()
		line.width = maxf(3.0, data.width * 0.12)
		line.default_color = Color(0.55, 1.0, 0.65, 0.42)
		line.points = PackedVector2Array([Vector2.ZERO, enemy.global_position - player.global_position])
		lines_root.add_child(line)

func _spawn_banner_visual() -> void:
	var pole := Line2D.new()
	pole.width = 4.0
	pole.default_color = Color(0.28, 0.18, 0.1, 0.9)
	pole.points = PackedVector2Array([Vector2(0, 16), Vector2(0, -42)])
	add_child(pole)
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([Vector2(0, -40), Vector2(34, -30), Vector2(20, 4), Vector2(0, -6)])
	cloth.color = Color(0.22, 0.95, 0.42, 0.35)
	add_child(cloth)

func _target_valid(enemy: Variant) -> bool:
	return enemy is Node2D and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("take_damage") and not bool(enemy.get("dying"))

func _get_damage() -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, data.damage))
	return data.damage

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

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
