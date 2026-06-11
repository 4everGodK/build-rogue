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
		target.call("take_damage", data.damage, player)
		_notify_artifact_damage()
		HitEffectManager.spawn_hit(get_tree(), target.global_position, "blood" if data.id == "heaven_eye" else "flash", eye_position.direction_to(target.global_position), 12.0)
	if time_left <= 0.0:
		queue_free()

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)
