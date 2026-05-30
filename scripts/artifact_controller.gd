extends Node
class_name ArtifactController

@export var projectile_scene: PackedScene

var owner_player: Player
var projectile_container: Node2D
var synergy_manager: SynergyManager
var artifacts: Array[Dictionary] = []
var cooldowns: Array[float] = []

func configure(player: Player, container: Node2D, synergies: SynergyManager) -> void:
	owner_player = player
	projectile_container = container
	synergy_manager = synergies

func set_artifacts(next_artifacts: Array) -> void:
	artifacts = next_artifacts.duplicate(true)
	cooldowns.clear()
	for artifact in artifacts:
		var typed_artifact: Dictionary = artifact
		cooldowns.append(randf_range(0.05, _effective_cooldown(typed_artifact)))

func _process(delta: float) -> void:
	if not is_instance_valid(owner_player) or projectile_scene == null:
		return

	for index in artifacts.size():
		var artifact: Dictionary = artifacts[index]
		cooldowns[index] -= delta
		if cooldowns[index] <= 0.0:
			_try_attack(artifact)
			cooldowns[index] = _effective_cooldown(artifact)

func _try_attack(artifact: Dictionary) -> void:
	var target: Enemy = _find_nearest_enemy()
	if target == null:
		return

	# Attack behavior is selected by data, so Player stays unaware of artifact types.
	var attack_type: String = artifact.get("attack_type", "projectile")
	var damage: float = _effective_damage(artifact)
	if attack_type == "projectile":
		damage *= synergy_manager.projectile_damage_multiplier()

	if attack_type == "scatter_projectile":
		_fire_scatter(target, damage, attack_type)
		return
	if attack_type == "bounce_projectile":
		_fire_projectile(target, damage, {"attack_type": "chain_projectile", "chain_count": 2, "chain_radius": 140.0})
		return
	if attack_type == "area":
		_apply_area_damage(target.global_position, damage, 82.0, Color(0.9, 0.7, 0.2, 0.28))
		return
	if attack_type == "body_strike":
		_apply_area_damage(target.global_position, damage, 64.0, Color(1.0, 0.25, 0.18, 0.28))
		return
	if attack_type == "orbit":
		_apply_area_damage(owner_player.global_position, damage, 96.0, Color(0.4, 0.85, 1.0, 0.2))
		return
	if attack_type == "summon":
		_fire_projectile(target, damage, {"attack_type": "projectile"})
		return

	var options: Dictionary = {"attack_type": attack_type}
	if attack_type == "explosive_projectile":
		options["explosion_radius"] = 72.0 * synergy_manager.explosion_radius_multiplier()
	elif attack_type == "chain_projectile":
		options["chain_count"] = 2 + synergy_manager.chain_bonus()
		options["chain_radius"] = 125.0

	_fire_projectile(target, damage, options)

func _fire_projectile(target: Enemy, damage: float, options: Dictionary) -> void:
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	projectile_container.add_child(projectile)
	projectile.setup(owner_player.global_position, target.global_position, damage, options)

func _fire_scatter(target: Enemy, damage: float, attack_type: String) -> void:
	var base_direction: Vector2 = owner_player.global_position.direction_to(target.global_position)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	for angle_offset in [-0.24, 0.0, 0.24]:
		var target_position: Vector2 = owner_player.global_position + base_direction.rotated(angle_offset) * 360.0
		var projectile: Projectile = projectile_scene.instantiate() as Projectile
		projectile_container.add_child(projectile)
		projectile.setup(owner_player.global_position, target_position, damage, {"attack_type": attack_type})

func _apply_area_damage(center: Vector2, damage: float, radius: float, color: Color) -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and center.distance_to(body.global_position) <= radius:
			body.take_damage(damage)
	_spawn_debug_circle(center, radius, color)

func _spawn_debug_circle(center: Vector2, radius: float, color: Color) -> void:
	var circle: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	for i in 24:
		var angle: float = TAU * float(i) / 24.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	circle.color = color
	circle.global_position = center
	get_tree().current_scene.add_child(circle)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(circle, "modulate:a", 0.0, 0.18)
	tween.tween_callback(circle.queue_free)

func _effective_damage(artifact: Dictionary) -> float:
	# Level-specific effects are intentionally not active yet.
	# Keep this hook so later upgrades can branch by artifact id and level.
	return float(artifact.get("damage", 1.0))

func _effective_cooldown(artifact: Dictionary) -> float:
	# Level-specific cooldown changes should be added here when that system is designed.
	return float(artifact.get("cooldown", 1.0))

func _find_nearest_enemy() -> Enemy:
	var nearest: Enemy = null
	var nearest_distance: float = INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy:
			var distance: float = owner_player.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest = body
				nearest_distance = distance
	return nearest
