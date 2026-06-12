extends Node
class_name ArtifactManager

const INITIAL_MAX_ARTIFACTS: int = 5

var owner_player: Node2D
var attack_container: Node
var synergy_manager: SynergyManager
var artifacts: Array[ArtifactInstance] = []
var battle_paused: bool = true

func configure(player: Node2D, container: Node) -> void:
	owner_player = player
	attack_container = container
	for instance in artifacts:
		instance.start(owner_player, attack_container)

func set_synergy_manager(manager: SynergyManager) -> void:
	synergy_manager = manager

func notify_artifact_damage(data: ArtifactData) -> void:
	if synergy_manager != null:
		synergy_manager.notify_artifact_damage(data)

func apply_attribute_on_hit(data: ArtifactData, target: Node, base_damage: float, source: Node = null, hit_position: Vector2 = Vector2.ZERO, pre_hit_hp_ratio: float = -1.0) -> void:
	if synergy_manager != null:
		synergy_manager.apply_attribute_on_hit(data, target, base_damage, source, hit_position, pre_hit_hp_ratio)

func get_sword_artifact_cooldown_multiplier(data: ArtifactData) -> float:
	if synergy_manager == null or data == null or data.system_tag != "剑修":
		return 1.0
	return synergy_manager.get_sword_cooldown_multiplier()

func clear_artifacts() -> void:
	for instance in artifacts:
		instance.dispose()
	artifacts.clear()

func sync_from_battle_slots(battle_slots: Array) -> void:
	clear_artifacts()
	for raw_stack in battle_slots:
		var stack: ArtifactStack = raw_stack as ArtifactStack
		if stack == null or stack.artifact_data == null:
			continue
		var instance: ArtifactInstance = ArtifactInstance.new(stack.artifact_data, stack.star_level, synergy_manager)
		artifacts.append(instance)
		if is_instance_valid(owner_player) and is_instance_valid(attack_container):
			instance.start(owner_player, attack_container)
			if battle_paused and is_instance_valid(instance.persistent_node) and instance.persistent_node.has_method("set_battle_paused"):
				instance.persistent_node.call("set_battle_paused", true)

func set_battle_paused(paused: bool) -> void:
	battle_paused = paused
	for instance in artifacts:
		if is_instance_valid(instance.persistent_node) and instance.persistent_node.has_method("set_battle_paused"):
			instance.persistent_node.call("set_battle_paused", paused)

func refresh_persistent_artifacts() -> void:
	for instance in artifacts:
		instance.start(owner_player, attack_container)

func _process(delta: float) -> void:
	if not is_instance_valid(owner_player) or not is_instance_valid(attack_container):
		return
	if battle_paused:
		return
	var target_reservations: Dictionary = {}
	for instance in artifacts:
		instance.update(delta, owner_player, attack_container, target_reservations)
