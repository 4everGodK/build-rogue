extends Node
class_name WaveManager

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal enemy_killed(gold_reward: int)

@export var enemy_scene: PackedScene
@export var spawn_margin: float = 60.0

var player: Player
var wave_number: int = 0
var alive_enemies: int = 0
var active: bool = false

func configure(target_player: Player) -> void:
	player = target_player

func start_next_wave() -> void:
	if enemy_scene == null or not is_instance_valid(player):
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
	var config := _wave_config(number)
	for index in range(int(config.get("count", 1))):
		var enemy := enemy_scene.instantiate() as Enemy
		get_parent().add_child(enemy)
		enemy.global_position = _random_edge_position()
		enemy.setup(player)
		enemy.gold_reward = int(config.get("gold_reward", 1))
		enemy.max_hp *= float(config.get("hp_multiplier", 1.0))
		enemy.hp = enemy.max_hp
		enemy.move_speed *= float(config.get("speed_multiplier", 1.0))
		if bool(config.get("boss", false)):
			enemy.scale = Vector2.ONE * 2.0
		enemy.died.connect(_on_enemy_died)
		alive_enemies += 1

func _wave_config(number: int) -> Dictionary:
	var cycle := ((number - 1) % 5) + 1
	match cycle:
		1:
			return {"count": 5, "gold_reward": 1}
		2:
			return {"count": 8, "gold_reward": 1}
		3:
			return {"count": 12, "gold_reward": 1}
		4:
			return {"count": 15, "gold_reward": 1}
		_:
			return {"count": 1, "gold_reward": 10, "hp_multiplier": 8.0, "speed_multiplier": 0.65, "boss": true}

func _random_edge_position() -> Vector2:
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var side := randi_range(0, 3)
	match side:
		0:
			return Vector2(randf_range(0, viewport.x), -spawn_margin)
		1:
			return Vector2(viewport.x + spawn_margin, randf_range(0, viewport.y))
		2:
			return Vector2(randf_range(0, viewport.x), viewport.y + spawn_margin)
		_:
			return Vector2(-spawn_margin, randf_range(0, viewport.y))

func _on_enemy_died(gold_reward: int) -> void:
	enemy_killed.emit(gold_reward)
	alive_enemies = max(0, alive_enemies - 1)
	if active and alive_enemies <= 0:
		active = false
		wave_cleared.emit(wave_number)
