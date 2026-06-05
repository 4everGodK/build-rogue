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

func setup(owner_player: Node2D, attack_direction: Vector2, data: ArtifactData) -> void:
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
	source = owner_player
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	rotation = direction.angle()

	var shape := CircleShape2D.new()
	shape.radius = maxf(4.0, minf(visual_radius, 14.0))
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var visual := Polygon2D.new()
	if data.attack_shape == "circle":
		visual.polygon = _circle_points(maxf(6.0, minf(visual_radius, 14.0)))
	else:
		visual.polygon = PackedVector2Array([Vector2(data.length * 0.5, 0), Vector2(-data.length * 0.5, -visual_radius), Vector2(-data.length * 0.3, 0), Vector2(-data.length * 0.5, visual_radius)])
	visual.color = data.visual_color
	add_child(visual)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta
	global_position += movement
	traveled_distance += movement.length()
	if traveled_distance >= max_distance:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	hit_enemies[body] = true
	body.call("take_damage", damage, source)
	if damage_reduction_percent > 0.0 and body.has_method("apply_damage_reduction"):
		body.call("apply_damage_reduction", damage_reduction_percent, debuff_duration, self)
	if explosion_radius > 0.0:
		_explode(body)
		queue_free()
		return
	if bounce_remaining > 0 and _bounce_to_next_enemy():
		bounce_remaining -= 1
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
				candidate.call("take_damage", damage, source)
	var blast := Polygon2D.new()
	blast.polygon = _circle_points(explosion_radius)
	blast.color = Color(1.0, 0.25, 0.05, 0.25)
	blast.global_position = global_position
	get_tree().current_scene.add_child(blast)
	var tween := get_tree().create_tween()
	tween.tween_property(blast, "modulate:a", 0.0, 0.18)
	tween.tween_callback(blast.queue_free)

func _bounce_to_next_enemy() -> bool:
	var next_enemy: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or hit_enemies.has(candidate):
			continue
		var distance := global_position.distance_to((candidate as Node2D).global_position)
		if distance <= bounce_range and distance < nearest_distance:
			next_enemy = candidate as Node2D
			nearest_distance = distance
	if next_enemy == null:
		return false
	direction = global_position.direction_to(next_enemy.global_position)
	rotation = direction.angle()
	return true

func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
