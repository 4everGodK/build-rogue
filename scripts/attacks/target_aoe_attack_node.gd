extends Node2D
class_name TargetAoeAttackNode

var player: Node2D
var data: ArtifactData
var target_position: Vector2

func setup(owner_player: Node2D, artifact_data: ArtifactData, target: Node2D) -> void:
	player = owner_player
	data = artifact_data
	target_position = target.global_position if target != null else owner_player.global_position
	global_position = target_position
	_strike()

func _strike() -> void:
	var radius: float = maxf(8.0, data.radius)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			var enemy := candidate as Node2D
			if enemy.global_position.distance_to(target_position) <= radius:
				candidate.call("take_damage", _get_damage(), player)
				_notify_artifact_damage()
	_spawn_visual(radius)
	get_tree().create_timer(maxf(0.08, data.duration)).timeout.connect(queue_free)

func _spawn_visual(radius: float) -> void:
	var bolt := Line2D.new()
	bolt.width = maxf(5.0, radius * 0.06)
	bolt.default_color = Color(0.68, 0.94, 1.0, 0.95)
	bolt.points = PackedVector2Array([
		Vector2(0.0, -radius * 1.35),
		Vector2(-radius * 0.12, -radius * 0.62),
		Vector2(radius * 0.1, -radius * 0.18),
		Vector2(0.0, 0.0),
	])
	add_child(bolt)
	HitEffectManager.spawn_hit(get_tree(), target_position, "lightning", Vector2.DOWN, radius)
	var ring := Line2D.new()
	ring.width = maxf(3.0, radius * 0.025)
	ring.default_color = Color(0.45, 0.84, 1.0, 0.42)
	ring.closed = true
	ring.points = _circle_points(radius, 56)
	add_child(ring)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, maxf(0.08, data.duration))

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _get_damage() -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, data.damage))
	return data.damage

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
