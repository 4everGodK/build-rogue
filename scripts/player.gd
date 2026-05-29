extends CharacterBody2D
class_name Player

signal hp_changed(current_hp: int, max_hp: int)
signal gold_changed(gold: int)
signal artifacts_changed(artifacts: Array)
signal died

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var invincible_duration: float = 0.7

var hp: int = max_hp
var gold: int = 10
var artifact_inventory: Array[Dictionary] = []
var invincible_time: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var artifact_controller: ArtifactController = $ArtifactController

func _ready() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	gold_changed.emit(gold)

func _physics_process(delta: float) -> void:
	var direction: Vector2 = _read_move_input()
	velocity = direction * move_speed
	move_and_slide()

	if invincible_time > 0.0:
		invincible_time -= delta
		visual.modulate = Color(1.0, 1.0, 1.0, 0.45) if int(Time.get_ticks_msec() / 80) % 2 == 0 else Color.WHITE
	else:
		visual.modulate = Color.WHITE

func _read_move_input() -> Vector2:
	var x: float = 0.0
	var y: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		y += 1.0
	return Vector2(x, y).normalized()

func take_damage(amount: int) -> void:
	if invincible_time > 0.0:
		return

	hp = max(0, hp - amount)
	invincible_time = invincible_duration
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_artifact(artifact: Dictionary) -> void:
	artifact_inventory.append(artifact.duplicate(true))
	artifacts_changed.emit(artifact_inventory)
	artifact_controller.set_artifacts(artifact_inventory)
