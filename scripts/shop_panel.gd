extends Control
class_name ShopPanel

signal buy_requested(offer_index: int)
signal reroll_requested
signal continue_requested
signal inventory_move_requested(from_area: String, from_index: int, to_area: String, to_index: int)

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var stone_label: Label = $Panel/MarginContainer/VBoxContainer/StoneLabel
@onready var message_label: Label = $Panel/MarginContainer/VBoxContainer/MessageLabel
@onready var offer_box: VBoxContainer = $Panel/MarginContainer/VBoxContainer/MainRow/OfferBox
@onready var battle_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/MainRow/InventoryBox/BattleGrid
@onready var bag_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/MainRow/InventoryBox/BagGrid
@onready var synergy_label: Label = $Panel/MarginContainer/VBoxContainer/MainRow/SynergyLabel
@onready var reroll_button: Button = $Panel/MarginContainer/VBoxContainer/ActionRow/RerollButton
@onready var continue_button: Button = $Panel/MarginContainer/VBoxContainer/ActionRow/ContinueButton

var current_offers: Array = []
var current_battle_slots: Array = []
var current_bag_slots: Array = []
var current_stones: int = 0

func _ready() -> void:
	hide()
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	continue_button.pressed.connect(func() -> void: continue_requested.emit())

func open_shop(wave: int, offers: Array, stones: int, battle_slots: Array, bag_slots: Array, system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	title_label.text = "第 %d 波完成 - 商店阶段" % wave
	set_offers(offers)
	set_economy(stones)
	set_inventory(battle_slots, bag_slots)
	set_synergies(system_counts, attribute_counts)
	set_message("拖拽法宝调整出战区和储物袋，点击继续进入下一波。")
	show()

func close_shop() -> void:
	hide()

func set_economy(stones: int) -> void:
	current_stones = stones
	stone_label.text = "灵石: %d    购买: 3    刷新: 1" % current_stones
	reroll_button.disabled = current_stones < ShopManager.REROLL_COST
	_render_offers()

func set_offers(offers: Array) -> void:
	current_offers = offers.duplicate(true)
	_render_offers()

func set_inventory(battle_slots: Array, bag_slots: Array) -> void:
	current_battle_slots = battle_slots.duplicate()
	current_bag_slots = bag_slots.duplicate()
	_render_slots()

func set_synergies(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	var system_parts: Array[String] = []
	for key in system_counts.keys():
		system_parts.append("%s:%d" % [key, system_counts[key]])
	var attribute_parts: Array[String] = []
	for key in attribute_counts.keys():
		attribute_parts.append("%s:%d" % [key, attribute_counts[key]])
	synergy_label.text = "羁绊统计\n体系: %s\n属性: %s" % [
		"无" if system_parts.is_empty() else "  ".join(system_parts),
		"无" if attribute_parts.is_empty() else "  ".join(attribute_parts),
	]

func set_message(message: String) -> void:
	message_label.text = message

func _render_offers() -> void:
	if not is_node_ready():
		return
	for child in offer_box.get_children():
		child.queue_free()
	for index in range(current_offers.size()):
		var offer: Dictionary = current_offers[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(310, 96)
		button.disabled = current_stones < ShopManager.BUY_COST
		button.text = "%s ★  3灵石\n体系:%s  属性:%s\n%s" % [
			offer.get("display_name", "未知法宝"),
			_offer_system_tag(offer),
			_offer_attribute_tag(offer),
			offer.get("description", ""),
		]
		button.pressed.connect(_on_offer_button_pressed.bind(index))
		offer_box.add_child(button)

func _render_slots() -> void:
	for child in battle_grid.get_children():
		child.queue_free()
	for child in bag_grid.get_children():
		child.queue_free()
	for index in range(current_battle_slots.size()):
		battle_grid.add_child(_make_slot_button("battle", index, current_battle_slots[index] as ArtifactStack))
	for index in range(current_bag_slots.size()):
		bag_grid.add_child(_make_slot_button("bag", index, current_bag_slots[index] as ArtifactStack))

func _make_slot_button(area: String, index: int, stack: ArtifactStack) -> InventorySlotButton:
	var button := InventorySlotButton.new()
	button.setup(area, index, stack)
	button.slot_drop_requested.connect(func(from_area: String, from_index: int, to_area: String, to_index: int) -> void:
		inventory_move_requested.emit(from_area, from_index, to_area, to_index)
	)
	return button

func _on_offer_button_pressed(offer_index: int) -> void:
	buy_requested.emit(offer_index)

func _offer_system_tag(offer: Dictionary) -> String:
	if offer.has("system_tag"):
		return str(offer["system_tag"])
	var tags: Array = offer.get("tags", [])
	return str(tags[0]) if tags.size() > 0 else ""

func _offer_attribute_tag(offer: Dictionary) -> String:
	if offer.has("attribute_tag"):
		return str(offer["attribute_tag"])
	var tags: Array = offer.get("tags", [])
	return str(tags[1]) if tags.size() > 1 else ""
