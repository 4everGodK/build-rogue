extends RefCounted
class_name ProjectileAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2) -> void:
	for index in maxi(1, data.count):
		var projectile := ArtifactProjectile.new()
		container.add_child(projectile)
		var centered_index := float(index) - float(maxi(1, data.count) - 1) * 0.5
		projectile.setup(player, direction.rotated(centered_index * 0.12), data)
