extends Area2D
class_name MeleeAttackNode

var damage: float
var source: Node
var hit_enemies: Dictionary = {}

func setup(player: Node2D, data: ArtifactData, direction: Vector2) -> void:
	source = player
	damage = data.damage
	global_position = player.global_position + direction * data.range * 0.5
	rotation = direction.angle()
	collision_layer = 0
	collision_mask = 2
	monitoring = true

	var shape := RectangleShape2D.new()
	shape.size = Vector2(data.range, data.radius * 2.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

	var slash := Polygon2D.new()
	slash.polygon = PackedVector2Array([
		Vector2(-data.range * 0.5, -data.radius),
		Vector2(data.range * 0.5, -data.radius * 0.35),
		Vector2(data.range * 0.5, data.radius * 0.35),
		Vector2(-data.range * 0.5, data.radius),
	])
	slash.color = data.visual_color
	add_child(slash)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(maxf(0.1, data.duration)).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if hit_enemies.has(body) or not body.has_method("take_damage"):
		return
	hit_enemies[body] = true
	body.call("take_damage", damage, source)
