extends RefCounted
class_name BattleEnvironmentConfig

const HEALING_PLANT := {
	"first_spawn_delay": 10.0,
	"spawn_interval": 15.0,
	"max_active": 2,
	"max_per_wave": 4,
	"max_hp": 35.0,
	"plant_radius": 16.0,
	"spawn_clearance": 56.0,
	"player_clearance": 120.0,
	"edge_margin": 90.0,
	"spawn_attempts": 18,
	"essence_heal_ratio": 0.03,
	"wave_heal_cap_ratio": 0.12,
}

static func healing_plant() -> Dictionary:
	return HEALING_PLANT.duplicate(true)
