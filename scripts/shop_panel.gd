extends Control
class_name ShopPanel

signal buy_requested(offer_index: int)
signal lock_requested(offer_index: int)
signal reroll_requested
signal breakthrough_requested
signal continue_requested
signal inventory_move_requested(from_area: String, from_index: int, to_area: String, to_index: int)
signal sell_requested(from_area: String, from_index: int)

@onready var title_label: Label = $Panel/MarginContainer/Root/TitleLabel
@onready var root_box: VBoxContainer = $Panel/MarginContainer/Root
@onready var main_row: HBoxContainer = $Panel/MarginContainer/Root/MainRow
@onready var left_column: VBoxContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn
@onready var shop_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame
@onready var battle_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame
@onready var bag_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame
@onready var sell_zone: PanelContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/SellZone
@onready var synergy_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/SynergyFrame
@onready var stone_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/ShopHeader/StoneLabel
@onready var cultivation_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/ShopHeader/CultivationLabel
@onready var message_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/MessageLabel
@onready var offer_box: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/OfferScroll/OfferBox
@onready var battle_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame/BattleBox/BattleLabel
@onready var battle_grid: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame/BattleBox/BattleGrid
@onready var bag_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame/BagBox/BagLabel
@onready var bag_grid: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame/BagBox/BagGrid
@onready var synergy_label: RichTextLabel = $Panel/MarginContainer/Root/MainRow/SynergyFrame/SynergyLabel
@onready var reroll_button: Button = $Panel/MarginContainer/Root/TopActionRow/RerollButton
@onready var breakthrough_button: Button = $Panel/MarginContainer/Root/TopActionRow/BreakthroughButton
@onready var continue_button: Button = $Panel/MarginContainer/Root/TopActionRow/ContinueButton

const SYSTEM_TAGS: Array[String] = ["剑修", "法修", "体修", "召唤", "魔修"]
const ATTRIBUTE_TAGS: Array[String] = ["金", "木", "水", "火", "土", "雷", "毒"]
const SYSTEM_THRESHOLDS: Dictionary = {
	"剑修": [3, 6, 9],
	"法修": [2, 4, 6],
	"体修": [3, 6, 9],
	"召唤": [2, 4, 6],
	"魔修": [2, 4],
}
const ATTRIBUTE_THRESHOLDS: Dictionary = {
	"火": [2, 4, 6],
	"毒": [2, 4, 6],
	"金": [2, 4, 6],
	"木": [2, 4, 6],
	"水": [2, 4, 6],
	"土": [2, 4, 6],
	"雷": [2, 4, 6],
}
const SYNERGY_INACTIVE_COLOR: String = "#7d838d"
const SYNERGY_ACTIVE_COLOR: String = "#7ee36d"
const SYNERGY_ADVANCED_COLOR: String = "#f1c45d"
const SYNERGY_COMPLETE_COLOR: String = "#ff73d1"
const SYNERGY_PARTIAL_COLOR: String = "#79b8ff"
const SYNERGY_EFFECTS: Dictionary = {
	"剑修": "3: 每次造成伤害，剑修法宝攻击速度 +2%，上限20层\n6: 每次造成伤害，剑修法宝攻击速度 +3%，上限40层\n9: 每次造成伤害，剑修法宝攻击速度 +4%，上限60层",
	"法修": "2: 额外发射物 +1，额外弹体 50% 伤害\n4: 额外发射物 +1，额外弹体 75% 伤害\n6: 额外发射物 +2，额外弹体 75% 伤害",
	"体修": "3: 生命 +30% 体型 +10%\n6: 生命 +80% 体型 +25%\n9: 生命 +150% 体型 +50%",
	"召唤": "2: 所有召唤法宝数量上限 +1\n4: 数量上限额外 +1，重生时间 -50%\n6: 数量上限额外 +2，召唤物死亡释放灵力冲击",
	"魔修": "2: 低血量魔修法宝伤害提升\n4: 低血量全部伤害提升",
	"金": "2: 金属性法宝对生命低于50%的敌人造成额外伤害\n4: 额外伤害提高\n6: 对生命低于30%的敌人造成大幅额外伤害",
	"木": "2: 木属性法宝命中禁锢0.5秒\n4: 禁锢提高至1秒\n6: 禁锢提高至1.5秒，禁锢目标受到额外伤害",
	"水": "2: 水属性法宝命中恢复生命\n4: 恢复量提高\n6: 满生命时恢复转化为护盾",
	"火": "2: 火属性法宝命中产生小范围爆炸\n4: 爆炸范围提高\n6: 爆炸伤害提高",
	"土": "2: 土属性法宝命中产生震荡波\n4: 震荡范围提高\n6: 中心目标眩晕，震荡伤害提高",
	"雷": "2: 雷属性伤害额外连锁2个目标\n4: 额外连锁4个目标\n6: 额外连锁6个目标，连锁伤害递减",
	"毒": "2: 毒属性法宝命中附加中毒\n4: 中毒伤害提高\n6: 中毒敌人死亡时产生毒爆",
}

var current_offers: Array = []
var current_battle_slots: Array = []
var current_bag_slots: Array = []
var current_stones: int = 0
var current_realm: String = "炼气"
var current_breakthrough_cost: int = 10
var current_cultivation_progress: int = 0
var current_breakthrough_requirement: int = 120
var current_cultivation_gain: int = 10
var current_is_max_realm: bool = false
var current_reroll_cost: int = ShopManager.REROLL_COST
var debug_catalog_mode: bool = false
var offer_card_size: Vector2 = Vector2(164, 166)
var battle_slot_size: Vector2 = Vector2(168, 72)
var bag_slot_size: Vector2 = Vector2(112, 60)

func _ready() -> void:
	hide()
	_apply_panel_styles()
	_apply_responsive_layout()
	reroll_button.pressed.connect(_on_reroll_button_pressed)
	breakthrough_button.pressed.connect(_on_breakthrough_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	sell_zone.sell_drop_requested.connect(_on_sell_drop_requested)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()
		_render_offers()
		_render_slots()

func open_shop(wave: int, offers: Array, stones: int, battle_slots: Array, bag_slots: Array, system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	title_label.text = "测试法宝列表" if debug_catalog_mode else "准备阶段：第 %d 波" % maxi(1, wave + 1)
	show()
	set_offers(offers)
	set_economy(stones)
	set_inventory(battle_slots, bag_slots)
	set_synergies(system_counts, attribute_counts)
	set_message("点击法宝购买，拖动到出战区或储物袋。")
	call_deferred("_refresh_layout_after_open")

func close_shop() -> void:
	hide()

func set_debug_catalog_mode(enabled: bool) -> void:
	debug_catalog_mode = enabled
	if not is_node_ready():
		return
	reroll_button.visible = not enabled
	breakthrough_button.visible = true
	continue_button.text = "关闭商店" if enabled else "继续战斗"
	_update_cultivation_display()
	_apply_responsive_layout()

func set_economy(stones: int) -> void:
	current_stones = stones
	stone_label.text = "灵石：%d" % current_stones
	reroll_button.text = "刷新：%d" % current_reroll_cost
	reroll_button.disabled = debug_catalog_mode
	_update_cultivation_display()
	_render_offers()

func set_reroll_cost(cost: int) -> void:
	current_reroll_cost = maxi(0, cost)
	if is_node_ready():
		reroll_button.text = "刷新：%d" % current_reroll_cost

func set_cultivation(
	realm: String,
	breakthrough_cost: int,
	is_max_realm: bool,
	cultivation_progress: int = 0,
	breakthrough_requirement: int = 0,
	cultivation_gain: int = 10
) -> void:
	current_realm = realm
	current_breakthrough_cost = breakthrough_cost
	current_is_max_realm = is_max_realm
	current_cultivation_progress = cultivation_progress
	current_breakthrough_requirement = breakthrough_requirement
	current_cultivation_gain = cultivation_gain
	_update_cultivation_display()

func _update_cultivation_display() -> void:
	if not is_node_ready():
		return
	if current_is_max_realm:
		cultivation_label.text = "修为：%s（已达上限）" % current_realm
		breakthrough_button.text = "已达上限"
		breakthrough_button.disabled = true
		return
	cultivation_label.text = "修为：%s %d/%d" % [
		current_realm,
		current_cultivation_progress,
		current_breakthrough_requirement,
	]
	breakthrough_button.text = "加修为：%d（+%d）" % [current_breakthrough_cost, current_cultivation_gain]
	breakthrough_button.disabled = current_stones < current_breakthrough_cost

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
	for index in range(current_offers.size()):
		var offer: Dictionary = current_offers[index] if index < current_offers.size() else {}
		var button: Button = Button.new()
		button.custom_minimum_size = offer_card_size
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.disabled = offer.is_empty()
		button.text = ""
		button.tooltip_text = "" if offer.is_empty() else _make_offer_tooltip(offer)
		button.focus_mode = Control.FOCUS_NONE
		_apply_offer_card_style(button, offer)
		if offer.is_empty():
			_build_empty_offer_card(button)
		else:
			_build_offer_card(button, offer, index)
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

func _on_lock_button_pressed(offer_index: int) -> void:
	lock_requested.emit(offer_index)

func _on_reroll_button_pressed() -> void:
	reroll_requested.emit()

func _on_breakthrough_button_pressed() -> void:
	breakthrough_requested.emit()

func _on_continue_button_pressed() -> void:
	continue_requested.emit()

func _on_sell_drop_requested(from_area: String, from_index: int) -> void:
	sell_requested.emit(from_area, from_index)

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

func _build_offer_card(button: Button, offer: Dictionary, offer_index: int) -> void:
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

	var lock_button: Button = Button.new()
	lock_button.text = "锁" if bool(offer.get("locked", false)) else "开"
	lock_button.tooltip_text = "取消锁定" if bool(offer.get("locked", false)) else "锁定此法宝"
	lock_button.custom_minimum_size = Vector2(34, 26)
	lock_button.anchor_left = 1.0
	lock_button.anchor_right = 1.0
	lock_button.offset_left = -42.0
	lock_button.offset_top = 6.0
	lock_button.offset_right = -8.0
	lock_button.offset_bottom = 32.0
	lock_button.focus_mode = Control.FOCUS_NONE
	lock_button.mouse_filter = Control.MOUSE_FILTER_STOP
	lock_button.pressed.connect(_on_lock_button_pressed.bind(offer_index))
	_apply_lock_button_style(lock_button, bool(offer.get("locked", false)))
	button.add_child(lock_button)

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
	tag_label.text = "%s / %s / %s" % [str(offer.get("tier", "凡器")), _offer_system_tag(offer), _offer_attribute_tag(offer)]
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
	price_label.text = "%d 灵石" % int(offer.get("cost", offer.get("price", 1)))
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", Color(0.98, 0.78, 0.34))
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(price_label)

func _make_offer_tooltip(offer: Dictionary) -> String:
	var lines: Array[String] = [
		"%s %s" % [offer.get("display_name", "未知法宝"), _make_stars(int(offer.get("star_level", 1)))],
		"%s / %s / %s" % [str(offer.get("tier", "凡器")), _offer_system_tag(offer), _offer_attribute_tag(offer)],
		"价格：%d 灵石" % int(offer.get("cost", offer.get("price", 1))),
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
	if float(offer.get("life_cost_flat", 0.0)) > 0.0:
		lines.append("生命消耗：%s" % _format_number(float(offer["life_cost_flat"])))
	if float(offer.get("kill_heal_amount", 0.0)) > 0.0:
		lines.append("击杀回复：%s" % _format_number(float(offer["kill_heal_amount"])))
	if float(offer.get("attack_speed_bonus", 0.0)) > 0.0:
		lines.append("攻速提升：%d%%" % int(roundf(float(offer["attack_speed_bonus"]) * 100.0)))
	if int(offer.get("summon_base_count", 0)) > 0:
		lines.append("召唤数量：%d" % int(offer["summon_base_count"]))
		lines.append("召唤生命：%s" % _format_number(float(offer.get("summon_hp", 0.0))))
		lines.append("召唤攻击：%s" % _format_number(float(offer.get("summon_attack", 0.0))))
		lines.append("召唤攻速：%.2f/秒" % float(offer.get("summon_attack_speed", 1.0)))
		lines.append("重生：%s秒" % _format_number(float(offer.get("summon_respawn_time", 0.0))))
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
	cultivation_label.add_theme_font_size_override("font_size", 16)
	cultivation_label.add_theme_color_override("font_color", Color(0.58, 0.86, 1.0))
	reroll_button.custom_minimum_size = Vector2(118, 38)
	breakthrough_button.custom_minimum_size = Vector2(130, 38)
	reroll_button.focus_mode = Control.FOCUS_NONE
	breakthrough_button.focus_mode = Control.FOCUS_NONE
	reroll_button.mouse_filter = Control.MOUSE_FILTER_STOP
	breakthrough_button.mouse_filter = Control.MOUSE_FILTER_STOP
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
	var offer_columns: int = 4 if debug_catalog_mode else ShopManager.OFFER_COUNT
	offer_box.columns = offer_columns
	var offer_gap: float = 8.0 * float(maxi(0, offer_columns - 1))
	var offer_width: float = floor((left_width - offer_gap) / float(offer_columns))
	offer_card_size = Vector2(clampf(offer_width, 112.0, 230.0), 176.0 if aspect < 1.7 else 168.0)

	var responsive_battle_count: float = maxf(1.0, float(maxi(1, current_battle_slots.size())))
	var battle_width: float = floor((left_width - 8.0 * (responsive_battle_count - 1.0)) / responsive_battle_count)
	battle_slot_size = Vector2(clampf(battle_width, 168.0, 250.0), 72.0)

	var responsive_bag_count: float = maxf(1.0, float(maxi(1, current_bag_slots.size())))
	var bag_width: float = floor((left_width - 8.0 * (responsive_bag_count - 1.0)) / responsive_bag_count)
	bag_slot_size = Vector2(clampf(bag_width, 96.0, 165.0), 58.0)

func _apply_offer_card_style(button: Button, offer: Dictionary = {}) -> void:
	var bg: Color = Color(0.10, 0.115, 0.14, 0.96)
	var border: Color = _tier_border_color(str(offer.get("tier", "")))
	if bool(offer.get("locked", false)):
		border = Color(1.0, 0.78, 0.22)
	button.add_theme_stylebox_override("normal", _make_card_style(bg, border, 2))
	button.add_theme_stylebox_override("hover", _make_card_style(bg.lightened(0.08), border.lightened(0.22), 3))
	button.add_theme_stylebox_override("pressed", _make_card_style(bg.darkened(0.08), border.lightened(0.38), 3))
	button.add_theme_stylebox_override("disabled", _make_card_style(Color(0.06, 0.06, 0.08, 0.86), Color(0.23, 0.23, 0.27), 1))

func _apply_lock_button_style(button: Button, locked: bool) -> void:
	var bg: Color = Color(0.22, 0.18, 0.08, 0.96) if locked else Color(0.08, 0.095, 0.12, 0.96)
	var border: Color = Color(1.0, 0.78, 0.22) if locked else Color(0.42, 0.46, 0.52)
	button.add_theme_stylebox_override("normal", _make_card_style(bg, border, 1))
	button.add_theme_stylebox_override("hover", _make_card_style(bg.lightened(0.12), border.lightened(0.20), 1))
	button.add_theme_stylebox_override("pressed", _make_card_style(bg.darkened(0.08), border.lightened(0.32), 1))
	button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36) if locked else Color(0.78, 0.82, 0.88))

func _tier_border_color(tier: String) -> Color:
	match tier:
		"凡器":
			return Color(0.58, 0.62, 0.66)
		"法器":
			return Color(0.35, 0.86, 0.42)
		"灵器":
			return Color(0.34, 0.62, 1.0)
		"灵宝":
			return Color(0.72, 0.42, 1.0)
		"仙宝":
			return Color(1.0, 0.78, 0.22)
		_:
			return Color(0.44, 0.39, 0.24)

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
