extends CharacterBody2D
class_name SummonUnit

const STATE_FOLLOW := "Follow"
const STATE_COMBAT := "Combat"
const STATE_RETURN := "Return"
const STATE_RESPAWN := "Respawn"
const SUMMON_COLLISION_LAYER: int = 8
const WALL_COLLISION_LAYER: int = 4
const DEFAULT_ARENA_SIZE: Vector2 = Vector2(1120.0, 672.0)
const SUMMON_ARENA_INSET: float = 42.0

var player: Node2D
var data: ArtifactData
var controller: SummonController
var slot_index: int = 0
var formation_index: int = 0
var formation_count: int = 1
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
var dash_destination: Vector2 = Vector2.ZERO
var damaged_during_dash: Dictionary = {}
var battle_paused: bool = false
var visual: Node2D
var collision: CollisionShape2D
var special_cooldown: float = 0.0
var ai_refresh_remaining: float = 0.0
var shield_remaining: float = 0.0
var damage_reduction: float = 0.0
var ghost_chain_hits: Dictionary = {}
var pending_ranged_shot: bool = false
var poison_burst_marks: Dictionary = {}

func setup(owner_player: Node2D, artifact_data: ArtifactData, owner_controller: SummonController, index: int) -> void:
	player = owner_player
	data = artifact_data
	controller = owner_controller
	slot_index = index
	max_hp = maxf(1.0, data.summon_hp)
	hp = max_hp
	taunt_cooldown = randf_range(0.2, 1.0)
	collision_layer = SUMMON_COLLISION_LAYER
	collision_mask = SUMMON_COLLISION_LAYER | WALL_COLLISION_LAYER
	if data.id == "ghost":
		collision_layer = 0
		collision_mask = 0
	elif data.id == "poison_bug":
		collision_mask = WALL_COLLISION_LAYER
	set_formation_slot(index, maxi(1, data.summon_base_count))
	add_to_group("summons")
	_build_collision()
	_build_visual()

func set_formation_slot(index: int, total_count: int) -> void:
	formation_index = maxi(0, index)
	formation_count = maxi(1, total_count)

func _physics_process(delta: float) -> void:
	if battle_paused:
		velocity = Vector2.ZERO
		return
	if data == null or not is_instance_valid(player):
		queue_free()
		return
	special_cooldown = maxf(0.0, special_cooldown - delta)
	shield_remaining = maxf(0.0, shield_remaining - delta)
	if shield_remaining <= 0.0:
		damage_reduction = 0.0
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

func set_battle_paused(paused: bool) -> void:
	battle_paused = paused
	set_physics_process(not paused)
	set_process(not paused)
	velocity = Vector2.ZERO

func take_damage(amount: float, _source = null) -> bool:
	if data != null and data.id == "ghost":
		return false
	if state == STATE_RESPAWN:
		return false
	hp -= amount * (1.0 - clampf(damage_reduction, 0.0, 0.9))
	_spawn_damage_flash()
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
	global_position = _safe_position(position)
	target = null
	velocity = Vector2.ZERO
	dash_remaining = 0.0
	damaged_during_dash.clear()
	ghost_chain_hits.clear()
	shield_remaining = 0.0
	damage_reduction = 0.0
	state = STATE_FOLLOW
	_play_spawn_effect()

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
	global_position = _safe_position(player.global_position + _follow_offset())
	target = null
	velocity = Vector2.ZERO
	dash_remaining = 0.0
	damaged_during_dash.clear()
	ghost_chain_hits.clear()
	shield_remaining = 0.0
	damage_reduction = 0.0
	state = STATE_FOLLOW
	_play_spawn_effect()

func _process_turret(delta: float) -> void:
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	if redeploy_remaining > 0.0:
		redeploy_remaining -= delta
		if redeploy_remaining <= 0.0:
			global_position = _safe_position(player.global_position + _follow_offset())
			visible = true
			_play_spawn_effect()
		return
	if global_position.distance_to(player.global_position) > maxf(1.0, data.summon_return_radius):
		_spawn_redeploy_effect()
		redeploy_remaining = maxf(0.2, data.secondary_delay if data.secondary_delay > 0.0 else 2.0)
		visible = false
		return
	target = _find_target()
	if target != null and attack_cooldown <= 0.0:
		_fire_turret_barrage(target)
		_reset_attack_cooldown()

func _fire_turret_barrage(primary_target: Node2D) -> void:
	_spawn_muzzle_flash()
	_fire_projectile(primary_target, true)
	if int(data.get_meta("star_level", 1)) < 3:
		return
	var secondary_target := _find_alternate_target(primary_target)
	if secondary_target == null:
		secondary_target = primary_target
	get_tree().create_timer(maxf(0.01, data.delayed_strike_interval)).timeout.connect(func() -> void:
		if is_instance_valid(self) and state != STATE_RESPAWN and visible:
			_fire_projectile(secondary_target, true, maxf(0.0, data.secondary_damage_mult))
	)

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
		if data.id == "sword_puppet" and int(data.get_meta("star_level", 1)) >= 3 and special_cooldown <= 0.0:
			_leap_slash(target)
		_reset_attack_cooldown()

func _process_ranged(delta: float) -> void:
	var distance := global_position.distance_to(target.global_position)
	var keep_distance := maxf(120.0, data.secondary_radius if data.secondary_radius > 0.0 else 220.0)
	if distance < keep_distance * 0.75:
		_move_toward(global_position + target.global_position.direction_to(global_position) * 80.0, delta, 1.0)
	elif distance > keep_distance * 1.25:
		_move_toward(target.global_position, delta, 0.8)
	if attack_cooldown <= 0.0 and not pending_ranged_shot:
		pending_ranged_shot = true
		attack_counter += 1
		_spawn_muzzle_flash()
		var charge_time: float = maxf(0.01, data.delayed_strike_delay)
		get_tree().create_timer(charge_time).timeout.connect(func() -> void:
			if not is_instance_valid(self) or state == STATE_RESPAWN:
				return
			pending_ranged_shot = false
			if int(data.get_meta("star_level", 1)) >= 3 and data.delayed_strike_count > 0 and attack_counter % data.delayed_strike_count == 0:
				_fire_spread_projectiles(target)
			else:
				_fire_projectile(target, false)
		)
		_reset_attack_cooldown()

func _process_tank(delta: float) -> void:
	var between := player.global_position
	if target != null:
		between = player.global_position.lerp(target.global_position, 0.42)
	_move_toward(between, delta, 0.9)
	if taunt_cooldown <= 0.0:
		_taunt()
		taunt_cooldown = maxf(0.5, data.secondary_delay if data.secondary_delay > 0.0 else 5.0)
	if target != null and global_position.distance_to(target.global_position) <= maxf(42.0, data.length) and attack_cooldown <= 0.0:
		_spawn_heavy_swing(target.global_position)
		damage_enemy(target, data.summon_attack)
		_reset_attack_cooldown()

func _process_ghost(delta: float) -> void:
	if dash_remaining > 0.0:
		var speed: float = data.summon_move_speed * 2.4
		global_position = global_position.move_toward(dash_destination, speed * delta)
		_spawn_ghost_trail()
		dash_remaining -= delta
		_damage_dash_contacts()
		if global_position.distance_to(dash_destination) <= 6.0 or dash_remaining <= 0.0:
			global_position = dash_destination
			dash_remaining = 0.0
			if int(data.get_meta("star_level", 1)) >= 3 and not bool(get_meta("ghost_second_dash_done", false)):
				var next_target := _find_ghost_chain_target()
				if next_target != null:
					set_meta("ghost_second_dash_done", true)
					_start_ghost_dash(next_target, maxf(0.0, data.secondary_damage_mult))
					return
			target = null
			visual.scale = Vector2.ONE
		return
	if attack_cooldown <= 0.0:
		if not _target_is_valid(target):
			target = _find_target()
		if target == null:
			state = STATE_FOLLOW
			return
		ghost_chain_hits.clear()
		set_meta("ghost_second_dash_done", false)
		_start_ghost_dash(target, 1.0)
		_reset_attack_cooldown()
	else:
		velocity = Vector2.ZERO

func _process_swarm(delta: float) -> void:
	if global_position.distance_to(player.global_position) > data.summon_return_radius * 1.25:
		global_position = _safe_position(player.global_position + _follow_offset())
		state = STATE_FOLLOW
		return
	ai_refresh_remaining -= delta
	if ai_refresh_remaining <= 0.0:
		ai_refresh_remaining = 0.18 + float(slot_index % 5) * 0.035
		target = _find_swarm_target()
	if target == null:
		state = STATE_FOLLOW
		return
	_process_melee(delta)

func _start_ghost_dash(dash_target: Node2D, damage_mult: float) -> void:
	if not _target_is_valid(dash_target):
		return
	damaged_during_dash.clear()
	dash_direction = global_position.direction_to(dash_target.global_position)
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT
	dash_destination = _safe_position(dash_target.global_position + dash_direction * maxf(48.0, data.length))
	dash_remaining = maxf(0.12, global_position.distance_to(dash_destination) / maxf(1.0, data.summon_move_speed * 2.4))
	set_meta("ghost_dash_damage_mult", damage_mult)
	if visual != null:
		visual.scale = Vector2(1.45, 0.65)

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

func _find_alternate_target(primary_target: Node2D) -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	var radius_squared := data.summon_combat_radius * data.summon_combat_radius
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == primary_target or not candidate is Node2D or not candidate.has_method("take_damage") or bool(candidate.get("dying")):
			continue
		var enemy := candidate as Node2D
		var distance_squared := global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= radius_squared and distance_squared < nearest_distance:
			nearest = enemy
			nearest_distance = distance_squared
	return nearest

func _find_ghost_chain_target() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	var search_range: float = data.secondary_radius if data.secondary_radius > 0.0 else data.summon_combat_radius
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not _target_is_valid(candidate as Node2D) or ghost_chain_hits.has(candidate):
			continue
		var distance := global_position.distance_to((candidate as Node2D).global_position)
		if distance <= search_range and distance < nearest_distance:
			nearest = candidate as Node2D
			nearest_distance = distance
	return nearest

func _find_swarm_target() -> Node2D:
	var candidates: Array[Node2D] = []
	var radius_squared := data.summon_combat_radius * data.summon_combat_radius
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or not candidate.has_method("take_damage") or bool(candidate.get("dying")):
			continue
		var enemy := candidate as Node2D
		if player.global_position.distance_squared_to(enemy.global_position) <= radius_squared:
			candidates.append(enemy)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	var spread_index: int = slot_index % mini(candidates.size(), 4)
	return candidates[spread_index]

func _target_is_valid(enemy: Node2D) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("take_damage") and not bool(enemy.get("dying"))

func _move_toward(destination: Vector2, delta: float, multiplier: float) -> void:
	var speed := data.summon_move_speed * multiplier
	if speed <= 0.0:
		velocity = Vector2.ZERO
		return
	var safe_destination := _safe_position(destination)
	var distance := global_position.distance_to(safe_destination)
	if distance <= 4.0:
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(safe_destination)
	var separation := _separation_vector()
	velocity = (direction + separation * 0.55).normalized() * minf(speed, distance / maxf(delta, 0.001))
	move_and_slide()
	global_position = _safe_position(global_position)

func _separation_vector() -> Vector2:
	var result := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("summons"):
		if other == self or not other is Node2D:
			continue
		var offset: Vector2 = global_position - (other as Node2D).global_position
		var distance: float = offset.length()
		var desired: float = 14.0 if data.id == "poison_bug" else 24.0
		if distance > 0.01 and distance < desired:
			result += offset.normalized() * (1.0 - distance / desired)
	return result.limit_length(1.0)

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
	HitEffectManager.spawn_hit(get_tree(), global_position + direction * attack_range * 0.55, "poison" if data.id == "poison_bug" else "sword", direction, attack_range)
	_spawn_swing_arc(direction, attack_range)

func _leap_slash(enemy: Node2D) -> void:
	if not _target_is_valid(enemy):
		return
	var leap_distance: float = maxf(24.0, data.secondary_radius)
	var target_pos: Vector2 = _safe_position(global_position + global_position.direction_to(enemy.global_position) * minf(leap_distance, global_position.distance_to(enemy.global_position)))
	if target_pos.distance_to(player.global_position) > data.summon_return_radius:
		return
	special_cooldown = maxf(0.2, data.secondary_delay)
	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.12)
	await tween.finished
	var radius: float = maxf(18.0, data.explosion_radius)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage") and global_position.distance_to((candidate as Node2D).global_position) <= radius:
			damage_enemy(candidate as Node2D, data.summon_attack * maxf(0.0, data.secondary_damage_mult))
	HitEffectManager.spawn_hit(get_tree(), global_position, "sword", Vector2.UP, radius)

func _fire_projectile(enemy: Node2D, explosive: bool, damage_mult: float = 1.0, direction_override: Vector2 = Vector2.ZERO) -> void:
	var projectile := SummonProjectile.new()
	if controller != null:
		controller.add_child(projectile)
	else:
		get_tree().current_scene.add_child(projectile)
	projectile.setup(self, player, data, enemy, explosive, damage_mult, direction_override)

func _fire_spread_projectiles(enemy: Node2D) -> void:
	if not _target_is_valid(enemy):
		return
	var base_direction := global_position.direction_to(enemy.global_position)
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT
	var arc: float = deg_to_rad(maxf(1.0, data.fan_angle))
	_fire_projectile(enemy, false, maxf(0.0, data.side_projectile_damage_mult), base_direction.rotated(-arc * 0.5))
	_fire_projectile(enemy, false, 1.0, base_direction)
	_fire_projectile(enemy, false, maxf(0.0, data.side_projectile_damage_mult), base_direction.rotated(arc * 0.5))

func _damage_dash_contacts() -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if damaged_during_dash.has(candidate) or ghost_chain_hits.has(candidate) or not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		var enemy := candidate as Node2D
		if global_position.distance_to(enemy.global_position) <= maxf(28.0, data.width * 0.5):
			damaged_during_dash[candidate] = true
			ghost_chain_hits[candidate] = true
			damage_enemy(enemy, data.summon_attack * float(get_meta("ghost_dash_damage_mult", 1.0)))
			if player.has_method("heal"):
				player.call("heal", maxf(1.0, data.heal_amount))
			HitEffectManager.spawn_hit(get_tree(), enemy.global_position, "sound", dash_direction, 42.0)

func damage_enemy(enemy: Node2D, damage: float) -> void:
	if enemy == null or not enemy.has_method("take_damage"):
		return
	var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(enemy)
	var final_damage: float = _get_damage(damage)
	var killed: bool = bool(enemy.call("take_damage", final_damage, player))
	_notify_artifact_damage()
	_apply_attribute_on_hit(enemy, final_damage, enemy.global_position, pre_hit_hp_ratio)
	if data.poison_dps > 0.0 and enemy.has_method("apply_poison"):
		enemy.call("apply_poison", data.poison_dps * _damage_multiplier(), maxf(0.1, data.poison_duration), data.poison_can_stack)
	if killed and data.id == "poison_bug":
		if int(data.get_meta("star_level", 1)) >= 3:
			_try_poison_bug_burst(enemy)
		elif randf() < 0.2 and controller != null:
			controller.try_spawn_extra_unit()

func _taunt() -> void:
	var radius := maxf(1.0, data.radius)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("apply_taunt"):
			if global_position.distance_to((candidate as Node2D).global_position) <= radius:
				candidate.call("apply_taunt", self, 2.0)
				_spawn_taunt_mark((candidate as Node2D).global_position)
	HitEffectManager.spawn_hit(get_tree(), global_position, "flash", Vector2.UP, radius)
	if data.id == "iron_guard_puppet" and int(data.get_meta("star_level", 1)) >= 3:
		shield_remaining = maxf(0.1, data.duration)
		damage_reduction = clampf(data.secondary_damage_mult, 0.0, 0.9)
		_spawn_guard_shield(radius)

func _shockwave() -> void:
	var radius := 92.0
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= radius:
				var pre_hit_hp_ratio: float = _pre_hit_hp_ratio(candidate)
				var shockwave_damage: float = _get_damage(data.summon_attack)
				candidate.call("take_damage", shockwave_damage, player)
				_notify_artifact_damage()
				_apply_attribute_on_hit(candidate, shockwave_damage, (candidate as Node2D).global_position, pre_hit_hp_ratio)

func _die() -> void:
	if controller != null:
		controller.on_unit_died(self)
	_spawn_death_effect()
	_spawn_respawn_mark()
	state = STATE_RESPAWN
	respawn_remaining = maxf(0.1, data.summon_respawn_time)
	visible = false
	target = null
	if collision != null:
		collision.disabled = true

func _reset_attack_cooldown() -> void:
	var cooldown_multiplier: float = 1.0
	if data.system_tag == "剑修" and player != null and player.has_method("get_sword_artifact_cooldown_multiplier"):
		cooldown_multiplier = float(player.call("get_sword_artifact_cooldown_multiplier", data))
	attack_cooldown = (1.0 / maxf(0.1, data.summon_attack_speed)) * cooldown_multiplier

func _notify_artifact_damage() -> void:
	if player != null and player.has_method("notify_artifact_damage"):
		player.call("notify_artifact_damage", data)

func _apply_attribute_on_hit(target: Node, base_damage: float, hit_position: Vector2, pre_hit_hp_ratio: float = -1.0) -> void:
	if player != null and player.has_method("apply_attribute_on_hit"):
		player.call("apply_attribute_on_hit", data, target, base_damage, hit_position, pre_hit_hp_ratio)

func _pre_hit_hp_ratio(target: Node) -> float:
	if target != null and target.has_method("get_hp_ratio"):
		return float(target.call("get_hp_ratio"))
	return -1.0

func _get_damage(base_damage: float) -> float:
	if player != null and player.has_method("get_artifact_damage"):
		return float(player.call("get_artifact_damage", data, base_damage))
	return base_damage

func _damage_multiplier() -> float:
	if player != null and player.has_method("get_artifact_damage"):
		var base_damage := maxf(1.0, data.summon_attack)
		return float(player.call("get_artifact_damage", data, base_damage)) / base_damage
	return 1.0

func _follow_offset() -> Vector2:
	var angle := TAU * float(formation_index) / float(formation_count)
	return Vector2(cos(angle), sin(angle)) * (54.0 + float(formation_index % 3) * 18.0)

func _safe_position(position: Vector2) -> Vector2:
	var arena_size := DEFAULT_ARENA_SIZE
	var scene := get_tree().current_scene
	if scene != null:
		var arena := scene.find_child("Arena_Demo", true, false)
		if arena != null:
			var value: Variant = arena.get("arena_size")
			if value is Vector2:
				arena_size = value
	var half_size := arena_size * 0.5
	return Vector2(
		clampf(position.x, -half_size.x + SUMMON_ARENA_INSET, half_size.x - SUMMON_ARENA_INSET),
		clampf(position.y, -half_size.y + SUMMON_ARENA_INSET, half_size.y - SUMMON_ARENA_INSET)
	)

func _has_special(key: String) -> bool:
	return data.summon_special_effect.find(key) >= 0

func has_enemy_aggro() -> bool:
	return data != null and data.id != "ghost" and data.id != "poison_bug"

func _try_poison_bug_burst(dead_enemy: Node2D) -> void:
	if dead_enemy == null:
		return
	var key: int = dead_enemy.get_instance_id()
	if poison_burst_marks.has(key):
		return
	var chain_limit: int = maxi(1, data.delayed_strike_count)
	if poison_burst_marks.size() >= chain_limit:
		return
	poison_burst_marks[key] = true
	var origin: Vector2 = dead_enemy.global_position
	var radius: float = maxf(12.0, data.poison_explosion_radius)
	var burst_damage: float = data.summon_attack * maxf(0.0, data.poison_explosion_damage_mult)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage") and origin.distance_to((candidate as Node2D).global_position) <= radius:
			var enemy := candidate as Node2D
			damage_enemy(enemy, burst_damage)
			if enemy.has_method("apply_poison"):
				enemy.call("apply_poison", data.poison_dps * _damage_multiplier(), maxf(0.1, data.poison_duration), false, player)
	HitEffectManager.spawn_hit(get_tree(), origin, "poison", Vector2.UP, radius)

func _play_spawn_effect() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.42)
	ring.closed = true
	ring.points = _circle_points(18.0 if data.id != "iron_guard_puppet" else 28.0, 36)
	ring.global_position = global_position
	get_tree().current_scene.add_child(ring)
	if visual != null:
		visual.scale = Vector2(0.35, 0.35)
	var tween := get_tree().create_tween()
	tween.tween_property(ring, "scale", Vector2(1.7, 1.7), 0.22)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.22)
	if visual != null:
		tween.parallel().tween_property(visual, "scale", Vector2.ONE, 0.18)
	tween.tween_callback(ring.queue_free)

func _spawn_death_effect() -> void:
	for index in 6:
		var shard := Polygon2D.new()
		shard.polygon = PackedVector2Array([Vector2(0, -4), Vector2(5, 3), Vector2(-4, 4)])
		shard.color = data.visual_color
		shard.global_position = global_position
		get_tree().current_scene.add_child(shard)
		var tween := get_tree().create_tween()
		tween.tween_property(shard, "global_position", global_position + Vector2.RIGHT.rotated(TAU * float(index) / 6.0) * randf_range(18.0, 34.0), 0.18)
		tween.parallel().tween_property(shard, "modulate:a", 0.0, 0.18)
		tween.tween_callback(shard.queue_free)

func _spawn_respawn_mark() -> void:
	var mark := Line2D.new()
	mark.width = 3.0
	mark.default_color = Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.22)
	mark.closed = true
	mark.points = _circle_points(20.0, 28)
	mark.global_position = global_position
	get_tree().current_scene.add_child(mark)
	var tween := get_tree().create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, maxf(0.3, data.summon_respawn_time))
	tween.tween_callback(mark.queue_free)

func _spawn_damage_flash() -> void:
	if visual == null:
		return
	visual.modulate = Color(1.0, 0.82, 0.62, 1.0)
	var tween := get_tree().create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.08)

func _spawn_muzzle_flash() -> void:
	HitEffectManager.spawn_hit(get_tree(), global_position, "lightning" if data.id == "crossbow_puppet" else "fire", Vector2.RIGHT, 12.0)

func _spawn_swing_arc(direction: Vector2, attack_range: float) -> void:
	var arc := Line2D.new()
	arc.width = 4.0
	arc.default_color = Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.62)
	arc.points = PackedVector2Array([Vector2(0, -12), Vector2(attack_range * 0.45, 0), Vector2(0, 12)])
	arc.global_position = global_position
	arc.rotation = direction.angle()
	get_tree().current_scene.add_child(arc)
	var tween := get_tree().create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.12)
	tween.tween_callback(arc.queue_free)

func _spawn_heavy_swing(origin: Vector2) -> void:
	HitEffectManager.spawn_hit(get_tree(), origin, "earth", global_position.direction_to(origin), 24.0)

func _spawn_taunt_mark(pos: Vector2) -> void:
	var mark := Line2D.new()
	mark.width = 2.5
	mark.default_color = Color(0.95, 0.78, 0.36, 0.55)
	mark.closed = true
	mark.points = _circle_points(12.0, 16)
	mark.global_position = pos
	get_tree().current_scene.add_child(mark)
	var tween := get_tree().create_tween()
	tween.tween_property(mark, "modulate:a", 0.0, 0.22)
	tween.tween_callback(mark.queue_free)

func _spawn_guard_shield(radius: float) -> void:
	var shield := Line2D.new()
	shield.width = 7.0
	shield.default_color = Color(0.78, 0.68, 0.48, 0.38)
	shield.closed = true
	shield.points = _circle_points(maxf(24.0, radius * 0.38), 44)
	shield.global_position = global_position
	get_tree().current_scene.add_child(shield)
	var tween := get_tree().create_tween()
	tween.tween_property(shield, "scale", Vector2.ONE * 2.4, maxf(0.1, data.duration))
	tween.parallel().tween_property(shield, "modulate:a", 0.0, maxf(0.1, data.duration))
	tween.tween_callback(shield.queue_free)

func _spawn_redeploy_effect() -> void:
	HitEffectManager.spawn_hit(get_tree(), global_position, "fire", Vector2.UP, 24.0)

func _spawn_ghost_trail() -> void:
	if int(Time.get_ticks_msec() / 40) % 2 != 0:
		return
	var trail := Line2D.new()
	trail.width = maxf(5.0, data.width * 0.18)
	trail.default_color = Color(data.visual_color.r, data.visual_color.g, data.visual_color.b, 0.22)
	trail.points = PackedVector2Array([-dash_direction * 30.0, Vector2.ZERO])
	trail.global_position = global_position
	get_tree().current_scene.add_child(trail)
	var tween := get_tree().create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.14)
	tween.tween_callback(trail.queue_free)

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
	if data.id == "crossbow_puppet":
		var bow := Line2D.new()
		bow.width = 3.0
		bow.default_color = Color(0.82, 0.95, 1.0, 0.85)
		bow.points = PackedVector2Array([Vector2(-12, -6), Vector2(12, 0), Vector2(-12, 6)])
		visual.add_child(bow)
	elif data.id == "turret":
		var barrel := Line2D.new()
		barrel.width = 7.0
		barrel.default_color = Color(1.0, 0.56, 0.22, 0.9)
		barrel.points = PackedVector2Array([Vector2.ZERO, Vector2(24, 0)])
		visual.add_child(barrel)
	elif data.id == "iron_guard_puppet":
		var shield := Line2D.new()
		shield.width = 5.0
		shield.default_color = Color(0.9, 0.78, 0.5, 0.9)
		shield.points = PackedVector2Array([Vector2(-16, -8), Vector2(-16, 10), Vector2(-5, 16)])
		visual.add_child(shield)

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

func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
