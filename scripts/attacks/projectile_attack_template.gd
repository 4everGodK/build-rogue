extends RefCounted
class_name ProjectileAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2, extra_count: int = 0, extra_damage_multiplier: float = 0.0, extra_directions: Array[Vector2] = []) -> void:
	if data.id == "magic_ring":
		var ring_attack: Node = load("res://scripts/attacks/magic_ring_attack_node.gd").new()
		container.add_child(ring_attack)
		ring_attack.setup(player, data, direction)
		return
	if data.id == "guqin":
		var guqin_attack: Node = load("res://scripts/attacks/guqin_attack_node.gd").new()
		container.add_child(guqin_attack)
		guqin_attack.setup(player, data, direction)
		return
	if data.id == "flying_sword" and int(data.get_meta("star_level", 1)) >= 3:
		_execute_triple_flying_sword(player, container, data, direction)
		return
	var base_count: int = maxi(1, data.count)
	var extra_to_fire: int = mini(maxi(0, extra_count), extra_directions.size())
	var total_count: int = base_count + extra_to_fire
	for index in range(total_count):
		var projectile: ArtifactProjectile = ArtifactProjectile.new()
		container.add_child(projectile)
		var projectile_data := data
		var projectile_direction: Vector2 = direction.rotated(_spread_angle(index))
		if index >= base_count:
			projectile_data = data.duplicate(true)
			projectile_data.damage *= extra_damage_multiplier
			projectile_direction = extra_directions[index - base_count]
		projectile.setup(player, projectile_direction, projectile_data)

static func _spread_angle(index: int) -> float:
	if index == 0:
		return 0.0
	var side: float = -1.0 if index % 2 == 1 else 1.0
	var step: float = float((index + 1) / 2)
	return side * step * 0.12

static func _execute_triple_flying_sword(player: Node2D, container: Node, data: ArtifactData, direction: Vector2) -> void:
	var fan: float = deg_to_rad(data.fan_angle if data.fan_angle > 0.0 else 26.0)
	var angles: Array[float] = [-fan * 0.5, 0.0, fan * 0.5]
	for index in angles.size():
		var projectile_data: ArtifactData = data.duplicate(true) as ArtifactData
		projectile_data.damage *= 1.0 if index == 1 else maxf(0.0, data.side_projectile_damage_mult)
		projectile_data.set_meta("flying_sword_side_index", index - 1)
		var projectile: ArtifactProjectile = ArtifactProjectile.new()
		container.add_child(projectile)
		projectile.setup(player, direction.rotated(angles[index]), projectile_data)
