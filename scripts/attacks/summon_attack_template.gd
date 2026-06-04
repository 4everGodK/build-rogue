extends RefCounted
class_name SummonAttackTemplate

# Phase two hook. Returning null keeps summon artifacts from blocking the core system.
static func create(_player: Node2D, _container: Node, _data: ArtifactData) -> Node:
	return null
