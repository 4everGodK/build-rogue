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

var hp: float = max_hp
var player: Player
var flash_time: float = 0.0
var poison_stacks: Array[Dictionary] = []
var knockback_velocity: Vector2 = Vector2.ZERO
var slow_effects: Dictionary = {}
var damage_reduction_effects: Dictionary = {}
var contact_damage_cooldown: float = 0.0

@onready var visual: Polygon2D = $Visual

func _physics_process(delta: float) -> void:
	if contact_damage_cooldown > 0.0:
		contact_damage_cooldown -= delta
	if is_instance_valid(player):
		var to_player := global_position.direction_to(player.global_position)
		if to_player == Vector2.ZERO:
			to_player = Vector2.RIGHT.rotated(randf() * TAU)
		var distance := global_position.distance_to(player.global_position)
		if distance > separation_radius:
			velocity = to_player * move_speed * _current_speed_multiplier()
		elif distance < contact_radius:
			velocity = -to_player * move_speed * 0.65 * _current_speed_multiplier()
		else:
			velocity = Vector2.ZERO
		velocity += knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		if distance <= contact_radius:
			_try_contact_damage(player)

	if flash_time > 0.0:
		flash_time -= delta
		visual.modulate = Color(1.0, 0.45, 0.45)
	else:
		visual.modulate = Color.WHITE

	_process_poison(delta)
	_process_timed_effects(delta)

func setup(target_player: Player) -> void:
	player = target_player

func take_damage(amount: float, _source = null) -> bool:
	if hp <= 0.0 or is_queued_for_deletion():
		return true
	hp -= amount
	flash_time = 0.08
	if hp <= 0.0:
		died.emit(gold_reward)
		queue_free()
		return true
	return false

func apply_poison(dps: float, duration: float, can_stack: bool) -> void:
	if dps <= 0.0 or duration <= 0.0:
		return
	if not can_stack:
		poison_stacks.clear()
	poison_stacks.append({"dps": dps, "time_left": duration})

func get_hp_ratio() -> float:
	return hp / max_hp

func apply_knockback(from_position: Vector2, force: float) -> void:
	if force <= 0.0:
		return
	knockback_velocity += from_position.direction_to(global_position) * force

func apply_slow(percent: float, duration: float, source = null) -> void:
	slow_effects[str(source)] = {"value": clampf(percent, 0.0, 0.9), "time_left": duration}

func apply_damage_reduction(percent: float, duration: float, source = null) -> void:
	damage_reduction_effects[str(source)] = {"value": clampf(percent, 0.0, 0.9), "time_left": duration}

func _current_speed_multiplier() -> float:
	var strongest: float = 0.0
	for effect in slow_effects.values():
		strongest = maxf(strongest, float(effect.get("value", 0.0)))
	return 1.0 - strongest

func _current_damage_multiplier() -> float:
	var strongest: float = 0.0
	for effect in damage_reduction_effects.values():
		strongest = maxf(strongest, float(effect.get("value", 0.0)))
	return 1.0 - strongest

func _process_timed_effects(delta: float) -> void:
	_tick_effect_dictionary(slow_effects, delta)
	_tick_effect_dictionary(damage_reduction_effects, delta)

func _tick_effect_dictionary(effects: Dictionary, delta: float) -> void:
	for key in effects.keys():
		var effect: Dictionary = effects[key]
		effect["time_left"] = float(effect.get("time_left", 0.0)) - delta
		if float(effect["time_left"]) <= 0.0:
			effects.erase(key)
		else:
			effects[key] = effect

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

func _try_contact_damage(target_player: Player) -> void:
	if contact_damage_cooldown > 0.0:
		return
	target_player.take_damage(int(ceil(float(contact_damage) * _current_damage_multiplier())))
	contact_damage_cooldown = contact_damage_interval
