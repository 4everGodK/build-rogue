extends Area2D
class_name SummonProjectile

var source_unit: SummonUnit
var player: Node2D
var data: ArtifactData
var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var max_distance: float = 600.0
var traveled: float = 0.0
var explosive: bool = false
var bounce_remaining: int = 0
var hit_enemies: Dictionary = {}
var damage_multiplier: float = 1.0

func setup(unit: SummonUnit, owner_player: Node2D, artifact_data: ArtifactData, target: Node2D, use_explosion: bool, projectile_damage_multiplier: float = 1.0, direction_override: Vector2 = Vector2.ZERO) -> void:
	source_unit = unit
	player = owner_player
	data = artifact_data
	explosive = use_explosion
	damage_multiplier = maxf(0.0, projectile_damage_multiplier)
	global_position = unit.global_position
	if direction_override.length_squared() > 0.001:
		direction = direction_override.normalized()
	elif target != null:
		direction = global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	speed = maxf(280.0, data.projectile_speed)
	max_distance = maxf(120.0, data.summon_combat_radius)
	bounce_remaining = maxi(data.projectile_bounce, data.bounce_count)
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	rotation = direction.angle()
	_build_shape()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	traveled += movement.length()
	if traveled >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	hit_enemies[body] = true
	if source_unit != null:
		source_unit.damage_enemy(body as Node2D, data.summon_attack * damage_multiplier)
	if explosive:
		_explode()
		queue_free()
		return
	if bounce_remaining > 0:
		var next_enemy := _nearest_unhit_enemy()
		if next_enemy != null:
			bounce_remaining -= 1
			direction = global_position.direction_to(next_enemy.global_position)
			rotation = direction.angle()
			traveled = 0.0
			return
	queue_free()

func _nearest_unhit_enemy() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if hit_enemies.has(candidate) or not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var distance := global_position.distance_to((candidate as Node2D).global_position)
		if distance <= data.bounce_range and distance < nearest_distance:
			nearest = candidate as Node2D
			nearest_distance = distance
	return nearest

func _explode() -> void:
	var radius := maxf(36.0, data.explosion_radius)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= radius:
				if source_unit != null:
					source_unit.damage_enemy(candidate as Node2D, data.summon_attack * damage_multiplier, {
						"profile": "explosion",
						"hit_origin": global_position,
						"effect_origin": global_position,
					})

func _build_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var projectile_collision := CollisionShape2D.new()
	projectile_collision.shape = shape
	add_child(projectile_collision)
	var visual_poly := Polygon2D.new()
	if explosive:
		visual_poly.polygon = _circle_points(7.0, 14)
		visual_poly.color = Color(1.0, 0.34, 0.08, 0.9)
	else:
		visual_poly.polygon = PackedVector2Array([Vector2(12, 0), Vector2(-8, -3), Vector2(-4, 0), Vector2(-8, 3)])
		visual_poly.color = data.visual_color
	add_child(visual_poly)
	var trail := Line2D.new()
	trail.width = 2.5
	trail.default_color = Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.42)
	trail.points = PackedVector2Array([Vector2(-22, 0), Vector2.ZERO])
	add_child(trail)

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
