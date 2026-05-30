extends RefCounted
class_name TypeSynergyModifier

const TIERS: Array[int] = [2, 4, 6]

var type_counts: Dictionary = {}
var active_tiers: Dictionary = {}

func setup(counts: Dictionary) -> TypeSynergyModifier:
	type_counts = counts.duplicate(true)
	active_tiers.clear()
	for type_tag in ArtifactTag.TYPE_TAGS:
		active_tiers[type_tag] = _tier_for_count(int(type_counts.get(type_tag, 0)))
	return self

func get_tier(type_tag: String) -> int:
	return int(active_tiers.get(type_tag, 0))

func get_active_entries() -> Dictionary:
	var entries: Dictionary = {}
	for type_tag in active_tiers.keys():
		var tier: int = int(active_tiers[type_tag])
		if tier > 0:
			entries["%s %d" % [type_tag, tier]] = {
				"category": "类型",
				"tag": type_tag,
				"count": int(type_counts.get(type_tag, 0)),
				"tier": tier,
				"theme": get_theme(type_tag),
				"summary": get_summary(type_tag, tier)
			}
	return entries

func get_theme(type_tag: String) -> String:
	match type_tag:
		"近战":
			return "连击"
		"发射物":
			return "弹幕"
		"环绕":
			return "护体法宝"
		"召唤":
			return "召唤海"
		"区域":
			return "阵法领域"
		"体修":
			return "法天象地"
		_:
			return ""

func get_summary(type_tag: String, tier: int) -> String:
	match type_tag:
		"近战":
			if tier >= 6:
				return "额外斩击可再次触发"
			if tier >= 4:
				return "每第4次近战攻击触发100%额外斩击"
			if tier >= 2:
				return "每第5次近战攻击触发50%额外斩击"
		"发射物":
			if tier >= 6:
				return "发射物额外发射一次"
			if tier >= 4:
				return "发射物数量+3，单发伤害-30%"
			if tier >= 2:
				return "发射物数量+1"
		"环绕":
			if tier >= 6:
				return "额外复制一圈环绕物"
			if tier >= 4:
				return "旋转速度+50%"
			if tier >= 2:
				return "环绕物数量+1"
		"召唤":
			if tier >= 6:
				return "召唤物复制一次攻击"
			if tier >= 4:
				return "召唤物攻击速度+50%"
			if tier >= 2:
				return "召唤物数量+1"
		"区域":
			if tier >= 6:
				return "同类区域同时存在数量+1"
			if tier >= 4:
				return "区域持续时间+50%"
			if tier >= 2:
				return "区域范围+30%"
		"体修":
			if tier >= 6:
				return "残影攻击可再次产生残影"
			if tier >= 4:
				return "攻击额外产生一次残影攻击"
			if tier >= 2:
				return "体修攻击范围+25%"
	return "未激活"

func melee_combo_interval() -> int:
	var tier: int = get_tier("近战")
	if tier >= 4:
		return 4
	if tier >= 2:
		return 5
	return 0

func melee_extra_damage_multiplier() -> float:
	var tier: int = get_tier("近战")
	if tier >= 4:
		return 1.0
	if tier >= 2:
		return 0.5
	return 0.0

func melee_extra_can_chain() -> bool:
	return get_tier("近战") >= 6

func projectile_extra_count() -> int:
	var tier: int = get_tier("发射物")
	if tier >= 4:
		return 3
	if tier >= 2:
		return 1
	return 0

func projectile_damage_multiplier() -> float:
	return 0.7 if get_tier("发射物") >= 4 else 1.0

func projectile_repeat_count() -> int:
	return 2 if get_tier("发射物") >= 6 else 1

func orbit_hit_count() -> int:
	var count: int = 1
	if get_tier("环绕") >= 2:
		count += 1
	if get_tier("环绕") >= 6:
		count *= 2
	return count

func orbit_cooldown_multiplier() -> float:
	return 0.67 if get_tier("环绕") >= 4 else 1.0

func summon_count() -> int:
	return 2 if get_tier("召唤") >= 2 else 1

func summon_cooldown_multiplier() -> float:
	return 0.67 if get_tier("召唤") >= 4 else 1.0

func summon_attack_repeat_count() -> int:
	return 2 if get_tier("召唤") >= 6 else 1

func area_radius_multiplier() -> float:
	return 1.3 if get_tier("区域") >= 2 else 1.0

func area_duration_multiplier() -> float:
	return 1.5 if get_tier("区域") >= 4 else 1.0

func area_instance_count() -> int:
	return 2 if get_tier("区域") >= 6 else 1

func body_strike_radius_multiplier() -> float:
	return 1.25 if get_tier("体修") >= 2 else 1.0

func body_strike_echo_count() -> int:
	if get_tier("体修") >= 6:
		return 2
	if get_tier("体修") >= 4:
		return 1
	return 0

static func _tier_for_count(count: int) -> int:
	var tier: int = 0
	for threshold in TIERS:
		if count >= threshold:
			tier = threshold
	return tier
