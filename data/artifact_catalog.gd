extends RefCounted
class_name ArtifactCatalog

const ARTIFACT_PATHS := {
	"one_handed_sword": "res://data/artifacts/one_handed_sword.tres",
	"flying_sword": "res://data/artifacts/flying_sword.tres",
	"guardian_flying_sword": "res://data/artifacts/guardian_flying_sword.tres",
	"fire_orb": "res://data/artifacts/fire_orb.tres",
	"damage_formation": "res://data/artifacts/damage_formation.tres",
}

static func all_ids() -> Array:
	return ARTIFACT_PATHS.keys()

static func get_data(id: String) -> ArtifactData:
	var path: String = ARTIFACT_PATHS.get(id, "")
	if path.is_empty():
		return null
	return load(path) as ArtifactData

static func get_artifact(id: String) -> Dictionary:
	var data := get_data(id)
	return {} if data == null else data.to_offer()

static func random_offer(count: int = 3) -> Array[Dictionary]:
	var ids: Array = all_ids()
	ids.shuffle()
	var offers: Array[Dictionary] = []
	for index in mini(count, ids.size()):
		offers.append(get_artifact(ids[index]))
	return offers
