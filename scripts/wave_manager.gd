extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal enemy_killed(gold_reward: int)
signal boss_defeated(wave_number: int)
signal special_enemy_introduced(enemy_type: String)
signal elite_defeated(enemy_type: String)

# Literal mirrors are retained so the existing Excel sync generator can extract them.
const BOSS_WAVES: Array[int] = [5, 9, 13, 17, 20]
const NORMAL_HP_GROWTH_PER_WAVE := 0.008
const BOSS_HP_GROWTH_PER_WAVE := 0.10
const GLOBAL_ENEMY_HP_MULTIPLIER := 1.0
const HP_POWER_GROWTH_START_WAVE := 99
const HP_POWER_GROWTH_PER_WAVE := 0.0
const HP_POWER_GROWTH_EXPONENT := 1.0
const SPAWN_COUNT_GROWTH_PER_WAVE := 0.0
const SURVIVAL_SPAWN_INTERVALS := {1:1.05,2:.98,3:.94,4:.86,5:.82,6:.78,7:.73,8:.69,9:.66,10:.63,11:.61,12:.58,13:.56,14:.54,15:.52,16:.495,17:.47,18:.445,19:.42,20:.40}
const SURVIVAL_PACK_SIZES := {1:2,2:2,3:2,4:2,5:2,6:2,7:2,8:3,9:3,10:3,11:3,12:3,13:3,14:4,15:4,16:4,17:4,18:4,19:4,20:4}
@export var basic_enemy_scene: PackedScene
@export var fast_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var ranged_enemy_scene: PackedScene
@export var charger_enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var spawn_margin := 60.0
@export var minimum_player_spawn_distance := 245.0
@export var arena_size := Vector2(1120.0, 672.0)
@export var survival_mode := true

var player: Player
var wave_number := 0
var alive_enemies := 0
var active := false
var normal_hp_multiplier := 1.0
var normal_damage_multiplier := 1.0
var boss_hp_multiplier := 1.0
var destiny_enemy_stat_multiplier := 1.0
var room_elapsed := 0.0
var spawn_timer := 0.0
var room_duration := 60.0
var elites_spawned := 0
var introduced_types: Dictionary = {}

func configure(target_player: Player) -> void: player = target_player
func set_room_duration(seconds: float) -> void: room_duration = maxf(1.0, seconds)
func set_destiny_enemy_stat_multiplier(multiplier: float) -> void: destiny_enemy_stat_multiplier = maxf(.1, multiplier)
func is_boss_wave(number: int) -> bool: return BOSS_WAVES.has(number)
func is_final_boss_wave(number: int) -> bool: return number == EnemyBalanceConfig.TOTAL_WAVES

func _process(delta: float) -> void:
	if not active or not survival_mode: return
	room_elapsed += delta
	spawn_timer -= delta
	_spawn_scheduled_elites()
	if spawn_timer <= 0.0:
		_spawn_survival_pack()
		var config := EnemyBalanceConfig.wave(wave_number)
		var interval := float(config.spawn_interval)
		if room_elapsed >= room_duration * float(config.late_start): interval /= float(config.late_multiplier)
		spawn_timer = interval

func start_next_wave() -> void:
	if basic_enemy_scene == null or not is_instance_valid(player): return
	wave_number += 1
	active = true
	room_elapsed = 0.0
	spawn_timer = .05
	elites_spawned = 0
	clear_existing_enemies()
	_update_wave_scaling()
	if survival_mode and is_boss_wave(wave_number): _spawn_enemy("boss")
	if not survival_mode: _spawn_survival_pack()
	wave_started.emit(wave_number)

func has_alive_boss() -> bool:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is BossBasic and not bool(enemy.get("dying")): return true
	return false

func pause_wave(paused: bool) -> void:
	active = not paused
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_combat_paused"): enemy.call("set_combat_paused", paused)

func clear_existing_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.queue_free()
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"): projectile.queue_free()
	alive_enemies = 0

func finish_current_room(clear_remaining: bool = true) -> void:
	active = false
	if clear_remaining: clear_existing_enemies()
	wave_cleared.emit(wave_number)

func _spawn_survival_pack() -> void:
	var config := EnemyBalanceConfig.wave(wave_number)
	if alive_enemies >= int(config.max_alive): return
	var count: int = mini(int(config.pack_size), int(config.max_alive) - alive_enemies)
	for _index in count:
		var enemy_type := _roll_enemy_type(config)
		if enemy_type != "": _spawn_enemy(enemy_type)

func _roll_enemy_type(config: Dictionary) -> String:
	var candidates: Array[String] = []
	var total := 0.0
	for key in config.weights:
		var enemy_type := str(key)
		if room_elapsed < float(config.first_spawn_times.get(enemy_type, 0.0)): continue
		if _type_count(enemy_type) >= int(config.type_caps.get(enemy_type, 999)): continue
		if (enemy_type == "fast" or enemy_type == "charger") and _mobile_threat_count() >= int(config.mobile_threat_cap): continue
		candidates.append(enemy_type)
		total += float(config.weights[key])
	if candidates.is_empty(): return "basic" if _type_count("basic") < int(config.type_caps.get("basic", 999)) else ""
	var roll := randf() * total
	for enemy_type in candidates:
		roll -= float(config.weights[enemy_type])
		if roll <= 0.0: return enemy_type
	return candidates.back()

func _spawn_scheduled_elites() -> void:
	var config := EnemyBalanceConfig.wave(wave_number)
	var wanted := int(config.elite_count)
	if elites_spawned >= wanted: return
	var times: Array = config.elite_times
	if elites_spawned < times.size() and room_elapsed >= room_duration * float(times[elites_spawned]):
		var elite_type := _pick_elite_type(config)
		if _spawn_enemy(elite_type, true): elites_spawned += 1

func _pick_elite_type(config: Dictionary) -> String:
	var choices: Array[String] = []
	for enemy_type in ["basic", "tank", "fast", "ranged", "charger"]:
		if config.weights.has(enemy_type) and _type_count(enemy_type) < int(config.type_caps.get(enemy_type, 999)): choices.append(enemy_type)
	return choices.pick_random() if not choices.is_empty() else "basic"

func _spawn_enemy(enemy_type: String, elite := false) -> bool:
	var scene := _scene_for(enemy_type)
	if scene == null: return false
	var enemy := scene.instantiate() as Enemy
	if enemy == null: return false
	if enemy_type == "boss":
		enemy.apply_spawn_scaling(boss_hp_multiplier * destiny_enemy_stat_multiplier, normal_damage_multiplier * destiny_enemy_stat_multiplier)
	else:
		enemy.apply_spawn_scaling(normal_hp_multiplier * destiny_enemy_stat_multiplier, normal_damage_multiplier * destiny_enemy_stat_multiplier)
	get_parent().add_child(enemy)
	enemy.global_position = _safe_edge_position()
	enemy.setup(player)
	if enemy is EnemyRanged: enemy.global_projectile_cap = int(EnemyBalanceConfig.wave(wave_number).enemy_projectile_cap)
	if elite: enemy.configure_elite()
	enemy.died.connect(_on_enemy_died)
	enemy.elite_reward_requested.connect(_on_elite_reward_requested)
	if enemy is BossBasic: enemy.died.connect(_on_boss_died.bind(wave_number))
	alive_enemies += 1
	if (enemy_type == "ranged" or enemy_type == "charger") and not introduced_types.has(enemy_type):
		introduced_types[enemy_type] = true
		special_enemy_introduced.emit(enemy_type)
	return true

func _scene_for(enemy_type: String) -> PackedScene:
	match enemy_type:
		"basic": return basic_enemy_scene
		"fast": return fast_enemy_scene
		"tank": return tank_enemy_scene
		"ranged": return ranged_enemy_scene
		"charger": return charger_enemy_scene
		"boss": return boss_scene
	return null

func _type_count(enemy_type: String) -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if str(enemy.get("enemy_type")) == enemy_type and not bool(enemy.get("dying")): count += 1
	return count

func _mobile_threat_count() -> int: return _type_count("fast") + _type_count("charger")

func _safe_edge_position() -> Vector2:
	var best := Vector2.ZERO
	for _attempt in 12:
		best = _random_edge_position()
		if not is_instance_valid(player) or best.distance_to(player.global_position) >= minimum_player_spawn_distance: return best
	return best

func _random_edge_position() -> Vector2:
	var half := arena_size * .5
	match randi_range(0, 3):
		0: return Vector2(randf_range(-half.x, half.x), -half.y + spawn_margin)
		1: return Vector2(half.x - spawn_margin, randf_range(-half.y, half.y))
		2: return Vector2(randf_range(-half.x, half.x), half.y - spawn_margin)
		_: return Vector2(-half.x + spawn_margin, randf_range(-half.y, half.y))

func _on_enemy_died(gold_reward: int) -> void:
	enemy_killed.emit(gold_reward)
	alive_enemies = maxi(0, alive_enemies - 1)
	if active and not survival_mode and alive_enemies <= 0:
		active = false
		wave_cleared.emit(wave_number)

func _on_elite_reward_requested(enemy_type: String) -> void: elite_defeated.emit(enemy_type)
func _on_boss_died(_reward: int, defeated_wave: int) -> void: boss_defeated.emit(defeated_wave)

func _update_wave_scaling() -> void:
	normal_hp_multiplier = EnemyBalanceConfig.normal_hp_multiplier(wave_number)
	normal_damage_multiplier = EnemyBalanceConfig.normal_damage_multiplier(wave_number)
	boss_hp_multiplier = EnemyBalanceConfig.boss_hp_multiplier(wave_number)
	print("[Wave Scaling] wave=%d hp=x%.3f damage=x%.3f theme=%s" % [wave_number, normal_hp_multiplier, normal_damage_multiplier, EnemyBalanceConfig.wave(wave_number).theme])
