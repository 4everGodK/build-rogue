extends RefCounted
class_name FormationAttackTemplate

static func create(player: Node2D, container: Node, data: ArtifactData) -> Node:
	var formation := FormationAttackNode.new()
	container.add_child(formation)
	formation.setup(player, data)
	return formation
