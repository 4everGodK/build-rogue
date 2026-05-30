extends Node
class_name ArtifactController

@export var projectile_scene: PackedScene

var owner_player: Player
var projectile_container: Node2D
var synergy_manager: SynergyManager
var artifacts: Array[Dictionary] = []
var cooldowns: Array[float] = []
var melee_attack_counts: Dictionary = {}

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
	var modifier: TypeSynergyModifier = synergy_manager.get_type_modifier()

	if attack_type == "scatter_projectile":
		_fire_scatter(target, damage * modifier.projectile_damage_multiplier(), attack_type, modifier)
		return
	if attack_type == "bounce_projectile":
		_fire_projectile_pattern(target, damage * modifier.projectile_damage_multiplier(), {"attack_type": "chain_projectile", "chain_count": 2, "chain_radius": 140.0}, modifier)
		return
	if attack_type == "area":
		_apply_repeated_area_damage(target.global_position, damage, 82.0 * modifier.area_radius_multiplier(), modifier.area_instance_count(), Color(0.9, 0.7, 0.2, 0.28))
		# TODO: use modifier.area_duration_multiplier() when persistent area nodes exist.
		return
	if attack_type == "body_strike":
		_apply_body_strike(target.global_position, damage, modifier)
		return
	if attack_type == "melee":
		_apply_melee_attack(artifact, target.global_position, damage, modifier)
		return
	if attack_type == "orbit":
		for i in modifier.orbit_hit_count():
			_apply_area_damage(owner_player.global_position, damage, 96.0 + 18.0 * float(i), Color(0.4, 0.85, 1.0, 0.2))
		# TODO: replace repeated pulse with real orbiting objects and rotation speed.
		return
	if attack_type == "summon":
		for _summon_index in modifier.summon_count():
			for _repeat_index in modifier.summon_attack_repeat_count():
				_fire_projectile(target, damage, {"attack_type": "projectile"})
		# TODO: replace direct shots with persistent summon units.
		return

	var options: Dictionary = {"attack_type": attack_type}
	if attack_type == "explosive_projectile":
		options["explosion_radius"] = 72.0 * synergy_manager.explosion_radius_multiplier()
	elif attack_type == "chain_projectile":
		options["chain_count"] = 2 + synergy_manager.chain_bonus()
		options["chain_radius"] = 125.0

	_fire_projectile_pattern(target, damage * modifier.projectile_damage_multiplier(), options, modifier)

func _fire_projectile_pattern(target: Enemy, damage: float, options: Dictionary, modifier: TypeSynergyModifier) -> void:
	var projectile_count: int = 1 + modifier.projectile_extra_count()
	for _repeat_index in modifier.projectile_repeat_count():
		for projectile_index in projectile_count:
			var adjusted_options: Dictionary = options.duplicate(true)
			var target_position: Vector2 = target.global_position
			if projectile_count > 1:
				var base_direction: Vector2 = owner_player.global_position.direction_to(target.global_position)
				if base_direction == Vector2.ZERO:
					base_direction = Vector2.RIGHT
				var spread_step: float = 0.18
				var centered_index: float = float(projectile_index) - float(projectile_count - 1) * 0.5
				target_position = owner_player.global_position + base_direction.rotated(centered_index * spread_step) * 420.0
			_fire_projectile_to_position(target_position, damage, adjusted_options)

func _fire_projectile(target: Enemy, damage: float, options: Dictionary) -> void:
	_fire_projectile_to_position(target.global_position, damage, options)

func _fire_projectile_to_position(target_position: Vector2, damage: float, options: Dictionary) -> void:
	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	projectile_container.add_child(projectile)
	projectile.setup(owner_player.global_position, target_position, damage, options)

func _fire_scatter(target: Enemy, damage: float, attack_type: String, modifier: TypeSynergyModifier) -> void:
	var base_direction: Vector2 = owner_player.global_position.direction_to(target.global_position)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	var projectile_count: int = 3 + modifier.projectile_extra_count()
	for projectile_index in projectile_count:
		var centered_index: float = float(projectile_index) - float(projectile_count - 1) * 0.5
		var angle_offset: float = centered_index * 0.18
		var target_position: Vector2 = owner_player.global_position + base_direction.rotated(angle_offset) * 360.0
		for _repeat_index in modifier.projectile_repeat_count():
			_fire_projectile_to_position(target_position, damage, {"attack_type": attack_type})

func _apply_melee_attack(artifact: Dictionary, center: Vector2, damage: float, modifier: TypeSynergyModifier) -> void:
	var radius: float = 58.0
	_apply_area_damage(center, damage, radius, Color(0.95, 0.95, 1.0, 0.25))

	var interval: int = modifier.melee_combo_interval()
	if interval <= 0:
		return

	var artifact_id: String = str(artifact.get("id", ""))
	melee_attack_counts[artifact_id] = int(melee_attack_counts.get(artifact_id, 0)) + 1
	if int(melee_attack_counts[artifact_id]) % interval != 0:
		return

	_apply_area_damage(center, damage * modifier.melee_extra_damage_multiplier(), radius * 1.15, Color(1.0, 1.0, 0.45, 0.28))
	if modifier.melee_extra_can_chain():
		# Simple prototype cap: one chained extra slash. Full recursive proc rules can be added here.
		_apply_area_damage(center, damage * modifier.melee_extra_damage_multiplier(), radius * 1.3, Color(1.0, 0.8, 0.35, 0.2))

func _apply_body_strike(center: Vector2, damage: float, modifier: TypeSynergyModifier) -> void:
	var radius: float = 64.0 * modifier.body_strike_radius_multiplier()
	_apply_area_damage(center, damage, radius, Color(1.0, 0.25, 0.18, 0.28))
	for echo_index in modifier.body_strike_echo_count():
		var echo_multiplier: float = 0.5
		_apply_area_damage(center, damage * echo_multiplier, radius * (1.1 + 0.15 * float(echo_index)), Color(1.0, 0.55, 0.35, 0.2))

func _apply_repeated_area_damage(center: Vector2, damage: float, radius: float, count: int, color: Color) -> void:
	for area_index in count:
		_apply_area_damage(center, damage, radius + 18.0 * float(area_index), color)

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
	var cooldown: float = float(artifact.get("cooldown", 1.0))
	var modifier: TypeSynergyModifier = synergy_manager.get_type_modifier()
	var attack_type: String = str(artifact.get("attack_type", ""))
	if attack_type == "orbit":
		cooldown *= modifier.orbit_cooldown_multiplier()
	elif attack_type == "summon":
		cooldown *= modifier.summon_cooldown_multiplier()
	return cooldown

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
