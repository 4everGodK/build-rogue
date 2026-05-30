extends Area2D
class_name Projectile

@export var speed: float = 420.0
@export var lifetime: float = 2.5
@export var radius: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0
var attack_type: String = "projectile"
var explosion_radius: float = 0.0
var extra_explosion_radius: float = 0.0
var extra_explosion_can_chain: bool = false
var chain_count: int = 0
var chain_radius: float = 120.0
var pierce_remaining: int = 0
var extra_chain_count: int = 0
var chain_can_repeat_target: bool = false
var poison_dps: float = 0.0
var poison_duration: float = 0.0
var poison_can_stack: bool = false
var poison_spread_on_death: bool = false
var lifesteal_ratio: float = 0.0
var execute_threshold: float = 0.0
var execute_multiplier: float = 1.0
var owner_player: Player
var already_hit: Array[Enemy] = []

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

func setup(start_position: Vector2, target_position: Vector2, projectile_damage: float, options: Dictionary = {}) -> void:
	global_position = start_position
	direction = start_position.direction_to(target_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	damage = projectile_damage
	attack_type = str(options.get("attack_type", "projectile"))
	explosion_radius = float(options.get("explosion_radius", 0.0))
	extra_explosion_radius = float(options.get("extra_explosion_radius", 0.0))
	extra_explosion_can_chain = bool(options.get("extra_explosion_can_chain", false))
	chain_count = int(options.get("chain_count", 0))
	chain_radius = float(options.get("chain_radius", 120.0))
	pierce_remaining = int(options.get("pierce_remaining", 0))
	extra_chain_count = int(options.get("extra_chain_count", 0))
	chain_can_repeat_target = bool(options.get("chain_can_repeat_target", false))
	poison_dps = float(options.get("poison_dps", 0.0))
	poison_duration = float(options.get("poison_duration", 0.0))
	poison_can_stack = bool(options.get("poison_can_stack", false))
	poison_spread_on_death = bool(options.get("poison_spread_on_death", false))
	lifesteal_ratio = float(options.get("lifesteal_ratio", 0.0))
	execute_threshold = float(options.get("execute_threshold", 0.0))
	execute_multiplier = float(options.get("execute_multiplier", 1.0))
	var raw_owner: Variant = options.get("owner_player", null)
	if raw_owner is Player:
		owner_player = raw_owner
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
	var killed: bool = _deal_damage(enemy, damage)

	# Extra effects are deliberately simple Area/scan logic for fast iteration.
	if attack_type == "explosive_projectile":
		_explode()
	elif attack_type == "chain_projectile":
		_chain_from(enemy)
	if extra_explosion_radius > 0.0:
		_explode(extra_explosion_radius, extra_explosion_can_chain)
	if extra_chain_count > 0:
		_chain_from(enemy, extra_chain_count, chain_can_repeat_target)
	if poison_spread_on_death and killed:
		_spread_poison(enemy.global_position)

	if pierce_remaining > 0:
		pierce_remaining -= 1
	else:
		queue_free()

func _explode(radius_override: float = -1.0, can_chain: bool = false) -> void:
	var active_radius: float = explosion_radius if radius_override < 0.0 else radius_override
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and global_position.distance_to(body.global_position) <= active_radius:
			var enemy: Enemy = body
			_deal_damage(enemy, damage * 0.65)
			if can_chain:
				_spawn_debug_circle(active_radius * 0.55, Color(1.0, 0.18, 0.05, 0.18), enemy.global_position)
	_spawn_debug_circle(active_radius, Color(1.0, 0.35, 0.08, 0.28))

func _chain_from(first_enemy: Enemy, override_chain_count: int = -1, can_repeat_target: bool = false) -> void:
	already_hit = [first_enemy]
	var source_position: Vector2 = first_enemy.global_position
	var hits: int = chain_count if override_chain_count < 0 else override_chain_count
	for i in hits:
		var next: Enemy = _find_next_chain_target(source_position, can_repeat_target)
		if next == null:
			return
		already_hit.append(next)
		var falloff: float = pow(0.75, float(i + 1))
		_deal_damage(next, damage * falloff)
		_spawn_debug_line(source_position, next.global_position)
		source_position = next.global_position

func _find_next_chain_target(source_position: Vector2, can_repeat_target: bool = false) -> Enemy:
	var best: Enemy = null
	var best_distance: float = INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and (can_repeat_target or not already_hit.has(body)):
			var distance: float = source_position.distance_to(body.global_position)
			if distance < best_distance and distance <= chain_radius:
				best = body
				best_distance = distance
	return best

func _deal_damage(enemy: Enemy, amount: float) -> bool:
	enemy.apply_poison(poison_dps, poison_duration, poison_can_stack)
	var final_amount: float = amount
	if execute_threshold > 0.0 and enemy.get_hp_ratio() <= execute_threshold:
		final_amount *= execute_multiplier
	var killed: bool = enemy.take_damage(final_amount)
	if owner_player != null and lifesteal_ratio > 0.0:
		owner_player.heal(final_amount * lifesteal_ratio)
	return killed

func _spread_poison(center: Vector2) -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and center.distance_to(body.global_position) <= 96.0:
			var enemy: Enemy = body
			enemy.apply_poison(poison_dps, poison_duration, true)

func _spawn_debug_circle(effect_radius: float, color: Color, center: Vector2 = Vector2.INF) -> void:
	var circle: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	for i in 24:
		var angle: float = TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * effect_radius)
	circle.polygon = points
	circle.color = color
	circle.global_position = global_position if center == Vector2.INF else center
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
