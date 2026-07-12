extends RefCounted
class_name EnemyBalanceConfig

const TOTAL_WAVES := 20
const BOSS_WAVES: Array[int] = [5, 9, 13, 17, 20]

const ENEMIES := {
	"basic": {"hp": 22.0, "speed": 82.0, "damage": 4, "first_wave": 1},
	"fast": {"hp": 17.0, "speed": 138.0, "damage": 5, "first_wave": 1},
	"tank": {"hp": 88.0, "speed": 52.0, "damage": 9, "first_wave": 3},
	"ranged": {"hp": 18.0, "speed": 58.0, "damage": 7, "first_wave": 6, "ideal_range": 270.0, "attack_interval": 3.0, "windup": 0.5, "projectile_speed": 225.0},
	"charger": {"hp": 30.0, "speed": 84.0, "damage": 9, "first_wave": 8, "dash_speed": 260.0, "windup": 0.85, "recovery": 1.0, "cooldown": 5.0},
}

const ELITE := {"scale": 1.32, "hp": 3.5, "damage": 1.4, "speed": 1.06}

static func normal_hp_multiplier(wave: int) -> float:
	return 1.0 + 0.008 * float(clampi(wave, 1, TOTAL_WAVES) - 1)

static func normal_damage_multiplier(wave: int) -> float:
	return 1.0 + 0.013 * float(clampi(wave, 1, TOTAL_WAVES) - 1)

static func boss_hp_multiplier(wave: int) -> float:
	return 1.0 + 0.10 * float(maxi(0, wave - 1))

static func wave(wave_number: int) -> Dictionary:
	var n := clampi(wave_number, 1, TOTAL_WAVES)
	var rows := {
		1: _w("教学", 1.05, 2, 28, {"basic": .90, "fast": .10}, {"fast": 18.0}, {"basic": 28, "fast": 2}, 0, []),
		2: _w("速度压力", 0.98, 2, 32, {"basic": .85, "fast": .15}, {}, {"basic": 28, "fast": 6}, 0, []),
		3: _w("速度压力", .94, 2, 36, {"basic": .70, "fast": .20, "tank": .10}, {"tank": 22.0}, {"fast": 8, "tank": 2}, 0, []),
		4: _w("高血目标", .86, 2, 40, {"basic": .63, "fast": .16, "tank": .21}, {}, {"fast": 8, "tank": 5}, 1, [.55]),
		5: _w("高血目标", .82, 2, 42, {"basic": .62, "fast": .16, "tank": .22}, {}, {"fast": 8, "tank": 5}, 1, [.62]),
		6: _w("远程教学", .78, 2, 44, {"basic": .57, "fast": .16, "tank": .16, "ranged": .11}, {"ranged": 10.0}, {"fast": 8, "tank": 5, "ranged": 2}, 0, []),
		7: _w("远程压力", .73, 2, 48, {"basic": .52, "fast": .15, "tank": .15, "ranged": .18}, {}, {"fast": 9, "tank": 5, "ranged": 4}, 1, [.65]),
		8: _w("突进教学", .69, 3, 50, {"basic": .51, "fast": .15, "tank": .15, "ranged": .14, "charger": .05}, {"charger": 12.0}, {"fast": 9, "tank": 5, "ranged": 4, "charger": 2}, 1, [.60]),
		9: _w("机动混合", .66, 3, 52, {"basic": .46, "fast": .15, "tank": .15, "ranged": .14, "charger": .10}, {}, {"fast": 9, "tank": 5, "ranged": 4, "charger": 3}, 1, [.68]),
		10: _w("杂兵海", .63, 3, 56, {"basic": .67, "fast": .18, "tank": .07, "ranged": .05, "charger": .03}, {}, {"fast": 12, "tank": 4, "ranged": 3, "charger": 2}, 1, [.58]),
		11: _w("重装波", .61, 3, 56, {"basic": .49, "fast": .08, "tank": .25, "ranged": .15, "charger": .03}, {}, {"fast": 7, "tank": 8, "ranged": 5, "charger": 2}, 1, [.52]),
		12: _w("追猎波", .58, 3, 60, {"basic": .50, "fast": .24, "tank": .08, "ranged": .06, "charger": .12}, {}, {"fast": 13, "tank": 4, "ranged": 3, "charger": 4}, 1, [.62]),
		13: _w("火力波", .56, 3, 60, {"basic": .48, "fast": .08, "tank": .17, "ranged": .22, "charger": .05}, {}, {"fast": 7, "tank": 7, "ranged": 6, "charger": 3}, 2, [.42, .75]),
		14: _w("精英波", .54, 4, 62, {"basic": .50, "fast": .12, "tank": .18, "ranged": .13, "charger": .07}, {}, {"fast": 9, "tank": 7, "ranged": 5, "charger": 3}, 2, [.35, .72]),
	}
	if rows.has(n): return _apply_enemy_count_growth(rows[n], n)
	var late_weights := {"basic": .45, "fast": .16, "tank": .17, "ranged": .13, "charger": .09}
	var elite_count := 2 if n < 18 else 3
	return _apply_enemy_count_growth(_w("高压组合", maxf(.40, .52 - .025 * float(n - 15)), 4, 64 + (n - 15) * 3, late_weights, {}, {"fast": 12, "tank": 8, "ranged": 6, "charger": 4}, elite_count, [.28, .58, .82].slice(0, elite_count)), n)

static func _apply_enemy_count_growth(config: Dictionary, wave_number: int) -> Dictionary:
	var result := config.duplicate(true)
	var multiplier := 1.0 if wave_number <= 1 else 1.5
	result["enemy_count_multiplier"] = multiplier
	result["pack_size"] = ceili(float(result["pack_size"]) * multiplier)
	result["max_alive"] = ceili(float(result["max_alive"]) * multiplier)
	return result

static func _w(theme: String, interval: float, pack: int, max_alive: int, weights: Dictionary, first_times: Dictionary, caps: Dictionary, elite_count: int, elite_times: Array) -> Dictionary:
	return {"theme": theme, "spawn_interval": interval, "pack_size": pack, "max_alive": max_alive, "weights": weights, "first_spawn_times": first_times, "type_caps": caps, "elite_count": elite_count, "elite_times": elite_times, "late_start": .55, "late_multiplier": 1.20, "enemy_projectile_cap": 18, "charging_cap": 3, "mobile_threat_cap": 16}
