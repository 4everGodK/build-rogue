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
	if runtime_data.attack_template == "summon":
		_apply_summon_growth(runtime_data, star_level)
		return
	var damage_mult: float = get_damage_multiplier(source_data, star_level)
	var cooldown_mult: float = get_cooldown_multiplier(source_data, star_level)
	runtime_data.damage *= damage_mult
	runtime_data.heal_amount *= damage_mult
	runtime_data.shield_amount *= damage_mult
	runtime_data.cooldown *= cooldown_mult
	if source_data.id == "giant_sword_art" and star_level >= 2:
		runtime_data.width *= 1.35
	if runtime_data.attack_template == "formation":
		runtime_data.tick_interval *= cooldown_mult

static func apply_star3_bonus(data: ArtifactData) -> void:
	match data.id:
		"giant_sword_art":
			data.attack_template = "melee"
			data.attack_shape = "circle"
			data.radius = maxf(data.radius, 720.0)
			data.length = maxf(data.length, 260.0)
			data.width = maxf(data.width, 130.0)
			data.duration = maxf(data.duration, 0.42)
			data.max_targets = 0
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
			data.kill_heal_amount += 3.0
		"blood_slash":
			data.range *= 1.5
		"poison_needle":
			data.poison_explosion_damage_mult = 0.5
			data.poison_explosion_radius = maxf(22.0, data.width * 4.5)
		"heaven_eye":
			data.radius *= 1.5
		"sword_puppet":
			data.length *= 1.3
			data.summon_special_effect += "\nthird_attack_double"
		"crossbow_puppet":
			data.projectile_bounce += 1
			data.bounce_range = maxf(data.bounce_range, 180.0)
		"iron_guard_puppet":
			data.radius *= 1.5
			data.summon_special_effect += "\nshockwave"
		"turret":
			data.explosion_radius *= 1.5
		"ghost":
			data.summon_special_effect += "\nsoul_shock"
		"poison_bug":
			data.poison_dps *= 2.0

static func describe_star_effect(data: ArtifactData, star_level: int) -> String:
	if data.attack_template == "summon" or data.summon_base_count > 0:
		return _describe_summon_star_effect(data, star_level)
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
	data.attack_template = str(offer.get("attack_template", data.attack_template))
	data.damage = float(offer.get("damage", data.damage))
	data.cooldown = float(offer.get("cooldown", data.cooldown))
	data.summon_base_count = int(offer.get("summon_base_count", 0))
	data.summon_hp = float(offer.get("summon_hp", 0.0))
	data.summon_attack = float(offer.get("summon_attack", 0.0))
	data.summon_attack_speed = float(offer.get("summon_attack_speed", 1.0))
	data.star2_damage_mult = float(offer.get("star2_damage_mult", 0.0))
	data.star2_cooldown_mult = float(offer.get("star2_cooldown_mult", 0.0))
	data.star3_damage_mult = float(offer.get("star3_damage_mult", 0.0))
	data.star3_cooldown_mult = float(offer.get("star3_cooldown_mult", 0.0))
	return describe_star_effect(data, star_level)

static func get_star3_description(id: String) -> String:
	match id:
		"giant_sword_art":
			return "巨剑以角色为中心横扫一整圈，对大范围敌人造成伤害"
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
			return "掌劲角度 +50%"
		"kick":
			return "旋身腿范围 +50%"
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
			return "击杀回复 +3"
		"blood_slash":
			return "剑气飞行距离 +50%"
		"poison_needle":
			return "命中位置产生毒爆，造成毒针伤害的50%"
		"heaven_eye":
			return "光束宽度 +50%"
		"sword_puppet":
			return "攻击范围 +30%，每第三次攻击造成 200% 伤害"
		"crossbow_puppet":
			return "灵能箭弹射 1 次"
		"iron_guard_puppet":
			return "嘲讽范围 +50%，受到攻击时释放震荡波"
		"turret":
			return "爆炸范围 +50%"
		"ghost":
			return "命中触发灵魂冲击"
		"poison_bug":
			return "中毒伤害翻倍"
		_:
			return "无专属强化"

static func _apply_summon_growth(data: ArtifactData, star_level: int) -> void:
	if star_level < 2:
		return
	match data.id:
		"sword_puppet":
			data.summon_hp *= 1.5
			data.summon_attack *= 1.5
		"crossbow_puppet":
			data.summon_attack *= 1.5
			data.summon_attack_speed *= 1.3
		"iron_guard_puppet":
			data.summon_hp *= 1.8
		"turret":
			data.summon_attack *= 1.5
		"ghost":
			data.summon_attack *= 1.5
			data.heal_amount *= 1.5
		"poison_bug":
			data.summon_base_count += 1
			data.summon_attack *= 1.5

static func _describe_summon_star_effect(data: ArtifactData, star_level: int) -> String:
	var preview: ArtifactData = data.duplicate(true) as ArtifactData
	_apply_summon_growth(preview, star_level)
	var lines: Array[String] = [
		"数量 %d" % maxi(1, preview.summon_base_count),
		"生命 %.0f" % preview.summon_hp,
		"攻击 %.0f" % preview.summon_attack,
		"攻速 %.2f/秒" % preview.summon_attack_speed,
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
