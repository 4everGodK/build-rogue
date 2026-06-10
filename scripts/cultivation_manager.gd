extends Node
class_name CultivationManager

signal cultivation_changed(realm: String, realm_index: int)
signal cultivation_message(message: String)

const REALMS: Array[String] = ["炼气", "筑基", "金丹", "元婴", "化神"]
const TIER_NAMES: Array[String] = ["凡器", "法器", "灵器", "灵宝", "仙宝"]
const TIER_COSTS: Dictionary = {
	"凡器": 1,
	"法器": 2,
	"灵器": 3,
	"灵宝": 4,
	"仙宝": 5,
}
const BREAKTHROUGH_COSTS: Array[int] = [10, 20, 40, 80]
const BASE_BATTLE_SLOT_COUNT: int = 5
const SHOP_TIER_WEIGHTS: Dictionary = {
	"炼气": {"凡器": 65, "法器": 25, "灵器": 8, "灵宝": 2, "仙宝": 0},
	"筑基": {"凡器": 45, "法器": 35, "灵器": 15, "灵宝": 5, "仙宝": 0},
	"金丹": {"凡器": 25, "法器": 35, "灵器": 25, "灵宝": 12, "仙宝": 3},
	"元婴": {"凡器": 10, "法器": 25, "灵器": 35, "灵宝": 22, "仙宝": 8},
	"化神": {"凡器": 5, "法器": 15, "灵器": 35, "灵宝": 30, "仙宝": 15},
}

var realm_index: int = 0

func reset() -> void:
	realm_index = 0
	cultivation_changed.emit(get_realm(), realm_index)

func get_realm() -> String:
	return REALMS[clampi(realm_index, 0, REALMS.size() - 1)]

func get_breakthrough_cost() -> int:
	if realm_index >= BREAKTHROUGH_COSTS.size():
		return 0
	return BREAKTHROUGH_COSTS[realm_index]

func is_max_realm() -> bool:
	return realm_index >= REALMS.size() - 1

func get_battle_slot_count() -> int:
	return BASE_BATTLE_SLOT_COUNT + clampi(realm_index, 0, REALMS.size() - 1)

func try_breakthrough(economy: EconomyManager) -> bool:
	if is_max_realm():
		cultivation_message.emit("已达最高修为")
		return false
	var cost: int = get_breakthrough_cost()
	if economy == null or not economy.spend_spirit_stones(cost):
		cultivation_message.emit("突破灵石不足")
		return false
	realm_index += 1
	cultivation_changed.emit(get_realm(), realm_index)
	cultivation_message.emit("突破至%s" % get_realm())
	return true

func roll_shop_tier() -> String:
	var weights: Dictionary = SHOP_TIER_WEIGHTS.get(get_realm(), SHOP_TIER_WEIGHTS["炼气"])
	var total: int = 0
	for tier in TIER_NAMES:
		total += int(weights.get(tier, 0))
	if total <= 0:
		return "凡器"
	var roll: int = randi_range(1, total)
	var running: int = 0
	for tier in TIER_NAMES:
		running += int(weights.get(tier, 0))
		if roll <= running:
			return tier
	return "凡器"

static func cost_for_tier(tier: String) -> int:
	return int(TIER_COSTS.get(tier, 1))
