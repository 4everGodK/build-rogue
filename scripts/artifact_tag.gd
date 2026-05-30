extends RefCounted
class_name ArtifactTag

const ATTRIBUTE_TAGS: Array[String] = ["金", "木", "水", "火", "土", "风", "雷", "毒", "暗"]
const TYPE_TAGS: Array[String] = ["近战", "发射物", "环绕", "轨道", "召唤", "区域", "爆发"]

static func is_attribute_tag(tag: String) -> bool:
	return ATTRIBUTE_TAGS.has(tag)

static func is_type_tag(tag: String) -> bool:
	return TYPE_TAGS.has(tag)

static func filter_attribute_tags(tags: Array[String]) -> Array[String]:
	var valid_tags: Array[String] = []
	for tag in tags:
		if is_attribute_tag(tag):
			valid_tags.append(tag)
	return valid_tags

static func filter_type_tags(tags: Array[String]) -> Array[String]:
	var valid_tags: Array[String] = []
	for tag in tags:
		if is_type_tag(tag):
			valid_tags.append(tag)
	return valid_tags
