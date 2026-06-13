extends Node2D
class_name SummonController

const DEFAULT_ARENA_SIZE: Vector2 = Vector2(1600.0, 960.0)
const SUMMON_ARENA_INSET: float = 42.0

var player: Node2D
var data: ArtifactData
var units: Array[SummonUnit] = []
var battle_paused: bool = false

func setup(owner_player: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	data = artifact_data
	_spawn_missing_units()

func _process(_delta: float) -> void:
	if battle_paused:
		return
	if not is_instance_valid(player) or data == null:
		queue_free()
		return
	_spawn_missing_units()

func set_battle_paused(paused: bool) -> void:
	battle_paused = paused
	set_process(not paused)
	for unit in units:
		if is_instance_valid(unit):
			unit.set_battle_paused(paused)

func try_spawn_extra_unit() -> void:
	if data == null or not is_instance_valid(player):
		return
	_prune_invalid_units()
	if _living_count() >= _max_count():
		return
	for unit in units:
		if is_instance_valid(unit) and unit.state == SummonUnit.STATE_RESPAWN:
			unit.force_respawn(_safe_spawn_position(unit.slot_index))
			return
	if units.size() < _max_count():
		var unit := _make_unit(units.size())
		unit.global_position = _safe_spawn_position(unit.slot_index)

func on_unit_died(unit: SummonUnit) -> void:
	if data != null and data.summon_death_burst:
		_death_burst(unit.global_position)

func redeploy_all_units(start_index: int = 0, total_count: int = -1) -> void:
	if data == null or not is_instance_valid(player):
		return
	_prune_invalid_units()
	_spawn_missing_units()
	var formation_total: int = total_count if total_count > 0 else units.size()
	for index in range(units.size()):
		var unit := units[index]
		if not is_instance_valid(unit):
			continue
		unit.slot_index = index
		unit.set_formation_slot(start_index + index, formation_total)
		unit.force_respawn(_safe_spawn_position_for(start_index + index, formation_total))

func _spawn_missing_units() -> void:
	_prune_invalid_units()
	while units.size() < _max_count():
		var unit := _make_unit(units.size())
		unit.global_position = _safe_spawn_position(unit.slot_index)

func _make_unit(index: int) -> SummonUnit:
	var unit := SummonUnit.new()
	add_child(unit)
	unit.setup(player, data, self, index)
	unit.set_battle_paused(battle_paused)
	units.append(unit)
	return unit

func _living_count() -> int:
	var count := 0
	for unit in units:
		if is_instance_valid(unit) and unit.state != SummonUnit.STATE_RESPAWN:
			count += 1
	return count

func _max_count() -> int:
	return maxi(0, data.summon_base_count)

func get_deploy_count() -> int:
	return _max_count()

func _slot_offset(index: int) -> Vector2:
	return _formation_offset(index, maxi(1, _max_count()))

func _formation_offset(index: int, total_count: int) -> Vector2:
	var angle := TAU * float(index) / float(maxi(1, total_count))
	var radius := 54.0 + float(index % 3) * 18.0
	return Vector2(cos(angle), sin(angle)) * radius

func _safe_spawn_position(index: int) -> Vector2:
	return _clamp_to_arena(player.global_position + _slot_offset(index))

func _safe_spawn_position_for(index: int, total_count: int) -> Vector2:
	return _clamp_to_arena(player.global_position + _formation_offset(index, total_count))

func _clamp_to_arena(position: Vector2) -> Vector2:
	var arena_size := DEFAULT_ARENA_SIZE
	var scene := get_tree().current_scene
	if scene != null:
		var arena := scene.find_child("Arena_Demo", true, false)
		if arena != null:
			var value: Variant = arena.get("arena_size")
			if value is Vector2:
				arena_size = value
	var half_size := arena_size * 0.5
	return Vector2(
		clampf(position.x, -half_size.x + SUMMON_ARENA_INSET, half_size.x - SUMMON_ARENA_INSET),
		clampf(position.y, -half_size.y + SUMMON_ARENA_INSET, half_size.y - SUMMON_ARENA_INSET)
	)

func _prune_invalid_units() -> void:
	var alive_units: Array[SummonUnit] = []
	for unit in units:
		if is_instance_valid(unit):
			alive_units.append(unit)
	units = alive_units

func _death_burst(origin: Vector2) -> void:
	var burst_radius := 130.0
	var burst_damage := maxf(8.0, data.summon_attack * 1.5)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if origin.distance_to((candidate as Node2D).global_position) <= burst_radius:
				candidate.call("take_damage", burst_damage, player)
	HitEffectManager.spawn_hit(get_tree(), origin, "flash", Vector2.UP, burst_radius)
