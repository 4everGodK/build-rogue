extends Node2D
class_name BeamAttackNode

var player: Node2D
var target: Node2D
var data: ArtifactData
var time_left: float
var tick_remaining: float = 0.0
var eye_visual: Node2D
var beam_root: Node2D
var beams: Array[Dictionary] = []

func setup(owner_player: Node2D, initial_target: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	target = initial_target
	data = artifact_data
	time_left = maxf(0.05, data.duration)
	beam_root = Node2D.new()
	add_child(beam_root)
	eye_visual = ArtifactVisuals.make_eye_visual()
	add_child(eye_visual)
	_build_beams(initial_target)
	_spawn_open_visual()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	time_left -= delta
	tick_remaining -= delta
	var eye_position := player.global_position + Vector2(0, -58)
	if is_instance_valid(eye_visual):
		eye_visual.global_position = eye_position
		eye_visual.rotation += delta * 1.6
	_update_beams(eye_position)
	if tick_remaining <= 0.0:
		tick_remaining = maxf(0.05, data.tick_interval)
		_spend_life_tick()
		_damage_tick(eye_position)
	if time_left <= 0.0:
		_close_and_free()

func _build_beams(initial_target: Node2D) -> void:
	var beam_count: int = 1
	if data.id == "heaven_eye" and int(data.get_meta("star_level", 1)) >= 3:
		beam_count = 3
	var reserved: Array[Node2D] = []
	for index in beam_count:
		var line := Line2D.new()
		line.width = maxf(2.0, data.radius) * (1.0 if index == 0 else 0.48)
		line.default_color = Color(0.9, 0.08, 0.16, 0.82 if index == 0 else 0.46)
		beam_root.add_child(line)
		var chosen := initial_target if index == 0 and _target_valid(initial_target) else _find_target(reserved)
		if _target_valid(chosen):
			reserved.append(chosen)
		beams.append({
			"line": line,
			"target": chosen,
			"damage_mult": 1.0 if index == 0 else maxf(0.0, data.side_projectile_damage_mult),
			"offset": Vector2(float(index - 1) * 7.0, 0.0),
		})

func _update_beams(eye_position: Vector2) -> void:
	var reserved: Array[Node2D] = []
	for beam in beams:
		var current := beam.get("target") as Node2D
		if not _target_valid(current):
			current = _find_target(reserved)
			beam["target"] = current
		if _target_valid(current):
			reserved.append(current)
			var line := beam["line"] as Line2D
			line.points = PackedVector2Array([eye_position + (beam["offset"] as Vector2), current.global_position])
			line.modulate.a = 1.0
			_spawn_lock_mark(current.global_position)
		else:
			(beam["line"] as Line2D).modulate.a = 0.0

func _damage_tick(eye_position: Vector2) -> void:
	for beam in beams:
		var enemy := beam.get("target") as Node2D
		if not _target_valid(enemy):
			continue
		var hit_damage: float = _get_damage(data.damage * float(beam.get("damage_mult", 1.0)))
		var pre: float = _pre_hit_hp_ratio(enemy)
		var killed: bool = bool(enemy.call("take_damage", hit_damage, player))
		_notify()
		_apply_attr(enemy, hit_damage, enemy.global_position, pre)
		HitEffectManager.spawn_hit(get_tree(), enemy.global_position, "blood", eye_position.direction_to(enemy.global_position), 12.0)
		if killed:
			_apply_kill_heal(enemy.global_position)
			beam["target"] = null

func _spend_life_tick() -> void:
	if data.life_cost_percent > 0.0 and player.has_method("spend_life_percent"):
		player.call("spend_life_percent", data.life_cost_percent, data.life_cost_min_hp_ratio)
	if data.life_cost_flat > 0.0 and player.has_method("spend_life_flat"):
		player.call("spend_life_flat", data.life_cost_flat, data.life_cost_min_hp_ratio)
	_spawn_life_to_eye()

func _find_target(reserved: Array[Node2D]) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	var fallback: Node2D
	var fallback_distance := INF
	var search_range: float = data.range if data.range > 0.0 else INF
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not _target_valid(candidate):
			continue
		var enemy := candidate as Node2D
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance > search_range:
			continue
		if distance < fallback_distance:
			fallback = enemy
			fallback_distance = distance
		if enemy in reserved:
			continue
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest if nearest != null else fallback

func _spawn_open_visual() -> void:
	if not is_instance_valid(eye_visual):
		return
	eye_visual.scale = Vector2(1.0, 0.1)
	eye_visual.modulate.a = 0.0
	var tween := get_tree().create_tween()
	tween.tween_property(eye_visual, "modulate:a", 1.0, maxf(0.08, data.windup_time))
	tween.parallel().tween_property(eye_visual, "scale", Vector2.ONE, maxf(0.08, data.windup_time))

func _spawn_lock_mark(center: Vector2) -> void:
	if int(Time.get_ticks_msec() / 80) % 3 != 0:
		return
	var mark := Line2D.new()
	mark.width = 2.0
	mark.default_color = Color(0.95, 0.1, 0.16, 0.34)
	mark.closed = true
	mark.points = _circle_points(12.0, 18)
	mark.global_position = center
	get_tree().current_scene.add_child(mark)
	var tween := get_tree().create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, 0.12)
	tween.tween_callback(mark.queue_free)

func _spawn_life_to_eye() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var from := player.global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-8.0, 8.0))
	var to := player.global_position + Vector2(0, -58)
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(0.85, 0.0, 0.06, 0.42)
	line.points = PackedVector2Array([from, to])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.14)
	tween.tween_callback(line.queue_free)

func _apply_kill_heal(from_position: Vector2) -> void:
	if data.kill_heal_amount <= 0.0 or player == null or not player.has_method("heal"):
		return
	player.call("heal", data.kill_heal_amount)
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(1.0, 0.08, 0.12, 0.72)
	line.points = PackedVector2Array([from_position, player.global_position])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func _close_and_free() -> void:
	set_physics_process(false)
	var tween := get_tree().create_tween()
	if is_instance_valid(eye_visual):
		tween.tween_property(eye_visual, "scale:y", 0.08, 0.12)
		tween.parallel().tween_property(eye_visual, "modulate:a", 0.0, 0.12)
	for beam in beams:
		var line := beam["line"] as Line2D
		tween.parallel().tween_property(line, "modulate:a", 0.0, 0.08)
	tween.tween_callback(queue_free)

func _target_valid(enemy: Variant) -> bool:
	return enemy is Node2D and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("take_damage") and not bool(enemy.get("dying"))

func _notify() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attr(hit_target: Node, base_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float = -1.0) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, hit_target, base_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(hit_target: Node) -> float:
	return float(hit_target.call("get_hp_ratio")) if hit_target != null and hit_target.has_method("get_hp_ratio") else -1.0

func _get_damage(base_damage: float) -> float:
	return float(player.call("get_artifact_damage", data, base_damage)) if player != null and player.has_method("get_artifact_damage") else base_damage

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
