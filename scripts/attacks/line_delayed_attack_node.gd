extends Node2D
class_name LineDelayedAttackNode

var player: Node2D
var data: ArtifactData
var direction: Vector2
var warning_line: Line2D

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	direction = attack_direction.normalized()
	warning_line = Line2D.new()
	warning_line.width = maxf(2.0, data.width * 0.2)
	warning_line.default_color = Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.3)
	warning_line.points = PackedVector2Array([player.global_position, player.global_position + direction * data.length])
	add_child(warning_line)
	_run_sequence()

func _run_sequence() -> void:
	await get_tree().create_timer(data.delayed_strike_delay).timeout
	if is_instance_valid(warning_line):
		warning_line.queue_free()
	for index in maxi(1, data.delayed_strike_count):
		if not is_instance_valid(player):
			queue_free()
			return
		var center := player.global_position + direction * data.length * (float(index) + 0.5) / float(maxi(1, data.delayed_strike_count))
		_strike(center)
		await get_tree().create_timer(data.delayed_strike_interval).timeout
	queue_free()

func _strike(center: Vector2) -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if center.distance_to((candidate as Node2D).global_position) <= data.radius:
				candidate.call("take_damage", data.damage, player)
	var visual := Polygon2D.new()
	visual.polygon = _circle_points(data.radius)
	visual.color = data.visual_color
	visual.global_position = center
	get_tree().current_scene.add_child(visual)
	var tween := get_tree().create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.12)
	tween.tween_callback(visual.queue_free)

func _circle_points(circle_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 18:
		var angle := TAU * float(index) / 18.0
		points.append(Vector2(cos(angle), sin(angle)) * circle_radius)
	return points
