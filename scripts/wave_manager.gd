extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal enemy_killed(gold_reward: int)

const NORMAL_HP_GROWTH_PER_WAVE: float = 0.12
const BOSS_HP_GROWTH_PER_WAVE: float = 0.18
const SPAWN_COUNT_GROWTH_PER_WAVE: float = 0.08

@export var basic_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var spawn_margin: float = 60.0
@export var arena_size: Vector2 = Vector2(2000.0, 1200.0)

var player: Player
var wave_number: int = 0
var alive_enemies: int = 0
var active: bool = false
var normal_hp_multiplier: float = 1.0
var boss_hp_multiplier: float = 1.0
var spawn_count_multiplier: float = 1.0

func configure(target_player: Player) -> void:
	player = target_player

func start_next_wave() -> void:
	if basic_enemy_scene == null or not is_instance_valid(player):
		return
	wave_number += 1
	active = true
	_spawn_wave(wave_number)
	wave_started.emit(wave_number)

func pause_wave(paused: bool) -> void:
	active = not paused
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(not paused)

func clear_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	alive_enemies = 0

func _spawn_wave(number: int) -> void:
	clear_existing_enemies()
	_update_wave_scaling(number)
	var config: Dictionary = _wave_config(number)
	_spawn_many(basic_enemy_scene, _scaled_spawn_count(int(config.get("basic", 0))), normal_hp_multiplier)
	_spawn_many(fast_enemy_scene, _scaled_spawn_count(int(config.get("fast", 0))), normal_hp_multiplier)
	_spawn_many(tank_enemy_scene, _scaled_spawn_count(int(config.get("tank", 0))), normal_hp_multiplier)
	_spawn_many(boss_scene, _scaled_spawn_count(int(config.get("boss", 0))), boss_hp_multiplier)

func _wave_config(number: int) -> Dictionary:
	match number:
		1:
			return {"basic": 5}
		2:
			return {"basic": 8, "fast": 2}
		3:
			return {"basic": 10, "fast": 4, "tank": 2}
		4:
			return {"basic": 15, "fast": 5, "tank": 4}
		_:
			return {"boss": 1}

func _spawn_many(scene: PackedScene, count: int, hp_multiplier: float) -> void:
	if scene == null:
		return
	for _index in range(count):
		var enemy: Enemy = scene.instantiate() as Enemy
		if enemy == null:
			continue
		enemy.max_hp *= hp_multiplier
		get_parent().add_child(enemy)
		enemy.hp = enemy.max_hp
		enemy.global_position = _random_edge_position()
		enemy.setup(player)
		enemy.died.connect(_on_enemy_died)
		alive_enemies += 1

func _random_edge_position() -> Vector2:
	var half_size: Vector2 = arena_size * 0.5
	var side: int = randi_range(0, 3)
	match side:
		0:
			return Vector2(randf_range(-half_size.x, half_size.x), -half_size.y + spawn_margin)
		1:
			return Vector2(half_size.x - spawn_margin, randf_range(-half_size.y, half_size.y))
		2:
			return Vector2(randf_range(-half_size.x, half_size.x), half_size.y - spawn_margin)
		_:
			return Vector2(-half_size.x + spawn_margin, randf_range(-half_size.y, half_size.y))

func _on_enemy_died(gold_reward: int) -> void:
	enemy_killed.emit(gold_reward)
	alive_enemies = max(0, alive_enemies - 1)
	if active and alive_enemies <= 0:
		active = false
		wave_cleared.emit(wave_number)

func _update_wave_scaling(number: int) -> void:
	normal_hp_multiplier = 1.0 + float(number - 1) * NORMAL_HP_GROWTH_PER_WAVE
	boss_hp_multiplier = 1.0 + float(number - 1) * BOSS_HP_GROWTH_PER_WAVE
	spawn_count_multiplier = 1.0 + float(number - 1) * SPAWN_COUNT_GROWTH_PER_WAVE
	print("[Wave Scaling] wave=%d normal_hp=x%.2f boss_hp=x%.2f spawn_count=x%.2f" % [
		number,
		normal_hp_multiplier,
		boss_hp_multiplier,
		spawn_count_multiplier,
	])

func _scaled_spawn_count(base_count: int) -> int:
	if base_count <= 0:
		return 0
	return maxi(1, ceili(float(base_count) * spawn_count_multiplier))
