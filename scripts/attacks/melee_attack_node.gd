extends Area2D
class_name MeleeAttackNode

var damage: float
var source: Node
var hit_enemies: Dictionary = {}
var max_targets: int = 0

func setup(player: Node2D, data: ArtifactData, direction: Vector2) -> void:
	source = player
	damage = data.damage
	max_targets = data.max_targets
	global_position = player.global_position
	rotation = direction.angle()
	collision_layer = 0
	collision_mask = 2
	monitoring = true

	var collision := CollisionShape2D.new()
	if data.attack_shape == "circle":
		var circle := CircleShape2D.new()
		circle.radius = data.radius
		collision.shape = circle
	else:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(data.length, data.width)
		collision.position.x = data.length * 0.5
		collision.shape = rectangle
	add_child(collision)

	var slash := Polygon2D.new()
	if data.attack_shape == "circle":
		slash.polygon = _circle_points(data.radius)
	else:
		slash.polygon = PackedVector2Array([
			Vector2(0, -data.width * 0.5),
			Vector2(data.length, -data.width * 0.25),
			Vector2(data.length, data.width * 0.25),
			Vector2(0, data.width * 0.5),
		])
	slash.color = data.visual_color
	add_child(slash)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(maxf(0.1, data.duration)).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	if max_targets > 0 and hit_enemies.size() >= max_targets:
		return
	hit_enemies[body] = true
	body.call("take_damage", damage, source)

func _circle_points(circle_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points
