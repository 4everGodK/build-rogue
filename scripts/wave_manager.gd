extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal enemy_killed(gold_reward: int)
signal boss_defeated(wave_number: int)

const NORMAL_HP_GROWTH_PER_WAVE: float = 0.30
const BOSS_HP_GROWTH_PER_WAVE: float = 0.22
const GLOBAL_ENEMY_HP_MULTIPLIER: float = 2.25
const HP_POWER_GROWTH_START_WAVE: int = 3
const HP_POWER_GROWTH_PER_WAVE: float = 0.015
const HP_POWER_GROWTH_EXPONENT: float = 2.0
const SPAWN_COUNT_GROWTH_PER_WAVE: float = 0.35
const BOSS_WAVES: Array[int] = [5, 9, 13, 17, 20]
const FIRST_BOSS_HP_MULTIPLIER: float = 0.8
const EARLY_NORMAL_HP_MULTIPLIERS: Dictionary = {
	1: 1.0,
	2: 1.0,
	3: 1.0,
}
const SURVIVAL_SPAWN_INTERVALS: Dictionary = {
	1: 1.033,
	2: 0.936,
	3: 0.936,
	4: 0.725,
	5: 0.697,
	6: 0.54,
	7: 0.458,
	8: 0.606,
	9: 0.566,
	10: 0.521,
	11: 0.472,
	12: 0.434,
	13: 0.405,
	14: 0.495,
	15: 0.458,
	16: 0.422,
	17: 0.397,
	18: 0.372,
	19: 0.357,
	20: 0.351,
}
const SURVIVAL_PACK_SIZES: Dictionary = {
	1: 2,
	2: 2,
	3: 2,
	4: 2,
	5: 2,
	6: 2,
	7: 2,
	8: 3,
	9: 3,
	10: 3,
	11: 3,
	12: 3,
	13: 3,
	14: 4,
	15: 4,
	16: 4,
	17: 4,
	18: 4,
	19: 4,
	20: 4,
}

@export var basic_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var spawn_margin: float = 60.0
@export var arena_size: Vector2 = Vector2(1120.0, 672.0)
@export var survival_mode: bool = true

var player: Player
var wave_number: int = 0
var alive_enemies: int = 0
var active: bool = false
var normal_hp_multiplier: float = 1.0
var boss_hp_multiplier: float = 1.0
var destiny_enemy_stat_multiplier: float = 1.0
var spawn_count_multiplier: float = 1.0
var room_elapsed: float = 0.0
var spawn_timer: float = 0.0

func configure(target_player: Player) -> void:
	player = target_player

func set_destiny_enemy_stat_multiplier(multiplier: float) -> void:
	destiny_enemy_stat_multiplier = maxf(0.1, multiplier)

func _process(delta: float) -> void:
	if not active or not survival_mode:
		return
	room_elapsed += delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_survival_pack()
		spawn_timer = _survival_spawn_interval(wave_number)

func start_next_wave() -> void:
	if basic_enemy_scene == null or not is_instance_valid(player):
		return
	wave_number += 1
	active = true
	room_elapsed = 0.0
	spawn_timer = 0.05
	clear_existing_enemies()
	_update_wave_scaling(wave_number)
	if survival_mode and is_boss_wave(wave_number):
		_spawn_many(boss_scene, 1, boss_hp_multiplier)
	if not survival_mode:
		_spawn_wave(wave_number)
	wave_started.emit(wave_number)

func is_boss_wave(number: int) -> bool:
	return BOSS_WAVES.has(number)

func is_final_boss_wave(number: int) -> bool:
	return number == 20

func has_alive_boss() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is BossBasic and not bool(enemy.get("dying")):
			return true
	return false

func pause_wave(paused: bool) -> void:
	active = not paused
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_combat_paused"):
			enemy.call("set_combat_paused", paused)
		else:
			enemy.set_physics_process(not paused)

func clear_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	alive_enemies = 0

func finish_current_room(clear_remaining: bool = true) -> void:
	active = false
	if clear_remaining:
		clear_existing_enemies()
	wave_cleared.emit(wave_number)

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
			return {"basic": 10, "fast": 3}
		3:
			return {"basic": 6, "fast": 2, "tank": 1}
		4:
			return {"basic": 11, "fast": 4, "tank": 2}
		_:
			var config: Dictionary = {"basic": 8, "fast": 4, "tank": 2}
			if is_boss_wave(number):
				config["boss"] = 1
			return config

func _spawn_many(scene: PackedScene, count: int, hp_multiplier: float) -> void:
	if scene == null:
		return
	for _index in range(count):
		var enemy: Enemy = scene.instantiate() as Enemy
		if enemy == null:
			continue
		enemy.max_hp *= hp_multiplier * destiny_enemy_stat_multiplier
		if enemy is BossBasic and wave_number == 5:
			enemy.max_hp *= FIRST_BOSS_HP_MULTIPLIER
		enemy.contact_damage = int(ceil(float(enemy.contact_damage) * destiny_enemy_stat_multiplier))
		if enemy is BossBasic:
			(enemy as BossBasic).bullet_damage = int(ceil(float((enemy as BossBasic).bullet_damage) * destiny_enemy_stat_multiplier))
		get_parent().add_child(enemy)
		enemy.hp = enemy.max_hp
		enemy.global_position = _random_edge_position()
		enemy.setup(player)
		enemy.died.connect(_on_enemy_died)
		if enemy is BossBasic:
			enemy.died.connect(_on_boss_died.bind(wave_number))
		alive_enemies += 1

func _spawn_survival_pack() -> void:
	var pack_count: int = _survival_pack_count()
	for _index in range(pack_count):
		_spawn_many(_roll_survival_enemy_scene(), 1, normal_hp_multiplier)

func _survival_pack_count() -> int:
	return int(SURVIVAL_PACK_SIZES.get(wave_number, 4))

func _survival_spawn_interval(number: int) -> float:
	return float(SURVIVAL_SPAWN_INTERVALS.get(number, 0.351))

func _roll_survival_enemy_scene() -> PackedScene:
	var roll: float = randf()
	if wave_number >= 3 and tank_enemy_scene != null and roll < 0.12:
		return tank_enemy_scene
	if wave_number >= 4 and tank_enemy_scene != null and roll < 0.22:
		return tank_enemy_scene
	if wave_number >= 2 and fast_enemy_scene != null and roll < 0.48:
		return fast_enemy_scene
	return basic_enemy_scene

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
	if active and not survival_mode and alive_enemies <= 0:
		active = false
		wave_cleared.emit(wave_number)

func _on_boss_died(_gold_reward: int, defeated_wave_number: int) -> void:
	boss_defeated.emit(defeated_wave_number)

func _update_wave_scaling(number: int) -> void:
	var power_growth_bonus := _hp_power_growth_bonus(number)
	normal_hp_multiplier = float(EARLY_NORMAL_HP_MULTIPLIERS.get(number, 1.0 + float(number - 3) * NORMAL_HP_GROWTH_PER_WAVE + power_growth_bonus)) * GLOBAL_ENEMY_HP_MULTIPLIER
	boss_hp_multiplier = (1.0 + float(number - 1) * BOSS_HP_GROWTH_PER_WAVE + power_growth_bonus) * GLOBAL_ENEMY_HP_MULTIPLIER
	spawn_count_multiplier = 1.0 + float(number - 1) * SPAWN_COUNT_GROWTH_PER_WAVE
	print("[Wave Scaling] wave=%d normal_hp=x%.2f boss_hp=x%.2f spawn_count=x%.2f" % [
		number,
		normal_hp_multiplier,
		boss_hp_multiplier,
		spawn_count_multiplier,
	])

func _hp_power_growth_bonus(number: int) -> float:
	var wave_delta: int = maxi(0, number - HP_POWER_GROWTH_START_WAVE)
	return pow(float(wave_delta), HP_POWER_GROWTH_EXPONENT) * HP_POWER_GROWTH_PER_WAVE

func _scaled_spawn_count(base_count: int) -> int:
	if base_count <= 0:
		return 0
	return maxi(1, ceili(float(base_count) * spawn_count_multiplier))
