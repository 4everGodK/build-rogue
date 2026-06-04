extends RefCounted
class_name OrbitAttackTemplate

static func create(player: Node2D, container: Node, data: ArtifactData) -> Node:
	var orbit := OrbitAttackNode.new()
	container.add_child(orbit)
	orbit.setup(player, data)
	return orbit
