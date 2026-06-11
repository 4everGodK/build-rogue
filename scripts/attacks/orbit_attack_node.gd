extends Node2D
class_name OrbitAttackNode

var player: Node2D
var data: ArtifactData
var angle: float = 0.0
var orbiters: Array[Area2D] = []
var last_hits: Dictionary = {}
var counter_cooldown_remaining: float = 0.0

func setup(owner_player: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	data = artifact_data
	global_position = player.global_position
	z_index = 1
	for index in maxi(1, data.count):
		var orbiter: Area2D = Area2D.new()
		orbiter.collision_layer = 0
		orbiter.collision_mask = 2
		orbiter.monitoring = true
		var shape: CircleShape2D = CircleShape2D.new()
		shape.radius = 7.0
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = shape
		orbiter.add_child(collision)
		var visual: Node2D = ArtifactVisuals.make_orbiter_visual(data)
		orbiter.add_child(visual)
		add_child(orbiter)
		orbiters.append(orbiter)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	counter_cooldown_remaining -= delta
	angle += data.rotation_speed * delta
	for index in orbiters.size():
		var orbiter: Area2D = orbiters[index]
		if _is_countering(orbiter):
			continue
		var orbit_angle: float = angle + TAU * float(index) / float(orbiters.size())
		orbiter.position = Vector2(cos(orbit_angle), sin(orbit_angle)) * data.radius
		orbiter.rotation = orbit_angle + PI * 0.5
		for body in orbiter.get_overlapping_bodies():
			_try_hit(body, orbiter)
	if data.counter_range > 0.0 and counter_cooldown_remaining <= 0.0:
		_try_counter_attack()

func _try_hit(body: Node, orbiter: Area2D) -> void:
	if not body.has_method("take_damage"):
		return
	var key: String = "%s:%s" % [orbiter.get_instance_id(), body.get_instance_id()]
	var now: float = Time.get_ticks_msec() * 0.001
	if now - float(last_hits.get(key, -INF)) < data.hit_interval:
		return
	last_hits[key] = now
	body.call("take_damage", data.damage * 0.25, player)
	_notify_artifact_damage()
	HitEffectManager.spawn_hit(get_tree(), orbiter.global_position, "sword", orbiter.global_transform.x, 14.0)
	_flash_orbiter(orbiter)

func _try_counter_attack() -> void:
	var target: Node2D = _find_nearest_counter_target()
	if target == null:
		return
	var orbiter: Area2D = _first_ready_orbiter()
	if orbiter == null:
		return
	var cooldown_multiplier: float = 1.0
	if player != null and player.has_method("get_sword_artifact_cooldown_multiplier"):
		cooldown_multiplier = float(player.call("get_sword_artifact_cooldown_multiplier", data))
	counter_cooldown_remaining = maxf(0.12, data.cooldown * cooldown_multiplier)
	_counter_stab(orbiter, target)

func _find_nearest_counter_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance_squared: float = INF
	var max_distance_squared: float = data.counter_range * data.counter_range
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy: Node2D = candidate as Node2D
		if enemy.is_queued_for_deletion() or bool(enemy.get("dying")):
			continue
		var distance_squared: float = player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= max_distance_squared and distance_squared < nearest_distance_squared:
			nearest = enemy
			nearest_distance_squared = distance_squared
	return nearest

func _first_ready_orbiter() -> Area2D:
	for orbiter in orbiters:
		if not _is_countering(orbiter):
			return orbiter
	return null

func _is_countering(orbiter: Area2D) -> bool:
	return orbiter.has_meta("countering") and bool(orbiter.get_meta("countering"))

func _counter_stab(orbiter: Area2D, target: Node2D) -> void:
	orbiter.set_meta("countering", true)
	var start_position: Vector2 = orbiter.global_position
	var target_position: Vector2 = target.global_position
	var distance: float = start_position.distance_to(target_position)
	var travel_time: float = clampf(distance / maxf(1.0, data.counter_speed), 0.06, 0.16)
	orbiter.rotation = start_position.direction_to(target_position).angle()
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(orbiter, "global_position", target_position, travel_time)
	await tween.finished
	if not is_instance_valid(orbiter) or not is_instance_valid(player):
		return
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.call("take_damage", data.damage, player)
		_notify_artifact_damage()
		HitEffectManager.spawn_hit(get_tree(), target.global_position, "sword", start_position.direction_to(target_position), 18.0)
	_flash_orbiter(orbiter)
	var return_time: float = clampf(target_position.distance_to(player.global_position) / maxf(1.0, data.counter_speed), 0.06, 0.18)
	tween = get_tree().create_tween()
	tween.tween_property(orbiter, "global_position", player.global_position + Vector2(data.radius, 0.0).rotated(angle), return_time)
	await tween.finished
	if is_instance_valid(orbiter):
		orbiter.set_meta("countering", false)

func _flash_orbiter(orbiter: Area2D) -> void:
	orbiter.modulate = Color(1.8, 1.8, 1.4, 1.0)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(orbiter, "modulate", Color.WHITE, 0.1)

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)
