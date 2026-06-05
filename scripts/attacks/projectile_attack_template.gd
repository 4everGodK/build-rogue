extends RefCounted
class_name ProjectileAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2, extra_count: int = 0, extra_damage_multiplier: float = 0.0) -> void:
	var base_count: int = maxi(1, data.count)
	var total_count: int = base_count + maxi(0, extra_count)
	for index in range(total_count):
		var projectile := ArtifactProjectile.new()
		container.add_child(projectile)
		var projectile_data := data
		if index >= base_count:
			projectile_data = data.duplicate(true)
			projectile_data.damage *= extra_damage_multiplier
		var centered_index := float(index) - float(total_count - 1) * 0.5
		projectile.setup(player, direction.rotated(centered_index * 0.12), projectile_data)
