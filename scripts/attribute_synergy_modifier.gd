extends RefCounted
class_name AttributeSynergyModifier

const TIERS: Array[int] = [2, 4, 6]

var attribute_counts: Dictionary = {}
var active_tiers: Dictionary = {}
var growth_stacks: int = 0

func setup(counts: Dictionary) -> AttributeSynergyModifier:
	attribute_counts = counts.duplicate(true)
	active_tiers.clear()
	for attribute_tag in ArtifactTag.ATTRIBUTE_TAGS:
		active_tiers[attribute_tag] = _tier_for_count(int(attribute_counts.get(attribute_tag, 0)))
	return self

func get_tier(attribute_tag: String) -> int:
	return int(active_tiers.get(attribute_tag, 0))

func get_active_entries() -> Dictionary:
	var entries: Dictionary = {}
	for attribute_tag in active_tiers.keys():
		var tier: int = int(active_tiers[attribute_tag])
		if tier > 0:
			entries["%s %d" % [attribute_tag, tier]] = {
				"category": "属性",
				"tag": attribute_tag,
				"count": int(attribute_counts.get(attribute_tag, 0)),
				"tier": tier,
				"theme": get_theme(attribute_tag),
				"summary": get_summary(attribute_tag, tier)
			}
	return entries

func add_growth_stack() -> void:
	if get_tier("木") <= 0:
		return
	if get_tier("木") < 6 and growth_stacks >= 10:
		return
	growth_stacks += 1

func damage_multiplier(player: Player = null) -> float:
	var multiplier: float = 1.0
	multiplier *= wood_growth_damage_multiplier()
	if player != null:
		multiplier *= water_shield_damage_multiplier(player)
		multiplier *= dark_low_hp_damage_multiplier(player)
	multiplier *= dark_temporary_damage_multiplier()
	return multiplier

func metal_pierce_bonus() -> int:
	return 1 if get_tier("金") >= 2 else 0

func metal_execute_damage_multiplier(enemy: Enemy) -> float:
	if get_tier("金") >= 4 and enemy != null and enemy.get_hp_ratio() <= 0.3:
		return 1.5
	return 1.0

func metal_execute_on_kill() -> bool:
	return get_tier("金") >= 6

func wood_growth_damage_multiplier() -> float:
	var per_stack: float = 0.1 if get_tier("木") >= 4 else 0.05
	return 1.0 + per_stack * float(growth_stacks)

func water_regen_per_second() -> float:
	return 1.0 if get_tier("水") >= 2 else 0.0

func water_overheal_to_shield() -> bool:
	return get_tier("水") >= 4

func water_shield_damage_multiplier(player: Player) -> float:
	if get_tier("水") >= 6 and player.shield > 0.0:
		return 1.2
	return 1.0

func fire_explosion_radius() -> float:
	if get_tier("火") >= 4:
		return 78.0
	if get_tier("火") >= 2:
		return 52.0
	return 0.0

func fire_explosion_can_chain() -> bool:
	return get_tier("火") >= 6

func earth_damage_taken_multiplier() -> float:
	return 0.85 if get_tier("土") >= 2 else 1.0

func earth_periodic_shield_amount(max_hp: int) -> float:
	return float(max_hp) * 0.12 if get_tier("土") >= 4 else 0.0

func earth_counter_enabled() -> bool:
	return get_tier("土") >= 6

func wind_pull_radius_multiplier() -> float:
	if get_tier("风") >= 4:
		return 2.0
	if get_tier("风") >= 2:
		return 1.0
	return 0.0

func wind_periodic_gather_enabled() -> bool:
	return get_tier("风") >= 6

func thunder_chain_count() -> int:
	if get_tier("雷") >= 4:
		return 3
	if get_tier("雷") >= 2:
		return 1
	return 0

func thunder_can_repeat_target() -> bool:
	return get_tier("雷") >= 6

func poison_damage_per_second(base_damage: float) -> float:
	return base_damage * 0.25 if get_tier("毒") >= 2 else 0.0

func poison_can_stack() -> bool:
	return get_tier("毒") >= 4

func poison_spread_on_death() -> bool:
	return get_tier("毒") >= 6

func dark_lifesteal_ratio() -> float:
	return 0.04 if get_tier("暗") >= 2 else 0.0

func dark_low_hp_damage_multiplier(player: Player) -> float:
	if get_tier("暗") >= 4 and player.get_hp_ratio() < 0.5:
		return 1.0 + (0.5 - player.get_hp_ratio())
	return 1.0

func dark_temporary_damage_multiplier() -> float:
	# TODO: implement temporary attack gain on kill as a timed buff store.
	return 1.0

func get_theme(attribute_tag: String) -> String:
	match attribute_tag:
		"金":
			return "穿透、斩杀"
		"木":
			return "成长"
		"水":
			return "回复"
		"火":
			return "爆发"
		"土":
			return "防御"
		"风":
			return "聚怪"
		"雷":
			return "连锁"
		"毒":
			return "持续伤害"
		"暗":
			return "献祭"
		_:
			return ""

func get_summary(attribute_tag: String, tier: int) -> String:
	match attribute_tag:
		"金":
			if tier >= 6:
				return "击杀时触发一次斩杀攻击"
			if tier >= 4:
				return "对30%生命以下目标伤害+50%"
			if tier >= 2:
				return "攻击穿透+1"
		"木":
			if tier >= 6:
				return "成长效果无上限"
			if tier >= 4:
				return "每30秒成长伤害翻倍"
			if tier >= 2:
				return "每30秒获得+5%伤害"
		"水":
			if tier >= 6:
				return "护盾存在时增伤"
			if tier >= 4:
				return "溢出治疗转化护盾"
			if tier >= 2:
				return "每秒回复生命"
		"火":
			if tier >= 6:
				return "爆炸可连锁触发"
			if tier >= 4:
				return "爆炸范围+50%"
			if tier >= 2:
				return "攻击附带小范围爆炸"
		"土":
			if tier >= 6:
				return "受到伤害时反击附近敌人"
			if tier >= 4:
				return "周期性获得护盾"
			if tier >= 2:
				return "减伤15%"
		"风":
			if tier >= 6:
				return "定期释放大范围聚怪"
			if tier >= 4:
				return "牵引范围翻倍"
			if tier >= 2:
				return "攻击附带牵引"
		"雷":
			if tier >= 6:
				return "弹射可重复命中同一目标但伤害递减"
			if tier >= 4:
				return "弹射次数+2"
			if tier >= 2:
				return "攻击弹射1次"
		"毒":
			if tier >= 6:
				return "死亡传播中毒"
			if tier >= 4:
				return "中毒可叠层"
			if tier >= 2:
				return "攻击附加中毒"
		"暗":
			if tier >= 6:
				return "击杀获得临时攻击力"
			if tier >= 4:
				return "生命越低伤害越高"
			if tier >= 2:
				return "获得吸血"
	return "未激活"

static func _tier_for_count(count: int) -> int:
	var tier: int = 0
	for threshold in TIERS:
		if count >= threshold:
			tier = threshold
	return tier
