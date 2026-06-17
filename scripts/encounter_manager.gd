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
	{"id": "gain_300_stones", "name": "洞府遗财", "category": "经济", "description": "立即获得300灵石", "spirit_stones": 300},
	{"id": "free_rerolls_3", "name": "天机自现", "category": "经济", "description": "接下来3次商店刷新免费", "free_reroll_shops": 3},
	{"id": "half_price_1", "name": "仙市折券", "category": "经济", "description": "接下来1次商店购买半价", "half_price_shops": 1},
	{"id": "next_one_cost_star3", "name": "凡器淬星", "category": "随机法宝", "description": "下次购买的1费法宝直接升级到3星", "next_one_cost_star": 3},
	{"id": "random_star_up", "name": "星辉点化", "category": "随机法宝", "description": "随机一个法宝升1星", "random_star_up": true},
	{"id": "reroll_higher_tier", "name": "灵宝换胎", "category": "随机法宝", "description": "场上所有法宝随机变成高一品阶但同一星级的法宝", "reroll_higher_tier": true},
	{"id": "synergy_damage", "name": "万法归一", "category": "Build强化", "description": "每激活一个羁绊，伤害 +5%", "damage_per_active_synergy": 0.05},
	{"id": "revive_once", "name": "替死符", "category": "生存", "description": "死亡后以50%血量复活一次", "revive_once_ratio": 0.5},
]

var selected_encounter_ids: Array[String] = []
var pending_free_reroll_shops: int = 0
var active_free_rerolls: bool = false
var pending_half_price_shops: int = 0
var active_shop_price_multiplier: float = 1.0
var next_one_cost_purchase_star: int = 1
var damage_per_active_synergy: float = 0.0
var revive_once_ratio: float = 0.0

func reset() -> void:
	selected_encounter_ids.clear()
	pending_free_reroll_shops = 0
	active_free_rerolls = false
	pending_half_price_shops = 0
	active_shop_price_multiplier = 1.0
	next_one_cost_purchase_star = 1
	damage_per_active_synergy = 0.0
	revive_once_ratio = 0.0

func get_choices(count: int = 3) -> Array[Dictionary]:
	var choices: Array[Dictionary] = ENCOUNTERS.duplicate(true)
	choices.shuffle()
	return choices.slice(0, mini(count, choices.size()))

func select_encounter(encounter_id: String) -> Dictionary:
	for encounter in ENCOUNTERS:
		if str(encounter.get("id", "")) == encounter_id:
			var selected: Dictionary = encounter.duplicate(true)
			selected_encounter_ids.append(encounter_id)
			_apply_selection(selected)
			encounter_selected.emit(selected)
			return selected
	return {}

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

func get_damage_multiplier(active_synergy_count: int) -> float:
	return 1.0 + damage_per_active_synergy * float(maxi(0, active_synergy_count))

func consume_revive_ratio() -> float:
	var ratio: float = revive_once_ratio
	revive_once_ratio = 0.0
	return ratio

func _apply_selection(encounter: Dictionary) -> void:
	pending_free_reroll_shops += int(encounter.get("free_reroll_shops", 0))
	pending_half_price_shops += int(encounter.get("half_price_shops", 0))
	next_one_cost_purchase_star = maxi(next_one_cost_purchase_star, int(encounter.get("next_one_cost_star", 1)))
	damage_per_active_synergy += float(encounter.get("damage_per_active_synergy", 0.0))
	revive_once_ratio = maxf(revive_once_ratio, float(encounter.get("revive_once_ratio", 0.0)))
