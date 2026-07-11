extends Node
class_name DestinyManager

signal destiny_selected(destiny: Dictionary)

const DESTINIES: Array[Dictionary] = [
	{
		"id": "treasure_body",
		"name": "聚宝灵体",
		"description": "开局获得额外40灵石，前3关法宝价格-40%",
		"starting_stones": 40,
		"early_shop_price_multiplier": 0.6,
		"early_shop_wave_limit": 3,
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
		"description": "每次商店额外出现1件法宝，但所有法宝价格+10%",
		"extra_offer_count": 1,
		"shop_price_multiplier": 1.1,
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
		"description": "最大生命值-30%，伤害+40%",
		"max_hp_multiplier": 0.7,
		"damage_multiplier": 1.4,
	},
	{
		"id": "go_with_fate",
		"name": "随缘而行",
		"description": "商店无法刷新，但每次商店额外出现3个法宝",
		"extra_offer_count": 3,
		"reroll_disabled": true,
	},
	{
		"id": "careful_budget",
		"name": "精打细算",
		"description": "每次商店第一次刷新免费，之后刷新价格提高50%",
		"first_reroll_free": true,
		"after_first_reroll_cost_multiplier": 1.5,
	},
	{
		"id": "grassroots_rise",
		"name": "草根逆袭",
		"description": "1费和2费法宝伤害提高25%，4费和5费法宝价格提高30%",
		"low_tier_damage_multiplier": 1.25,
		"high_tier_price_multiplier": 1.3,
	},
	{
		"id": "born_great",
		"name": "大器天成",
		"description": "4费和5费法宝伤害提高30%，1费和2费法宝伤害降低20%",
		"high_tier_damage_multiplier": 1.3,
		"low_tier_damage_multiplier": 0.8,
	},
	{
		"id": "elite_force",
		"name": "精兵之道",
		"description": "出战法宝上限-2，伤害+40%",
		"battle_slot_delta": -2,
		"damage_multiplier": 1.4,
	},
	{
		"id": "qi_deviation",
		"name": "走火入魔",
		"description": "伤害+30%，但是每关结束后损失20%当前生命值",
		"post_wave_current_hp_loss": 0.2,
		"damage_multiplier": 1.3,
	},
	{
		"id": "blood_burn",
		"name": "燃烧精血",
		"description": "购买修为时额外损失10点生命值，获得50%额外修为",
		"cultivation_life_cost": 10,
		"cultivation_gain_multiplier": 1.5,
	},
	{
		"id": "survive_calamity",
		"name": "劫后余生",
		"description": "每次boss战开始时，玩家损失30%当前生命值；击败boss后获得额外奇遇选项",
		"boss_start_current_hp_loss": 0.3,
		"boss_extra_encounter_options": 1,
	},
	{
		"id": "hard_luck",
		"name": "命途多舛",
		"description": "敌人生命值和伤害提高30%，获得灵石奖励+50%",
		"enemy_stat_multiplier": 1.3,
		"spirit_stone_reward_multiplier": 1.5,
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

func get_selected_summary() -> Dictionary:
	if selected_destiny.is_empty():
		return {}
	return {
		"title": str(selected_destiny.get("name", "")),
		"detail": str(selected_destiny.get("description", "")),
	}

func get_starting_stones_bonus() -> int:
	return int(selected_destiny.get("starting_stones", 0))

func begin_shop(_current_stones: int) -> void:
	pass

func record_shop_spend(_amount: int) -> void:
	pass

func begin_battle(_current_stones: int) -> void:
	pass

func get_shop_price_multiplier(cleared_wave: int, data: ArtifactData = null) -> float:
	var multiplier: float = float(selected_destiny.get("shop_price_multiplier", 1.0))
	var early_limit: int = int(selected_destiny.get("early_shop_wave_limit", 0))
	if early_limit > 0 and cleared_wave < early_limit:
		multiplier *= float(selected_destiny.get("early_shop_price_multiplier", 1.0))
	if data != null and _get_tier_index(data) >= 4:
		multiplier *= float(selected_destiny.get("high_tier_price_multiplier", 1.0))
	return multiplier

func get_reroll_cost_multiplier(reroll_count: int = 0) -> float:
	if bool(selected_destiny.get("first_reroll_free", false)) and reroll_count <= 0:
		return 0.0
	var multiplier: float = float(selected_destiny.get("reroll_cost_multiplier", 1.0))
	if bool(selected_destiny.get("first_reroll_free", false)) and reroll_count > 0:
		multiplier *= float(selected_destiny.get("after_first_reroll_cost_multiplier", 1.0))
	return multiplier

func is_reroll_disabled() -> bool:
	return bool(selected_destiny.get("reroll_disabled", false))

func get_extra_offer_count() -> int:
	return int(selected_destiny.get("extra_offer_count", 0))

func requires_distinct_shop_systems() -> bool:
	return false

func get_battle_slot_delta() -> int:
	return int(selected_destiny.get("battle_slot_delta", 0))

func get_encounter_choice_bonus() -> int:
	return 0

func get_boss_extra_encounter_options() -> int:
	return int(selected_destiny.get("boss_extra_encounter_options", 0))

func get_enemy_stat_multiplier() -> float:
	return maxf(0.1, float(selected_destiny.get("enemy_stat_multiplier", 1.0)))

func get_spirit_stone_reward_multiplier() -> float:
	return maxf(0.0, float(selected_destiny.get("spirit_stone_reward_multiplier", 1.0)))

func get_post_wave_current_hp_loss_ratio() -> float:
	return clampf(float(selected_destiny.get("post_wave_current_hp_loss", 0.0)), 0.0, 1.0)

func get_boss_start_current_hp_loss_ratio() -> float:
	return clampf(float(selected_destiny.get("boss_start_current_hp_loss", 0.0)), 0.0, 1.0)

func get_cultivation_life_cost() -> int:
	return maxi(0, int(selected_destiny.get("cultivation_life_cost", 0)))

func get_cultivation_gain_multiplier() -> float:
	return maxf(0.0, float(selected_destiny.get("cultivation_gain_multiplier", 1.0)))

func get_star3_max_hp_penalty() -> int:
	return 0

func set_star3_battle_count(_count: int) -> void:
	pass

func get_damage_multiplier(cleared_waves: int, _active_synergy_count: int = 0, _hp_ratio: float = 1.0) -> float:
	var multiplier: float = float(selected_destiny.get("damage_multiplier", 1.0))
	multiplier += float(selected_destiny.get("damage_per_cleared_wave", 0.0)) * float(maxi(0, cleared_waves))
	return maxf(0.0, multiplier)

func get_artifact_damage_multiplier(data: ArtifactData, _star_level: int, _is_first_system_artifact: bool, _same_name_count: int) -> float:
	if data == null:
		return 1.0
	var multiplier: float = 1.0
	var tier_index: int = _get_tier_index(data)
	if tier_index <= 2:
		multiplier *= float(selected_destiny.get("low_tier_damage_multiplier", 1.0))
	if tier_index >= 4:
		multiplier *= float(selected_destiny.get("high_tier_damage_multiplier", 1.0))
	return maxf(0.0, multiplier)

func get_max_hp_multiplier() -> float:
	return maxf(0.1, float(selected_destiny.get("max_hp_multiplier", 1.0)))

func begin_encounter() -> void:
	pass

func _get_tier_index(data: ArtifactData) -> int:
	if data == null:
		return 0
	var index: int = CultivationManager.TIER_NAMES.find(data.tier)
	return index + 1 if index >= 0 else 0
