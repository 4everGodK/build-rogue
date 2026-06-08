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

func setup(owner_player: Node2D, attack_direction: Vector2, data: ArtifactData) -> void:
	self.data = data
	global_position = owner_player.global_position
	direction = attack_direction.normalized()
	speed = data.projectile_speed
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
	monitoring = true
	rotation = direction.angle()

	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = maxf(4.0, minf(visual_radius, 14.0))
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	trail_node = ArtifactVisuals.make_projectile_trail(data)
	add_child(trail_node)
	visual_node = ArtifactVisuals.make_projectile_visual(data)
	add_child(visual_node)
	spin_speed = ArtifactVisuals.projectile_spin_speed(data)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var movement: Vector2 = direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()
	if is_instance_valid(visual_node) and spin_speed > 0.0:
		visual_node.rotation += spin_speed * delta
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	hit_enemies[body] = true
	var killed: bool = bool(body.call("take_damage", damage, source))
	_apply_kill_heal(killed)
	if data.poison_dps > 0.0 and body.has_method("apply_poison"):
		body.call("apply_poison", data.poison_dps, maxf(0.1, data.poison_duration), data.poison_can_stack)
	HitEffectManager.spawn_hit(get_tree(), global_position, ArtifactVisuals.projectile_hit_kind(data), direction, maxf(14.0, visual_radius * 1.8))
	if data.id == "flying_sword":
		HitEffectManager.spawn_hit(get_tree(), global_position, "lightning", direction, maxf(10.0, visual_radius * 1.2))
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

func _explode(direct_target: Node) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == direct_target:
			continue
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= explosion_radius:
				var killed: bool = bool(candidate.call("take_damage", damage, source))
				_apply_kill_heal(killed)
	var blast: Polygon2D = Polygon2D.new()
	blast.polygon = _circle_points(explosion_radius)
	blast.color = Color(1.0, 0.25, 0.05, 0.25)
	blast.global_position = global_position
	get_tree().current_scene.add_child(blast)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(blast, "modulate:a", 0.0, 0.18)
	tween.tween_callback(blast.queue_free)

func _poison_explode() -> void:
	var blast_radius: float = data.poison_explosion_radius if data.poison_explosion_radius > 0.0 else maxf(18.0, visual_radius * 3.0)
	var poison_damage: float = damage * data.poison_explosion_damage_mult
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= blast_radius:
				var killed: bool = bool(candidate.call("take_damage", poison_damage, source))
				_apply_kill_heal(killed)
	HitEffectManager.spawn_hit(get_tree(), global_position, "poison", direction, blast_radius)

func _apply_kill_heal(killed: bool) -> void:
	if not killed or data == null or data.kill_heal_amount <= 0.0:
		return
	if source != null and source.has_method("heal"):
		source.call("heal", data.kill_heal_amount)

func _bounce_to_next_enemy() -> bool:
	var next_enemy: Node2D
	var nearest_distance: float = INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or hit_enemies.has(candidate):
			continue
		var distance: float = global_position.distance_to((candidate as Node2D).global_position)
		if distance <= bounce_range and distance < nearest_distance:
			next_enemy = candidate as Node2D
			nearest_distance = distance
	if next_enemy == null:
		return false
	HitEffectManager.spawn_coin_path(get_tree(), global_position, next_enemy.global_position)
	direction = global_position.direction_to(next_enemy.global_position)
	rotation = direction.angle()
	return true

func _circle_points(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 16:
		var angle: float = TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
