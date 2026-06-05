extends CanvasLayer
class_name GameUI

@onready var hp_label: Label = $Root/MarginContainer/VBoxContainer/HpLabel
@onready var shield_label: Label = $Root/MarginContainer/VBoxContainer/ShieldLabel
@onready var stone_label: Label = $Root/MarginContainer/VBoxContainer/StoneLabel
@onready var wave_label: Label = $Root/MarginContainer/VBoxContainer/WaveLabel

func set_hp(current_hp: int, maximum_hp: int) -> void:
	hp_label.text = "生命: %d / %d" % [current_hp, maximum_hp]

func set_shield(current_shield: float, maximum_shield: float) -> void:
	shield_label.text = "护盾: %d / %d" % [int(ceil(current_shield)), int(ceil(maximum_shield))]

func set_spirit_stones(amount: int) -> void:
	stone_label.text = "灵石: %d" % amount

func set_wave_status(wave: int, status: String) -> void:
	wave_label.text = "第 %d 波: %s" % [wave, status]
