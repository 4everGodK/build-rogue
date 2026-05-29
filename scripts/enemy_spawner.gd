extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var base_interval: float = 1.6
@export var min_interval: float = 0.35
@export var spawn_margin: float = 60.0

var player: Player
var active: bool = false
var battle_elapsed: float = 0.0
var spawn_timer: float = 0.0

func start_battle(target_player: Player) -> void:
	player = target_player
	active = true
	battle_elapsed = 0.0
	spawn_timer = 0.2

func stop_battle() -> void:
	active = false

func _process(delta: float) -> void:
	if not active or enemy_scene == null:
		return

	battle_elapsed += delta
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		# Difficulty ramp for the prototype: shorter intervals as the wave runs.
		var interval: float = max(min_interval, base_interval - battle_elapsed * 0.015)
		spawn_timer = interval

func _spawn_enemy() -> void:
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	get_parent().add_child(enemy)
	enemy.global_position = _random_edge_position()
	enemy.setup(player)
	enemy.died.connect(_on_enemy_died)

func _random_edge_position() -> Vector2:
	var viewport: Vector2 = get_viewport_rect().size
	var side: int = randi_range(0, 3)
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
	if is_instance_valid(player):
		player.add_gold(gold_reward)
