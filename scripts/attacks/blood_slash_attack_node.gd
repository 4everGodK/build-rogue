extends Node2D
class_name BloodSlashAttackNode

var player: Node2D
var data: ArtifactData
var direction := Vector2.RIGHT
var origin := Vector2.ZERO
var speed := 360.0
var distance := 0.0
var phase := "out"
var pause_left := 0.0
var outbound_hits: Dictionary = {}
var return_hits: Dictionary = {}
var visual: Node2D
var attack_instance_id: String = ""

func setup(owner_player: Node2D, artifact_data: ArtifactData, attack_direction: Vector2) -> void:
	player = owner_player
	data = artifact_data
	attack_instance_id = HitFeedbackManager.begin_attack(self)
	direction = attack_direction.normalized() if attack_direction.length_squared() > 0.001 else Vector2.RIGHT
	origin = player.global_position
	global_position = origin + direction * 28.0
	rotation = direction.angle()
	speed = maxf(1.0, data.projectile_speed)
	visual = _make_visual()
	add_child(visual)
	_spawn_life_draw()
	set_physics_process(false)
	var gather := get_tree().create_tween()
	visual.scale = Vector2(0.25, 0.7)
	gather.tween_property(visual, "scale", Vector2.ONE, maxf(0.04, data.windup_time))
	await gather.finished
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	if phase == "pause":
		pause_left -= delta
		if pause_left <= 0.0:
			phase = "return"
			direction = -direction
			rotation = direction.angle()
			speed = data.return_speed if data.return_speed > 0.0 else data.projectile_speed * 1.25
		return
	var movement := direction * speed * delta
	global_position += movement
	distance += movement.length()
	_damage_overlaps()
	if phase == "out" and distance >= data.range:
		if int(data.get_meta("star_level", 1)) >= 3:
			phase = "pause"
			pause_left = maxf(0.03, data.pause_time)
			distance = 0.0
		else:
			_shatter()
			queue_free()
	elif phase == "return" and global_position.distance_to(player.global_position) <= 32.0:
		_shatter()
		queue_free()

func _damage_overlaps() -> void:
	var hits: Dictionary = return_hits if phase == "return" else outbound_hits
	var hit_damage_base: float = data.damage * (maxf(0.0, data.secondary_damage_mult) if phase == "return" else 1.0)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage") or hits.has(candidate):
			continue
		var enemy := candidate as Node2D
		var offset: Vector2 = enemy.global_position - global_position
		var forward: float = offset.dot(direction)
		var lateral: float = abs(offset.cross(direction))
		if abs(forward) > maxf(18.0, data.length * 0.55) or lateral > maxf(10.0, data.width * 0.65):
			continue
		hits[enemy] = true
		var hit_damage: float = _get_damage(hit_damage_base)
		var pre: float = _pre_hit_hp_ratio(enemy)
		var killed: bool = HitFeedbackManager.deal_damage(enemy, hit_damage, player, data, self, {
			"profile": "explosion",
			"attack_instance_id": attack_instance_id,
			"hit_origin": global_position,
			"effect_origin": global_position,
		})
		_notify()
		_apply_attr(enemy, hit_damage, enemy.global_position, pre)
		_apply_kill_heal(killed, enemy.global_position)
		_spawn_cut(enemy.global_position)

func _make_visual() -> Node2D:
	var root := Node2D.new()
	var blade := Line2D.new()
	blade.width = maxf(10.0, data.width)
	blade.default_color = Color(0.95, 0.0, 0.08, 0.78)
	blade.points = PackedVector2Array([Vector2(-data.length * 0.55, data.width * 0.45), Vector2(0, 0), Vector2(data.length * 0.6, -data.width * 0.42)])
	root.add_child(blade)
	var edge := Line2D.new()
	edge.width = maxf(4.0, data.width * 0.22)
	edge.default_color = Color(1.0, 0.18, 0.18, 0.9)
	edge.points = blade.points
	root.add_child(edge)
	return root

func _spawn_cut(center: Vector2) -> void:
	var cut := Line2D.new()
	cut.width = 4.0
	cut.default_color = Color(1.0, 0.02, 0.08, 0.72)
	cut.points = PackedVector2Array([Vector2(-18, 0), Vector2(18, 0)])
	cut.global_position = center
	cut.rotation = rotation
	get_tree().current_scene.add_child(cut)
	var tween := get_tree().create_tween()
	tween.tween_property(cut, "modulate:a", 0.0, maxf(0.12, data.hit_flash_duration))
	tween.tween_callback(cut.queue_free)

func _spawn_life_draw() -> void:
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(0.9, 0.0, 0.06, 0.55)
	line.points = PackedVector2Array([player.global_position, player.global_position + direction.orthogonal() * 24.0])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)

func _apply_kill_heal(killed: bool, from_position: Vector2) -> void:
	if not killed or data.kill_heal_amount <= 0.0 or player == null or not player.has_method("heal"):
		return
	player.call("heal", data.kill_heal_amount, data)
	var line := Line2D.new()
	line.width = 2.5
	line.default_color = Color(1.0, 0.08, 0.12, 0.72)
	line.points = PackedVector2Array([from_position, player.global_position])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.2)
	tween.tween_callback(line.queue_free)

func _shatter() -> void:
	HitEffectPool.show_cosmetic(global_position, "explosion", maxf(0.5, data.width / 34.0), direction)

func _get_damage(base_damage: float) -> float:
	return float(player.call("get_artifact_damage", data, base_damage)) if player != null and player.has_method("get_artifact_damage") else base_damage

func _notify() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attr(target: Node, damage: float, pos: Vector2, pre: float) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, target, damage, pos, pre)

func _pre_hit_hp_ratio(target: Node) -> float:
	return float(target.call("get_hp_ratio")) if target != null and target.has_method("get_hp_ratio") else -1.0
