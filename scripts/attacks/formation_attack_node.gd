extends Area2D
class_name FormationAttackNode

var player: Node2D
var data: ArtifactData
var tick_remaining: float = 0.0

func setup(owner_player: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	data = artifact_data
	global_position = player.global_position
	z_index = -1
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	var shape := CircleShape2D.new()
	shape.radius = data.radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	if data.visual_color.a > 0.0:
		var visual := Polygon2D.new()
		visual.polygon = _circle_points(data.radius)
		visual.color = data.visual_color
		add_child(visual)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	tick_remaining -= delta
	if tick_remaining > 0.0:
		return
	tick_remaining = maxf(0.05, data.tick_interval)
	if data.effect_type == "attack_speed" and player.has_method("set_artifact_cooldown_multiplier"):
		player.call("set_artifact_cooldown_multiplier", maxf(0.1, 1.0 - data.attack_speed_bonus))
	elif data.effect_type == "heal" and player.has_method("heal"):
		player.call("heal", data.heal_amount)
	elif data.effect_type == "shield" and player.has_method("add_shield"):
		player.call("add_shield", data.shield_amount, data.shield_max)
	for body in get_overlapping_bodies():
		if data.effect_type == "damage" and body.has_method("take_damage"):
			body.call("take_damage", data.damage, player)
		elif data.effect_type == "slow" and body.has_method("apply_slow"):
			body.call("apply_slow", data.slow_percent, data.tick_interval * 1.5, self)

func _circle_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 40:
		var angle := TAU * float(index) / 40.0
		var wobble := 1.0 if index % 2 == 0 else 0.88
		points.append(Vector2(cos(angle), sin(angle)) * radius * wobble)
	return points

func _exit_tree() -> void:
	if data != null and data.effect_type == "attack_speed" and is_instance_valid(player):
		if player.has_method("set_artifact_cooldown_multiplier"):
			player.call("set_artifact_cooldown_multiplier", 1.0)
