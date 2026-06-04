extends Node
class_name ArtifactManager

const MAX_ARTIFACTS: int = 9

var owner_player: Node2D
var attack_container: Node
var artifacts: Array[ArtifactInstance] = []

func configure(player: Node2D, container: Node) -> void:
	owner_player = player
	attack_container = container
	for instance in artifacts:
		instance.start(owner_player, attack_container)

func add_artifact(data: ArtifactData) -> bool:
	if data == null or artifacts.size() >= MAX_ARTIFACTS:
		return false
	var instance := ArtifactInstance.new(data)
	artifacts.append(instance)
	if is_instance_valid(owner_player) and is_instance_valid(attack_container):
		instance.start(owner_player, attack_container)
	return true

func clear_artifacts() -> void:
	for instance in artifacts:
		instance.dispose()
	artifacts.clear()

func refresh_persistent_artifacts() -> void:
	for instance in artifacts:
		instance.start(owner_player, attack_container)

func _process(delta: float) -> void:
	if not is_instance_valid(owner_player) or not is_instance_valid(attack_container):
		return
	for instance in artifacts:
		instance.update(delta, owner_player, attack_container)
