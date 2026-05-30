extends Node
class_name ArtifactController

@export var projectile_scene: PackedScene
@export var orbiting_artifact_scene: PackedScene

var owner_player: Player
var projectile_container: Node2D
var synergy_manager: SynergyManager
var artifacts: Array[Dictionary] = []
var cooldowns: Array[float] = []
var melee_attack_counts: Dictionary = {}
var orbit_nodes: Array[Node] = []

func configure(player: Player, container: Node2D, synergies: SynergyManager) -> void:
	owner_player = player
	projectile_container = container
	synergy_manager = synergies

func set_artifacts(next_artifacts: Array) -> void:
	artifacts = next_artifacts.duplicate(true)
	cooldowns.clear()
	_clear_orbit_nodes()
	for artifact in artifacts:
		var typed_artifact: Dictionary = artifact
		cooldowns.append(randf_range(0.05, _effective_cooldown(typed_artifact)))
	refresh_orbiting_artifacts()

func refresh_orbiting_artifacts() -> void:
	_clear_orbit_nodes()
	for artifact in artifacts:
		var typed_artifact: Dictionary = artifact
		if str(typed_artifact.get("attack_type", "")) == "orbit":
			_spawn_orbiting_artifacts(typed_artifact)

func _process(delta: float) -> void:
	if not is_instance_valid(owner_player) or projectile_scene == null:
		return

	for index in artifacts.size():
		var artifact: Dictionary = artifacts[index]
		if str(artifact.get("attack_type", "")) == "orbit":
			continue
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
	var attribute_modifier: AttributeSynergyModifier = synergy_manager.get_attribute_modifier()
	var damage: float = _effective_damage(artifact) * attribute_modifier.damage_multiplier(owner_player)
	var modifier: TypeSynergyModifier = synergy_manager.get_type_modifier()

	if attack_type == "scatter_projectile":
		_fire_scatter(target, damage * modifier.projectile_damage_multiplier(), attack_type, modifier)
		return
	if attack_type == "bounce_projectile":
		_fire_projectile_pattern(target, damage * modifier.projectile_damage_multiplier(), _with_attribute_options({"attack_type": "chain_projectile", "chain_count": 2, "chain_radius": 140.0}, attribute_modifier, damage), modifier)
		return
	if attack_type == "area":
		_apply_repeated_area_damage(target.global_position, damage, 82.0 * modifier.area_radius_multiplier(), modifier.area_instance_count(), Color(0.9, 0.7, 0.2, 0.28), attribute_modifier)
		# TODO: use modifier.area_duration_multiplier() when persistent area nodes exist.
		return
	if attack_type == "body_strike":
		_apply_body_strike(target.global_position, damage, modifier)
		return
	if attack_type == "melee":
		_apply_melee_attack(artifact, target.global_position, damage, modifier)
		return
	if attack_type == "orbit":
		return
	if attack_type == "summon":
		for _summon_index in modifier.summon_count():
			for _repeat_index in modifier.summon_attack_repeat_count():
				_fire_projectile(target, damage, _with_attribute_options({"attack_type": "projectile"}, attribute_modifier, damage))
		# TODO: replace direct shots with persistent summon units.
		return

	var options: Dictionary = {"attack_type": attack_type}
	if attack_type == "explosive_projectile":
		options["explosion_radius"] = 72.0 * synergy_manager.explosion_radius_multiplier()
	elif attack_type == "chain_projectile":
		options["chain_count"] = 2 + synergy_manager.chain_bonus()
		options["chain_radius"] = 125.0

	_fire_projectile_pattern(target, damage * modifier.projectile_damage_multiplier(), _with_attribute_options(options, attribute_modifier, damage), modifier)

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
			var attribute_modifier: AttributeSynergyModifier = synergy_manager.get_attribute_modifier()
			_fire_projectile_to_position(target_position, damage, _with_attribute_options({"attack_type": attack_type}, attribute_modifier, damage))

func _apply_melee_attack(artifact: Dictionary, center: Vector2, damage: float, modifier: TypeSynergyModifier) -> void:
	var radius: float = 58.0
	var attribute_modifier: AttributeSynergyModifier = synergy_manager.get_attribute_modifier()
	_apply_area_damage(center, damage, radius, Color(0.95, 0.95, 1.0, 0.25), attribute_modifier)

	var interval: int = modifier.melee_combo_interval()
	if interval <= 0:
		return

	var artifact_id: String = str(artifact.get("id", ""))
	melee_attack_counts[artifact_id] = int(melee_attack_counts.get(artifact_id, 0)) + 1
	if int(melee_attack_counts[artifact_id]) % interval != 0:
		return

	_apply_area_damage(center, damage * modifier.melee_extra_damage_multiplier(), radius * 1.15, Color(1.0, 1.0, 0.45, 0.28), attribute_modifier)
	if modifier.melee_extra_can_chain():
		# Simple prototype cap: one chained extra slash. Full recursive proc rules can be added here.
		_apply_area_damage(center, damage * modifier.melee_extra_damage_multiplier(), radius * 1.3, Color(1.0, 0.8, 0.35, 0.2), attribute_modifier)

func _apply_body_strike(center: Vector2, damage: float, modifier: TypeSynergyModifier) -> void:
	var attribute_modifier: AttributeSynergyModifier = synergy_manager.get_attribute_modifier()
	var radius: float = 64.0 * modifier.body_strike_radius_multiplier()
	_apply_area_damage(center, damage, radius, Color(1.0, 0.25, 0.18, 0.28), attribute_modifier)
	for echo_index in modifier.body_strike_echo_count():
		var echo_multiplier: float = 0.5
		_apply_area_damage(center, damage * echo_multiplier, radius * (1.1 + 0.15 * float(echo_index)), Color(1.0, 0.55, 0.35, 0.2), attribute_modifier)

func _apply_repeated_area_damage(center: Vector2, damage: float, radius: float, count: int, color: Color, attribute_modifier: AttributeSynergyModifier) -> void:
	for area_index in count:
		_apply_area_damage(center, damage, radius + 18.0 * float(area_index), color, attribute_modifier)

func _apply_area_damage(center: Vector2, damage: float, radius: float, color: Color, attribute_modifier: AttributeSynergyModifier = null, apply_attribute_effects: bool = true) -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and center.distance_to(body.global_position) <= radius:
			var enemy: Enemy = body
			if apply_attribute_effects:
				_damage_enemy(enemy, damage, attribute_modifier)
			else:
				enemy.take_damage(damage)
	_spawn_debug_circle(center, radius, color)

func _damage_enemy(enemy: Enemy, damage: float, attribute_modifier: AttributeSynergyModifier = null) -> bool:
	if attribute_modifier == null:
		attribute_modifier = synergy_manager.get_attribute_modifier()
	var final_damage: float = damage * attribute_modifier.metal_execute_damage_multiplier(enemy)
	enemy.apply_poison(attribute_modifier.poison_damage_per_second(damage), 4.0, attribute_modifier.poison_can_stack())
	var killed: bool = enemy.take_damage(final_damage)
	var lifesteal_ratio: float = attribute_modifier.dark_lifesteal_ratio()
	if lifesteal_ratio > 0.0:
		owner_player.heal(final_damage * lifesteal_ratio)
	if attribute_modifier.fire_explosion_radius() > 0.0:
		_attribute_fire_explosion(enemy.global_position, damage, attribute_modifier)
	if attribute_modifier.thunder_chain_count() > 0:
		_attribute_thunder_chain(enemy, damage, attribute_modifier)
	if killed and attribute_modifier.metal_execute_on_kill():
		_apply_area_damage(enemy.global_position, damage * 0.8, 72.0, Color(1.0, 0.95, 0.35, 0.22), null, false)
	return killed

func _attribute_fire_explosion(center: Vector2, damage: float, attribute_modifier: AttributeSynergyModifier) -> void:
	var radius: float = attribute_modifier.fire_explosion_radius()
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and center.distance_to(body.global_position) <= radius:
			var enemy: Enemy = body
			enemy.take_damage(damage * 0.35)
	_spawn_debug_circle(center, radius, Color(1.0, 0.22, 0.08, 0.18))
	if attribute_modifier.fire_explosion_can_chain():
		# TODO: replace this visual-only secondary pulse with true explosion propagation rules.
		_spawn_debug_circle(center, radius * 1.35, Color(1.0, 0.1, 0.02, 0.12))

func _attribute_thunder_chain(first_enemy: Enemy, damage: float, attribute_modifier: AttributeSynergyModifier) -> void:
	var source_position: Vector2 = first_enemy.global_position
	var hit_enemies: Array[Enemy] = [first_enemy]
	for chain_index in attribute_modifier.thunder_chain_count():
		var next_enemy: Enemy = _find_chain_target(source_position, hit_enemies, attribute_modifier.thunder_can_repeat_target())
		if next_enemy == null:
			return
		hit_enemies.append(next_enemy)
		next_enemy.take_damage(damage * pow(0.7, float(chain_index + 1)))
		_spawn_debug_line(source_position, next_enemy.global_position)
		source_position = next_enemy.global_position

func _find_chain_target(source_position: Vector2, hit_enemies: Array[Enemy], can_repeat_target: bool) -> Enemy:
	var best: Enemy = null
	var best_distance: float = INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and (can_repeat_target or not hit_enemies.has(body)):
			var distance: float = source_position.distance_to(body.global_position)
			if distance < best_distance and distance <= 130.0:
				best = body
				best_distance = distance
	return best

func _with_attribute_options(options: Dictionary, attribute_modifier: AttributeSynergyModifier, base_damage: float) -> Dictionary:
	var next_options: Dictionary = options.duplicate(true)
	next_options["owner_player"] = owner_player
	next_options["pierce_remaining"] = int(next_options.get("pierce_remaining", 0)) + attribute_modifier.metal_pierce_bonus()
	next_options["extra_explosion_radius"] = attribute_modifier.fire_explosion_radius()
	next_options["extra_explosion_can_chain"] = attribute_modifier.fire_explosion_can_chain()
	next_options["extra_chain_count"] = int(next_options.get("extra_chain_count", 0)) + attribute_modifier.thunder_chain_count()
	next_options["chain_can_repeat_target"] = attribute_modifier.thunder_can_repeat_target()
	next_options["poison_dps"] = attribute_modifier.poison_damage_per_second(base_damage)
	next_options["poison_duration"] = 4.0
	next_options["poison_can_stack"] = attribute_modifier.poison_can_stack()
	next_options["poison_spread_on_death"] = attribute_modifier.poison_spread_on_death()
	next_options["lifesteal_ratio"] = attribute_modifier.dark_lifesteal_ratio()
	next_options["execute_threshold"] = 0.3 if attribute_modifier.get_tier("金") >= 4 else 0.0
	next_options["execute_multiplier"] = 1.5
	return next_options

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

func _spawn_debug_line(from: Vector2, to: Vector2) -> void:
	var line: Line2D = Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.6, 0.9, 1.0, 0.8)
	line.points = PackedVector2Array([from, to])
	get_tree().current_scene.add_child(line)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.14)
	tween.tween_callback(line.queue_free)

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

func _spawn_orbiting_artifacts(artifact: Dictionary) -> void:
	if orbiting_artifact_scene == null:
		return

	var modifier: TypeSynergyModifier = synergy_manager.get_type_modifier()
	var config: Dictionary = _orbit_config_for_artifact(str(artifact.get("id", "")))
	var ring_count: int = modifier.orbit_ring_count()
	var object_count: int = modifier.orbit_object_count()
	var base_radius: float = float(config.get("radius", 86.0))
	var base_speed: float = float(config.get("speed", 3.0)) * modifier.orbit_speed_multiplier()
	var damage: float = _effective_damage(artifact) * synergy_manager.get_attribute_modifier().damage_multiplier(owner_player)
	var hit_interval: float = float(config.get("hit_interval", 0.35))
	var knockback: float = float(config.get("knockback", 0.0))
	var clockwise: bool = bool(config.get("clockwise", true))
	var color: Color = config.get("color", Color(0.4, 0.85, 1.0, 1.0))
	var size: float = float(config.get("size", 8.0))

	for ring_index in ring_count:
		var radius: float = base_radius + float(ring_index) * 38.0
		var ring_clockwise: bool = clockwise if ring_index % 2 == 0 else not clockwise
		for object_index in object_count:
			var start_angle: float = TAU * float(object_index) / float(object_count)
			if ring_count > 1:
				start_angle += float(ring_index) * PI / float(object_count)
			var node: OrbitingArtifactNode = orbiting_artifact_scene.instantiate() as OrbitingArtifactNode
			projectile_container.add_child(node)
			node.configure(owner_player, start_angle, radius, base_speed, ring_clockwise, damage, hit_interval, knockback, -1.0, color, size)
			orbit_nodes.append(node)

func _clear_orbit_nodes() -> void:
	for node in orbit_nodes:
		if is_instance_valid(node):
			node.queue_free()
	orbit_nodes.clear()

func _orbit_config_for_artifact(artifact_id: String) -> Dictionary:
	match artifact_id:
		"moon_wheel":
			return {"radius": 78.0, "speed": 6.5, "clockwise": true, "hit_interval": 0.22, "knockback": 0.0, "color": Color(0.55, 0.9, 1.0, 1.0), "size": 7.0}
		"flying_wheel":
			return {"radius": 118.0, "speed": 2.2, "clockwise": true, "hit_interval": 0.45, "knockback": 60.0, "color": Color(0.95, 0.8, 0.25, 1.0), "size": 11.0}
		"buddha_beads":
			return {"radius": 74.0, "speed": 3.8, "clockwise": false, "hit_interval": 0.28, "knockback": 0.0, "color": Color(0.75, 0.62, 0.38, 1.0), "size": 8.0}
		"bronze_bell":
			return {"radius": 106.0, "speed": 1.8, "clockwise": false, "hit_interval": 0.55, "knockback": 210.0, "color": Color(0.8, 0.55, 0.25, 1.0), "size": 12.0}
		_:
			return {"radius": 86.0, "speed": 3.0, "clockwise": true, "hit_interval": 0.35, "knockback": 0.0, "color": Color(0.4, 0.85, 1.0, 1.0), "size": 8.0}

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
