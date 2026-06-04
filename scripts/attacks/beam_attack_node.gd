extends Node2D
class_name BeamAttackNode

var player: Node2D
var target: Node2D
var data: ArtifactData
var time_left: float
var tick_remaining: float = 0.0
var line: Line2D

func setup(owner_player: Node2D, initial_target: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	target = initial_target
	data = artifact_data
	time_left = maxf(0.05, data.duration)
	line = Line2D.new()
	line.width = maxf(2.0, data.radius)
	line.default_color = data.visual_color
	add_child(line)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(target):
		queue_free()
		return
	line.points = PackedVector2Array([player.global_position, target.global_position])
	time_left -= delta
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = maxf(0.05, data.tick_interval)
		target.call("take_damage", data.damage, player)
	if time_left <= 0.0:
		queue_free()
