extends Node2D
class_name SummonController

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
	if _living_count() >= _max_count():
		return
	for unit in units:
		if is_instance_valid(unit) and unit.state == SummonUnit.STATE_RESPAWN:
			unit.force_respawn(player.global_position + _slot_offset(unit.slot_index))
			return
	if units.size() < _max_count():
		var unit := _make_unit(units.size())
		unit.global_position = player.global_position + _slot_offset(units.size())

func on_unit_died(unit: SummonUnit) -> void:
	if data != null and data.summon_death_burst:
		_death_burst(unit.global_position)

func _spawn_missing_units() -> void:
	while units.size() < _max_count():
		var unit := _make_unit(units.size())
		unit.global_position = player.global_position + _slot_offset(units.size())

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

func _slot_offset(index: int) -> Vector2:
	var angle := TAU * float(index) / float(maxi(1, _max_count()))
	var radius := 54.0 + float(index % 3) * 18.0
	return Vector2(cos(angle), sin(angle)) * radius

func _death_burst(origin: Vector2) -> void:
	var burst_radius := 130.0
	var burst_damage := maxf(8.0, data.summon_attack * 1.5)
	for candidate in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and candidate.has_method("take_damage"):
			if origin.distance_to((candidate as Node2D).global_position) <= burst_radius:
				candidate.call("take_damage", burst_damage, player)
	HitEffectManager.spawn_hit(get_tree(), origin, "flash", Vector2.UP, burst_radius)
