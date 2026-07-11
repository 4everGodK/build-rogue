extends Node
class_name EncounterManager

signal encounter_selected(encounter: Dictionary)

const SYSTEM_TAGS: Array[String] = ["剑修", "法修", "体修", "召唤", "魔修"]
const ATTRIBUTE_TAGS: Array[String] = ["金", "木", "水", "火", "土", "雷", "毒"]

const ENCOUNTERS: Array[Dictionary] = [
	{"id": "bonus_sword", "name": "剑心顿悟", "category": "羁绊", "description": "剑修激活数 +1", "synergy_tag": "剑修"},
	{"id": "bonus_magic", "name": "法意流转", "category": "羁绊", "description": "法修激活数 +1", "synergy_tag": "法修"},
	{"id": "bonus_body", "name": "淬体机缘", "category": "羁绊", "description": "体修激活数 +1", "synergy_tag": "体修"},
	{"id": "bonus_summon", "name": "役灵契机", "category": "羁绊", "description": "召唤激活数 +1", "synergy_tag": "召唤"},
	{"id": "bonus_demon", "name": "魔念入骨", "category": "羁绊", "description": "魔修激活数 +1", "synergy_tag": "魔修"},
	{"id": "bonus_metal", "name": "金炁入怀", "category": "羁绊", "description": "金激活数 +1", "synergy_tag": "金"},
	{"id": "bonus_wood", "name": "木灵垂青", "category": "羁绊", "description": "木激活数 +1", "synergy_tag": "木"},
	{"id": "bonus_water", "name": "水脉回响", "category": "羁绊", "description": "水激活数 +1", "synergy_tag": "水"},
	{"id": "bonus_fire", "name": "火种跃动", "category": "羁绊", "description": "火激活数 +1", "synergy_tag": "火"},
	{"id": "bonus_earth", "name": "土德护身", "category": "羁绊", "description": "土激活数 +1", "synergy_tag": "土"},
	{"id": "bonus_lightning", "name": "雷纹贯体", "category": "羁绊", "description": "雷激活数 +1", "synergy_tag": "雷"},
	{"id": "bonus_poison", "name": "毒脉暗生", "category": "羁绊", "description": "毒激活数 +1", "synergy_tag": "毒"},
	{"id": "gain_150_stones", "name": "洞府遗财", "category": "经济", "description": "立即获得150灵石", "spirit_stones": 150},
	{"id": "free_rerolls_3", "name": "天机自现", "category": "经济", "description": "接下来3次商店刷新免费", "free_reroll_shops": 3},
	{"id": "half_price_1", "name": "仙市折券", "category": "经济", "description": "接下来1次商店购买半价", "half_price_shops": 1},
	{"id": "no_gather_extra_stones", "name": "灵泉外溢", "category": "经济", "description": "无法聚灵，但每回合额外获得20灵石", "disable_spirit_gathering": true, "extra_room_clear_stones": 20},
	{"id": "all_in_all_encounters", "name": "倾囊悟道", "category": "经济", "description": "花费所有灵石（包括聚灵），获得其他所有奇遇", "all_in_all_encounters": true},
	{"id": "next_one_cost_star3", "name": "凡器淬星", "category": "随机", "description": "下次购买的1费法宝直接升级到3星", "next_one_cost_star": 3},
	{"id": "random_star_up", "name": "星辉点化", "category": "随机", "description": "随机一个法宝升1星", "random_star_up": true},
	{"id": "reroll_higher_tier", "name": "灵宝换胎", "category": "随机", "description": "场上所有法宝随机变成高一品阶但同一星级的法宝", "reroll_higher_tier": true},
	{"id": "synergy_damage", "name": "万法归一", "category": "Build强化", "description": "每激活一个不同种类羁绊，伤害 +5%", "damage_per_active_synergy": 0.05},
	{"id": "star_mastery", "name": "炼器宗师", "category": "Build强化", "description": "3星法宝伤害提高25%，1星法宝伤害降低20%", "star3_damage_multiplier": 1.25, "star1_damage_multiplier": 0.8},
	{"id": "pair_damage", "name": "好事成双", "category": "Build强化", "description": "场上恰好有2件同名法宝时，这两件法宝伤害+30%", "exact_pair_damage_multiplier": 1.3},
	{"id": "revive_once", "name": "替死符", "category": "生存", "description": "死亡后复活一次，永久失去50%最大生命值，但是伤害+15%", "revive_once_ratio": 0.5, "revive_max_hp_multiplier": 0.5, "revive_damage_multiplier": 1.15},
	{"id": "sturdy_body", "name": "玄龟厚体", "category": "生存", "description": "最大生命值+30%，移动速度-10%", "max_hp_multiplier": 1.3, "move_speed_multiplier": 0.9},
	{"id": "near_death_guard", "name": "一线生机", "category": "生存", "description": "每关第一次生命低于20%时，无敌2秒并恢复10%生命", "low_hp_rescue": true},
	{"id": "last_stand", "name": "背水一战", "category": "风险收益", "description": "生命值低于50%时，伤害提高25%，高于50%时，伤害降低10%", "low_hp_damage_multiplier": 1.25, "high_hp_damage_multiplier": 0.9},
	{"id": "heaven_envy", "name": "天妒英才", "category": "风险收益", "description": "每个出战的3星法宝降低8点最大生命值，3星法宝伤害额外提高25%", "max_hp_penalty_per_star3": 8, "star3_damage_multiplier": 1.25},
]

var selected_encounter_ids: Array[String] = []
var selected_encounters: Array[Dictionary] = []
var pending_free_reroll_shops: int = 0
var active_free_rerolls: bool = false
var pending_half_price_shops: int = 0
var active_shop_price_multiplier: float = 1.0
var next_one_cost_purchase_star: int = 1
var damage_per_active_synergy: float = 0.0
var base_damage_multiplier: float = 1.0
var low_hp_damage_multiplier: float = 1.0
var high_hp_damage_multiplier: float = 1.0
var star1_damage_multiplier: float = 1.0
var star3_damage_multiplier: float = 1.0
var exact_pair_damage_multiplier: float = 1.0
var max_hp_multiplier: float = 1.0
var move_speed_multiplier: float = 1.0
var max_hp_penalty_per_star3: int = 0
var disable_spirit_gathering: bool = false
var extra_room_clear_stones: int = 0
var revive_once_ratio: float = 0.0
var revive_max_hp_multiplier: float = 1.0
var revive_damage_multiplier: float = 1.0
var low_hp_rescue_enabled: bool = false
var low_hp_rescue_used_waves: Dictionary = {}

func reset() -> void:
	selected_encounter_ids.clear()
	selected_encounters.clear()
	pending_free_reroll_shops = 0
	active_free_rerolls = false
	pending_half_price_shops = 0
	active_shop_price_multiplier = 1.0
	next_one_cost_purchase_star = 1
	damage_per_active_synergy = 0.0
	base_damage_multiplier = 1.0
	low_hp_damage_multiplier = 1.0
	high_hp_damage_multiplier = 1.0
	star1_damage_multiplier = 1.0
	star3_damage_multiplier = 1.0
	exact_pair_damage_multiplier = 1.0
	max_hp_multiplier = 1.0
	move_speed_multiplier = 1.0
	max_hp_penalty_per_star3 = 0
	disable_spirit_gathering = false
	extra_room_clear_stones = 0
	revive_once_ratio = 0.0
	revive_max_hp_multiplier = 1.0
	revive_damage_multiplier = 1.0
	low_hp_rescue_enabled = false
	low_hp_rescue_used_waves.clear()

func get_choices(count: int = 3) -> Array[Dictionary]:
	var choices: Array[Dictionary] = ENCOUNTERS.duplicate(true)
	choices.shuffle()
	return choices.slice(0, mini(count, choices.size()))

func select_encounter(encounter_id: String) -> Dictionary:
	for encounter in ENCOUNTERS:
		if str(encounter.get("id", "")) == encounter_id:
			var selected: Dictionary = encounter.duplicate(true)
			selected_encounter_ids.append(encounter_id)
			selected_encounters.append(selected.duplicate(true))
			apply_encounter_effects(selected)
			encounter_selected.emit(selected)
			return selected
	return {}

func record_selected_encounter(encounter: Dictionary) -> void:
	var encounter_id: String = str(encounter.get("id", ""))
	if encounter_id.is_empty() or selected_encounter_ids.has(encounter_id):
		return
	selected_encounter_ids.append(encounter_id)
	selected_encounters.append(encounter.duplicate(true))

func get_selected_summaries() -> Array:
	var result: Array = []
	for encounter in selected_encounters:
		result.append({
			"title": str(encounter.get("name", "")),
			"detail": str(encounter.get("description", "")),
		})
	return result

func get_all_other_encounters(excluded_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for encounter in ENCOUNTERS:
		if str(encounter.get("id", "")) != excluded_id:
			result.append(encounter.duplicate(true))
	return result

func apply_encounter_effects(encounter: Dictionary) -> void:
	pending_free_reroll_shops += int(encounter.get("free_reroll_shops", 0))
	pending_half_price_shops += int(encounter.get("half_price_shops", 0))
	next_one_cost_purchase_star = maxi(next_one_cost_purchase_star, int(encounter.get("next_one_cost_star", 1)))
	damage_per_active_synergy += float(encounter.get("damage_per_active_synergy", 0.0))
	base_damage_multiplier *= float(encounter.get("damage_multiplier", 1.0))
	if encounter.has("low_hp_damage_multiplier"):
		low_hp_damage_multiplier *= float(encounter["low_hp_damage_multiplier"])
	if encounter.has("high_hp_damage_multiplier"):
		high_hp_damage_multiplier *= float(encounter["high_hp_damage_multiplier"])
	star1_damage_multiplier *= float(encounter.get("star1_damage_multiplier", 1.0))
	star3_damage_multiplier *= float(encounter.get("star3_damage_multiplier", 1.0))
	exact_pair_damage_multiplier *= float(encounter.get("exact_pair_damage_multiplier", 1.0))
	max_hp_multiplier *= float(encounter.get("max_hp_multiplier", 1.0))
	move_speed_multiplier *= float(encounter.get("move_speed_multiplier", 1.0))
	max_hp_penalty_per_star3 += int(encounter.get("max_hp_penalty_per_star3", 0))
	disable_spirit_gathering = disable_spirit_gathering or bool(encounter.get("disable_spirit_gathering", false))
	extra_room_clear_stones += int(encounter.get("extra_room_clear_stones", 0))
	revive_once_ratio = maxf(revive_once_ratio, float(encounter.get("revive_once_ratio", 0.0)))
	revive_max_hp_multiplier *= float(encounter.get("revive_max_hp_multiplier", 1.0))
	revive_damage_multiplier *= float(encounter.get("revive_damage_multiplier", 1.0))
	low_hp_rescue_enabled = low_hp_rescue_enabled or bool(encounter.get("low_hp_rescue", false))

func begin_shop() -> void:
	active_free_rerolls = pending_free_reroll_shops > 0
	if pending_free_reroll_shops > 0:
		pending_free_reroll_shops -= 1
	active_shop_price_multiplier = 0.5 if pending_half_price_shops > 0 else 1.0
	if pending_half_price_shops > 0:
		pending_half_price_shops -= 1

func get_shop_price_multiplier() -> float:
	return active_shop_price_multiplier

func is_reroll_free() -> bool:
	return active_free_rerolls

func consume_next_purchase_star(data: ArtifactData) -> int:
	if data == null or next_one_cost_purchase_star <= 1:
		return 1
	if data.tier != "凡器":
		return 1
	var star: int = next_one_cost_purchase_star
	next_one_cost_purchase_star = 1
	return star

func get_damage_multiplier(active_synergy_count: int, hp_ratio: float = 1.0) -> float:
	var multiplier: float = base_damage_multiplier
	multiplier *= 1.0 + damage_per_active_synergy * float(maxi(0, active_synergy_count))
	if not is_equal_approx(low_hp_damage_multiplier, 1.0) or not is_equal_approx(high_hp_damage_multiplier, 1.0):
		multiplier *= low_hp_damage_multiplier if hp_ratio < 0.5 else high_hp_damage_multiplier
	return maxf(0.0, multiplier)

func get_artifact_damage_multiplier(_data: ArtifactData, star_level: int, same_name_count: int) -> float:
	var multiplier: float = 1.0
	if star_level <= 1:
		multiplier *= star1_damage_multiplier
	if star_level >= 3:
		multiplier *= star3_damage_multiplier
	if same_name_count == 2:
		multiplier *= exact_pair_damage_multiplier
	return maxf(0.0, multiplier)

func get_max_hp_multiplier() -> float:
	return maxf(0.1, max_hp_multiplier)

func get_move_speed_multiplier() -> float:
	return maxf(0.1, move_speed_multiplier)

func get_star3_max_hp_penalty(star3_count: int) -> int:
	return maxi(0, max_hp_penalty_per_star3 * maxi(0, star3_count))

func get_extra_room_clear_stones() -> int:
	return maxi(0, extra_room_clear_stones)

func is_spirit_gathering_disabled() -> bool:
	return disable_spirit_gathering

func consume_revive() -> Dictionary:
	if revive_once_ratio <= 0.0:
		return {}
	max_hp_multiplier *= revive_max_hp_multiplier
	base_damage_multiplier *= revive_damage_multiplier
	var result: Dictionary = {
		"revive_ratio": revive_once_ratio,
	}
	revive_once_ratio = 0.0
	revive_max_hp_multiplier = 1.0
	revive_damage_multiplier = 1.0
	return result

func consume_revive_ratio() -> float:
	var revive: Dictionary = consume_revive()
	return float(revive.get("revive_ratio", 0.0))

func try_consume_low_hp_rescue(wave_number: int, hp_ratio: float) -> bool:
	if not low_hp_rescue_enabled or hp_ratio >= 0.2:
		return false
	if low_hp_rescue_used_waves.has(wave_number):
		return false
	low_hp_rescue_used_waves[wave_number] = true
	return true
