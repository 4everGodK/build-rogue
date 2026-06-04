extends RefCounted
class_name ArtifactInstance

var data: ArtifactData
var cooldown_remaining: float = 0.0
var persistent_node: Node

func _init(artifact_data: ArtifactData = null) -> void:
	data = artifact_data
	if data != null:
		cooldown_remaining = randf_range(0.05, maxf(0.05, data.cooldown))

func start(player: Node2D, attack_container: Node) -> void:
	if data == null or is_instance_valid(persistent_node):
		return
	match data.attack_template:
		"orbit":
			persistent_node = OrbitAttackTemplate.create(player, attack_container, data)
		"formation":
			persistent_node = FormationAttackTemplate.create(player, attack_container, data)
		"summon":
			persistent_node = SummonAttackTemplate.create(player, attack_container, data)

func update(delta: float, player: Node2D, attack_container: Node) -> void:
	if data == null:
		return
	if data.attack_template in ["orbit", "formation", "summon"]:
		start(player, attack_container)
		return

	cooldown_remaining -= delta
	if cooldown_remaining > 0.0:
		return

	var target: Node2D = find_nearest_enemy(player)
	if target == null:
		return

	var direction: Vector2 = player.global_position.direction_to(target.global_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	match data.attack_template:
		"melee":
			MeleeAttackTemplate.execute(player, attack_container, data, direction)
		"projectile":
			ProjectileAttackTemplate.execute(player, attack_container, data, direction)
		"beam":
			BeamAttackTemplate.execute(player, attack_container, data, target)
	cooldown_remaining = maxf(0.05, data.cooldown)

func dispose() -> void:
	if is_instance_valid(persistent_node):
		persistent_node.queue_free()
	persistent_node = null

static func find_nearest_enemy(player: Node2D) -> Node2D:
	var nearest: Node2D
	var nearest_distance_squared: float = INF
	for candidate in player.get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		var distance_squared := player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = enemy
			nearest_distance_squared = distance_squared
	return nearest
