extends CharacterBody2D
class_name SummonUnit

const STATE_FOLLOW := "Follow"
const STATE_COMBAT := "Combat"
const STATE_RETURN := "Return"
const STATE_RESPAWN := "Respawn"

var player: Node2D
var data: ArtifactData
var controller: SummonController
var slot_index: int = 0
var state: String = STATE_FOLLOW
var hp: float = 1.0
var max_hp: float = 1.0
var attack_cooldown: float = 0.0
var respawn_remaining: float = 0.0
var target: Node2D
var attack_counter: int = 0
var taunt_cooldown: float = 0.0
var redeploy_remaining: float = 0.0
var dash_remaining: float = 0.0
var dash_direction: Vector2 = Vector2.RIGHT
var damaged_during_dash: Dictionary = {}
var visual: Node2D
var collision: CollisionShape2D

func setup(owner_player: Node2D, artifact_data: ArtifactData, owner_controller: SummonController, index: int) -> void:
	player = owner_player
	data = artifact_data
	controller = owner_controller
	slot_index = index
	max_hp = maxf(1.0, data.summon_hp)
	hp = max_hp
	taunt_cooldown = randf_range(0.2, 1.0)
	collision_layer = 4
	collision_mask = 2
	if data.summon_behavior_type == "ghost":
		collision_layer = 0
		collision_mask = 0
	add_to_group("summons")
	_build_collision()
	_build_visual()

func _physics_process(delta: float) -> void:
	if data == null or not is_instance_valid(player):
		queue_free()
		return
	if state == STATE_RESPAWN:
		_process_respawn(delta)
		return
	if data.summon_behavior_type == "turret":
		_process_turret(delta)
		return
	if global_position.distance_to(player.global_position) > maxf(1.0, data.summon_return_radius):
		state = STATE_RETURN
		target = null
	match state:
		STATE_FOLLOW:
			_process_follow(delta)
		STATE_COMBAT:
			_process_combat(delta)
		STATE_RETURN:
			_process_return(delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	taunt_cooldown = maxf(0.0, taunt_cooldown - delta)

func take_damage(amount: float, _source = null) -> bool:
	if state == STATE_RESPAWN:
		return false
	hp -= amount
	if data.id == "iron_guard_puppet" and _has_special("shockwave"):
		_shockwave()
	if hp <= 0.0:
		_die()
		return true
	return false

func force_respawn(position: Vector2) -> void:
	hp = max_hp
	respawn_remaining = 0.0
	visible = true
	if collision != null:
		collision.disabled = false
	global_position = position
	state = STATE_FOLLOW

func _process_follow(delta: float) -> void:
	var enemy := _find_target()
	if enemy != null:
		target = enemy
		state = STATE_COMBAT
		return
	_move_toward(player.global_position + _follow_offset(), delta, 0.8)

func _process_combat(delta: float) -> void:
	if not _target_is_valid(target):
		target = _find_target()
	if target == null:
		state = STATE_FOLLOW
		return
	if global_position.distance_to(player.global_position) > maxf(1.0, data.summon_return_radius):
		state = STATE_RETURN
		target = null
		return
	match data.summon_behavior_type:
		"melee":
			_process_melee(delta)
		"ranged":
			_process_ranged(delta)
		"tank":
			_process_tank(delta)
		"ghost":
			_process_ghost(delta)
		"swarm":
			_process_swarm(delta)

func _process_return(delta: float) -> void:
	var destination := player.global_position + _follow_offset()
	_move_toward(destination, delta, 1.25)
	if global_position.distance_to(destination) <= 32.0:
		state = STATE_FOLLOW

func _process_respawn(delta: float) -> void:
	respawn_remaining -= delta
	if respawn_remaining > 0.0:
		return
	hp = max_hp
	visible = true
	set_physics_process(true)
	if collision != null:
		collision.disabled = false
	global_position = player.global_position + _follow_offset()
	state = STATE_FOLLOW

func _process_turret(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if redeploy_remaining > 0.0:
		redeploy_remaining -= delta
		if redeploy_remaining <= 0.0:
			global_position = player.global_position + _follow_offset()
			visible = true
		return
	if global_position.distance_to(player.global_position) > 900.0:
		redeploy_remaining = 2.0
		visible = false
		return
	target = _find_target()
	if target != null and attack_cooldown <= 0.0:
		_fire_projectile(target, true)
		_reset_attack_cooldown()

func _process_melee(delta: float) -> void:
	var attack_range := maxf(46.0, data.length)
	if global_position.distance_to(target.global_position) > attack_range:
		_move_toward(target.global_position, delta, 1.0)
	elif attack_cooldown <= 0.0:
		attack_counter += 1
		var damage := data.summon_attack
		if data.id == "sword_puppet" and attack_counter % 3 == 0 and _has_special("third_attack_double"):
			damage *= 2.0
		_swing(target.global_position, damage, attack_range)
		_reset_attack_cooldown()

func _process_ranged(delta: float) -> void:
	var distance := global_position.distance_to(target.global_position)
	var keep_distance := 220.0
	if distance < keep_distance * 0.75:
		_move_toward(global_position + target.global_position.direction_to(global_position) * 80.0, delta, 1.0)
	elif distance > keep_distance * 1.25:
		_move_toward(target.global_position, delta, 0.8)
	if attack_cooldown <= 0.0:
		_fire_projectile(target, false)
		_reset_attack_cooldown()

func _process_tank(delta: float) -> void:
	var between := player.global_position
	if target != null:
		between = player.global_position.lerp(target.global_position, 0.42)
	_move_toward(between, delta, 0.9)
	if taunt_cooldown <= 0.0:
		_taunt()
		taunt_cooldown = 5.0
	if target != null and global_position.distance_to(target.global_position) <= maxf(42.0, data.length) and attack_cooldown <= 0.0:
		damage_enemy(target, data.summon_attack)
		_reset_attack_cooldown()

func _process_ghost(delta: float) -> void:
	if dash_remaining > 0.0:
		global_position += dash_direction * data.summon_move_speed * 1.7 * delta
		dash_remaining -= delta
		_damage_dash_contacts()
		return
	if attack_cooldown <= 0.0:
		damaged_during_dash.clear()
		dash_direction = global_position.direction_to(target.global_position)
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2.RIGHT
		dash_remaining = 0.28
		_reset_attack_cooldown()
	else:
		_move_toward(target.global_position, delta, 1.0)

func _process_swarm(delta: float) -> void:
	if global_position.distance_to(player.global_position) > data.summon_return_radius * 1.25:
		global_position = player.global_position + _follow_offset()
		state = STATE_FOLLOW
		return
	_process_melee(delta)

func _find_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	var radius_squared := data.summon_combat_radius * data.summon_combat_radius
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		if bool(candidate.get("dying")):
			continue
		var enemy := candidate as Node2D
		var distance_squared := player.global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= radius_squared and distance_squared < nearest_distance:
			nearest = enemy
			nearest_distance = distance_squared
	return nearest

func _target_is_valid(enemy: Node2D) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("take_damage") and not bool(enemy.get("dying"))

func _move_toward(destination: Vector2, delta: float, multiplier: float) -> void:
	var speed := data.summon_move_speed * multiplier
	if speed <= 0.0:
		return
	var direction := global_position.direction_to(destination)
	velocity = direction * speed
	move_and_slide()

func _swing(origin: Vector2, damage: float, attack_range: float) -> void:
	var direction := global_position.direction_to(origin)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			var enemy := candidate as Node2D
			var to_enemy := global_position.direction_to(enemy.global_position)
			if global_position.distance_to(enemy.global_position) <= attack_range and direction.dot(to_enemy) >= 0.35:
				damage_enemy(enemy, damage)
	HitEffectManager.spawn_hit(get_tree(), global_position + direction * attack_range * 0.55, "sword", direction, attack_range)

func _fire_projectile(enemy: Node2D, explosive: bool) -> void:
	var projectile := SummonProjectile.new()
	if controller != null:
		controller.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)
	projectile.setup(self, player, data, enemy, explosive)

func _damage_dash_contacts() -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if damaged_during_dash.has(candidate) or not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		if global_position.distance_to(enemy.global_position) <= 28.0:
			damaged_during_dash[candidate] = true
			damage_enemy(enemy, data.summon_attack)
			if player.has_method("heal"):
				player.call("heal", maxf(1.0, data.heal_amount))
			if _has_special("soul_shock"):
				HitEffectManager.spawn_hit(get_tree(), enemy.global_position, "sound", dash_direction, 42.0)

func damage_enemy(enemy: Node2D, damage: float) -> void:
	if enemy == null or not enemy.has_method("take_damage"):
		return
	var killed: bool = bool(enemy.call("take_damage", damage, player))
	if data.poison_dps > 0.0 and enemy.has_method("apply_poison"):
		enemy.call("apply_poison", data.poison_dps, maxf(0.1, data.poison_duration), data.poison_can_stack)
	if killed and data.id == "poison_bug" and randf() < 0.2 and controller != null:
		controller.try_spawn_extra_unit()

func _taunt() -> void:
	var radius := maxf(1.0, data.radius)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("apply_taunt"):
			if global_position.distance_to((candidate as Node2D).global_position) <= radius:
				candidate.call("apply_taunt", self, 2.0)
	HitEffectManager.spawn_hit(get_tree(), global_position, "flash", Vector2.UP, radius)

func _shockwave() -> void:
	var radius := 92.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= radius:
				candidate.call("take_damage", data.summon_attack, player)

func _die() -> void:
	if controller != null:
		controller.on_unit_died(self)
	state = STATE_RESPAWN
	respawn_remaining = maxf(0.1, data.summon_respawn_time)
	visible = false
	target = null
	if collision != null:
		collision.disabled = true

func _reset_attack_cooldown() -> void:
	attack_cooldown = 1.0 / maxf(0.1, data.summon_attack_speed)

func _follow_offset() -> Vector2:
	var angle := TAU * float(slot_index) / float(maxi(1, data.summon_base_count))
	return Vector2(cos(angle), sin(angle)) * (54.0 + float(slot_index % 3) * 18.0)

func _has_special(key: String) -> bool:
	return data.summon_special_effect.find(key) >= 0

func _build_collision() -> void:
	collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0 if data.id == "poison_bug" else 14.0
	collision.shape = shape
	add_child(collision)

func _build_visual() -> void:
	visual = Node2D.new()
	add_child(visual)
	var body := Polygon2D.new()
	body.polygon = _visual_polygon()
	body.color = data.visual_color
	visual.add_child(body)

func _visual_polygon() -> PackedVector2Array:
	match data.summon_behavior_type:
		"turret":
			return PackedVector2Array([Vector2(-15, 12), Vector2(-10, -10), Vector2(12, -14), Vector2(18, 8)])
		"ghost":
			return PackedVector2Array([Vector2(0, -16), Vector2(13, -4), Vector2(8, 14), Vector2(0, 8), Vector2(-8, 14), Vector2(-13, -4)])
		"swarm":
			return PackedVector2Array([Vector2(0, -8), Vector2(10, 0), Vector2(0, 8), Vector2(-10, 0)])
		_:
			return PackedVector2Array([Vector2(0, -14), Vector2(13, 0), Vector2(0, 14), Vector2(-13, 0)])
