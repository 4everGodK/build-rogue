extends Node
class_name ArtifactController

@export var projectile_scene: PackedScene

var owner_player: Player
var projectile_container: Node2D
var synergy_manager: SynergyManager
var artifacts: Array[Dictionary] = []
var cooldowns: Array[float] = []

func configure(player: Player, container: Node2D, synergies: SynergyManager) -> void:
	owner_player = player
	projectile_container = container
	synergy_manager = synergies

func set_artifacts(next_artifacts: Array) -> void:
	artifacts = next_artifacts.duplicate(true)
	while cooldowns.size() < artifacts.size():
		var artifact: Dictionary = artifacts[cooldowns.size()]
		cooldowns.append(randf_range(0.05, artifact.get("cooldown", 1.0)))
	if cooldowns.size() > artifacts.size():
		cooldowns.resize(artifacts.size())

func _process(delta: float) -> void:
	if not is_instance_valid(owner_player) or projectile_scene == null:
		return

	for index in artifacts.size():
		var artifact: Dictionary = artifacts[index]
		cooldowns[index] -= delta
		if cooldowns[index] <= 0.0:
			_try_attack(artifact)
			cooldowns[index] = artifact.get("cooldown", 1.0)

func _try_attack(artifact: Dictionary) -> void:
	var target: Enemy = _find_nearest_enemy()
	if target == null:
		return

	# Attack behavior is selected by data, so Player stays unaware of artifact types.
	var attack_type: String = artifact.get("attack_type", "projectile")
	var damage: float = float(artifact.get("damage", 1.0))
	if attack_type == "projectile":
		damage *= synergy_manager.projectile_damage_multiplier()

	var options: Dictionary = {"attack_type": attack_type}
	if attack_type == "explosive_projectile":
		options["explosion_radius"] = 72.0 * synergy_manager.explosion_radius_multiplier()
	elif attack_type == "chain_projectile":
		options["chain_count"] = 2 + synergy_manager.chain_bonus()
		options["chain_radius"] = 125.0

	var projectile: Projectile = projectile_scene.instantiate() as Projectile
	projectile_container.add_child(projectile)
	projectile.setup(owner_player.global_position, target.global_position, damage, options)

func _find_nearest_enemy() -> Enemy:
	var nearest: Enemy = null
	var nearest_distance: float = INF
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy:
			var distance: float = owner_player.global_position.distance_to(body.global_position)
			if distance < nearest_distance:
				nearest = body
				nearest_distance = distance
	return nearest
