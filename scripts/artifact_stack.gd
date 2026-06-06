extends RefCounted
class_name ArtifactStack

var artifact_data: ArtifactData
var star_level: int = 1

func _init(data: ArtifactData = null, star: int = 1) -> void:
	artifact_data = data
	star_level = clampi(star, 1, 3)

func is_same_artifact_and_star(other: ArtifactStack) -> bool:
	return other != null and artifact_data != null and other.artifact_data != null and artifact_data.id == other.artifact_data.id and star_level == other.star_level

func get_display_name() -> String:
	if artifact_data == null:
		return "空"
	return "%s%s" % [artifact_data.display_name, get_star_text()]

func get_star_text() -> String:
	var stars := ""
	for _index in range(star_level):
		stars += "★"
	return stars

func to_offer() -> Dictionary:
	if artifact_data == null:
		return {}
	var offer := artifact_data.to_offer()
	offer["star_level"] = star_level
	return offer

func get_upgrade_tooltip() -> String:
	if artifact_data == null:
		return ""
	return "%s %s\n\n%s" % [
		artifact_data.display_name,
		get_star_text(),
		ArtifactStarConfig.describe_star_effect(artifact_data, star_level),
	]
