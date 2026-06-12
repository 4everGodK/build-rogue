extends CharacterBody2D
class_name Enemy

signal died(gold_reward: int)

@export var max_hp: float = 20.0
@export var move_speed: float = 80.0
@export var contact_damage: int = 8
@export var contact_radius: float = 24.0
@export var separation_radius: float = 36.0
@export var contact_damage_interval: float = 0.8
@export var gold_reward: int = 2
@export var death_animation_duration: float = 0.15
@export var arena_half_size: Vector2 = Vector2(784.0, 464.0)

var hp: float = max_hp
var player: Player
var flash_time: float = 0.0
var dying: bool = false
var poison_stacks: Array[Dictionary] = []
var knockback_velocity: Vector2 = Vector2.ZERO
var slow_effects: Dictionary = {}
var root_effects: Dictionary = {}
var stun_effects: Dictionary = {}
var damage_taken_effects: Dictionary = {}
var effect_cooldowns: Dictionary = {}
var damage_reduction_effects: Dictionary = {}
var contact_damage_cooldown: float = 0.0
var taunt_target: Node2D
var taunt_time: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var contact_area: Area2D = $ContactArea

func _ready() -> void:
	hp = max_hp

func _physics_process(delta: float) -> void:
	if dying:
		return
	if contact_damage_cooldown > 0.0:
		contact_damage_cooldown -= delta
	_tick_cooldowns(delta)
	var current_target := _current_target()
	if _is_stunned():
		velocity = Vector2.ZERO
		move_and_slide()
	elif is_instance_valid(current_target):
		var to_target: Vector2 = global_position.direction_to(current_target.global_position)
		if to_target == Vector2.ZERO:
			to_target = Vector2.RIGHT.rotated(randf() * TAU)
		var distance: float = global_position.distance_to(current_target.global_position)
		if distance > separation_radius:
			velocity = to_target * move_speed * _current_speed_multiplier()
		elif distance < contact_radius:
			velocity = -to_target * move_speed * 0.65 * _current_speed_multiplier()
		else:
			velocity = Vector2.ZERO
		velocity += knockback_velocity
		move_and_slide()
		clamp_to_arena()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		var contact_distance: float = global_position.distance_to(current_target.global_position)
		if contact_distance <= maxf(contact_radius, separation_radius) and not _is_stunned():
			_try_contact_damage(current_target)

	if flash_time > 0.0:
		flash_time -= delta
		visual.modulate = Color.WHITE
	else:
		visual.modulate = Color.WHITE

	_process_poison(delta)
	_process_timed_effects(delta)
	if taunt_time > 0.0:
		taunt_time -= delta

func setup(target_player: Player) -> void:
	player = target_player

func set_combat_paused(paused: bool) -> void:
	set_physics_process(not paused)
	set_process(not paused)
	velocity = Vector2.ZERO
	if contact_area != null:
		contact_area.monitoring = not paused

func clamp_to_arena() -> void:
	global_position = global_position.clamp(-arena_half_size, arena_half_size)

func take_damage(amount: float, _source = null) -> bool:
	if dying or hp <= 0.0 or is_queued_for_deletion():
		return false
	var final_amount: float = amount * _current_incoming_damage_multiplier()
	hp -= final_amount
	flash_time = 0.08
	_spawn_damage_number(final_amount)
	if hp <= 0.0:
		_die()
		return true
	return false

func apply_poison(dps: float, duration: float, can_stack: bool, source = null, burst_radius: float = 0.0, burst_damage: float = 0.0) -> void:
	if dps <= 0.0 or duration <= 0.0:
		return
	if not can_stack:
		poison_stacks.clear()
	poison_stacks.append({
		"dps": dps,
		"time_left": duration,
		"source": source,
		"burst_radius": burst_radius,
		"burst_damage": burst_damage,
	})

func get_hp_ratio() -> float:
	return hp / max_hp

func apply_knockback(from_position: Vector2, force: float) -> void:
	if force <= 0.0:
		return
	knockback_velocity += from_position.direction_to(global_position) * force

func apply_slow(percent: float, duration: float, source = null) -> void:
	slow_effects[str(source)] = {"value": clampf(percent, 0.0, 0.9), "time_left": duration}

func apply_root(duration: float, source = null, internal_cooldown: float = 0.0) -> bool:
	if duration <= 0.0:
		return false
	var key: String = "root:%s" % str(source)
	if float(effect_cooldowns.get(key, 0.0)) > 0.0:
		return false
	root_effects[str(source)] = {"value": 1.0, "time_left": duration}
	if internal_cooldown > 0.0:
		effect_cooldowns[key] = internal_cooldown
	return true

func apply_stun(duration: float, source = null, internal_cooldown: float = 0.0) -> bool:
	if duration <= 0.0:
		return false
	var key: String = "stun:%s" % str(source)
	if float(effect_cooldowns.get(key, 0.0)) > 0.0:
		return false
	stun_effects[str(source)] = {"value": 1.0, "time_left": duration}
	if internal_cooldown > 0.0:
		effect_cooldowns[key] = internal_cooldown
	return true

func apply_damage_taken_multiplier(percent: float, duration: float, source = null) -> void:
	if percent <= 0.0 or duration <= 0.0:
		return
	damage_taken_effects[str(source)] = {"value": maxf(0.0, percent), "time_left": duration}

func apply_damage_reduction(percent: float, duration: float, source = null) -> void:
	damage_reduction_effects[str(source)] = {"value": clampf(percent, 0.0, 0.9), "time_left": duration}

func apply_taunt(source: Node2D, duration: float) -> void:
	if source == null or duration <= 0.0:
		return
	taunt_target = source
	taunt_time = duration

func _current_speed_multiplier() -> float:
	if _is_rooted() or _is_stunned():
		return 0.0
	var strongest: float = 0.0
	for effect in slow_effects.values():
		strongest = maxf(strongest, float(effect.get("value", 0.0)))
	return 1.0 - strongest

func _is_rooted() -> bool:
	return not root_effects.is_empty()

func _is_stunned() -> bool:
	return not stun_effects.is_empty()

func _current_incoming_damage_multiplier() -> float:
	var strongest: float = 0.0
	for effect in damage_taken_effects.values():
		strongest = maxf(strongest, float(effect.get("value", 0.0)))
	return 1.0 + strongest

func _current_damage_multiplier() -> float:
	var strongest: float = 0.0
	for effect in damage_reduction_effects.values():
		strongest = maxf(strongest, float(effect.get("value", 0.0)))
	return 1.0 - strongest

func _process_timed_effects(delta: float) -> void:
	_tick_effect_dictionary(slow_effects, delta)
	_tick_effect_dictionary(root_effects, delta)
	_tick_effect_dictionary(stun_effects, delta)
	_tick_effect_dictionary(damage_taken_effects, delta)
	_tick_effect_dictionary(damage_reduction_effects, delta)

func _tick_effect_dictionary(effects: Dictionary, delta: float) -> void:
	for key in effects.keys():
		var effect: Dictionary = effects[key]
		effect["time_left"] = float(effect.get("time_left", 0.0)) - delta
		if float(effect["time_left"]) <= 0.0:
			effects.erase(key)
		else:
			effects[key] = effect

func _tick_cooldowns(delta: float) -> void:
	for key in effect_cooldowns.keys():
		var time_left: float = float(effect_cooldowns.get(key, 0.0)) - delta
		if time_left <= 0.0:
			effect_cooldowns.erase(key)
		else:
			effect_cooldowns[key] = time_left

func _process_poison(delta: float) -> void:
	if poison_stacks.is_empty():
		return

	var total_damage: float = 0.0
	for index in range(poison_stacks.size() - 1, -1, -1):
		var poison: Dictionary = poison_stacks[index]
		total_damage += float(poison.get("dps", 0.0)) * delta
		poison["time_left"] = float(poison.get("time_left", 0.0)) - delta
		if float(poison["time_left"]) <= 0.0:
			poison_stacks.remove_at(index)
		else:
			poison_stacks[index] = poison

	if total_damage > 0.0:
		take_damage(total_damage)

func _on_contact_area_body_entered(body: Node) -> void:
	if body is Player:
		_try_contact_damage(body)

func _try_contact_damage(target: Node) -> void:
	if contact_damage_cooldown > 0.0:
		return
	if target != null and target.has_method("take_damage"):
		var damage := int(ceil(float(contact_damage) * _current_damage_multiplier()))
		if target is Player:
			target.call("take_damage", damage)
		else:
			target.call("take_damage", damage, self)
	contact_damage_cooldown = contact_damage_interval

func _current_target() -> Node2D:
	if taunt_time > 0.0 and is_instance_valid(taunt_target):
		return taunt_target
	var nearest: Node2D = player
	var nearest_distance_squared: float = INF
	if is_instance_valid(player):
		nearest_distance_squared = global_position.distance_squared_to(player.global_position)
	for candidate in get_tree().get_nodes_in_group("summons"):
		if not candidate is Node2D or not candidate.has_method("take_damage"):
			continue
		if candidate.has_method("has_enemy_aggro") and not bool(candidate.call("has_enemy_aggro")):
			continue
		if candidate.is_queued_for_deletion() or not bool(candidate.get("visible")):
			continue
		if str(candidate.get("state")) == "Respawn":
			continue
		var summon := candidate as Node2D
		var distance_squared: float = global_position.distance_squared_to(summon.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = summon
			nearest_distance_squared = distance_squared
	return nearest

func _spawn_damage_number(amount: float) -> void:
	var label: Label = Label.new()
	label.text = str(int(ceil(amount)))
	label.modulate = Color(1.0, 0.95, 0.45, 1.0)
	label.position = global_position + Vector2(-8.0, -28.0)
	get_tree().current_scene.add_child(label)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0.0, -24.0), 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(label.queue_free)

func _die() -> void:
	_try_poison_death_burst()
	dying = true
	set_physics_process(false)
	died.emit(gold_reward)
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, death_animation_duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, death_animation_duration)
	tween.tween_callback(queue_free)

func _try_poison_death_burst() -> void:
	var best_radius: float = 0.0
	var best_damage: float = 0.0
	var burst_source = null
	for poison in poison_stacks:
		var radius: float = float(poison.get("burst_radius", 0.0))
		var damage: float = float(poison.get("burst_damage", 0.0))
		if radius > 0.0 and damage > best_damage:
			best_radius = radius
			best_damage = damage
			burst_source = poison.get("source", null)
	if best_radius <= 0.0 or best_damage <= 0.0:
		return
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate == self:
			continue
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= best_radius:
				candidate.call("take_damage", best_damage, burst_source)
	HitEffectManager.spawn_hit(get_tree(), global_position, "poison", Vector2.UP, best_radius)
