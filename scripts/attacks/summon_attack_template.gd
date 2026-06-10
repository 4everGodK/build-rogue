extends RefCounted
class_name SummonAttackTemplate

static func create(player: Node2D, container: Node, data: ArtifactData) -> Node:
	var controller := SummonController.new()
	container.add_child(controller)
	controller.setup(player, data)
	return controller
