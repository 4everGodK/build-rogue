extends Node2D
class_name SoulBannerAttackNode

var player: Node2D
var data: ArtifactData
var targets: Array = []
var time_left: float = 0.0
var tick_remaining: float = 0.0
var lines_root: Node2D
var banner_visual: Node2D
var marked_enemies: Dictionary = {}
var spawned_from_enemy: Dictionary = {}
var active_souls: Array = []
var souls_since_wave: int = 0

func setup(owner_player: Node2D, artifact_data: ArtifactData, primary_target: Node2D) -> void:
	player = owner_player
	data = artifact_data
	global_position = player.global_position + Vector2(-28.0, -18.0)
	time_left = maxf(0.2, data.duration)
	lines_root = Node2D.new()
	add_child(lines_root)
	banner_visual = _make_banner_visual()
	add_child(banner_visual)
	_collect_targets(primary_target)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position + Vector2(-28.0, -18.0)
	time_left -= delta
	tick_remaining -= delta
	_prune_souls()
	_refill_targets()
	_redraw_links()
	if is_instance_valid(banner_visual):
		banner_visual.rotation = sin(Time.get_ticks_msec() * 0.004) * 0.06
	if tick_remaining <= 0.0:
		tick_remaining = maxf(0.05, data.tick_interval)
		_tick_damage()
	if time_left <= 0.0:
		_fade_and_free()

func _collect_targets(primary_target: Node2D) -> void:
	targets.clear()
	if _target_valid(primary_target):
		targets.append(primary_target)
	_mark_target(primary_target)
	_refill_targets()

func _refill_targets() -> void:
	var target_count: int = _target_count()
	if targets.size() >= target_count:
		return
	var candidates: Array[Dictionary] = []
	var radius_squared: float = data.range * data.range
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _target_valid(candidate):
			continue
		var enemy := candidate as Node2D
		if enemy in targets:
			continue
		var distance_squared: float = player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= radius_squared:
			candidates.append({"enemy": enemy, "distance_squared": distance_squared})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["distance_squared"]) < float(b["distance_squared"])
	)
	for item in candidates:
		var stored_enemy: Variant = item.get("enemy")
		if not _target_valid(stored_enemy):
			continue
		var enemy := stored_enemy as Node2D
		targets.append(enemy)
		_mark_target(enemy)
		if targets.size() >= target_count:
			break

func _tick_damage() -> void:
	for index in range(targets.size() - 1, -1, -1):
		var stored_enemy: Variant = targets[index]
		if not _target_valid(stored_enemy):
			targets.remove_at(index)
			continue
		var enemy := stored_enemy as Node2D
		if data.slow_percent > 0.0 and enemy.has_method("apply_slow"):
			enemy.call("apply_slow", data.slow_percent, maxf(data.tick_interval * 1.5, 0.3), self)
		if data.damage_reduction_percent > 0.0 and enemy.has_method("apply_damage_reduction"):
			enemy.call("apply_damage_reduction", data.damage_reduction_percent, maxf(data.tick_interval * 1.5, 0.3), self)
		var hit_damage: float = _get_damage(data.damage)
		var pre: float = _pre_hit_hp_ratio(enemy)
		var killed: bool = HitFeedbackManager.deal_damage(enemy, hit_damage, player, data, self, {
			"is_continuous": true,
			"hit_origin": global_position,
		})
		_notify()
		_apply_attr(enemy, hit_damage, enemy.global_position, pre)
		HitEffectManager.spawn_hit(get_tree(), enemy.global_position, "blood", global_position.direction_to(enemy.global_position), 12.0)
		if killed:
			var origin: Vector2 = enemy.global_position
			targets.remove_at(index)
			_spawn_soul_from_enemy(enemy, origin)

func _mark_target(enemy: Node2D) -> void:
	if not _target_valid(enemy):
		return
	var id: int = enemy.get_instance_id()
	if marked_enemies.has(id):
		return
	marked_enemies[id] = true
	if enemy.has_signal("died"):
		enemy.died.connect(func(_gold_reward: int) -> void:
			if is_instance_valid(enemy):
				_spawn_soul_from_enemy(enemy, enemy.global_position)
		, CONNECT_ONE_SHOT)

func _spawn_soul_from_enemy(enemy: Node2D, origin: Vector2) -> void:
	if enemy == null:
		return
	var id: int = enemy.get_instance_id()
	if not marked_enemies.has(id) or spawned_from_enemy.has(id):
		return
	if _active_soul_count() >= _max_souls():
		return
	spawned_from_enemy[id] = true
	_spawn_soul(origin)

func _spawn_soul(origin: Vector2) -> void:
	var soul := Area2D.new()
	soul.collision_layer = 0
	soul.collision_mask = 2
	soul.monitoring = true
	soul.global_position = origin
	get_tree().current_scene.add_child(soul)
	active_souls.append(soul)
	var radius: float = _soul_body_radius()
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	soul.add_child(collision)
	var visual := _make_soul_visual(radius)
	soul.add_child(visual)
	var exploded := {"done": false}
	soul.body_entered.connect(func(body: Node) -> void:
		if bool(exploded["done"]) or not body.has_method("take_damage"):
			return
		exploded["done"] = true
		_explode_soul(soul.global_position)
		soul.queue_free()
	)
	var target := _nearest_enemy(origin)
	var tween := get_tree().create_tween()
	tween.tween_property(soul, "global_position", global_position, 0.12)
	if target != null:
		tween.tween_property(soul, "global_position", target.global_position, maxf(0.12, origin.distance_to(target.global_position) / maxf(1.0, data.counter_speed)))
	else:
		tween.tween_interval(maxf(0.12, data.secondary_delay))
	tween.tween_callback(func() -> void:
		if is_instance_valid(soul) and not bool(exploded["done"]):
			exploded["done"] = true
			if target != null:
				_explode_soul(soul.global_position)
			else:
				HitEffectManager.spawn_hit(get_tree(), soul.global_position, "poison", Vector2.UP, radius)
			soul.queue_free()
	)
	get_tree().create_timer(maxf(0.2, data.summon_respawn_time)).timeout.connect(func() -> void:
		if is_instance_valid(soul) and not bool(exploded["done"]):
			exploded["done"] = true
			soul.queue_free()
	)
	_count_soul_for_wave()

func _explode_soul(origin: Vector2) -> void:
	var radius: float = _soul_explosion_radius()
	var soul_damage: float = _get_damage(data.damage * maxf(0.0, data.secondary_damage_mult))
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if _target_valid(candidate) and origin.distance_to((candidate as Node2D).global_position) <= radius:
			var enemy := candidate as Node2D
			var pre: float = _pre_hit_hp_ratio(enemy)
			HitFeedbackManager.deal_damage(enemy, soul_damage, player, data, self, {
				"is_continuous": true,
				"hit_origin": global_position,
			})
			_notify()
			_apply_attr(enemy, soul_damage, enemy.global_position, pre)
	_spawn_soul_wave_visual(origin, radius, false)

func _count_soul_for_wave() -> void:
	if int(data.get_meta("star_level", 1)) < 3:
		return
	souls_since_wave += 1
	var trigger_count: int = maxi(1, data.delayed_strike_count)
	if souls_since_wave < trigger_count:
		return
	souls_since_wave -= trigger_count
	_release_soul_wave()

func _release_soul_wave() -> void:
	var radius: float = maxf(data.range, data.explosion_radius * 2.0)
	var wave_damage: float = _get_damage(data.damage * maxf(0.0, data.poison_explosion_damage_mult))
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if _target_valid(candidate) and global_position.distance_to((candidate as Node2D).global_position) <= radius:
			var enemy := candidate as Node2D
			var pre: float = _pre_hit_hp_ratio(enemy)
			HitFeedbackManager.deal_damage(enemy, wave_damage, player, data, self, {
				"is_continuous": true,
				"hit_origin": global_position,
			})
			_notify()
			_apply_attr(enemy, wave_damage, enemy.global_position, pre)
	_spawn_soul_wave_visual(global_position, radius, true)

func _nearest_enemy(origin: Vector2) -> Node2D:
	var nearest: Node2D
	var nearest_distance: float = INF
	var search_range: float = data.summon_combat_radius if data.summon_combat_radius > 0.0 else data.range
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _target_valid(candidate):
			continue
		var distance: float = origin.distance_to((candidate as Node2D).global_position)
		if distance <= search_range and distance < nearest_distance:
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
		line.width = maxf(2.0, data.width * 0.1)
		line.default_color = Color(0.35, 0.05, 0.42, 0.5)
		line.points = PackedVector2Array([Vector2.ZERO, enemy.global_position - global_position])
		lines_root.add_child(line)

func _make_banner_visual() -> Node2D:
	var root := Node2D.new()
	var pole := Line2D.new()
	pole.width = 4.0
	pole.default_color = Color(0.22, 0.12, 0.18, 0.92)
	pole.points = PackedVector2Array([Vector2(0, 20), Vector2(0, -48)])
	root.add_child(pole)
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([Vector2(0, -46), Vector2(38, -36), Vector2(24, 4), Vector2(0, -8)])
	cloth.color = Color(0.22, 0.05, 0.32, 0.62)
	root.add_child(cloth)
	return root

func _make_soul_visual(radius: float) -> Node2D:
	var root := Node2D.new()
	var body := Polygon2D.new()
	body.polygon = _circle_points(radius, 18)
	body.color = Color(0.6, 0.95, 0.8, 0.58)
	root.add_child(body)
	var tail := Line2D.new()
	tail.width = maxf(3.0, radius * 0.3)
	tail.default_color = Color(0.42, 0.95, 0.72, 0.32)
	tail.points = PackedVector2Array([Vector2(-radius * 1.6, 0), Vector2.ZERO])
	root.add_child(tail)
	return root

func _spawn_soul_wave_visual(center: Vector2, radius: float, strong: bool) -> void:
	var ring := Line2D.new()
	ring.width = 6.0 if strong else 4.0
	ring.default_color = Color(0.42, 1.0, 0.72, 0.42 if strong else 0.28)
	ring.closed = true
	ring.points = _circle_points(maxf(8.0, radius * 0.25), 48)
	ring.global_position = center
	get_tree().current_scene.add_child(ring)
	var tween := get_tree().create_tween()
	tween.tween_property(ring, "scale", Vector2.ONE * 4.0, 0.22)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ring.queue_free)

func _fade_and_free() -> void:
	set_physics_process(false)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)

func _target_count() -> int:
	if int(data.get_meta("star_level", 1)) >= 3:
		return maxi(data.max_targets, data.count)
	return data.max_targets if data.max_targets > 0 else 3

func _max_souls() -> int:
	return maxi(1, data.summon_base_count)

func _active_soul_count() -> int:
	_prune_souls()
	return active_souls.size()

func _prune_souls() -> void:
	for index in range(active_souls.size() - 1, -1, -1):
		if not is_instance_valid(active_souls[index]) or active_souls[index].is_queued_for_deletion():
			active_souls.remove_at(index)

func _soul_body_radius() -> float:
	var mult: float = maxf(1.0, data.secondary_radius) if int(data.get_meta("star_level", 1)) >= 3 else 1.0
	return maxf(8.0, data.width * 0.45) * mult

func _soul_explosion_radius() -> float:
	var mult: float = maxf(1.0, data.secondary_radius) if int(data.get_meta("star_level", 1)) >= 3 else 1.0
	return maxf(12.0, data.explosion_radius) * mult

func _target_valid(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy is Node2D and not enemy.is_queued_for_deletion() and enemy.has_method("take_damage") and not bool(enemy.get("dying"))

func _get_damage(base_damage: float) -> float:
	return float(player.call("get_artifact_damage", data, base_damage)) if player != null and player.has_method("get_artifact_damage") else base_damage

func _notify() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attr(target: Node, base_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float = -1.0) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, target, base_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(target: Node) -> float:
	return float(target.call("get_hp_ratio")) if target != null and target.has_method("get_hp_ratio") else -1.0

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
