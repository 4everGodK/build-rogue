extends RefCounted
class_name LineDelayedAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2) -> void:
	var attack := LineDelayedAttackNode.new()
	container.add_child(attack)
	attack.setup(player, data, direction)
