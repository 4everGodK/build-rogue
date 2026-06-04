extends CanvasLayer
class_name GameUI

@onready var hp_label: Label = $Root/MarginContainer/VBoxContainer/HpLabel
@onready var gold_label: Label = $Root/MarginContainer/VBoxContainer/GoldLabel
@onready var wave_label: Label = $Root/MarginContainer/VBoxContainer/WaveLabel
@onready var artifact_label: Label = $Root/MarginContainer/VBoxContainer/ArtifactLabel

func set_hp(current_hp: int, maximum_hp: int) -> void:
	hp_label.text = "生命: %d / %d" % [current_hp, maximum_hp]

func set_gold(value: int) -> void:
	gold_label.text = "灵石: %d" % value

func set_wave_time(wave: int, time_left: float) -> void:
	wave_label.text = "第 %d 轮  剩余: %02d" % [wave, max(0, int(ceil(time_left)))]

func set_artifacts(artifacts: Array) -> void:
	if artifacts.is_empty():
		artifact_label.text = "法宝: 无"
		return
	var names: Array[String] = []
	for artifact in artifacts:
		names.append(str(artifact.get("display_name", "未知法宝")))
	artifact_label.text = "法宝: " + "、".join(names)
