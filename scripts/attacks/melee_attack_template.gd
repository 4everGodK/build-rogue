extends RefCounted
class_name MeleeAttackTemplate

static func execute(player: Node2D, container: Node, data: ArtifactData, direction: Vector2) -> void:
	if data.id == "fire_gourd":
		var attack: Node = load("res://scripts/attacks/fire_gourd_attack_node.gd").new()
		container.add_child(attack)
		attack.setup(player, data, direction)
		return
	if data.id == "blood_sword":
		var attack: Node = load("res://scripts/attacks/blood_sword_attack_node.gd").new()
		container.add_child(attack)
		attack.setup(player, data, direction)
		return
	if data.id == "scythe":
		var attack: Node = load("res://scripts/attacks/scythe_attack_node.gd").new()
		container.add_child(attack)
		attack.setup(player, data, direction)
		return
	var attack := MeleeAttackNode.new()
	container.add_child(attack)
	attack.setup(player, data, direction)
