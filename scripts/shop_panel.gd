extends Control
class_name ShopPanel

signal buy_requested(artifact: Dictionary)
signal reroll_requested
signal continue_requested

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var offer_box: VBoxContainer = $Panel/MarginContainer/VBoxContainer/OfferBox
@onready var reroll_button: Button = $Panel/MarginContainer/VBoxContainer/ActionRow/RerollButton
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ActionRow/ContinueButton

var current_offers: Array[Dictionary] = []

func _ready() -> void:
	hide()
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	continue_button.pressed.connect(func() -> void: continue_requested.emit())

func open_shop(wave: int, offers: Array[Dictionary], player_gold: int, reroll_cost: int) -> void:
	current_offers = offers.duplicate(true)
	title_label.text = "第 %d 轮结束 - 商店  金币:%d" % [wave, player_gold]
	reroll_button.text = "刷新 -%d" % reroll_cost
	_render_offers(player_gold)
	show()

func refresh_gold(player_gold: int, reroll_cost: int) -> void:
	title_label.text = title_label.text.split("  金币:")[0] + ("  金币:%d" % player_gold)
	reroll_button.disabled = player_gold < reroll_cost
	_render_offers(player_gold)

func close_shop() -> void:
	hide()

func _render_offers(player_gold: int) -> void:
	for child in offer_box.get_children():
		child.queue_free()

	for artifact in current_offers:
		offer_box.add_child(_make_offer_button(artifact, player_gold))

func _make_offer_button(artifact: Dictionary, player_gold: int) -> Button:
	var offer: Dictionary = artifact.duplicate(true)
	var button: Button = Button.new()
	var price: int = offer.get("price", 0)
	var tags_array: Array = offer.get("tags", [])
	var tags: String = " / ".join(tags_array)
	button.text = "%s  $%d\n%s\n标签: %s" % [
		offer.get("display_name", "未知法宝"),
		price,
		offer.get("description", ""),
		tags
	]
	button.custom_minimum_size = Vector2(360, 86)
	button.disabled = player_gold < price
	button.pressed.connect(func() -> void: buy_requested.emit(offer))
	return button
