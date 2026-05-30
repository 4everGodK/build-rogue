extends RefCounted
class_name ArtifactCatalog

# Prototype artifact table. Add new artifacts here first, then map their
# attack_type inside ArtifactController when a new behavior is needed.
const ARTIFACTS := {
	"gold_sword": {
		"id": "gold_sword",
		"display_name": "金飞剑",
		"description": "自动寻找最近敌人，发射直线飞剑。",
		"tags": ["剑", "金"],
		"attack_type": "projectile",
		"damage": 10.0,
		"cooldown": 0.75,
		"level": 1,
		"price": 6
	},
	"fire_orb": {
		"id": "fire_orb",
		"display_name": "火珠",
		"description": "命中后造成小范围爆炸。",
		"tags": ["珠", "火"],
		"attack_type": "explosive_projectile",
		"damage": 8.0,
		"cooldown": 1.25,
		"level": 1,
		"price": 7
	},
	"thunder_seal": {
		"id": "thunder_seal",
		"display_name": "雷印",
		"description": "命中后连锁攻击附近敌人。",
		"tags": ["印", "雷"],
		"attack_type": "chain_projectile",
		"damage": 7.0,
		"cooldown": 1.5,
		"level": 1,
		"price": 8
	}
}

static func all_ids() -> Array:
	return ARTIFACTS.keys()

static func get_artifact(id: String) -> Dictionary:
	var artifact: Dictionary = ARTIFACTS.get(id, {}).duplicate(true)
	artifact["level"] = 1
	return artifact

static func random_offer(count: int = 3) -> Array[Dictionary]:
	var ids: Array = all_ids()
	var offers: Array[Dictionary] = []
	for i in count:
		var id: String = ids.pick_random()
		offers.append(get_artifact(id))
	return offers
