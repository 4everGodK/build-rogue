extends Control
class_name ShopPanel

signal buy_requested(offer_index: int)
signal reroll_requested
signal continue_requested
signal inventory_move_requested(from_area: String, from_index: int, to_area: String, to_index: int)

@onready var title_label: Label = $Panel/MarginContainer/Root/TitleLabel
@onready var root_box: VBoxContainer = $Panel/MarginContainer/Root
@onready var main_row: HBoxContainer = $Panel/MarginContainer/Root/MainRow
@onready var left_column: VBoxContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn
@onready var shop_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame
@onready var battle_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame
@onready var bag_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame
@onready var synergy_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/SynergyFrame
@onready var stone_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/ShopHeader/StoneLabel
@onready var message_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/MessageLabel
@onready var offer_box: HBoxContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/OfferBox
@onready var battle_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame/BattleBox/BattleLabel
@onready var battle_grid: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame/BattleBox/BattleGrid
@onready var bag_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame/BagBox/BagLabel
@onready var bag_grid: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame/BagBox/BagGrid
@onready var synergy_label: RichTextLabel = $Panel/MarginContainer/Root/MainRow/SynergyFrame/SynergyLabel
@onready var reroll_button: Button = $Panel/MarginContainer/Root/TopActionRow/RerollButton
@onready var continue_button: Button = $Panel/MarginContainer/Root/TopActionRow/ContinueButton

const SYSTEM_TAGS: Array[String] = ["剑修", "法修", "体修", "阵法", "召唤", "魔修"]
const ATTRIBUTE_TAGS: Array[String] = ["金", "木", "水", "火", "土", "风", "雷", "毒", "暗"]
const SYSTEM_THRESHOLDS: Dictionary = {
	"剑修": [2, 4, 6],
	"法修": [2, 4, 6],
	"体修": [2, 4],
	"阵法": [2, 4],
	"召唤": [2],
	"魔修": [2, 4],
}
const ATTRIBUTE_THRESHOLDS: Dictionary = {
	"火": [3],
	"风": [3],
	"毒": [3],
	"金": [2],
	"木": [2],
	"水": [2],
	"土": [2],
	"雷": [2],
	"暗": [2],
}
const SYNERGY_INACTIVE_COLOR: String = "#7d838d"
const SYNERGY_ACTIVE_COLOR: String = "#7ee36d"
const SYNERGY_ADVANCED_COLOR: String = "#f1c45d"
const SYNERGY_COMPLETE_COLOR: String = "#ff73d1"
const SYNERGY_PARTIAL_COLOR: String = "#79b8ff"
const SYNERGY_EFFECTS: Dictionary = {
	"剑修": "2: 20% 双击\n4: 35% 双击\n6: 50% 双击",
	"法修": "2: 额外发射物 +1，额外弹体 50% 伤害\n4: 额外发射物 +1，额外弹体 75% 伤害\n6: 额外发射物 +2，额外弹体 75% 伤害",
	"体修": "2: 生命上限 +20\n4: 受伤反震",
	"阵法": "2: 阵法范围 +25%\n4: 阵法范围 +50%",
	"召唤": "2: 召唤流预留羁绊",
	"魔修": "2: 低血量魔修法宝伤害提升\n4: 低血量全部伤害提升",
	"火": "属性羁绊预留：火属性 Build 方向",
	"风": "属性羁绊预留：风属性 Build 方向",
	"毒": "属性羁绊预留：毒属性 Build 方向",
	"金": "属性羁绊预留：金属性 Build 方向",
	"木": "属性羁绊预留：木属性 Build 方向",
	"水": "属性羁绊预留：水属性 Build 方向",
	"土": "属性羁绊预留：土属性 Build 方向",
	"雷": "属性羁绊预留：雷属性 Build 方向",
	"暗": "属性羁绊预留：暗属性 Build 方向",
}

var current_offers: Array = []
var current_battle_slots: Array = []
var current_bag_slots: Array = []
var current_stones: int = 0
var offer_card_size: Vector2 = Vector2(164, 166)
var battle_slot_size: Vector2 = Vector2(168, 72)
var bag_slot_size: Vector2 = Vector2(112, 60)

func _ready() -> void:
	hide()
	_apply_panel_styles()
	_apply_responsive_layout()
	reroll_button.pressed.connect(_on_reroll_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()
		_render_offers()
		_render_slots()

func open_shop(wave: int, offers: Array, stones: int, battle_slots: Array, bag_slots: Array, system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	title_label.text = "准备阶段：第 %d 波" % maxi(1, wave + 1)
	show()
	set_offers(offers)
	set_economy(stones)
	set_inventory(battle_slots, bag_slots)
	set_synergies(system_counts, attribute_counts)
	set_message("点击法宝购买，拖动到出战区或储物袋。")
	call_deferred("_refresh_layout_after_open")

func close_shop() -> void:
	hide()

func set_economy(stones: int) -> void:
	current_stones = stones
	stone_label.text = "灵石：%d" % current_stones
	reroll_button.text = "刷新：%d" % ShopManager.REROLL_COST
	reroll_button.disabled = false
	_render_offers()

func set_offers(offers: Array) -> void:
	current_offers = offers.duplicate(true)
	_render_offers()

func set_inventory(battle_slots: Array, bag_slots: Array) -> void:
	current_battle_slots = battle_slots.duplicate()
	current_bag_slots = bag_slots.duplicate()
	_update_slot_layouts()
	_render_slots()

func set_synergies(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	var lines: Array[String] = [
		"[b][color=#f2d27b]体系[/color][/b]",
	]
	for system_tag in _sorted_synergy_tags(SYSTEM_TAGS, system_counts, SYSTEM_THRESHOLDS):
		var system_thresholds: Array = SYSTEM_THRESHOLDS.get(system_tag, [2])
		lines.append(_format_synergy_line(system_tag, int(system_counts.get(system_tag, 0)), system_thresholds))
	lines.append("")
	lines.append("[b][color=#f2d27b]属性[/color][/b]")
	for attribute_tag in _sorted_synergy_tags(ATTRIBUTE_TAGS, attribute_counts, ATTRIBUTE_THRESHOLDS):
		var attribute_thresholds: Array = ATTRIBUTE_THRESHOLDS.get(attribute_tag, [2])
		lines.append(_format_synergy_line(attribute_tag, int(attribute_counts.get(attribute_tag, 0)), attribute_thresholds))
	lines.append("")
	lines.append("[color=#7ee36d]■ 已激活[/color]  [color=#7d838d]■ 未激活[/color]")
	synergy_label.text = "\n".join(lines)
	synergy_label.tooltip_text = ""

func _refresh_layout_after_open() -> void:
	_apply_responsive_layout()
	_render_offers()
	_render_slots()

func set_message(message: String) -> void:
	message_label.text = message

func _render_offers() -> void:
	if not is_node_ready():
		return
	for child in offer_box.get_children():
		child.queue_free()
	for index in range(ShopManager.OFFER_COUNT):
		var offer: Dictionary = current_offers[index] if index < current_offers.size() else {}
		var button: Button = Button.new()
		button.custom_minimum_size = offer_card_size
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.disabled = offer.is_empty()
		button.text = ""
		button.tooltip_text = "" if offer.is_empty() else _make_offer_tooltip(offer)
		button.focus_mode = Control.FOCUS_NONE
		_apply_offer_card_style(button)
		if offer.is_empty():
			_build_empty_offer_card(button)
		else:
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

func _update_slot_layouts() -> void:
	var battle_count: int = current_battle_slots.size()
	var filled_battle: int = _filled_slot_count(current_battle_slots)
	battle_label.text = "出战区（%d/%d）" % [filled_battle, battle_count]
	battle_grid.columns = maxi(1, battle_count)
	bag_label.text = "储物袋（%d/%d）" % [_filled_slot_count(current_bag_slots), current_bag_slots.size()]
	bag_grid.columns = maxi(1, current_bag_slots.size())

func _filled_slot_count(slots: Array) -> int:
	var count: int = 0
	for slot in slots:
		if slot != null:
			count += 1
	return count

func _make_slot_button(area: String, index: int, stack: ArtifactStack) -> InventorySlotButton:
	var button: InventorySlotButton = InventorySlotButton.new()
	button.setup(area, index, stack)
	button.custom_minimum_size = battle_slot_size if area == "battle" else bag_slot_size
	button.slot_drop_requested.connect(func(from_area: String, from_index: int, to_area: String, to_index: int) -> void:
		inventory_move_requested.emit(from_area, from_index, to_area, to_index)
	)
	return button

func _on_offer_button_pressed(offer_index: int) -> void:
	buy_requested.emit(offer_index)

func _on_reroll_button_pressed() -> void:
	reroll_requested.emit()

func _on_continue_button_pressed() -> void:
	continue_requested.emit()

func _build_empty_offer_card(button: Button) -> void:
	var label: Label = Label.new()
	label.text = "已购买"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.add_theme_color_override("font_color", Color(0.42, 0.43, 0.46))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)

func _build_offer_card(button: Button, offer: Dictionary) -> void:
	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 8.0
	box.offset_top = 7.0
	box.offset_right = -8.0
	box.offset_bottom = -7.0
	box.add_theme_constant_override("separation", 4)
	button.add_child(box)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 7)
	box.add_child(top_row)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = _get_offer_icon(offer)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(50, 50)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(icon_rect)

	var name_box: VBoxContainer = VBoxContainer.new()
	name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(name_box)

	var name_label: Label = Label.new()
	name_label.text = str(offer.get("display_name", "未知法宝"))
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.62))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_box.add_child(name_label)

	var star_label: Label = Label.new()
	star_label.text = _make_stars(int(offer.get("star_level", 1)))
	star_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_box.add_child(star_label)

	var tag_label: Label = Label.new()
	tag_label.text = "%s / %s" % [_offer_system_tag(offer), _offer_attribute_tag(offer)]
	tag_label.add_theme_font_size_override("font_size", 13)
	tag_label.add_theme_color_override("font_color", Color(0.68, 0.82, 1.0))
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tag_label)

	var desc_label: Label = Label.new()
	desc_label.text = _short_description(str(offer.get("description", "")), 28)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 44)
	desc_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc_label)

	var price_label: Label = Label.new()
	price_label.text = "%d 灵石" % int(offer.get("price", ShopManager.BUY_COST))
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", Color(0.98, 0.78, 0.34))
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(price_label)

func _make_offer_tooltip(offer: Dictionary) -> String:
	var lines: Array[String] = [
		"%s %s" % [offer.get("display_name", "未知法宝"), _make_stars(int(offer.get("star_level", 1)))],
		"%s / %s" % [_offer_system_tag(offer), _offer_attribute_tag(offer)],
		"",
		str(offer.get("description", "")),
		"",
		"伤害：%s" % _format_number(float(offer.get("damage", 0.0))),
		"冷却：%.2f 秒" % float(offer.get("cooldown", 0.0)),
	]
	var specials: Array[String] = _offer_special_lines(offer)
	if not specials.is_empty():
		lines.append("")
		lines.append("特殊机制：")
		lines.append_array(specials)
	lines.append("")
	lines.append("升星效果：")
	lines.append(ArtifactStarConfig.describe_offer(offer, int(offer.get("star_level", 1))))
	return "\n".join(lines)

func _offer_special_lines(offer: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if float(offer.get("poison_dps", 0.0)) > 0.0:
		lines.append("中毒：每秒 %s，持续 %.1f 秒" % [_format_number(float(offer["poison_dps"])), float(offer.get("poison_duration", 0.0))])
	if float(offer.get("knockback_force", 0.0)) > 0.0:
		lines.append("击退：%s" % _format_number(float(offer["knockback_force"])))
	if int(offer.get("projectile_pierce", 0)) > 0:
		lines.append("穿透：+%d" % int(offer["projectile_pierce"]))
	if int(offer.get("projectile_bounce", 0)) > 0 or int(offer.get("bounce_count", 0)) > 0:
		lines.append("弹射：%d 次" % maxi(int(offer.get("projectile_bounce", 0)), int(offer.get("bounce_count", 0))))
	if float(offer.get("explosion_radius", 0.0)) > 0.0:
		lines.append("爆炸半径：%s" % _format_number(float(offer["explosion_radius"])))
	if float(offer.get("counter_range", 0.0)) > 0.0:
		lines.append("反击范围：%s" % _format_number(float(offer["counter_range"])))
	if float(offer.get("slow_percent", 0.0)) > 0.0:
		lines.append("减速：%d%%" % int(roundf(float(offer["slow_percent"]) * 100.0)))
	if float(offer.get("heal_amount", 0.0)) > 0.0:
		lines.append("治疗：%s" % _format_number(float(offer["heal_amount"])))
	if float(offer.get("shield_amount", 0.0)) > 0.0:
		lines.append("护盾：%s" % _format_number(float(offer["shield_amount"])))
	if float(offer.get("damage_reduction_percent", 0.0)) > 0.0:
		lines.append("减伤：%d%%" % int(roundf(float(offer["damage_reduction_percent"]) * 100.0)))
	if float(offer.get("life_cost_percent", 0.0)) > 0.0:
		lines.append("生命消耗：%s%%" % _format_number(float(offer["life_cost_percent"])))
	if float(offer.get("attack_speed_bonus", 0.0)) > 0.0:
		lines.append("攻速提升：%d%%" % int(roundf(float(offer["attack_speed_bonus"]) * 100.0)))
	return lines

func _format_synergy_line(tag: String, count: int, thresholds: Array) -> String:
	var target: int = _next_synergy_target(count, thresholds)
	var tier: int = _synergy_tier(count, thresholds)
	var color: String = SYNERGY_INACTIVE_COLOR
	if tier >= thresholds.size():
		color = SYNERGY_COMPLETE_COLOR
	elif tier >= 2:
		color = SYNERGY_ADVANCED_COLOR
	elif tier >= 1:
		color = SYNERGY_ACTIVE_COLOR
	elif count > 0:
		color = SYNERGY_PARTIAL_COLOR
	return "[color=%s][hint=%s]◆ %-3s  %d/%d[/hint][/color]" % [color, _synergy_hint_text(tag, count, thresholds), tag, mini(count, target), target]

func _sorted_synergy_tags(tags: Array[String], counts: Dictionary, threshold_map: Dictionary) -> Array[String]:
	var active: Array[String] = []
	var partial: Array[String] = []
	var inactive: Array[String] = []
	for tag in tags:
		var count: int = int(counts.get(tag, 0))
		var thresholds: Array = threshold_map.get(tag, [2])
		if _synergy_tier(count, thresholds) > 0:
			active.append(tag)
		elif count > 0:
			partial.append(tag)
		else:
			inactive.append(tag)
	var result: Array[String] = []
	result.append_array(active)
	result.append_array(partial)
	result.append_array(inactive)
	return result

func _synergy_hint_text(tag: String, count: int, thresholds: Array) -> String:
	var target: int = _next_synergy_target(count, thresholds)
	var state: String = "未激活"
	if _synergy_tier(count, thresholds) > 0:
		state = "已激活"
	elif count > 0:
		state = "部分激活"
	var effect_text: String = str(SYNERGY_EFFECTS.get(tag, "效果待定")).replace("\n", "；")
	return "%s %d/%d（%s）：%s" % [tag, mini(count, target), target, state, effect_text]

func _next_synergy_target(count: int, thresholds: Array) -> int:
	for threshold in thresholds:
		if count < int(threshold):
			return int(threshold)
	return int(thresholds[thresholds.size() - 1])

func _synergy_tier(count: int, thresholds: Array) -> int:
	var tier: int = 0
	for threshold in thresholds:
		if count >= int(threshold):
			tier += 1
	return tier

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

func _short_description(description: String, max_length: int) -> String:
	if description.length() <= max_length:
		return description
	return description.substr(0, max_length) + "..."

func _get_offer_icon(offer: Dictionary) -> Texture2D:
	var icon: Texture2D = offer.get("icon", null) as Texture2D
	if icon != null:
		return icon
	var id: String = str(offer.get("id", ""))
	var path: String = "res://art/icons/%s.png" % id
	if id != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _make_stars(star_level: int) -> String:
	var stars: String = ""
	for _index in range(maxi(1, star_level)):
		stars += "★"
	return stars

func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value

func _apply_panel_styles() -> void:
	shop_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.095, 0.12, 0.96), Color(0.62, 0.48, 0.22), 2))
	battle_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.12, 0.17, 0.96), Color(0.25, 0.72, 1.0), 2))
	bag_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.065, 0.08, 0.82), Color(0.32, 0.31, 0.28), 1))
	synergy_frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.055, 0.065, 0.075, 0.96), Color(0.58, 0.46, 0.22), 2))
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	stone_label.add_theme_font_size_override("font_size", 20)
	stone_label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.58))
	reroll_button.custom_minimum_size = Vector2(118, 38)
	reroll_button.focus_mode = Control.FOCUS_NONE
	reroll_button.mouse_filter = Control.MOUSE_FILTER_STOP
	battle_label.add_theme_font_size_override("font_size", 18)
	battle_label.add_theme_color_override("font_color", Color(0.48, 0.84, 1.0))
	bag_label.add_theme_color_override("font_color", Color(0.72, 0.69, 0.58))
	synergy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	synergy_label.add_theme_constant_override("line_separation", 4)

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var aspect: float = viewport_size.x / viewport_size.y
	main_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	left_column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	shop_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	battle_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	bag_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	synergy_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	synergy_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	var side_width: float = 270.0
	if aspect >= 2.1:
		side_width = 330.0
	elif aspect >= 1.75:
		side_width = 300.0
	synergy_frame.custom_minimum_size = Vector2(side_width, 0.0)

	var available_left_width: float = maxf(520.0, viewport_size.x - side_width - 78.0)
	var left_width: float = clampf(available_left_width, 520.0, 1180.0)
	var offer_gap: float = 8.0 * float(maxi(0, ShopManager.OFFER_COUNT - 1))
	var offer_width: float = floor((left_width - offer_gap) / float(ShopManager.OFFER_COUNT))
	offer_card_size = Vector2(clampf(offer_width, 112.0, 230.0), 176.0 if aspect < 1.7 else 168.0)

	var responsive_battle_count: float = maxf(1.0, float(maxi(1, current_battle_slots.size())))
	var battle_width: float = floor((left_width - 8.0 * (responsive_battle_count - 1.0)) / responsive_battle_count)
	battle_slot_size = Vector2(clampf(battle_width, 168.0, 250.0), 72.0)

	var responsive_bag_count: float = maxf(1.0, float(maxi(1, current_bag_slots.size())))
	var bag_width: float = floor((left_width - 8.0 * (responsive_bag_count - 1.0)) / responsive_bag_count)
	bag_slot_size = Vector2(clampf(bag_width, 96.0, 165.0), 58.0)

func _apply_offer_card_style(button: Button) -> void:
	var bg: Color = Color(0.10, 0.115, 0.14, 0.96)
	button.add_theme_stylebox_override("normal", _make_card_style(bg, Color(0.44, 0.39, 0.24), 2))
	button.add_theme_stylebox_override("hover", _make_card_style(bg.lightened(0.08), Color(0.98, 0.78, 0.34), 3))
	button.add_theme_stylebox_override("pressed", _make_card_style(bg.darkened(0.08), Color(1.0, 0.92, 0.62), 3))
	button.add_theme_stylebox_override("disabled", _make_card_style(Color(0.06, 0.06, 0.08, 0.86), Color(0.23, 0.23, 0.27), 1))

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

func _make_card_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 7
	style.content_margin_top = 7
	style.content_margin_right = 7
	style.content_margin_bottom = 7
	return style
