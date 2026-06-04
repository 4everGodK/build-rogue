extends RefCounted
class_name MeleeAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2) -> void:
	var attack := MeleeAttackNode.new()
	container.add_child(attack)
	attack.setup(player, data, direction)
