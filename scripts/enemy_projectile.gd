extends Area2D
class_name EnemyProjectile

var direction := Vector2.RIGHT
var speed := 225.0
var damage := 7
var lifetime := 4.0

func setup(origin: Vector2, target_position: Vector2, projectile_damage: int, projectile_speed: float) -> void:
	add_to_group("enemy_projectiles")
	global_position = origin
	direction = origin.direction_to(target_position)
	if direction == Vector2.ZERO: direction = Vector2.RIGHT
	damage = projectile_damage
	speed = projectile_speed
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0: queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()
