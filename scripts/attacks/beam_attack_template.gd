extends RefCounted
class_name BeamAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, target: Node2D) -> void:
	var beam := BeamAttackNode.new()
	container.add_child(beam)
	beam.setup(player, target, data)
