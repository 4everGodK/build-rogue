extends Area2D
class_name MeleeAttackNode

var damage: float
var source: Node
var hit_enemies: Dictionary = {}
var max_targets: int = 0
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT

func setup(player: Node2D, data: ArtifactData, direction: Vector2) -> void:
	self.data = data
	self.direction = direction.normalized()
	source = player
	damage = data.damage
	max_targets = data.max_targets
	global_position = player.global_position
	rotation = direction.angle()
	collision_layer = 0
	collision_mask = 2
	monitoring = true

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
	if data.extra_melee_wave_damage_mult > 0.0:
		_spawn_extra_melee_wave(data)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(maxf(0.1, data.duration)).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	if max_targets > 0 and hit_enemies.size() >= max_targets:
		return
	hit_enemies[body] = true
	var dealt_damage: float = _roll_damage()
	var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(body)
	var killed: bool = bool(body.call("take_damage", dealt_damage, source))
	_notify_artifact_damage()
	_apply_attribute_on_hit(body, dealt_damage, (body as Node2D).global_position if body is Node2D else global_position, pre_hit_hp_ratio)
	if data.id == "scythe" and data.heal_amount > 0.0 and source != null and source.has_method("heal"):
		source.call("heal", dealt_damage * data.heal_amount)
	_apply_kill_heal(killed)
	if data.knockback_force > 0.0 and source is Node2D and body.has_method("apply_knockback"):
		body.call("apply_knockback", (source as Node2D).global_position, data.knockback_force)
	if data.slow_percent > 0.0 and body.has_method("apply_slow"):
		body.call("apply_slow", data.slow_percent, maxf(0.2, data.debuff_duration), self)
	if body is Node2D:
		HitEffectManager.spawn_hit(get_tree(), (body as Node2D).global_position, ArtifactVisuals.melee_hit_kind(data), direction, 18.0)

func _roll_damage() -> float:
	var final_damage: float = damage
	if source != null and source.has_method("get_artifact_damage"):
		final_damage = float(source.call("get_artifact_damage", data, damage))
	if data != null and data.crit_chance > 0.0 and randf() < data.crit_chance:
		return final_damage * maxf(1.0, data.crit_damage_mult)
	return final_damage

func _apply_kill_heal(killed: bool) -> void:
	if not killed or data == null or data.kill_heal_amount <= 0.0:
		return
	if source != null and source.has_method("heal"):
		source.call("heal", data.kill_heal_amount)

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
		var killed: bool = bool(body.call("take_damage", wave_damage, source))
		_notify_artifact_damage()
		_apply_attribute_on_hit(body, wave_damage, (body as Node2D).global_position if body is Node2D else wave.global_position, pre_hit_hp_ratio)
		_apply_kill_heal(killed)
		if body is Node2D:
			HitEffectManager.spawn_hit(get_tree(), (body as Node2D).global_position, "sword", direction, 14.0)
	)

func _animate_visual(visual: Node2D, data: ArtifactData) -> void:
	visual.scale = Vector2(0.65, 0.65)
	visual.modulate.a = 0.0
	var tween: Tween = get_tree().create_tween()
	var appear_time: float = minf(0.06, maxf(0.03, data.duration * 0.35))
	tween.tween_property(visual, "modulate:a", 1.0, appear_time)
	tween.parallel().tween_property(visual, "scale", Vector2.ONE, appear_time)
	if data.id == "giant_sword_art" and data.attack_shape == "circle":
		tween.parallel().tween_property(visual, "rotation", TAU, maxf(0.18, data.duration))
	tween.tween_property(visual, "modulate:a", 0.0, maxf(0.04, data.duration - appear_time))

func _circle_points(circle_radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 24:
		var angle: float = TAU * float(index) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points
