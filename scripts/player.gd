extends CharacterBody2D
class_name Player

signal hp_changed(current_hp: int, max_hp: int)
signal gold_changed(gold: int)
signal artifacts_changed(artifacts: Array)
signal died

const FUSION_COUNT: int = 3
const MAX_ARTIFACT_LEVEL: int = 3

@export var move_speed: float = 220.0
@export var max_hp: int = 100
@export var invincible_duration: float = 0.7

var hp: int = max_hp
var gold: int = 10
var artifact_inventory: Array[Dictionary] = []
var invincible_time: float = 0.0
var shield: float = 0.0
var earth_shield_timer: float = 0.0
var synergy_manager: SynergyManager

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

	_process_attribute_recovery(delta)

func configure_synergy_manager(manager: SynergyManager) -> void:
	synergy_manager = manager

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

	var final_damage: float = float(amount)
	if synergy_manager != null:
		var attribute_modifier: AttributeSynergyModifier = synergy_manager.get_attribute_modifier()
		final_damage *= attribute_modifier.earth_damage_taken_multiplier()
		if attribute_modifier.earth_counter_enabled():
			_counter_nearby_enemies()

	var shield_damage: float = min(shield, final_damage)
	shield -= shield_damage
	final_damage -= shield_damage

	hp = max(0, hp - int(ceil(final_damage)))
	invincible_time = invincible_duration
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		died.emit()

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	var missing_hp: float = float(max_hp - hp)
	var applied_heal: float = min(missing_hp, amount)
	var old_hp: int = hp
	var old_shield: float = shield
	hp = min(max_hp, hp + int(floor(applied_heal)))
	var overflow: float = amount - applied_heal
	if synergy_manager != null and overflow > 0.0 and synergy_manager.get_attribute_modifier().water_overheal_to_shield():
		add_shield(overflow)
	if hp != old_hp or not is_equal_approx(shield, old_shield):
		hp_changed.emit(hp, max_hp)

func add_shield(amount: float) -> void:
	if amount <= 0.0:
		return
	shield = min(float(max_hp) * 0.6, shield + amount)

func get_hp_ratio() -> float:
	return float(hp) / float(max_hp)

func get_attribute_modifier() -> AttributeSynergyModifier:
	if synergy_manager == null:
		return AttributeSynergyModifier.new()
	return synergy_manager.get_attribute_modifier()

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_artifact(artifact: Dictionary) -> void:
	var new_artifact: Dictionary = artifact.duplicate(true)
	if not new_artifact.has("level"):
		new_artifact["level"] = 1
	artifact_inventory.append(new_artifact)
	var artifact_id: String = str(new_artifact.get("id", ""))
	_resolve_fusions(artifact_id, int(new_artifact.get("level", 1)))
	_sync_artifacts()

func _resolve_fusions(artifact_id: String, starting_level: int) -> void:
	var current_level: int = starting_level
	var fused: bool = true
	while fused:
		fused = false
		if current_level >= MAX_ARTIFACT_LEVEL:
			return
		var matching_indices: Array[int] = _find_matching_artifact_indices(artifact_id, current_level)
		if matching_indices.size() >= FUSION_COUNT:
			for remove_index in range(FUSION_COUNT - 1, -1, -1):
				artifact_inventory.remove_at(matching_indices[remove_index])

			var upgraded_artifact: Dictionary = ArtifactCatalog.get_artifact(artifact_id)
			upgraded_artifact["level"] = current_level + 1
			artifact_inventory.append(upgraded_artifact)
			current_level += 1
			fused = true

func _find_matching_artifact_indices(artifact_id: String, level: int) -> Array[int]:
	var indices: Array[int] = []
	for index in artifact_inventory.size():
		var artifact: Dictionary = artifact_inventory[index]
		if artifact.get("id", "") == artifact_id and int(artifact.get("level", 1)) == level:
			indices.append(index)
	return indices

func _sync_artifacts() -> void:
	artifacts_changed.emit(artifact_inventory)
	artifact_controller.set_artifacts(artifact_inventory)

func _process_attribute_recovery(delta: float) -> void:
	if synergy_manager == null:
		return

	var modifier: AttributeSynergyModifier = synergy_manager.get_attribute_modifier()
	heal(modifier.water_regen_per_second() * delta)

	var shield_amount: float = modifier.earth_periodic_shield_amount(max_hp)
	if shield_amount > 0.0:
		earth_shield_timer += delta
		if earth_shield_timer >= 8.0:
			earth_shield_timer = 0.0
			add_shield(shield_amount)
	else:
		earth_shield_timer = 0.0

func _counter_nearby_enemies() -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Enemy and global_position.distance_to(body.global_position) <= 90.0:
			var enemy: Enemy = body
			enemy.take_damage(8.0)
