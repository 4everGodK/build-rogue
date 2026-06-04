extends Area2D
class_name ArtifactProjectile

var direction: Vector2
var speed: float
var damage: float
var max_distance: float
var traveled_distance: float = 0.0
var pierce_remaining: int
var source: Node
var hit_enemies: Dictionary = {}

func setup(owner_player: Node2D, attack_direction: Vector2, data: ArtifactData) -> void:
	global_position = owner_player.global_position
	direction = attack_direction.normalized()
	speed = data.projectile_speed
	damage = data.damage
	max_distance = data.range
	pierce_remaining = data.projectile_pierce
	source = owner_player
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	rotation = direction.angle()

	var shape := CircleShape2D.new()
	shape.radius = maxf(4.0, minf(data.radius, 10.0))
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var visual := Polygon2D.new()
	if data.id == "fire_orb":
		visual.polygon = _circle_points(maxf(6.0, minf(data.radius, 12.0)))
	else:
		visual.polygon = PackedVector2Array([Vector2(13, 0), Vector2(-7, -4), Vector2(-3, 0), Vector2(-7, 4)])
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
	if pierce_remaining <= 0:
		queue_free()
	else:
		pierce_remaining -= 1

func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 16:
		var angle := TAU * float(index) / 16.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
