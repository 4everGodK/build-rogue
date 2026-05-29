extends Area2D
class_name Projectile

@export var speed: float = 420.0
@export var lifetime: float = 2.5
@export var radius: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var attack_type: String = "projectile"
var explosion_radius: float = 0.0
var chain_count: int = 0
var chain_radius: float = 120.0
var already_hit: Array[Enemy] = []

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func setup(start_position: Vector2, target_position: Vector2, projectile_damage: float, options := {}) -> void:
	global_position = start_position
	direction = start_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = projectile_damage
	attack_type = options.get("attack_type", "projectile")
	explosion_radius = options.get("explosion_radius", 0.0)
	chain_count = options.get("chain_count", 0)
	chain_radius = options.get("chain_radius", 120.0)
	rotation = direction.angle()

func _ready() -> void:
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body is Enemy:
		return

	var enemy: Enemy = body as Enemy
	enemy.take_damage(damage)

	# Extra effects are deliberately simple Area/scan logic for fast iteration.
	if attack_type == "explosive_projectile":
		_explode()
	elif attack_type == "chain_projectile":
		_chain_from(enemy)

	queue_free()

func _explode() -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and global_position.distance_to(body.global_position) <= explosion_radius:
			body.take_damage(damage * 0.65)
	_spawn_debug_circle(explosion_radius, Color(1.0, 0.35, 0.08, 0.28))

func _chain_from(first_enemy: Enemy) -> void:
	already_hit = [first_enemy]
	var source_position: Vector2 = first_enemy.global_position
	for i in chain_count:
		var next: Enemy = _find_next_chain_target(source_position)
		if next == null:
			return
		already_hit.append(next)
		next.take_damage(damage * 0.75)
		_spawn_debug_line(source_position, next.global_position)
		source_position = next.global_position

func _find_next_chain_target(source_position: Vector2) -> Enemy:
	var best: Enemy = null
	var best_distance: float = INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and not already_hit.has(body):
			var distance: float = source_position.distance_to(body.global_position)
			if distance < best_distance and distance <= chain_radius:
				best = body
				best_distance = distance
	return best

func _spawn_debug_circle(effect_radius: float, color: Color) -> void:
	var circle: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	for i in 24:
		var angle: float = TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * effect_radius)
	circle.polygon = points
	circle.color = color
	circle.global_position = global_position
	get_tree().current_scene.add_child(circle)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(circle, "modulate:a", 0.0, 0.18)
	tween.tween_callback(circle.queue_free)

func _spawn_debug_line(from: Vector2, to: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.55, 0.85, 1.0, 0.85)
	line.points = PackedVector2Array([from, to])
	get_tree().current_scene.add_child(line)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.14)
	tween.tween_callback(line.queue_free)
