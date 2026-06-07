extends RefCounted
class_name ArtifactStarConfig

const DEFAULT_STAR2_DAMAGE_MULT: float = 1.8
const DEFAULT_STAR2_COOLDOWN_MULT: float = 0.85
const DEFAULT_STAR3_DAMAGE_MULT: float = 3.0
const DEFAULT_STAR3_COOLDOWN_MULT: float = 0.7

static func get_damage_multiplier(data: ArtifactData, star_level: int) -> float:
	match clampi(star_level, 1, 3):
		2:
			return data.star2_damage_mult if data.star2_damage_mult > 0.0 else DEFAULT_STAR2_DAMAGE_MULT
		3:
			return data.star3_damage_mult if data.star3_damage_mult > 0.0 else DEFAULT_STAR3_DAMAGE_MULT
		_:
			return 1.0

static func get_cooldown_multiplier(data: ArtifactData, star_level: int) -> float:
	match clampi(star_level, 1, 3):
		2:
			return data.star2_cooldown_mult if data.star2_cooldown_mult > 0.0 else DEFAULT_STAR2_COOLDOWN_MULT
		3:
			return data.star3_cooldown_mult if data.star3_cooldown_mult > 0.0 else DEFAULT_STAR3_COOLDOWN_MULT
		_:
			return 1.0

static func apply_numeric_growth(runtime_data: ArtifactData, source_data: ArtifactData, star_level: int) -> void:
	var damage_mult: float = get_damage_multiplier(source_data, star_level)
	var cooldown_mult: float = get_cooldown_multiplier(source_data, star_level)
	runtime_data.damage *= damage_mult
	runtime_data.heal_amount *= damage_mult
	runtime_data.shield_amount *= damage_mult
	runtime_data.cooldown *= cooldown_mult
	if runtime_data.attack_template == "formation":
		runtime_data.tick_interval *= cooldown_mult

static func apply_star3_bonus(data: ArtifactData) -> void:
	match data.id:
		"one_handed_sword":
			data.extra_melee_wave_damage_mult = 0.55
			data.extra_melee_wave_range = 90.0
			data.extra_melee_wave_width = 20.0
		"flying_sword":
			data.projectile_return_count += 1
		"guardian_flying_sword":
			data.count += 1
		"long_spear":
			data.length *= 1.5
			data.range = maxf(data.range, data.length)
		"dagger":
			data.crit_chance += 0.2
			data.crit_damage_mult = maxf(data.crit_damage_mult, 2.0)
		"fire_orb":
			data.explosion_radius *= 1.5
		"guqin":
			data.damage_reduction_percent *= 1.5
		"copper_coin":
			data.projectile_bounce += 2
			data.bounce_count += 2
		"brush":
			data.length *= 1.35
			data.width *= 1.2
		"magic_ring":
			data.width *= 1.5
			data.radius *= 1.5
		"fist":
			data.length *= 1.5
			data.width *= 1.5
			data.range = maxf(data.range, data.length)
		"palm":
			data.width *= 1.5
			data.melee_arc_multiplier *= 1.5
		"kick":
			data.radius *= 1.5
		"flame_robe":
			data.radius *= 1.5
		"golden_shield":
			data.shield_knockback_force = 260.0
		"slow_formation":
			data.slow_percent += 0.2
		"attack_speed_formation":
			data.movement_speed_bonus = 0.2
		"healing_formation":
			data.heal_amount *= 1.5
		"damage_formation":
			data.tick_interval /= 1.5
		"blood_sword":
			data.life_cost_percent *= 0.7
		"blood_slash":
			data.range *= 1.5
		"poison_needle":
			data.poison_explosion_damage_mult = 0.5
			data.poison_explosion_radius = maxf(22.0, data.width * 4.5)
		"heaven_eye":
			data.radius *= 1.5

static func describe_star_effect(data: ArtifactData, star_level: int) -> String:
	var damage_mult: float = get_damage_multiplier(data, star_level)
	var cooldown_mult: float = get_cooldown_multiplier(data, star_level)
	var effective_damage: float = data.damage * damage_mult
	var effective_cooldown: float = maxf(0.05, data.cooldown * cooldown_mult)
	var attack_speed: float = 1.0 / effective_cooldown
	var lines: Array[String] = [
		"伤害 %.0f" % effective_damage,
		"攻速 %.2f/秒" % attack_speed,
	]
	if star_level >= 3:
		lines.append("")
		lines.append("三星效果:")
		lines.append(get_star3_description(data.id))
	else:
		lines.append("")
		lines.append("升到三星:")
		lines.append(get_star3_description(data.id))
	return "\n".join(lines)

static func describe_offer(offer: Dictionary, star_level: int = 1) -> String:
	var data: ArtifactData = ArtifactData.new()
	data.id = str(offer.get("id", ""))
	data.damage = float(offer.get("damage", data.damage))
	data.cooldown = float(offer.get("cooldown", data.cooldown))
	data.star2_damage_mult = float(offer.get("star2_damage_mult", 0.0))
	data.star2_cooldown_mult = float(offer.get("star2_cooldown_mult", 0.0))
	data.star3_damage_mult = float(offer.get("star3_damage_mult", 0.0))
	data.star3_cooldown_mult = float(offer.get("star3_cooldown_mult", 0.0))
	return describe_star_effect(data, star_level)

static func get_star3_description(id: String) -> String:
	match id:
		"one_handed_sword":
			return "挥砍末端额外发出一道短距离剑气"
		"flying_sword":
			return "命中敌人后自动回旋一次"
		"guardian_flying_sword":
			return "护体飞剑数量 +1"
		"long_spear":
			return "攻击距离 +50%"
		"dagger":
			return "暴击率 +20%"
		"fire_orb":
			return "爆炸范围 +50%"
		"guqin":
			return "减伤效果提升 50%"
		"copper_coin":
			return "弹射次数 +2"
		"brush":
			return "墨迹长度 +35%，宽度 +20%"
		"magic_ring":
			return "法环宽度 +50%"
		"fist":
			return "攻击范围 +50%"
		"palm":
			return "掌风角度 +50%"
		"kick":
			return "旋风腿范围 +50%"
		"flame_robe":
			return "灼烧范围 +50%"
		"golden_shield":
			return "获得护盾时击退附近敌人"
		"slow_formation":
			return "减速效果额外 +20%"
		"attack_speed_formation":
			return "阵内角色移速 +20%"
		"healing_formation":
			return "回血量额外 +50%"
		"damage_formation":
			return "伤害触发频率 +50%"
		"blood_sword":
			return "生命消耗减少 30%"
		"blood_slash":
			return "剑气飞行距离 +50%"
		"poison_needle":
			return "命中位置产生毒爆，造成毒针伤害的50%"
		"heaven_eye":
			return "光束宽度 +50%"
		_:
			return "无专属强化"
