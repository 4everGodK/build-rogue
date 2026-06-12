extends Node2D
class_name BeamAttackNode

var player: Node2D
var target: Node2D
var data: ArtifactData
var time_left: float
var tick_remaining: float = 0.0
var line: Line2D
var eye_visual: Node2D

func setup(owner_player: Node2D, initial_target: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	target = initial_target
	data = artifact_data
	time_left = maxf(0.05, data.duration)
	line = Line2D.new()
	line.width = maxf(2.0, data.radius)
	line.default_color = Color(1.0, 0.04, 0.08, 0.88) if data.id == "heaven_eye" else data.visual_color
	add_child(line)
	eye_visual = ArtifactVisuals.make_eye_visual()
	add_child(eye_visual)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(target):
		queue_free()
		return
	var eye_position := player.global_position + Vector2(0, -58)
	if is_instance_valid(eye_visual):
		eye_visual.global_position = eye_position
		eye_visual.rotation += delta * 2.0
	line.points = PackedVector2Array([eye_position, target.global_position])
	time_left -= delta
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = maxf(0.05, data.tick_interval)
		if data.life_cost_percent > 0.0 and player.has_method("spend_life_percent"):
			player.call("spend_life_percent", data.life_cost_percent)
		if data.life_cost_flat > 0.0 and player.has_method("spend_life_flat"):
			player.call("spend_life_flat", data.life_cost_flat, data.life_cost_min_hp_ratio)
		var hit_damage: float = _get_damage()
		var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(target)
		var killed: bool = bool(target.call("take_damage", hit_damage, player))
		_notify_artifact_damage()
		_apply_attribute_on_hit(target, hit_damage, target.global_position, pre_hit_hp_ratio)
		if killed and data.kill_heal_amount > 0.0 and player.has_method("heal"):
			player.call("heal", data.kill_heal_amount)
		HitEffectManager.spawn_hit(get_tree(), target.global_position, "blood" if data.id == "heaven_eye" else "flash", eye_position.direction_to(target.global_position), 12.0)
	if time_left <= 0.0:
		queue_free()

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attribute_on_hit(hit_target: Node, base_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float = -1.0) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, hit_target, base_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(hit_target: Node) -> float:
	if hit_target != null and hit_target.has_method("get_hp_ratio"):
		return float(hit_target.call("get_hp_ratio"))
	return -1.0

func _get_damage() -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, data.damage))
	return data.damage
