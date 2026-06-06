extends CharacterBody2D
class_name Player

signal hp_changed(current_hp: int, max_hp: int)
signal shield_changed(current_shield: float, max_shield: float)
signal died

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var invincible_duration: float = 0.5
@export var counter_radius: float = 92.0
@export var arena_half_size: Vector2 = Vector2(980.0, 580.0)

var hp: int = max_hp
var base_max_hp: int = 100
var movement_paused: bool = true
var invincible_time: float = 0.0
var shield: float = 0.0
var shield_limit: float = 0.0
var artifact_cooldown_multiplier: float = 1.0
var body_counter_enabled: bool = false
var body_counter_damage: float = 8.0

@onready var visual: Polygon2D = $Visual
@onready var artifact_manager: ArtifactManager = $ArtifactManager

func _ready() -> void:
	base_max_hp = max_hp
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	shield_changed.emit(shield, shield_limit)

func _physics_process(delta: float) -> void:
	if movement_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	velocity = _read_move_input() * move_speed
	move_and_slide()
	global_position = global_position.clamp(-arena_half_size, arena_half_size)
	if invincible_time > 0.0:
		invincible_time -= delta
		visual.modulate = Color(1.0, 0.25, 0.25, 0.85) if int(Time.get_ticks_msec() / 80) % 2 == 0 else Color.WHITE
	else:
		visual.modulate = Color.WHITE
		visual.scale = visual.scale.move_toward(Vector2.ONE, delta * 8.0)

func _read_move_input() -> Vector2:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		direction.x += 1.0
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		direction.y += 1.0
	return direction.normalized()

func take_damage(amount: int) -> void:
	if invincible_time > 0.0:
		return
	var remaining_damage := float(amount)
	var absorbed := minf(shield, remaining_damage)
	shield -= absorbed
	remaining_damage -= absorbed
	hp = max(0, hp - int(ceil(remaining_damage)))
	invincible_time = invincible_duration
	visual.modulate = Color(1.0, 0.2, 0.2, 1.0)
	visual.scale = Vector2(1.18, 1.18)
	hp_changed.emit(hp, max_hp)
	shield_changed.emit(shield, shield_limit)
	if body_counter_enabled:
		_counter_nearby_enemies()
	if hp <= 0:
		died.emit()

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	hp = mini(max_hp, hp + int(ceil(amount)))
	hp_changed.emit(hp, max_hp)

func add_shield(amount: float, maximum: float = 0.0) -> void:
	if maximum > 0.0:
		shield_limit = maxf(shield_limit, maximum)
	var cap: float = shield_limit if shield_limit > 0.0 else float(max_hp)
	shield = minf(cap, shield + maxf(0.0, amount))
	shield_changed.emit(shield, cap)

func spend_life_percent(percent: float) -> void:
	var cost := maxi(1, int(ceil(float(max_hp) * maxf(0.0, percent) * 0.01)))
	hp = maxi(1, hp - cost)
	hp_changed.emit(hp, max_hp)

func set_artifact_cooldown_multiplier(multiplier: float) -> void:
	artifact_cooldown_multiplier = clampf(multiplier, 0.1, 1.0)

func get_artifact_cooldown_multiplier() -> float:
	return artifact_cooldown_multiplier

func get_hp_ratio() -> float:
	return float(hp) / float(max_hp)

func set_body_synergy(max_hp_bonus: int, counter_enabled: bool, counter_damage: float) -> void:
	var old_max_hp := max_hp
	max_hp = base_max_hp + max_hp_bonus
	hp = mini(max_hp, hp + max(0, max_hp - old_max_hp))
	body_counter_enabled = counter_enabled
	body_counter_damage = counter_damage
	hp_changed.emit(hp, max_hp)

func reset_combat_state() -> void:
	artifact_manager.clear_artifacts()
	shield = 0.0
	shield_limit = 0.0
	artifact_cooldown_multiplier = 1.0
	shield_changed.emit(shield, shield_limit)

func set_battle_paused(paused: bool) -> void:
	movement_paused = paused
	artifact_manager.set_battle_paused(paused)

func _counter_nearby_enemies() -> void:
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if global_position.distance_to((candidate as Node2D).global_position) <= counter_radius:
				candidate.call("take_damage", body_counter_damage, self)
