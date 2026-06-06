extends Control
class_name ShopPanel

signal buy_requested(offer_index: int)
signal reroll_requested
signal continue_requested
signal inventory_move_requested(from_area: String, from_index: int, to_area: String, to_index: int)

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var stone_label: Label = $Panel/MarginContainer/VBoxContainer/ActionRow/StoneLabel
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
	title_label.text = "准备阶段 - 商店" if wave <= 0 else "第 %d 波完成 - 商店阶段" % wave
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
	var lines: Array[String] = ["羁绊统计", "", "体系:"]
	var system_keys := system_counts.keys()
	system_keys.sort()
	if system_keys.is_empty():
		lines.append("无")
	else:
		for key in system_keys:
			var count := int(system_counts[key])
			var active_mark: String = "★ " if _is_system_synergy_active(str(key), count) else "  "
			lines.append("%s%s  %d" % [active_mark, key, count])
	lines.append("")
	lines.append("属性:")
	var attribute_keys := attribute_counts.keys()
	attribute_keys.sort()
	if attribute_keys.is_empty():
		lines.append("无")
	else:
		for key in attribute_keys:
			lines.append("  %s  %d" % [key, attribute_counts[key]])
	synergy_label.text = "\n".join(lines)

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
		button.custom_minimum_size = Vector2(330, 112)
		button.disabled = current_stones < ShopManager.BUY_COST
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		_apply_card_style(button)
		_build_offer_card(button, offer)
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

func _short_description(description: String) -> String:
	if description.length() <= 18:
		return description
	return description.substr(0, 18) + "..."

func _build_offer_card(button: Button, offer: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.anchor_right = 1.0
	row.anchor_bottom = 1.0
	row.offset_left = 10.0
	row.offset_top = 8.0
	row.offset_right = -10.0
	row.offset_bottom = -8.0
	row.add_theme_constant_override("separation", 10)
	button.add_child(row)

	var icon_rect := TextureRect.new()
	icon_rect.texture = _get_offer_icon(offer)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(78, 78)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_rect)

	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	var name_label := Label.new()
	name_label.text = "%s %s" % [offer.get("display_name", "未知法宝"), _make_stars(int(offer.get("star_level", 1)))]
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var tag_label := Label.new()
	tag_label.text = "%s / %s" % [_offer_system_tag(offer), _offer_attribute_tag(offer)]
	tag_label.add_theme_color_override("font_color", Color(0.68, 0.82, 1.0))
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(tag_label)

	var price_label := Label.new()
	price_label.text = "%d 灵石" % int(offer.get("price", ShopManager.BUY_COST))
	price_label.add_theme_color_override("font_color", Color(0.98, 0.78, 0.34))
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(price_label)

	var desc_label := Label.new()
	desc_label.text = _short_description(str(offer.get("description", "")))
	desc_label.clip_text = true
	desc_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(desc_label)

func _get_offer_icon(offer: Dictionary) -> Texture2D:
	var icon: Texture2D = offer.get("icon", null) as Texture2D
	if icon != null:
		return icon
	var id: String = str(offer.get("id", ""))
	var path := "res://art/icons/%s.png" % id
	if id != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _make_stars(star_level: int) -> String:
	var stars := ""
	for _index in range(maxi(1, star_level)):
		stars += "★"
	return stars

func _is_system_synergy_active(system_tag: String, count: int) -> bool:
	match system_tag:
		"剑修", "法修", "体修", "阵法", "魔修":
			return count >= 2
		_:
			return false

func _apply_card_style(button: Button) -> void:
	var bg := Color(0.10, 0.12, 0.18, 0.96)
	button.add_theme_stylebox_override("normal", _make_card_style(bg, Color(0.42, 0.46, 0.58), 2))
	button.add_theme_stylebox_override("hover", _make_card_style(bg.lightened(0.08), Color(0.98, 0.78, 0.34), 3))
	button.add_theme_stylebox_override("pressed", _make_card_style(bg.darkened(0.08), Color(1.0, 0.92, 0.62), 3))
	button.add_theme_stylebox_override("disabled", _make_card_style(Color(0.07, 0.07, 0.10, 0.85), Color(0.24, 0.25, 0.30), 1))

func _make_card_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style
