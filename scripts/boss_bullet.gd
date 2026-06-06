extends Area2D
class_name BossBullet

var direction: Vector2 = Vector2.RIGHT
var speed: float = 230.0
var damage: int = 8
var life_time: float = 3.0

func setup(origin: Vector2, bullet_direction: Vector2, bullet_damage: int) -> void:
	add_to_group("boss_projectiles")
	global_position = origin
	direction = bullet_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = bullet_damage
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	body_entered.connect(_on_body_entered)
	_make_collision()
	_make_visual()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	life_time -= delta
	if life_time <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
		queue_free()

func _make_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 7.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)

func _make_visual() -> void:
	var visual := Polygon2D.new()
	var points := PackedVector2Array()
	for index in 14:
		var angle := TAU * float(index) / 14.0
		points.append(Vector2(cos(angle), sin(angle)) * 7.0)
	visual.polygon = points
	visual.color = Color(0.95, 0.12, 0.28, 0.9)
	add_child(visual)
