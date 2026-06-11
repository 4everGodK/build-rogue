extends RefCounted
class_name ArtifactCatalog

const ARTIFACT_PATHS := {
	"one_handed_sword": "res://data/artifacts/one_handed_sword.tres",
	"two_handed_sword": "res://data/artifacts/two_handed_sword.tres",
	"giant_sword_art": "res://data/artifacts/giant_sword_art.tres",
	"flying_sword": "res://data/artifacts/flying_sword.tres",
	"guardian_flying_sword": "res://data/artifacts/guardian_flying_sword.tres",
	"long_spear": "res://data/artifacts/long_spear.tres",
	"dagger": "res://data/artifacts/dagger.tres",
	"fire_orb": "res://data/artifacts/fire_orb.tres",
	"fire_gourd": "res://data/artifacts/fire_gourd.tres",
	"guqin": "res://data/artifacts/guqin.tres",
	"copper_coin": "res://data/artifacts/copper_coin.tres",
	"brush": "res://data/artifacts/brush.tres",
	"magic_ring": "res://data/artifacts/magic_ring.tres",
	"divine_thunder": "res://data/artifacts/divine_thunder.tres",
	"fist": "res://data/artifacts/fist.tres",
	"palm": "res://data/artifacts/palm.tres",
	"kick": "res://data/artifacts/kick.tres",
	"flame_robe": "res://data/artifacts/flame_robe.tres",
	"golden_shield": "res://data/artifacts/golden_shield.tres",
	"slow_formation": "res://data/artifacts/slow_formation.tres",
	"attack_speed_formation": "res://data/artifacts/attack_speed_formation.tres",
	"healing_formation": "res://data/artifacts/healing_formation.tres",
	"damage_formation": "res://data/artifacts/damage_formation.tres",
	"blood_sword": "res://data/artifacts/blood_sword.tres",
	"blood_slash": "res://data/artifacts/blood_slash.tres",
	"poison_needle": "res://data/artifacts/poison_needle.tres",
	"heaven_eye": "res://data/artifacts/heaven_eye.tres",
	"sword_puppet": "res://data/artifacts/sword_puppet.tres",
	"crossbow_puppet": "res://data/artifacts/crossbow_puppet.tres",
	"iron_guard_puppet": "res://data/artifacts/iron_guard_puppet.tres",
	"turret": "res://data/artifacts/turret.tres",
	"ghost": "res://data/artifacts/ghost.tres",
	"poison_bug": "res://data/artifacts/poison_bug.tres",
}

static func all_ids() -> Array:
	return ARTIFACT_PATHS.keys()

static func ids_for_system(system_tag: String) -> Array[String]:
	var result: Array[String] = []
	for raw_id in all_ids():
		var id := str(raw_id)
		var data := get_data(id)
		if data != null and data.system_tag == system_tag:
			result.append(id)
	return result

static func get_data(id: String) -> ArtifactData:
	var path: String = ARTIFACT_PATHS.get(id, "")
	return null if path.is_empty() else load(path) as ArtifactData

static func get_artifact(id: String) -> Dictionary:
	var data := get_data(id)
	return {} if data == null else data.to_offer()

static func random_offer(count: int = 3) -> Array[Dictionary]:
	var ids: Array = all_ids()
	ids.shuffle()
	var offers: Array[Dictionary] = []
	for index in mini(count, ids.size()):
		offers.append(get_artifact(str(ids[index])))
	return offers
