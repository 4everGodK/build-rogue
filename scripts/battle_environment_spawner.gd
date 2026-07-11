extends Node
class_name BattleEnvironmentSpawner

const HealingPlantScript := preload("res://scripts/healing_plant.gd")

var player: Node2D
var config: Dictionary = {}
var tracker = null
var arena_size: Vector2 = Vector2(1120.0, 672.0)
var active: bool = false
var paused: bool = false
var spawn_timer: float = 0.0
var spawned_this_wave: int = 0

func configure(next_player: Node2D, next_arena_size: Vector2, next_config: Dictionary, next_tracker) -> void:
	player = next_player
	arena_size = next_arena_size
	config = next_config.duplicate(true)
	tracker = next_tracker

func begin_wave() -> void:
	clear_all()
	active = true
	paused = false
	spawned_this_wave = 0
	spawn_timer = maxf(0.0, float(config.get("first_spawn_delay", 10.0)))

func end_wave() -> void:
	active = false
	paused = false
	clear_all()

func set_paused(paused: bool) -> void:
	self.paused = paused

func _process(delta: float) -> void:
	if not active or paused:
		return
	spawn_timer -= delta
	if spawn_timer > 0.0:
		return
	_try_spawn_plant()
	spawn_timer = maxf(0.1, float(config.get("spawn_interval", 15.0)))

func clear_all() -> void:
	for plant in get_tree().get_nodes_in_group("healing_plants"):
		if is_instance_valid(plant):
			plant.queue_free()
	for essence in get_tree().get_nodes_in_group("healing_essences"):
		if is_instance_valid(essence):
			essence.queue_free()

func _try_spawn_plant() -> void:
	if spawned_this_wave >= int(config.get("max_per_wave", 4)):
		return
	if get_tree().get_nodes_in_group("healing_plants").size() >= int(config.get("max_active", 2)):
		return
	var position = _find_spawn_position()
	if position == null:
		return
	var plant := HealingPlantScript.new() as Node2D
	plant.global_position = position
	plant.call("setup", config, tracker)
	get_tree().current_scene.add_child(plant)
	plant.connect("plant_destroyed", _on_plant_destroyed)
	spawned_this_wave += 1

func _on_plant_destroyed(_plant) -> void:
	pass

func _find_spawn_position():
	var attempts: int = maxi(1, int(config.get("spawn_attempts", 18)))
	var half: Vector2 = arena_size * 0.5
	var edge_margin: float = maxf(0.0, float(config.get("edge_margin", 90.0)))
	for _index in attempts:
		var candidate := Vector2(
			randf_range(-half.x + edge_margin, half.x - edge_margin),
			randf_range(-half.y + edge_margin, half.y - edge_margin)
		)
		if _position_is_valid(candidate):
			return candidate
	return null

func _position_is_valid(position: Vector2) -> bool:
	if is_instance_valid(player):
		if position.distance_to(player.global_position) < float(config.get("player_clearance", 120.0)):
			return false
	var clearance: float = float(config.get("spawn_clearance", 56.0))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and not enemy.is_in_group("healing_plants"):
			if position.distance_to((enemy as Node2D).global_position) < clearance:
				return false
	for plant in get_tree().get_nodes_in_group("healing_plants"):
		if plant is Node2D:
			if position.distance_to((plant as Node2D).global_position) < clearance:
				return false
	return not _overlaps_obstacle(position)

func _overlaps_obstacle(position: Vector2) -> bool:
	var world := get_viewport().world_2d
	if world == null:
		return false
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = maxf(4.0, float(config.get("plant_radius", 16.0)))
	query.shape = shape
	query.transform = Transform2D(0.0, position)
	query.collision_mask = 4
	return not world.direct_space_state.intersect_shape(query, 1).is_empty()
