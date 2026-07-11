extends RefCounted
class_name BattleHealingTracker

var heal_ratio: float = 0.03
var wave_cap_ratio: float = 0.12
var healed_this_wave: float = 0.0

func configure(config: Dictionary) -> void:
	heal_ratio = maxf(0.0, float(config.get("essence_heal_ratio", heal_ratio)))
	wave_cap_ratio = maxf(0.0, float(config.get("wave_heal_cap_ratio", wave_cap_ratio)))

func begin_wave() -> void:
	healed_this_wave = 0.0

func try_consume(player: Node) -> float:
	if player == null or not player.has_method("heal"):
		return 0.0
	var max_hp: float = float(player.get("max_hp"))
	if max_hp <= 0.0:
		return 0.0
	var wave_cap: float = max_hp * wave_cap_ratio
	var remaining: float = maxf(0.0, wave_cap - healed_this_wave)
	if remaining <= 0.0:
		return 0.0
	var heal_amount: float = minf(maxf(1.0, max_hp * heal_ratio), remaining)
	var before: float = float(player.get("hp"))
	player.call("heal", heal_amount)
	var actual: float = maxf(0.0, float(player.get("hp")) - before)
	healed_this_wave += actual
	return actual
