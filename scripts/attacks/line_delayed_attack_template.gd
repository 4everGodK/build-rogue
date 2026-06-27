extends RefCounted
class_name LineDelayedAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2) -> void:
	if data.id == "brush":
		var brush_attack: Node = load("res://scripts/attacks/brush_attack_node.gd").new()
		container.add_child(brush_attack)
		brush_attack.setup(player, data, direction)
		return
	var attack := LineDelayedAttackNode.new()
	container.add_child(attack)
	attack.setup(player, data, direction)
