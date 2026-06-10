extends RefCounted
class_name ProjectileAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2, extra_count: int = 0, extra_damage_multiplier: float = 0.0, extra_directions: Array[Vector2] = []) -> void:
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
