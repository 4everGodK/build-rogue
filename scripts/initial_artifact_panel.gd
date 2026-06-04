extends Control
class_name InitialArtifactPanel

signal artifact_selected(artifact: Dictionary)

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var offer_box: VBoxContainer = $Panel/MarginContainer/VBoxContainer/OfferBox

func _ready() -> void:
	hide()

func open_choices(offers: Array[Dictionary]) -> void:
	title_label.text = "选择初始法宝"
	for child in offer_box.get_children():
		child.queue_free()
	for artifact in offers:
		offer_box.add_child(_make_offer_button(artifact))
	show()

func close_choices() -> void:
	hide()

func _make_offer_button(artifact: Dictionary) -> Button:
	var offer: Dictionary = artifact.duplicate(true)
	var button := Button.new()
	button.text = "%s\n%s\n标签: %s" % [
		offer.get("display_name", "未知法宝"),
		offer.get("description", ""),
		" / ".join(offer.get("tags", [])),
	]
	button.custom_minimum_size = Vector2(360, 86)
	button.pressed.connect(func() -> void: artifact_selected.emit(offer))
	return button
