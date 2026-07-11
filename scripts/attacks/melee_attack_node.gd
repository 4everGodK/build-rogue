extends Area2D
class_name MeleeAttackNode

var damage: float
var source: Node
var hit_enemies: Dictionary = {}
var max_targets: int = 0
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT
var attack_instance_id: String = ""
var last_hit_was_critical: bool = false

func setup(player: Node2D, data: ArtifactData, direction: Vector2) -> void:
	self.data = data
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	self.direction = direction.normalized()
	source = player
	damage = data.damage
	max_targets = data.max_targets
	global_position = player.global_position
	rotation = direction.angle()
	collision_layer = 0
	collision_mask = 2
	monitoring = false

	if data.attack_shape == "circle":
		var collision: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = data.radius
		collision.shape = circle
		add_child(collision)
	elif data.attack_shape == "head_slash":
		var collision: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = maxf(12.0, data.width * 0.5)
		collision.position.x = data.length
		collision.shape = circle
		add_child(collision)
	elif data.attack_shape == "cone":
		var collision_polygon := CollisionPolygon2D.new()
		var half_width: float = maxf(8.0, data.width * 0.5)
		collision_polygon.polygon = PackedVector2Array([
			Vector2(0.0, -half_width * 0.22),
			Vector2(data.length, -half_width),
			Vector2(data.length, half_width),
			Vector2(0.0, half_width * 0.22),
		])
		add_child(collision_polygon)
	else:
		var collision: CollisionShape2D = CollisionShape2D.new()
		var rectangle: RectangleShape2D = RectangleShape2D.new()
		rectangle.size = Vector2(data.length, data.width)
		collision.position.x = data.length * 0.5
		collision.shape = rectangle
		add_child(collision)

	var visual: Node2D = ArtifactVisuals.make_melee_visual(data)
	add_child(visual)
	_animate_visual(visual, data)
	if _should_spawn_cross_slash():
		_spawn_cross_slash_damage()
	if data.id == "long_spear" and int(data.get_meta("star_level", 1)) >= 3:
		_spawn_delayed_endpoint_blast()
	if data.extra_melee_wave_damage_mult > 0.0:
		_spawn_extra_melee_wave(data)
	body_entered.connect(_on_body_entered)
	if data.windup_time > 0.0:
		get_tree().create_timer(data.windup_time).timeout.connect(func() -> void:
			if is_instance_valid(self):
				_activate_monitoring()
		)
	else:
		_activate_monitoring()
	get_tree().create_timer(maxf(0.1, data.windup_time + data.duration)).timeout.connect(queue_free)

func _activate_monitoring() -> void:
	monitoring = true
	for body in get_overlapping_bodies():
		_on_body_entered(body)

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	if max_targets > 0 and hit_enemies.size() >= max_targets:
		return
	hit_enemies[body] = true
	var dealt_damage: float = _roll_damage()
	var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(body)
	var killed: bool = HitFeedbackManager.deal_damage(body, dealt_damage, source, data, self, {
		"attack_instance_id": attack_instance_id,
		"is_critical": last_hit_was_critical,
		"hit_origin": (source as Node2D).global_position if source is Node2D else global_position,
	})
	_notify_artifact_damage()
	_apply_attribute_on_hit(body, dealt_damage, (body as Node2D).global_position if body is Node2D else global_position, pre_hit_hp_ratio)
	if data.id == "scythe" and data.heal_amount > 0.0 and source != null and source.has_method("heal"):
		source.call("heal", dealt_damage * data.heal_amount, data)
	_apply_kill_heal(killed)
	if data.slow_percent > 0.0 and body.has_method("apply_slow"):
		body.call("apply_slow", data.slow_percent, maxf(0.2, data.debuff_duration), self)
	if body is Node2D:
		_apply_sword_special_on_hit(body as Node2D, dealt_damage)

func _apply_sword_special_on_hit(body: Node2D, dealt_damage: float) -> void:
	var star: int = int(data.get_meta("star_level", 1))
	match data.id:
		"one_handed_sword":
			if _should_spawn_cross_slash():
				_spawn_cross_slash_damage()
		"dagger":
			_spawn_dagger_back_aoe(body)
			if star >= 3:
				_spawn_delayed_single_damage(body, data.secondary_damage_mult, maxf(0.03, data.secondary_delay))
		"two_handed_sword":
			_spawn_sword_scar(global_position + direction * data.length * 0.72, direction, true)
			if star >= 3:
				_spawn_delayed_scar_blast(global_position + direction * data.length * 0.72)

func _roll_damage() -> float:
	last_hit_was_critical = false
	var final_damage: float = damage
	if source != null and source.has_method("get_artifact_damage"):
		final_damage = float(source.call("get_artifact_damage", data, damage))
	if data != null and data.crit_chance > 0.0 and randf() < data.crit_chance:
		last_hit_was_critical = true
		return final_damage * maxf(1.0, data.crit_damage_mult)
	return final_damage

func _get_damage(base_damage: float) -> float:
	if source != null and source.has_method("get_artifact_damage"):
		return float(source.call("get_artifact_damage", data, base_damage))
	return base_damage

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

func _spawn_extra_melee_wave(data: ArtifactData) -> void:
	var wave: Area2D = Area2D.new()
	wave.collision_layer = 0
	wave.collision_mask = 2
	wave.monitoring = true
	wave.position = Vector2(data.length + data.extra_melee_wave_range * 0.5, 0.0)
	add_child(wave)

	var rectangle: RectangleShape2D = RectangleShape2D.new()
	rectangle.size = Vector2(data.extra_melee_wave_range, data.extra_melee_wave_width)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = rectangle
	wave.add_child(collision)

	var visual: Line2D = Line2D.new()
	visual.width = maxf(3.0, data.extra_melee_wave_width * 0.25)
	visual.default_color = Color(0.86, 0.95, 1.0, 0.65)
	visual.points = PackedVector2Array([
		Vector2(-data.extra_melee_wave_range * 0.5, 0.0),
		Vector2(data.extra_melee_wave_range * 0.5, 0.0),
	])
	wave.add_child(visual)

	var wave_hits: Dictionary = {}
	wave.body_entered.connect(func(body: Node) -> void:
		if wave_hits.has(body) or not body.has_method("take_damage"):
			return
		wave_hits[body] = true
		var wave_damage: float = damage * data.extra_melee_wave_damage_mult
		if source != null and source.has_method("get_artifact_damage"):
			wave_damage = float(source.call("get_artifact_damage", data, wave_damage))
		var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(body)
		var killed: bool = HitFeedbackManager.deal_damage(body, wave_damage, source, data, self, {
			"attack_instance_id": attack_instance_id,
			"hit_origin": global_position,
		})
		_notify_artifact_damage()
		_apply_attribute_on_hit(body, wave_damage, (body as Node2D).global_position if body is Node2D else wave.global_position, pre_hit_hp_ratio)
		_apply_kill_heal(killed)
	)

func _spawn_cross_slash_damage() -> void:
	if has_meta("cross_slash_spawned"):
		return
	set_meta("cross_slash_spawned", true)
	var cross_data: ArtifactData = data.duplicate(true) as ArtifactData
	cross_data.damage = damage * maxf(0.0, data.secondary_damage_mult)
	cross_data.windup_time = 0.0
	cross_data.set_meta("suppress_cross", true)
	var cross := MeleeAttackNode.new()
	get_parent().add_child(cross)
	cross.setup(source as Node2D, cross_data, direction.rotated(PI * 0.5))

func _should_spawn_cross_slash() -> bool:
	var star: int = int(data.get_meta("star_level", 1))
	return data.id == "one_handed_sword" and star >= 3 and int(data.get_meta("attack_count", 0)) % 3 == 0 and not bool(data.get_meta("suppress_cross", false)) and not has_meta("cross_slash_spawned")

func _spawn_dagger_back_aoe(target: Node2D) -> void:
	var radius: float = maxf(0.0, data.secondary_radius)
	var mult: float = maxf(0.0, data.secondary_damage_mult)
	if radius <= 0.0 or mult <= 0.0:
		return
	var center: Vector2 = target.global_position + direction * radius * 0.55
	_spawn_area_damage(center, radius, damage * mult, "poison")

func _spawn_delayed_single_damage(target: Node2D, mult: float, delay: float) -> void:
	if mult <= 0.0:
		return
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if not is_instance_valid(target) or not target.has_method("take_damage"):
			return
		var hit_damage: float = _get_damage(damage * mult)
		var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(target)
		var killed: bool = HitFeedbackManager.deal_damage(target, hit_damage, source, data, self, {
			"attack_instance_id": attack_instance_id,
			"hit_origin": global_position,
		})
		_notify_artifact_damage()
		_apply_attribute_on_hit(target, hit_damage, target.global_position, pre_hit_hp_ratio)
		_apply_kill_heal(killed)
	)

func _spawn_delayed_scar_blast(center: Vector2) -> void:
	var delay: float = maxf(0.05, data.secondary_delay)
	_spawn_sword_scar(center, direction, false)
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_spawn_area_damage(center, maxf(data.secondary_radius, data.radius), damage * maxf(0.0, data.secondary_damage_mult), "earth")
	)

func _spawn_delayed_endpoint_blast() -> void:
	var center: Vector2 = global_position + direction * data.length
	var delay: float = maxf(0.03, data.windup_time + data.duration * 0.65)
	get_tree().create_timer(delay).timeout.connect(func() -> void:
		if not is_instance_valid(self):
			return
		_spawn_area_damage(center, maxf(8.0, data.secondary_radius), damage * maxf(0.0, data.secondary_damage_mult), "fire")
	)

func _spawn_area_damage(center: Vector2, radius: float, base_damage: float, hit_kind: String) -> void:
	var final_damage: float = _get_damage(base_damage)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			var enemy := candidate as Node2D
			if center.distance_to(enemy.global_position) <= radius:
				var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(enemy)
				var killed: bool = HitFeedbackManager.deal_damage(enemy, final_damage, source, data, self, {
					"attack_instance_id": attack_instance_id,
					"hit_origin": center,
					"effect_origin": center,
				})
				_notify_artifact_damage()
				_apply_attribute_on_hit(enemy, final_damage, enemy.global_position, pre_hit_hp_ratio)
				_apply_kill_heal(killed)

func _spawn_sword_scar(center: Vector2, scar_direction: Vector2, strong: bool) -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var root := Node2D.new()
	root.global_position = center
	root.rotation = scar_direction.angle()
	var line := Line2D.new()
	line.width = 5.0 if strong else 3.0
	line.default_color = Color(0.9, 0.72, 0.36, 0.42 if strong else 0.26)
	line.points = PackedVector2Array([Vector2(-data.length * 0.28, 0.0), Vector2(data.length * 0.28, 0.0)])
	root.add_child(line)
	var ring := Line2D.new()
	ring.width = 3.0
	ring.default_color = Color(0.9, 0.72, 0.36, 0.18)
	ring.closed = true
	ring.points = _circle_points(maxf(18.0, data.radius), 28)
	root.add_child(ring)
	get_tree().current_scene.add_child(root)
	var tween := get_tree().create_tween()
	tween.tween_property(root, "modulate:a", 0.0, maxf(0.18, data.secondary_delay + 0.25))
	tween.tween_callback(root.queue_free)

func _shake_source(strength: float) -> void:
	if source == null or not source is Node2D:
		return
	var node := source as Node2D
	var origin: Vector2 = node.position
	var tween := get_tree().create_tween()
	tween.tween_property(node, "position", origin + Vector2(strength, 0.0), 0.025)
	tween.tween_property(node, "position", origin - Vector2(strength * 0.55, 0.0), 0.035)
	tween.tween_property(node, "position", origin, 0.04)

func _animate_visual(visual: Node2D, data: ArtifactData) -> void:
	if data.id == "long_spear":
		_animate_long_spear_visual(visual, data)
		return
	if data.id == "giant_sword_art" and data.attack_shape == "circle":
		_animate_giant_sword_sweep_visual(visual, data)
		return
	visual.scale = Vector2(0.65, 0.65)
	visual.modulate.a = 0.0
	var tween: Tween = get_tree().create_tween()
	var appear_time: float = minf(0.06, maxf(0.03, data.duration * 0.35))
	tween.tween_property(visual, "modulate:a", 1.0, appear_time)
	tween.parallel().tween_property(visual, "scale", Vector2.ONE, appear_time)
	tween.tween_property(visual, "modulate:a", 0.0, maxf(0.04, data.duration - appear_time))

func _animate_long_spear_visual(visual: Node2D, data: ArtifactData) -> void:
	visual.modulate.a = 1.0
	var point: Node2D = null
	var shaft: Node2D = null
	var spear_aura: Node2D = null
	if visual.get_child_count() > 0:
		point = visual.get_child(0) as Node2D
	if visual.get_child_count() > 1:
		shaft = visual.get_child(1) as Node2D
	if visual.get_child_count() > 2:
		spear_aura = visual.get_child(2) as Node2D
	if shaft != null:
		shaft.scale.x = 0.0
		shaft.modulate.a = 0.0
	if spear_aura != null:
		spear_aura.scale.x = 0.0
		spear_aura.modulate.a = 0.0
	var tween := get_tree().create_tween()
	if point != null:
		point.scale = Vector2(0.45, 0.45)
		tween.tween_property(point, "scale", Vector2(1.9, 1.9), maxf(0.04, data.windup_time * 0.55))
		tween.parallel().tween_property(point, "modulate:a", 0.95, maxf(0.04, data.windup_time * 0.55))
	if shaft != null:
		tween.tween_property(shaft, "modulate:a", 1.0, 0.02)
		tween.parallel().tween_property(shaft, "scale:x", 1.0, maxf(0.06, data.duration * 0.42))
	if spear_aura != null:
		tween.tween_property(spear_aura, "modulate:a", 1.0, 0.02)
		tween.parallel().tween_property(spear_aura, "scale:x", 1.0, maxf(0.05, data.duration * 0.28))
	tween.tween_property(visual, "modulate:a", 0.0, maxf(0.05, data.duration * 0.32))

func _animate_giant_sword_sweep_visual(visual: Node2D, data: ArtifactData) -> void:
	visual.modulate.a = 0.0
	visual.scale = Vector2(0.08, 1.0)
	var tween := get_tree().create_tween()
	var reveal_time: float = maxf(0.08, data.reveal_time)
	var pause_time: float = maxf(0.04, data.pause_time)
	tween.tween_property(visual, "modulate:a", 1.0, reveal_time * 0.35)
	tween.parallel().tween_property(visual, "scale", Vector2.ONE, reveal_time)
	tween.tween_interval(pause_time)
	tween.tween_property(visual, "rotation", TAU, maxf(0.18, data.duration))
	tween.parallel().tween_property(visual, "modulate:a", 0.0, maxf(0.08, data.duration * 0.18)).set_delay(maxf(0.0, data.duration * 0.82))

func _circle_points(circle_radius: float, segments: int = 24) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in segments:
		var angle: float = TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points
