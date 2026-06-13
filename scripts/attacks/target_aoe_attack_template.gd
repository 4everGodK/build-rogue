extends RefCounted
class_name TargetAoeAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, target: Node2D) -> void:
	var attack: Node = load("res://scripts/attacks/target_aoe_attack_node.gd").new()
	container.add_child(attack)
	attack.setup(player, data, target)
