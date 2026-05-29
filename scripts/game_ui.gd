extends CanvasLayer
class_name GameUI

@onready var hp_label: Label = $Root/MarginContainer/VBoxContainer/HpLabel
@onready var gold_label: Label = $Root/MarginContainer/VBoxContainer/GoldLabel
@onready var wave_label: Label = $Root/MarginContainer/VBoxContainer/WaveLabel
@onready var artifact_label: Label = $Root/MarginContainer/VBoxContainer/ArtifactLabel
@onready var synergy_label: Label = $Root/MarginContainer/VBoxContainer/SynergyLabel

func set_hp(current_hp: int, max_hp: int) -> void:
	hp_label.text = "生命: %d / %d" % [current_hp, max_hp]

func set_gold(gold: int) -> void:
	gold_label.text = "灵石: %d" % gold

func set_wave_time(wave: int, time_left: float) -> void:
	wave_label.text = "第 %d 轮  剩余: %02d" % [wave, max(0, int(ceil(time_left)))]

func set_artifacts(artifacts: Array) -> void:
	if artifacts.is_empty():
		artifact_label.text = "法宝: 无"
		return

	var names: Array[String] = []
	for artifact in artifacts:
		names.append("%s Lv%d" % [
			artifact.get("display_name", "未知法宝"),
			int(artifact.get("level", 1))
		])
	artifact_label.text = "法宝: " + "、".join(names)

func set_synergies(active_synergies: Dictionary, tag_counts: Dictionary) -> void:
	var active_names: Array[String] = []
	for name in active_synergies.keys():
		active_names.append(name)

	var tag_parts: Array[String] = []
	for tag in tag_counts.keys():
		tag_parts.append("%s:%d" % [tag, tag_counts[tag]])

	var active_text: String = "无" if active_names.is_empty() else "、".join(active_names)
	var tag_text: String = "无" if tag_parts.is_empty() else "  ".join(tag_parts)
	synergy_label.text = "羁绊: %s\n标签: %s" % [active_text, tag_text]
