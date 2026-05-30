extends RefCounted
class_name ArtifactCatalog

const ARTIFACTS := {
	"flying_sword": {"id": "flying_sword", "display_name": "飞剑", "description": "自动索敌斩击最近敌人", "tags": ["金", "近战"], "attack_type": "melee", "damage": 10.0, "cooldown": 0.75, "level": 1, "star": 1, "price": 6},
	"long_spear": {"id": "long_spear", "display_name": "长枪", "description": "向前长距离穿刺", "tags": ["风", "近战"], "attack_type": "melee", "damage": 12.0, "cooldown": 1.05, "level": 1, "star": 1, "price": 6},
	"dagger": {"id": "dagger", "display_name": "匕首", "description": "高速连续攻击", "tags": ["毒", "近战"], "attack_type": "melee", "damage": 5.0, "cooldown": 0.35, "level": 1, "star": 1, "price": 5},
	"hammer": {"id": "hammer", "display_name": "锤子", "description": "低频高伤范围震荡", "tags": ["土", "近战", "区域"], "attack_type": "area", "damage": 18.0, "cooldown": 1.6, "level": 1, "star": 1, "price": 7},
	"chain_scythe": {"id": "chain_scythe", "display_name": "锁链镰刀", "description": "大范围横扫", "tags": ["暗", "近战"], "attack_type": "melee", "damage": 13.0, "cooldown": 1.15, "level": 1, "star": 1, "price": 7},
	"scissors": {"id": "scissors", "display_name": "剪刀", "description": "连续交叉切割", "tags": ["风", "近战"], "attack_type": "melee", "damage": 8.0, "cooldown": 0.65, "level": 1, "star": 1, "price": 6},
	"flying_needle": {"id": "flying_needle", "display_name": "飞针", "description": "扇形散射", "tags": ["毒", "发射物"], "attack_type": "scatter_projectile", "damage": 5.0, "cooldown": 0.85, "level": 1, "star": 1, "price": 5},
	"copper_coin": {"id": "copper_coin", "display_name": "铜钱", "description": "命中后弹射", "tags": ["金", "发射物"], "attack_type": "bounce_projectile", "damage": 7.0, "cooldown": 0.9, "level": 1, "star": 1, "price": 6},
	"chess_piece": {"id": "chess_piece", "display_name": "棋子", "description": "从天而降砸向目标区域", "tags": ["木", "发射物", "区域"], "attack_type": "area", "damage": 14.0, "cooldown": 1.4, "level": 1, "star": 1, "price": 7},
	"brush": {"id": "brush", "display_name": "毛笔", "description": "挥出穿透墨迹剑气", "tags": ["木", "发射物"], "attack_type": "projectile", "damage": 9.0, "cooldown": 0.95, "level": 1, "star": 1, "price": 6},
	"jade_shuttle": {"id": "jade_shuttle", "display_name": "玉梭", "description": "飞出后返回", "tags": ["水", "发射物"], "attack_type": "returning_projectile", "damage": 8.0, "cooldown": 1.0, "level": 1, "star": 1, "price": 6},
	"lantern": {"id": "lantern", "display_name": "灯笼", "description": "发射鬼火", "tags": ["火", "发射物"], "attack_type": "explosive_projectile", "damage": 8.0, "cooldown": 1.15, "level": 1, "star": 1, "price": 6},
	"moon_wheel": {"id": "moon_wheel", "display_name": "月轮", "description": "高速旋转切割", "tags": ["风", "环绕"], "attack_type": "orbit", "damage": 7.0, "cooldown": 0.55, "level": 1, "star": 1, "price": 6},
	"flying_wheel": {"id": "flying_wheel", "display_name": "飞轮", "description": "缓慢大范围环绕", "tags": ["金", "环绕"], "attack_type": "orbit", "damage": 11.0, "cooldown": 1.1, "level": 1, "star": 1, "price": 7},
	"bell": {"id": "bell", "display_name": "铃铛", "description": "周期性释放震荡波", "tags": ["风", "环绕", "区域"], "attack_type": "area", "damage": 8.0, "cooldown": 1.25, "level": 1, "star": 1, "price": 6},
	"buddha_beads": {"id": "buddha_beads", "display_name": "佛珠", "description": "持续碰撞伤害", "tags": ["土", "环绕"], "attack_type": "orbit", "damage": 9.0, "cooldown": 0.8, "level": 1, "star": 1, "price": 6},
	"jade_pendant": {"id": "jade_pendant", "display_name": "玉佩", "description": "环绕并周期性产生护盾", "tags": ["水", "环绕"], "attack_type": "orbit", "damage": 4.0, "cooldown": 1.4, "level": 1, "star": 1, "price": 7},
	"bronze_bell": {"id": "bronze_bell", "display_name": "铜钟", "description": "缓慢环绕并击退敌人", "tags": ["土", "环绕"], "attack_type": "orbit", "damage": 12.0, "cooldown": 1.3, "level": 1, "star": 1, "price": 7},
	"bronze_puppet": {"id": "bronze_puppet", "display_name": "铜甲傀儡", "description": "近战傀儡", "tags": ["土", "召唤", "近战"], "attack_type": "summon", "damage": 10.0, "cooldown": 1.2, "level": 1, "star": 1, "price": 8},
	"crossbow_puppet": {"id": "crossbow_puppet", "display_name": "机关弩傀儡", "description": "远程射击", "tags": ["金", "召唤", "发射物"], "attack_type": "summon", "damage": 8.0, "cooldown": 0.95, "level": 1, "star": 1, "price": 8},
	"paper_doll": {"id": "paper_doll", "display_name": "纸人", "description": "冲锋自爆", "tags": ["暗", "召唤", "爆发"], "attack_type": "summon", "damage": 16.0, "cooldown": 1.8, "level": 1, "star": 1, "price": 8},
	"skeleton": {"id": "skeleton", "display_name": "骷髅", "description": "持续追击敌人", "tags": ["暗", "召唤"], "attack_type": "summon", "damage": 9.0, "cooldown": 1.0, "level": 1, "star": 1, "price": 8},
	"cauldron": {"id": "cauldron", "display_name": "鼎", "description": "固定位置喷发火焰", "tags": ["火", "区域"], "attack_type": "area", "damage": 13.0, "cooldown": 1.3, "level": 1, "star": 1, "price": 7},
	"incense_burner": {"id": "incense_burner", "display_name": "香炉", "description": "持续释放毒雾", "tags": ["毒", "区域"], "attack_type": "area", "damage": 8.0, "cooldown": 1.0, "level": 1, "star": 1, "price": 7},
	"guqin": {"id": "guqin", "display_name": "古琴", "description": "持续释放音波领域", "tags": ["风", "区域"], "attack_type": "area", "damage": 9.0, "cooldown": 1.1, "level": 1, "star": 1, "price": 7},
	"gourd": {"id": "gourd", "display_name": "葫芦", "description": "产生灵气漩涡", "tags": ["水", "区域"], "attack_type": "area", "damage": 10.0, "cooldown": 1.2, "level": 1, "star": 1, "price": 7},
	"iron_fist": {"id": "iron_fist", "display_name": "铁拳", "description": "巨大拳影向前轰击", "tags": ["金", "体修", "爆发"], "attack_type": "body_strike", "damage": 12.0, "cooldown": 0.95, "level": 1, "star": 1, "price": 7},
	"mountain_fist": {"id": "mountain_fist", "display_name": "崩山拳", "description": "巨大拳头砸地并产生冲击波", "tags": ["土", "体修", "区域"], "attack_type": "body_strike", "damage": 18.0, "cooldown": 1.55, "level": 1, "star": 1, "price": 8},
	"thunder_kick": {"id": "thunder_kick", "display_name": "奔雷腿", "description": "雷电腿影连续踢击", "tags": ["雷", "体修"], "attack_type": "body_strike", "damage": 10.0, "cooldown": 0.75, "level": 1, "star": 1, "price": 7},
	"wind_god_kick": {"id": "wind_god_kick", "display_name": "风神腿", "description": "高速穿梭踢击", "tags": ["风", "体修"], "attack_type": "body_strike", "damage": 9.0, "cooldown": 0.65, "level": 1, "star": 1, "price": 7},
	"flame_palm": {"id": "flame_palm", "display_name": "烈焰掌", "description": "巨大火焰手掌拍击", "tags": ["火", "体修", "爆发"], "attack_type": "body_strike", "damage": 15.0, "cooldown": 1.25, "level": 1, "star": 1, "price": 8},
	"ice_palm": {"id": "ice_palm", "display_name": "玄冰掌", "description": "冰掌向前推进", "tags": ["水", "体修"], "attack_type": "body_strike", "damage": 11.0, "cooldown": 1.0, "level": 1, "star": 1, "price": 7},
	"poison_dragon_claw": {"id": "poison_dragon_claw", "display_name": "毒龙爪", "description": "巨大爪影撕裂", "tags": ["毒", "体修"], "attack_type": "body_strike", "damage": 12.0, "cooldown": 0.9, "level": 1, "star": 1, "price": 7},
	"blood_demon_hand": {"id": "blood_demon_hand", "display_name": "血魔手", "description": "鬼手从地下伸出抓击敌人", "tags": ["暗", "体修"], "attack_type": "body_strike", "damage": 14.0, "cooldown": 1.15, "level": 1, "star": 1, "price": 8}
}

static func all_ids() -> Array:
	return ARTIFACTS.keys()

static func get_artifact(id: String) -> Dictionary:
	var artifact: Dictionary = ARTIFACTS.get(id, {}).duplicate(true)
	artifact["level"] = 1
	artifact["star"] = 1
	return artifact

static func random_offer(count: int = 3) -> Array[Dictionary]:
	var ids: Array = all_ids()
	var offers: Array[Dictionary] = []
	for i in count:
		var id: String = ids.pick_random()
		offers.append(get_artifact(id))
	return offers
