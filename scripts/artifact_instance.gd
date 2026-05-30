extends Resource
class_name ArtifactInstance

@export var data: ArtifactData
@export_range(1, 3, 1) var level: int = 1
@export_range(1, 3, 1) var star: int = 1

func get_artifact_id() -> String:
	if data == null:
		return ""
	return data.id

func get_display_name() -> String:
	if data == null:
		return "未配置法宝"
	return "%s Lv%d ★%d" % [data.display_name, level, star]
