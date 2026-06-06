extends Node
class_name RunSummary

var start_time_msec: int = 0
var kill_count: int = 0
var total_spirit_stones: int = 0

func start_run() -> void:
	start_time_msec = Time.get_ticks_msec()
	kill_count = 0
	total_spirit_stones = 0

func record_kill(spirit_stones: int) -> void:
	kill_count += 1
	total_spirit_stones += spirit_stones

func get_elapsed_seconds() -> float:
	if start_time_msec <= 0:
		return 0.0
	return float(Time.get_ticks_msec() - start_time_msec) * 0.001

func format_elapsed_time() -> String:
	var seconds: int = int(get_elapsed_seconds())
	var minutes: int = int(seconds / 60)
	return "%02d:%02d" % [minutes, seconds % 60]

func build_text(battle_slots: Array) -> String:
	var lines: Array[String] = []
	for raw_stack in battle_slots:
		var stack: ArtifactStack = raw_stack as ArtifactStack
		if stack != null and stack.artifact_data != null:
			lines.append(stack.get_display_name())
	return "无" if lines.is_empty() else "\n".join(lines)

func synergy_text(system_counts: Dictionary) -> String:
	var lines: Array[String] = []
	var keys := system_counts.keys()
	keys.sort()
	for key in keys:
		var count: int = int(system_counts[key])
		if count >= 2:
			lines.append("%s %d" % [key, count])
	return "无" if lines.is_empty() else "\n".join(lines)
