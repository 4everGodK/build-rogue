extends RefCounted
class_name SoulBannerAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, target: Node2D) -> void:
	var attack: Node = load("res://scripts/attacks/soul_banner_attack_node.gd").new()
	container.add_child(attack)
	attack.setup(player, data, target)
