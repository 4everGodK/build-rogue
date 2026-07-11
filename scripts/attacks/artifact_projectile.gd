extends Area2D
class_name ArtifactProjectile

var direction: Vector2
var speed: float
var damage: float
var max_distance: float
var traveled_distance: float = 0.0
var pierce_remaining: int
var bounce_remaining: int
var bounce_range: float
var explosion_radius: float
var debuff_duration: float
var damage_reduction_percent: float
var visual_radius: float
var source: Node
var hit_enemies: Dictionary = {}
var data: ArtifactData
var visual_node: Node2D
var trail_node: Line2D
var spin_speed: float = 0.0
var return_remaining: int = 0
var returning_to_source: bool = false
var return_hit_enemies: Dictionary = {}
var launch_position: Vector2
var charge_remaining: float = 0.0
var charge_total: float = 0.0
var attack_instance_id: String = ""

func setup(owner_player: Node2D, attack_direction: Vector2, data: ArtifactData) -> void:
	self.data = data
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	global_position = owner_player.global_position
	launch_position = owner_player.global_position
	direction = attack_direction.normalized()
	if data.id == "giant_sword_art":
		global_position -= direction * maxf(40.0, data.length * 0.45)
	speed = data.projectile_speed
	if data.id == "flying_sword":
		global_position += Vector2(0.0, -18.0).rotated(direction.angle()) + direction.orthogonal() * float(data.get_meta("flying_sword_side_index", 0)) * 12.0
		charge_remaining = maxf(0.0, data.windup_time)
	if data.id == "fire_orb":
		global_position += direction.orthogonal() * 18.0
		charge_remaining = maxf(0.0, data.windup_time)
	if data.id == "copper_coin":
		global_position += direction * 18.0
		charge_remaining = maxf(0.0, data.windup_time)
	if data.id == "giant_sword_art":
		charge_remaining = maxf(0.0, data.reveal_time + data.pause_time)
	charge_total = charge_remaining
	damage = data.damage
	max_distance = data.range
	pierce_remaining = data.projectile_pierce
	bounce_remaining = maxi(data.projectile_bounce, data.bounce_count)
	bounce_range = data.bounce_range
	explosion_radius = data.explosion_radius
	debuff_duration = data.debuff_duration
	damage_reduction_percent = data.damage_reduction_percent
	visual_radius = maxf(4.0, data.width * 0.5)
	return_remaining = data.projectile_return_count
	source = owner_player
	collision_layer = 0
	collision_mask = 2
	monitoring = charge_remaining <= 0.0
	rotation = direction.angle()

	var collision: CollisionShape2D = CollisionShape2D.new()
	if data.attack_shape == "line":
		var rectangle: RectangleShape2D = RectangleShape2D.new()
		rectangle.size = Vector2(maxf(16.0, data.length), maxf(8.0, data.width))
		collision.position.x = data.length * 0.2
		collision.shape = rectangle
	else:
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = maxf(4.0, minf(visual_radius, 14.0))
		collision.shape = shape
	add_child(collision)

	trail_node = ArtifactVisuals.make_projectile_trail(data)
	add_child(trail_node)
	visual_node = ArtifactVisuals.make_projectile_visual(data)
	add_child(visual_node)
	_prepare_charge_visual()
	spin_speed = ArtifactVisuals.projectile_spin_speed(data)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if charge_remaining > 0.0:
		charge_remaining -= delta
		if is_instance_valid(visual_node):
			_update_charge_visual()
		if charge_remaining <= 0.0:
			_activate_monitoring()
		return
	if data.id == "flying_sword" and returning_to_source and is_instance_valid(source) and source is Node2D:
		direction = global_position.direction_to((source as Node2D).global_position)
		if direction == Vector2.ZERO:
			direction = -global_transform.x
		speed = data.return_speed if data.return_speed > 0.0 else data.projectile_speed
	rotation = direction.angle()
	var movement: Vector2 = direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()
	if is_instance_valid(visual_node) and spin_speed > 0.0:
		visual_node.rotation += spin_speed * delta
	if data.id == "flying_sword" and returning_to_source and is_instance_valid(source) and source is Node2D:
		if global_position.distance_to((source as Node2D).global_position) <= 18.0:
			queue_free()
			return
	if traveled_distance >= max_distance:
		if data.id == "flying_sword" and not returning_to_source:
			_begin_flying_sword_return()
			return
		queue_free()

func _on_body_entered(body: Node) -> void:
	var phase_hits: Dictionary = return_hit_enemies if returning_to_source else hit_enemies
	if phase_hits.has(body) or not body.has_method("take_damage"):
		return
	phase_hits[body] = true
	var hit_damage: float = _get_damage(damage)
	var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(body)
	var killed: bool = HitFeedbackManager.deal_damage(body, hit_damage, source, data, self, {
		"attack_instance_id": attack_instance_id,
		"hit_origin": global_position - direction * maxf(8.0, visual_radius),
	})
	_notify_artifact_damage()
	_apply_attribute_on_hit(body, hit_damage, global_position, pre_hit_hp_ratio)
	_apply_kill_heal(killed)
	if data.poison_dps > 0.0 and body.has_method("apply_poison"):
		body.call("apply_poison", data.poison_dps, maxf(0.1, data.poison_duration), data.poison_can_stack, source, 0.0, 0.0, data)
	if damage_reduction_percent > 0.0 and body.has_method("apply_damage_reduction"):
		body.call("apply_damage_reduction", damage_reduction_percent, debuff_duration, self)
	if data.poison_explosion_damage_mult > 0.0:
		_poison_explode()
	if explosion_radius > 0.0:
		_explode(body)
		queue_free()
		return
	if bounce_remaining > 0 and _bounce_to_next_enemy():
		bounce_remaining -= 1
		return
	if data.id == "copper_coin":
		if int(data.get_meta("star_level", 1)) >= 3 and not bool(data.get_meta("split_coin", false)):
			_split_copper_coin()
		_shatter_coin()
		queue_free()
		return
	if data.id == "flying_sword":
		return
	if return_remaining > 0:
		return_remaining -= 1
		direction = -direction
		rotation = direction.angle()
		traveled_distance = 0.0
		return
	if pierce_remaining <= 0:
		queue_free()
	else:
		pierce_remaining -= 1

func _begin_flying_sword_return() -> void:
	returning_to_source = true
	traveled_distance = 0.0
	if is_instance_valid(source) and source is Node2D:
		direction = global_position.direction_to((source as Node2D).global_position)
	rotation = direction.angle()

func _activate_monitoring() -> void:
	monitoring = true
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func _prepare_charge_visual() -> void:
	if not is_instance_valid(visual_node):
		return
	if data.id == "giant_sword_art":
		visual_node.scale = Vector2(0.08, 1.0)
		visual_node.modulate.a = 0.72
	elif data.id == "fire_orb":
		visual_node.scale = Vector2(0.2, 0.2)
	elif data.id == "flying_sword":
		visual_node.scale = Vector2(0.86, 0.86)

func _update_charge_visual() -> void:
	if data.id == "giant_sword_art":
		var reveal_time: float = maxf(0.01, data.reveal_time)
		var elapsed: float = maxf(0.0, charge_total - charge_remaining)
		var reveal_t: float = clampf(elapsed / reveal_time, 0.0, 1.0)
		visual_node.scale = Vector2(lerpf(0.08, 1.0, reveal_t), 1.0)
		visual_node.modulate.a = lerpf(0.52, 1.0, reveal_t)
	elif data.id == "flying_sword":
		visual_node.scale = Vector2.ONE * (0.92 + 0.08 * sin(Time.get_ticks_msec() * 0.035))
	elif data.id == "fire_orb":
		var t: float = clampf((charge_total - charge_remaining) / maxf(0.01, charge_total), 0.0, 1.0)
		visual_node.scale = Vector2.ONE * lerpf(0.2, 1.0, t)
	elif data.id == "copper_coin":
		visual_node.rotation += 0.45

func _explode(direct_target: Node) -> void:
	HitFeedbackManager.play_area_feedback(source, data, self, global_position, attack_instance_id, "explosion")
	if data.id == "fire_orb":
		_explode_fire_orb(direct_target)
		return
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == direct_target:
			continue
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= explosion_radius:
				var killed: bool = HitFeedbackManager.deal_damage(candidate, _get_damage(damage), source, data, self, {
					"profile": "explosion",
					"attack_instance_id": attack_instance_id,
					"hit_origin": global_position,
					"effect_origin": global_position,
				})
				_notify_artifact_damage()
				_apply_kill_heal(killed)
	var blast: Polygon2D = Polygon2D.new()
	blast.polygon = _circle_points(explosion_radius)
	blast.color = Color(1.0, 0.25, 0.05, 0.25)
	blast.global_position = global_position
	get_tree().current_scene.add_child(blast)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(blast, "modulate:a", 0.0, 0.18)
	tween.tween_callback(blast.queue_free)

func _explode_fire_orb(direct_target: Node) -> void:
	if is_instance_valid(visual_node):
		var shrink := get_tree().create_tween()
		shrink.tween_property(visual_node, "scale", Vector2(0.35, 0.35), 0.045)
		await shrink.finished
	var radius: float = maxf(8.0, explosion_radius)
	_damage_explosion(radius, damage, direct_target)
	_spawn_orb_blast(radius, Color(1.0, 0.32, 0.06, 0.36))
	if int(data.get_meta("star_level", 1)) >= 3 and data.secondary_damage_mult > 0.0:
		await get_tree().create_timer(maxf(0.04, data.secondary_delay)).timeout
		var radius2: float = radius * maxf(1.0, data.secondary_radius)
		_damage_explosion(radius2, damage * data.secondary_damage_mult, null)
		_spawn_orb_blast(radius2, Color(1.0, 0.58, 0.16, 0.2))

func _damage_explosion(radius: float, base_damage: float, direct_target: Node) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == direct_target:
			continue
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= radius:
				var killed: bool = HitFeedbackManager.deal_damage(candidate, _get_damage(base_damage), source, data, self, {
					"profile": "explosion",
					"attack_instance_id": attack_instance_id,
					"hit_origin": global_position,
					"effect_origin": global_position,
				})
				_notify_artifact_damage()
				_apply_kill_heal(killed)

func _spawn_orb_blast(radius: float, color: Color) -> void:
	var blast := Line2D.new()
	blast.width = maxf(4.0, radius * 0.08)
	blast.default_color = color
	blast.closed = true
	blast.points = _circle_points(maxf(4.0, radius * 0.25))
	blast.global_position = global_position
	get_tree().current_scene.add_child(blast)
	var tween := get_tree().create_tween()
	tween.tween_property(blast, "scale", Vector2.ONE * 4.0, 0.18)
	tween.parallel().tween_property(blast, "modulate:a", 0.0, 0.18)
	tween.tween_callback(blast.queue_free)

func _poison_explode() -> void:
	var blast_radius: float = data.poison_explosion_radius if data.poison_explosion_radius > 0.0 else maxf(18.0, visual_radius * 3.0)
	var poison_damage: float = _get_damage(damage * data.poison_explosion_damage_mult)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= blast_radius:
				var killed: bool = HitFeedbackManager.deal_damage(candidate, poison_damage, source, data, self, {
					"profile": "explosion",
					"attack_instance_id": attack_instance_id,
					"hit_origin": global_position,
					"effect_origin": global_position,
				})
				_notify_artifact_damage()
				_apply_kill_heal(killed)

func _apply_kill_heal(killed: bool) -> void:
	if not killed or data == null or data.kill_heal_amount <= 0.0:
		return
	if source != null and source.has_method("heal"):
		source.call("heal", data.kill_heal_amount, data)

func _notify_artifact_damage() -> void:
	if source != null and source.has_method("notify_artifact_damage"):
		source.call("notify_artifact_damage", data)

func _apply_attribute_on_hit(target: Node, base_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float = -1.0) -> void:
	if source != null and source.has_method("apply_attribute_on_hit"):
		source.call("apply_attribute_on_hit", data, target, base_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(target: Node) -> float:
	if target != null and target.has_method("get_hp_ratio"):
		return float(target.call("get_hp_ratio"))
	return -1.0

func _get_damage(base_damage: float) -> float:
	if source != null and source.has_method("get_artifact_damage"):
		return float(source.call("get_artifact_damage", data, base_damage))
	return base_damage

func _bounce_to_next_enemy() -> bool:
	var next_enemy: Node2D
	var nearest_distance: float = INF
	var fallback_enemy: Node2D
	var fallback_distance: float = INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D:
			continue
		var distance: float = global_position.distance_to((candidate as Node2D).global_position)
		if distance > bounce_range:
			continue
		if not hit_enemies.has(candidate) and distance < nearest_distance:
			next_enemy = candidate as Node2D
			nearest_distance = distance
		elif distance < fallback_distance:
			fallback_enemy = candidate as Node2D
			fallback_distance = distance
	if next_enemy == null:
		next_enemy = fallback_enemy
	if next_enemy == null:
		return false
	HitEffectManager.spawn_coin_path(get_tree(), global_position, next_enemy.global_position)
	direction = global_position.direction_to(next_enemy.global_position)
	rotation = direction.angle()
	return true

func _split_copper_coin() -> void:
	var targets: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage") and global_position.distance_to((candidate as Node2D).global_position) <= maxf(bounce_range, data.secondary_radius):
			targets.append(candidate as Node2D)
	targets.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	var split_count: int = maxi(1, data.count)
	for index in split_count:
		if targets.is_empty():
			break
		var target: Node2D = targets[index % targets.size()]
		var split_data: ArtifactData = data.duplicate(true) as ArtifactData
		split_data.damage *= maxf(0.0, data.secondary_damage_mult)
		split_data.projectile_bounce = 0
		split_data.bounce_count = 0
		split_data.range = global_position.distance_to(target.global_position) + 16.0
		split_data.set_meta("split_coin", true)
		var coin := ArtifactProjectile.new()
		get_parent().add_child(coin)
		coin.setup(source as Node2D, global_position.direction_to(target.global_position), split_data)
		coin.global_position = global_position

func _shatter_coin() -> void:
	HitEffectManager.spawn_hit(get_tree(), global_position, "coin", direction, 14.0)

func _circle_points(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 16:
		var angle: float = TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
