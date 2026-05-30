extends Area2D
class_name OrbitingArtifactNode

@export var orbit_radius: float = 80.0
@export var angular_speed: float = 4.0
@export var clockwise: bool = true
@export var damage: float = 5.0
@export var hit_interval: float = 0.35
@export var knockback_force: float = 0.0
@export var lifetime: float = -1.0
@export var visual_radius: float = 8.0
@export var visual_color: Color = Color(0.4, 0.85, 1.0, 1.0)

var target: Node2D
var angle: float = 0.0
var hit_cooldowns: Dictionary = {}

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func configure(
	target_node: Node2D,
	start_angle: float,
	radius: float,
	speed: float,
	is_clockwise: bool,
	artifact_damage: float,
	interval: float,
	knockback: float,
	node_lifetime: float,
	color: Color,
	size: float
) -> void:
	target = target_node
	angle = start_angle
	orbit_radius = radius
	angular_speed = speed
	clockwise = is_clockwise
	damage = artifact_damage
	hit_interval = interval
	knockback_force = knockback
	lifetime = node_lifetime
	visual_color = color
	visual_radius = size

func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = visual_radius
	collision.shape = shape
	visual.color = visual_color
	visual.polygon = _build_polygon(visual_radius)
	monitoring = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	var direction: float = -1.0 if clockwise else 1.0
	angle += angular_speed * direction * delta
	global_position = target.global_position + Vector2(cos(angle), sin(angle)) * orbit_radius

	_tick_hit_cooldowns(delta)
	_hit_overlapping_enemies()

	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			queue_free()

func _tick_hit_cooldowns(delta: float) -> void:
	for id in hit_cooldowns.keys():
		hit_cooldowns[id] = float(hit_cooldowns[id]) - delta
		if float(hit_cooldowns[id]) <= 0.0:
			hit_cooldowns.erase(id)

func _hit_overlapping_enemies() -> void:
	for body in get_overlapping_bodies():
		if not body is Enemy:
			continue
		var enemy: Enemy = body
		var id: int = enemy.get_instance_id()
		if hit_cooldowns.has(id):
			continue
		enemy.take_damage(damage)
		if knockback_force > 0.0:
			enemy.apply_knockback(global_position, knockback_force)
		hit_cooldowns[id] = hit_interval

func _build_polygon(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i in 12:
		var point_angle: float = TAU * float(i) / 12.0
		points.append(Vector2(cos(point_angle), sin(point_angle)) * radius)
	return points
