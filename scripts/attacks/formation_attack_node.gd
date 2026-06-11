extends Area2D
class_name FormationAttackNode

var player: Node2D
var data: ArtifactData
var tick_remaining: float = 0.0
var damaged_connected: bool = false

func setup(owner_player: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	data = artifact_data
	global_position = player.global_position
	z_index = 1
	if data.id == "golden_body_avatar":
		z_index = -1
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = data.radius
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var visual: Node2D = ArtifactVisuals.make_formation_visual(data)
	add_child(visual)
	if data.effect_type == "counter_damage" and player.has_signal("damaged"):
		player.damaged.connect(_on_player_damaged)
		damaged_connected = true

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	if data.effect_type == "counter_damage":
		return
	tick_remaining -= delta
	if tick_remaining > 0.0:
		return
	tick_remaining = maxf(0.05, data.tick_interval)
	if data.effect_type == "attack_speed" and player.has_method("set_artifact_cooldown_multiplier"):
		player.call("set_artifact_cooldown_multiplier", maxf(0.1, 1.0 - data.attack_speed_bonus))
		if player.has_method("set_artifact_move_speed_multiplier"):
			player.call("set_artifact_move_speed_multiplier", 1.0 + data.movement_speed_bonus)
	elif data.effect_type == "heal" and player.has_method("heal"):
		player.call("heal", data.heal_amount)
	elif data.effect_type == "shield" and player.has_method("add_shield"):
		player.call("add_shield", data.shield_amount, data.shield_max)
		if data.shield_knockback_force > 0.0:
			_knockback_nearby_enemies()
		HitEffectManager.spawn_hit(get_tree(), player.global_position, "shield", Vector2.RIGHT, data.radius)
	if data.effect_type == "avatar_slam":
		HitEffectManager.spawn_hit(get_tree(), player.global_position, _formation_hit_kind(), Vector2.RIGHT, data.radius)
		_damage_overlapping_bodies()
	else:
		_damage_overlapping_bodies()

func _damage_overlapping_bodies() -> void:
	for body in get_overlapping_bodies():
		if data.damage > 0.0 and body.has_method("take_damage"):
			var hit_damage: float = _get_damage()
			var killed: bool = bool(body.call("take_damage", hit_damage, player))
			_notify_artifact_damage()
			if killed and data.kill_heal_amount > 0.0 and player.has_method("heal"):
				player.call("heal", data.kill_heal_amount)
			if data.heal_amount > 0.0 and player.has_method("heal"):
				player.call("heal", data.heal_amount)
			if body is Node2D:
				HitEffectManager.spawn_hit(get_tree(), (body as Node2D).global_position, _formation_hit_kind(), Vector2.RIGHT, 12.0)
		if data.effect_type == "slow" and body.has_method("apply_slow"):
			body.call("apply_slow", data.slow_percent, data.tick_interval * 1.5, self)

func _formation_hit_kind() -> String:
	match data.id:
		"thorn_armor":
			return "fire"
		"body_barrier":
			return "flash"
		"golden_body_avatar":
			return "earth"
		_:
			return "flash"

func _circle_points(radius: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for index in 40:
		var angle: float = TAU * float(index) / 40.0
		var wobble: float = 1.0 if index % 2 == 0 else 0.88
		points.append(Vector2(cos(angle), sin(angle)) * radius * wobble)
	return points

func _exit_tree() -> void:
	if damaged_connected and is_instance_valid(player):
		player.damaged.disconnect(_on_player_damaged)
	if data != null and data.effect_type == "attack_speed" and is_instance_valid(player):
		if player.has_method("set_artifact_cooldown_multiplier"):
			player.call("set_artifact_cooldown_multiplier", 1.0)
		if player.has_method("set_artifact_move_speed_multiplier"):
			player.call("set_artifact_move_speed_multiplier", 1.0)

func _knockback_nearby_enemies() -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("apply_knockback"):
			if player.global_position.distance_to((candidate as Node2D).global_position) <= data.radius:
				candidate.call("apply_knockback", player.global_position, data.shield_knockback_force)

func _on_player_damaged(_amount: float) -> void:
	if data == null or data.effect_type != "counter_damage":
		return
	_damage_overlapping_bodies()
	HitEffectManager.spawn_hit(get_tree(), player.global_position, _formation_hit_kind(), Vector2.RIGHT, data.radius)

func _get_damage() -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, data.damage))
	return data.damage

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)
