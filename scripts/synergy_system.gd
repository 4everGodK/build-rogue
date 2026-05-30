extends RefCounted
class_name SynergySystem

static func calculate(artifact_instances: Array) -> Dictionary:
	var unique_artifacts: Dictionary = {}
	var attribute_counts: Dictionary = {}
	var type_counts: Dictionary = {}

	for raw_instance in artifact_instances:
		if not raw_instance is ArtifactInstance:
			continue
		var instance: ArtifactInstance = raw_instance
		if instance.data == null:
			continue

		var artifact_id: String = instance.get_artifact_id()
		if artifact_id.is_empty() or unique_artifacts.has(artifact_id):
			continue
		unique_artifacts[artifact_id] = true

		for tag in instance.data.get_valid_attribute_tags():
			attribute_counts[tag] = int(attribute_counts.get(tag, 0)) + 1
		for tag in instance.data.get_valid_type_tags():
			type_counts[tag] = int(type_counts.get(tag, 0)) + 1

	var type_modifier: TypeSynergyModifier = TypeSynergyModifier.new().setup(type_counts)
	return {
		"unique_artifact_count": unique_artifacts.size(),
		"attribute_counts": attribute_counts,
		"type_counts": type_counts,
		"active_attribute_synergies": _build_active_synergies(attribute_counts, "属性"),
		"active_type_synergies": type_modifier.get_active_entries().values(),
		"type_modifier": type_modifier
	}

static func describe(result: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("=== 法宝羁绊 Debug ===")
	lines.append("唯一法宝数: %d" % int(result.get("unique_artifact_count", 0)))
	lines.append("属性标签: %s" % _format_counts(result.get("attribute_counts", {})))
	lines.append("类型标签: %s" % _format_counts(result.get("type_counts", {})))
	lines.append("激活属性羁绊: %s" % _format_active(result.get("active_attribute_synergies", [])))
	lines.append("激活类型羁绊: %s" % _format_active(result.get("active_type_synergies", [])))
	return "\n".join(lines)

static func _build_active_synergies(counts: Dictionary, category: String) -> Array[Dictionary]:
	var active: Array[Dictionary] = []
	for tag in counts.keys():
		var count: int = int(counts[tag])
		if count >= 2:
			active.append({
				"category": category,
				"tag": tag,
				"threshold": 2,
				"count": count,
				"display_name": "%s 2" % tag
			})
	return active

static func _format_counts(counts: Dictionary) -> String:
	if counts.is_empty():
		return "无"
	var parts: Array[String] = []
	for tag in counts.keys():
		parts.append("%s:%d" % [tag, int(counts[tag])])
	return "  ".join(parts)

static func _format_active(active_synergies: Array) -> String:
	if active_synergies.is_empty():
		return "无"
	var parts: Array[String] = []
	for synergy in active_synergies:
		var synergy_data: Dictionary = synergy
		parts.append("%s(%d/%d)" % [
			synergy_data.get("display_name", ""),
			int(synergy_data.get("count", 0)),
			int(synergy_data.get("threshold", synergy_data.get("tier", 2)))
		])
	return "、".join(parts)
