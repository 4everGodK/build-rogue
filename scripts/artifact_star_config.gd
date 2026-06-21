extends RefCounted
class_name ArtifactStarConfig

const DEFAULT_STAR2_DAMAGE_MULT: float = 1.55
const DEFAULT_STAR2_COOLDOWN_MULT: float = 0.85
const DEFAULT_STAR3_DAMAGE_MULT: float = 2.25
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

static func apply_star3_bonus(_data: ArtifactData) -> void:
	return

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
	if data.max_hp_damage_coefficient > 0.0:
		lines.append("最大生命系数 %.1f%%" % (data.max_hp_damage_coefficient * 100.0))
	return "\n".join(lines)

static func describe_offer(offer: Dictionary, star_level: int = 1) -> String:
	var data: ArtifactData = ArtifactData.new()
	data.id = str(offer.get("id", ""))
	data.attack_template = str(offer.get("attack_template", data.attack_template))
	data.damage = float(offer.get("damage", data.damage))
	data.max_hp_damage_coefficient = float(offer.get("max_hp_damage_coefficient", 0.0))
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
			data.summon_attack *= 1.5
		"turret":
			data.summon_attack *= 1.5
		"ghost":
			data.summon_attack *= 1.5
			data.heal_amount *= 1.5
		"poison_bug":
			data.summon_base_count += 1
			data.summon_attack *= 1.5
	if star_level < 3:
		return
	match data.id:
		"sword_puppet", "iron_guard_puppet", "turret", "ghost":
			data.summon_attack *= 2.0
		"crossbow_puppet", "poison_bug":
			data.summon_attack *= 1.55

static func _describe_summon_star_effect(data: ArtifactData, star_level: int) -> String:
	var preview: ArtifactData = data.duplicate(true) as ArtifactData
	_apply_summon_growth(preview, star_level)
	var lines: Array[String] = [
		"数量 %d" % maxi(1, preview.summon_base_count),
		"生命 %.0f" % preview.summon_hp,
		"攻击 %.0f" % preview.summon_attack,
		"攻速 %.2f/秒" % preview.summon_attack_speed,
	]
	return "\n".join(lines)
