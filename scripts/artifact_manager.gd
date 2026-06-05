extends Node
class_name ArtifactManager

const MAX_ARTIFACTS: int = 9

var owner_player: Node2D
var attack_container: Node
var artifacts: Array[ArtifactInstance] = []
var battle_paused: bool = true

func configure(player: Node2D, container: Node) -> void:
	owner_player = player
	attack_container = container
	for instance in artifacts:
		instance.start(owner_player, attack_container)

func clear_artifacts() -> void:
	for instance in artifacts:
		instance.dispose()
	artifacts.clear()

func sync_from_battle_slots(battle_slots: Array) -> void:
	clear_artifacts()
	for raw_stack in battle_slots:
		var stack := raw_stack as ArtifactStack
		if stack == null or stack.artifact_data == null:
			continue
		var instance := ArtifactInstance.new(stack.artifact_data, stack.star_level)
		artifacts.append(instance)
		if is_instance_valid(owner_player) and is_instance_valid(attack_container):
			instance.start(owner_player, attack_container)

func set_battle_paused(paused: bool) -> void:
	battle_paused = paused

func refresh_persistent_artifacts() -> void:
	for instance in artifacts:
		instance.start(owner_player, attack_container)

func _process(delta: float) -> void:
	if not is_instance_valid(owner_player) or not is_instance_valid(attack_container):
		return
	if battle_paused:
		return
	for instance in artifacts:
		instance.update(delta, owner_player, attack_container)
