extends Node
class_name CultivationManager

signal cultivation_changed(realm: String, realm_index: int)
signal cultivation_message(message: String)

const REALMS: Array[String] = ["炼气", "筑基", "金丹", "元婴", "化神"]
const TIER_NAMES: Array[String] = ["凡器", "法器", "灵器", "灵宝", "仙宝"]
const TIER_COSTS: Dictionary = {
	"凡器": 10,
	"法器": 20,
	"灵器": 30,
	"灵宝": 40,
	"仙宝": 50,
}
const BREAKTHROUGH_REQUIREMENTS: Array[int] = [120, 160, 240, 400]
const CULTIVATION_CLICK_COST: int = 40
const CULTIVATION_GAIN_PER_CLICK: int = 40
const BASE_BATTLE_SLOT_COUNT: int = 5
const SHOP_TIER_WEIGHTS: Dictionary = {
	"炼气": {"凡器": 80, "法器": 20, "灵器": 0, "灵宝": 0, "仙宝": 0},
	"筑基": {"凡器": 50, "法器": 40, "灵器": 10, "灵宝": 0, "仙宝": 0},
	"金丹": {"凡器": 15, "法器": 45, "灵器": 35, "灵宝": 5, "仙宝": 0},
	"元婴": {"凡器": 0, "法器": 20, "灵器": 45, "灵宝": 25, "仙宝": 10},
	"化神": {"凡器": 0, "法器": 5, "灵器": 35, "灵宝": 40, "仙宝": 20},
}

var realm_index: int = 0
var cultivation_progress: int = 0

func reset() -> void:
	realm_index = 0
	cultivation_progress = 0
	cultivation_changed.emit(get_realm(), realm_index)

func get_realm() -> String:
	return REALMS[clampi(realm_index, 0, REALMS.size() - 1)]

func get_breakthrough_cost() -> int:
	return 0 if is_max_realm() else CULTIVATION_CLICK_COST

func get_breakthrough_requirement() -> int:
	if realm_index >= BREAKTHROUGH_REQUIREMENTS.size():
		return 0
	return BREAKTHROUGH_REQUIREMENTS[realm_index]

func get_cultivation_progress() -> int:
	return cultivation_progress

func get_cultivation_gain_per_click() -> int:
	return 0 if is_max_realm() else CULTIVATION_GAIN_PER_CLICK

func get_required_material_name() -> String:
	return ""

func has_required_material() -> bool:
	return true

func is_cultivation_full() -> bool:
	var requirement: int = get_breakthrough_requirement()
	return requirement > 0 and cultivation_progress >= requirement

func add_breakthrough_material(_material_index: int) -> bool:
	return false

func is_max_realm() -> bool:
	return realm_index >= REALMS.size() - 1

func get_battle_slot_count() -> int:
	return BASE_BATTLE_SLOT_COUNT + clampi(realm_index, 0, REALMS.size() - 1)

func try_breakthrough(economy: EconomyManager, gain_multiplier: float = 1.0, life_cost_player: Player = null, life_cost_flat: int = 0) -> bool:
	if is_max_realm():
		cultivation_message.emit("已达上限，无法继续提升修为")
		return false
	if is_cultivation_full():
		return _advance_realm()
	var cost: int = get_breakthrough_cost()
	if economy == null or not economy.spend_spirit_stones(cost):
		cultivation_message.emit("提升修为灵石不足")
		return false
	if life_cost_player != null and life_cost_flat > 0:
		life_cost_player.spend_life_flat(float(life_cost_flat))
	var gain: int = maxi(0, int(ceil(float(get_cultivation_gain_per_click()) * maxf(0.0, gain_multiplier))))
	return add_cultivation(gain)

func add_cultivation(amount: int) -> bool:
	if amount <= 0 or is_max_realm():
		return false
	var requirement: int = get_breakthrough_requirement()
	cultivation_progress = mini(requirement, cultivation_progress + amount)
	if is_cultivation_full():
		return _advance_realm()
	cultivation_changed.emit(get_realm(), realm_index)
	cultivation_message.emit("修为 +%d（%d/%d）" % [amount, cultivation_progress, requirement])
	return false

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
	return int(TIER_COSTS.get(tier, 10))

func _advance_realm() -> bool:
	if is_max_realm():
		return false
	realm_index += 1
	cultivation_progress = 0
	cultivation_changed.emit(get_realm(), realm_index)
	cultivation_message.emit("突破至%s" % get_realm())
	return true
