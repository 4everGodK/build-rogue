extends CharacterBody2D
class_name Player

signal hp_changed(current_hp: int, max_hp: int)
signal shield_changed(current_shield: float, max_shield: float)
signal died

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var invincible_duration: float = 0.7

var hp: int = max_hp
var movement_paused: bool = true
var invincible_time: float = 0.0
var shield: float = 0.0
var shield_limit: float = 0.0
var artifact_cooldown_multiplier: float = 1.0

@onready var visual: Polygon2D = $Visual
@onready var artifact_manager: ArtifactManager = $ArtifactManager

func _ready() -> void:
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
	if invincible_time > 0.0:
		invincible_time -= delta
		visual.modulate = Color(1.0, 1.0, 1.0, 0.45) if int(Time.get_ticks_msec() / 80) % 2 == 0 else Color.WHITE
	else:
		visual.modulate = Color.WHITE

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
	hp_changed.emit(hp, max_hp)
	shield_changed.emit(shield, shield_limit)
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
	var cap := shield_limit if shield_limit > 0.0 else float(max_hp)
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

func reset_combat_state() -> void:
	artifact_manager.clear_artifacts()
	shield = 0.0
	shield_limit = 0.0
	artifact_cooldown_multiplier = 1.0
	shield_changed.emit(shield, shield_limit)

func set_battle_paused(paused: bool) -> void:
	movement_paused = paused
	artifact_manager.set_battle_paused(paused)
