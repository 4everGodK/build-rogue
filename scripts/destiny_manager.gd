extends Node
class_name DestinyManager

signal destiny_selected(destiny: Dictionary)

const DESTINIES: Array[Dictionary] = [
	{
		"id": "treasure_body",
		"name": "聚宝灵体",
		"description": "开局获得50灵石，前5关法宝价格-50%",
		"starting_stones": 50,
		"early_shop_price_multiplier": 0.5,
		"early_shop_wave_limit": 5,
	},
	{
		"id": "loose_cultivator",
		"name": "散修",
		"description": "法宝价格-20%，刷新价格+40%",
		"shop_price_multiplier": 0.8,
		"reroll_cost_multiplier": 1.4,
	},
	{
		"id": "trade_genius",
		"name": "经商天才",
		"description": "每次商店额外出现1件法宝",
		"extra_offer_count": 1,
	},
	{
		"id": "late_bloomer",
		"name": "大器晚成",
		"description": "伤害-30%，每过一关，伤害+3%",
		"damage_multiplier": 0.7,
		"damage_per_cleared_wave": 0.03,
	},
	{
		"id": "broken_body",
		"name": "残缺道体",
		"description": "最大生命值-30%，伤害+50%",
		"max_hp_multiplier": 0.7,
		"damage_multiplier": 1.5,
	},
]

var selected_destiny: Dictionary = {}

func reset() -> void:
	selected_destiny.clear()

func get_starting_choices(count: int = 3) -> Array[Dictionary]:
	var choices: Array[Dictionary] = DESTINIES.duplicate(true)
	choices.shuffle()
	return choices.slice(0, mini(count, choices.size()))

func select_destiny(destiny_id: String) -> bool:
	for destiny in DESTINIES:
		if str(destiny.get("id", "")) == destiny_id:
			selected_destiny = destiny.duplicate(true)
			destiny_selected.emit(selected_destiny)
			return true
	return false

func has_selected_destiny() -> bool:
	return not selected_destiny.is_empty()

func get_destiny_name() -> String:
	return str(selected_destiny.get("name", ""))

func get_starting_stones_bonus() -> int:
	return int(selected_destiny.get("starting_stones", 0))

func get_shop_price_multiplier(cleared_wave: int) -> float:
	var multiplier: float = float(selected_destiny.get("shop_price_multiplier", 1.0))
	var early_limit: int = int(selected_destiny.get("early_shop_wave_limit", 0))
	if early_limit > 0 and cleared_wave < early_limit:
		multiplier *= float(selected_destiny.get("early_shop_price_multiplier", 1.0))
	return multiplier

func get_reroll_cost_multiplier() -> float:
	return float(selected_destiny.get("reroll_cost_multiplier", 1.0))

func get_extra_offer_count() -> int:
	return int(selected_destiny.get("extra_offer_count", 0))

func get_damage_multiplier(cleared_waves: int) -> float:
	var multiplier: float = float(selected_destiny.get("damage_multiplier", 1.0))
	multiplier += float(selected_destiny.get("damage_per_cleared_wave", 0.0)) * float(maxi(0, cleared_waves))
	return maxf(0.0, multiplier)

func get_max_hp_multiplier() -> float:
	return maxf(0.1, float(selected_destiny.get("max_hp_multiplier", 1.0)))
