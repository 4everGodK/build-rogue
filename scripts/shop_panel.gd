extends Control
class_name ShopPanel

signal buy_requested(offer_index: int)
signal lock_requested(offer_index: int)
signal reroll_requested
signal breakthrough_requested
signal spirit_gathering_requested
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
@onready var sell_zone: SellDropZone = $Panel/MarginContainer/Root/MainRow/LeftColumn/SellZone
@onready var synergy_frame: PanelContainer = $Panel/MarginContainer/Root/MainRow/SynergyFrame
@onready var stone_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/ShopHeader/StoneLabel
@onready var cultivation_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/ShopHeader/CultivationLabel
@onready var message_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/MessageLabel
@onready var offer_box: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/OfferScroll/OfferBox
@onready var offer_scroll: ScrollContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/ShopFrame/ShopBox/OfferScroll
@onready var battle_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame/BattleBox/BattleLabel
@onready var battle_grid: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BattleFrame/BattleBox/BattleGrid
@onready var bag_label: Label = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame/BagBox/BagLabel
@onready var bag_grid: GridContainer = $Panel/MarginContainer/Root/MainRow/LeftColumn/BagFrame/BagBox/BagGrid
@onready var synergy_label: RichTextLabel = $Panel/MarginContainer/Root/MainRow/SynergyFrame/SynergyLabel
@onready var reroll_button: Button = $Panel/MarginContainer/Root/TopActionRow/RerollButton
@onready var breakthrough_button: Button = $Panel/MarginContainer/Root/TopActionRow/BreakthroughButton
@onready var spirit_gathering_button: Button = $Panel/MarginContainer/Root/TopActionRow/SpiritGatheringButton
@onready var spirit_gathering_label: Label = $Panel/MarginContainer/Root/TopActionRow/SpiritGatheringLabel
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
var current_material_name: String = ""
var current_has_material: bool = false
var current_is_cultivation_full: bool = false
var current_is_max_realm: bool = false
var current_reroll_cost: int = ShopManager.REROLL_COST
var current_spirit_gathering_cost: int = 100
var current_spirit_gathering_layers: int = 0
var current_spirit_gathering_max_layers: int = 3
var current_spirit_gathering_disabled: bool = false
var current_system_counts: Dictionary = {}
var current_attribute_counts: Dictionary = {}
var current_destiny_summary: Dictionary = {}
var current_encounter_summaries: Array = []
var debug_catalog_mode: bool = false
var offer_card_size: Vector2 = Vector2(164, 166)
var battle_slot_size: Vector2 = Vector2(168, 72)
var bag_slot_size: Vector2 = Vector2(112, 60)
var compact_layout: bool = false
var offer_buttons: Array[Button] = []
var lock_buttons: Array[Button] = []
var battle_slot_buttons: Array[Control] = []
var bag_slot_buttons: Array[Control] = []
var keyboard_source_area: String = ""
var keyboard_source_index: int = -1

func _ready() -> void:
	hide()
	_apply_panel_styles()
	_apply_responsive_layout()
	reroll_button.pressed.connect(_on_reroll_button_pressed)
	breakthrough_button.pressed.connect(_on_breakthrough_button_pressed)
	spirit_gathering_button.pressed.connect(_on_spirit_gathering_button_pressed)
	continue_button.pressed.connect(_on_continue_button_pressed)
	sell_zone.sell_drop_requested.connect(_on_sell_drop_requested)
	sell_zone.keyboard_sell_requested.connect(_on_keyboard_sell_requested)

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
	set_message("购买：确认键　移动：先选法宝再选槽位　出售：选法宝后确认出售区。")
	call_deferred("_refresh_layout_after_open")
	call_deferred("_focus_shop_entry")

func close_shop() -> void:
	_clear_keyboard_source()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible or keyboard_source_area.is_empty():
		return
	if event.is_action_pressed("ui_cancel"):
		_clear_keyboard_source()
		set_message("已取消移动法宝。")
		get_viewport().set_input_as_handled()

func set_debug_catalog_mode(enabled: bool) -> void:
	debug_catalog_mode = enabled
	if not is_node_ready():
		return
	reroll_button.visible = not enabled
	spirit_gathering_button.visible = not enabled
	spirit_gathering_label.visible = not enabled
	breakthrough_button.visible = true
	continue_button.text = "关闭商店" if enabled else "继续战斗"
	_update_cultivation_display()
	_update_spirit_gathering_display()
	_apply_responsive_layout()

func set_economy(stones: int) -> void:
	current_stones = stones
	stone_label.text = "灵石：%d" % current_stones
	reroll_button.text = "刷新：%d" % current_reroll_cost
	reroll_button.disabled = debug_catalog_mode
	_update_spirit_gathering_display()
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
	cultivation_gain: int = 10,
	material_name: String = "",
	has_material: bool = false,
	is_cultivation_full: bool = false
) -> void:
	current_realm = realm
	current_breakthrough_cost = breakthrough_cost
	current_is_max_realm = is_max_realm
	current_cultivation_progress = cultivation_progress
	current_breakthrough_requirement = breakthrough_requirement
	current_cultivation_gain = cultivation_gain
	current_material_name = material_name
	current_has_material = has_material
	current_is_cultivation_full = is_cultivation_full
	_update_cultivation_display()

func set_spirit_gathering(cost: int, layers: int, max_layers: int, disabled: bool = false) -> void:
	current_spirit_gathering_cost = maxi(0, cost)
	current_spirit_gathering_layers = maxi(0, layers)
	current_spirit_gathering_max_layers = maxi(1, max_layers)
	current_spirit_gathering_disabled = disabled
	_update_spirit_gathering_display()

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
	if current_is_cultivation_full:
		var material_state: String = "已获" if current_has_material else "缺少"
		cultivation_label.text += "  %s：%s" % [current_material_name, material_state]
		breakthrough_button.text = "突破：%s" % current_material_name
		breakthrough_button.disabled = false
		return
	breakthrough_button.text = "加修为：%d（+%d）" % [current_breakthrough_cost, current_cultivation_gain]
	breakthrough_button.disabled = current_stones < current_breakthrough_cost

func _update_spirit_gathering_display() -> void:
	if not is_node_ready():
		return
	spirit_gathering_button.text = "聚灵禁用" if current_spirit_gathering_disabled else "聚灵 %d" % current_spirit_gathering_cost
	spirit_gathering_label.text = "%d/%d" % [current_spirit_gathering_layers, current_spirit_gathering_max_layers]
	spirit_gathering_button.tooltip_text = "当前奇遇效果使聚灵不可用。" if current_spirit_gathering_disabled else "花费%d灵石聚灵1层。\n下回合返还110灵石。\n最多%d层。" % [current_spirit_gathering_cost, current_spirit_gathering_max_layers]
	spirit_gathering_label.tooltip_text = spirit_gathering_button.tooltip_text
	spirit_gathering_button.disabled = debug_catalog_mode or current_spirit_gathering_disabled or current_spirit_gathering_layers >= current_spirit_gathering_max_layers or current_stones < current_spirit_gathering_cost

func set_offers(offers: Array) -> void:
	current_offers = offers.duplicate(true)
	_render_offers()

func set_inventory(battle_slots: Array, bag_slots: Array) -> void:
	current_battle_slots = battle_slots.duplicate()
	current_bag_slots = bag_slots.duplicate()
	_update_slot_layouts()
	_render_slots()

func set_synergies(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	current_system_counts = system_counts.duplicate(true)
	current_attribute_counts = attribute_counts.duplicate(true)
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
	_append_run_modifier_lines(lines)
	synergy_label.text = "\n".join(lines)
	synergy_label.tooltip_text = ""

func set_run_modifiers(destiny_summary: Dictionary, encounter_summaries: Array) -> void:
	current_destiny_summary = destiny_summary.duplicate(true)
	current_encounter_summaries = encounter_summaries.duplicate(true)
	set_synergies(current_system_counts, current_attribute_counts)

func _append_run_modifier_lines(lines: Array[String]) -> void:
	if current_destiny_summary.is_empty() and current_encounter_summaries.is_empty():
		return
	lines.append("")
	lines.append("[b][color=#f2d27b]天命/奇遇[/color][/b]")
	if not current_destiny_summary.is_empty():
		lines.append(_format_run_modifier_line("天命", current_destiny_summary))
	for summary in current_encounter_summaries:
		lines.append(_format_run_modifier_line("奇遇", summary))

func _format_run_modifier_line(kind: String, summary: Dictionary) -> String:
	var title: String = str(summary.get("title", ""))
	var detail: String = str(summary.get("detail", ""))
	if title.is_empty():
		title = kind
	if detail.is_empty():
		detail = title
	return "[color=#d7c39a][hint=%s]%s：%s[/hint][/color]" % [_bbcode_hint(detail), kind, _bbcode_hint(title)]

func _bbcode_hint(text: String) -> String:
	return text.replace("[", "［").replace("]", "］").replace("\n", "；")

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
	offer_buttons.clear()
	lock_buttons.clear()
	lock_buttons.resize(current_offers.size())
	for index in range(current_offers.size()):
		var offer: Dictionary = current_offers[index] if index < current_offers.size() else {}
		var button: Button = Button.new()
		button.custom_minimum_size = offer_card_size
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.disabled = offer.is_empty()
		button.text = ""
		button.tooltip_text = "" if offer.is_empty() else _make_offer_tooltip(offer)
		button.focus_mode = Control.FOCUS_ALL
		_apply_offer_card_style(button, offer)
		if offer.is_empty():
			_build_empty_offer_card(button)
		else:
			_build_offer_card(button, offer, index)
			button.pressed.connect(_on_offer_button_pressed.bind(index))
		offer_box.add_child(button)
		offer_buttons.append(button)
	call_deferred("_configure_focus_navigation")

func _render_slots() -> void:
	for child in battle_grid.get_children():
		child.queue_free()
	for child in bag_grid.get_children():
		child.queue_free()
	battle_slot_buttons.clear()
	bag_slot_buttons.clear()
	for index in range(current_battle_slots.size()):
		var battle_button := _make_slot_button("battle", index, current_battle_slots[index] as ArtifactStack)
		battle_grid.add_child(battle_button)
		battle_slot_buttons.append(battle_button)
	for index in range(current_bag_slots.size()):
		var bag_button := _make_slot_button("bag", index, current_bag_slots[index] as ArtifactStack)
		bag_grid.add_child(bag_button)
		bag_slot_buttons.append(bag_button)
	call_deferred("_configure_focus_navigation")

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
	button.pressed.connect(_on_inventory_slot_activated.bind(area, index))
	return button

func _on_offer_button_pressed(offer_index: int) -> void:
	buy_requested.emit(offer_index)

func _on_lock_button_pressed(offer_index: int) -> void:
	lock_requested.emit(offer_index)

func _on_reroll_button_pressed() -> void:
	reroll_requested.emit()

func _on_breakthrough_button_pressed() -> void:
	breakthrough_requested.emit()

func _on_spirit_gathering_button_pressed() -> void:
	spirit_gathering_requested.emit()

func _on_continue_button_pressed() -> void:
	continue_requested.emit()

func _on_sell_drop_requested(from_area: String, from_index: int) -> void:
	sell_requested.emit(from_area, from_index)

func _on_inventory_slot_activated(area: String, index: int) -> void:
	if keyboard_source_area.is_empty():
		if _stack_at(area, index) == null:
			set_message("空槽位不能作为移动起点。")
			return
		keyboard_source_area = area
		keyboard_source_index = index
		set_message("已选中法宝：选择目标槽位移动，或确认出售区出售。")
		return
	if keyboard_source_area == area and keyboard_source_index == index:
		_clear_keyboard_source()
		set_message("已取消选择。")
		return
	inventory_move_requested.emit(keyboard_source_area, keyboard_source_index, area, index)
	_clear_keyboard_source()
	set_message("法宝已移动。")

func _on_keyboard_sell_requested() -> void:
	if keyboard_source_area.is_empty():
		set_message("请先在出战区或储物袋选择要出售的法宝。")
		return
	sell_requested.emit(keyboard_source_area, keyboard_source_index)
	_clear_keyboard_source()
	set_message("法宝已出售。")

func _stack_at(area: String, index: int) -> ArtifactStack:
	var slots: Array = current_battle_slots if area == "battle" else current_bag_slots if area == "bag" else []
	if index < 0 or index >= slots.size():
		return null
	return slots[index] as ArtifactStack

func _clear_keyboard_source() -> void:
	keyboard_source_area = ""
	keyboard_source_index = -1

func _focus_shop_entry() -> void:
	for button in offer_buttons:
		if is_instance_valid(button) and button.visible and not button.disabled:
			button.grab_focus()
			return
	if is_instance_valid(continue_button):
		continue_button.grab_focus()

func _configure_focus_navigation() -> void:
	if not is_node_ready():
		return
	var top_row: Array[Control] = []
	for control in [reroll_button, breakthrough_button, spirit_gathering_button, continue_button]:
		if is_instance_valid(control) and control.visible and not control.disabled:
			top_row.append(control)
	var locks := _valid_focus_controls(lock_buttons)
	var offers := _valid_focus_controls(offer_buttons)
	var battle := _valid_focus_controls(battle_slot_buttons)
	var bag := _valid_focus_controls(bag_slot_buttons)
	var sell: Array[Control] = [sell_zone]
	_link_horizontal(top_row)
	_link_horizontal(locks)
	_link_horizontal(offers)
	_link_horizontal(battle)
	_link_horizontal(bag)
	_link_vertical(top_row, locks if not locks.is_empty() else offers)
	if not locks.is_empty():
		_link_vertical(locks, offers)
	_link_vertical(offers, battle)
	_link_vertical(battle, bag)
	_link_vertical(bag, sell)
	if is_instance_valid(sell_zone) and is_instance_valid(continue_button):
		sell_zone.focus_neighbor_bottom = sell_zone.get_path_to(continue_button)

func _valid_focus_controls(source: Array) -> Array[Control]:
	var result: Array[Control] = []
	for value in source:
		var control := value as Control
		if is_instance_valid(control) and control.visible and not bool(control.get("disabled")):
			result.append(control)
	return result

func _link_horizontal(row: Array[Control]) -> void:
	if row.size() <= 1:
		return
	for index in row.size():
		var control := row[index]
		var left := row[(index - 1 + row.size()) % row.size()]
		var right := row[(index + 1) % row.size()]
		control.focus_neighbor_left = control.get_path_to(left)
		control.focus_neighbor_right = control.get_path_to(right)

func _link_vertical(upper: Array[Control], lower: Array[Control]) -> void:
	if upper.is_empty() or lower.is_empty():
		return
	for index in upper.size():
		var target_index := mini(lower.size() - 1, int(floor(float(index) * float(lower.size()) / float(upper.size()))))
		upper[index].focus_neighbor_bottom = upper[index].get_path_to(lower[target_index])
	for index in lower.size():
		var target_index := mini(upper.size() - 1, int(floor(float(index) * float(upper.size()) / float(lower.size()))))
		lower[index].focus_neighbor_top = lower[index].get_path_to(upper[target_index])

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
	lock_button.text = "已锁" if bool(offer.get("locked", false)) else "锁定"
	lock_button.tooltip_text = "取消锁定" if bool(offer.get("locked", false)) else "锁定此法宝"
	lock_button.custom_minimum_size = UITokens.MIN_TARGET
	lock_button.anchor_left = 1.0
	lock_button.anchor_right = 1.0
	lock_button.offset_left = -56.0
	lock_button.offset_top = 4.0
	lock_button.offset_right = -8.0
	lock_button.offset_bottom = 52.0
	lock_button.focus_mode = Control.FOCUS_ALL
	lock_button.mouse_filter = Control.MOUSE_FILTER_STOP
	lock_button.pressed.connect(_on_lock_button_pressed.bind(offer_index))
	_apply_lock_button_style(lock_button, bool(offer.get("locked", false)))
	button.add_child(lock_button)
	if offer_index >= 0 and offer_index < lock_buttons.size():
		lock_buttons[offer_index] = lock_button

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 7)
	box.add_child(top_row)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = _get_offer_icon(offer)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(42, 42) if compact_layout else Vector2(50, 50)
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
	tag_label.add_theme_font_size_override("font_size", UITokens.FONT_CAPTION)
	tag_label.add_theme_color_override("font_color", Color(0.68, 0.82, 1.0))
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(tag_label)

	var decision_label := Label.new()
	var decision := _offer_decision_hint(offer)
	decision_label.text = str(decision.get("text", ""))
	decision_label.add_theme_font_size_override("font_size", UITokens.FONT_CAPTION)
	decision_label.add_theme_color_override("font_color", decision.get("color", UITokens.JADE_500))
	decision_label.clip_text = true
	decision_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(decision_label)

	var desc_label: Label = Label.new()
	desc_label.text = _short_description(str(offer.get("description", "")), 18)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(0, 24)
	desc_label.visible = not compact_layout
	desc_label.add_theme_color_override("font_color", Color(0.82, 0.84, 0.9))
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(desc_label)

	var price_label: Label = Label.new()
	var offer_cost := int(offer.get("cost", offer.get("price", 1)))
	price_label.text = "%d 灵石" % offer_cost
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.add_theme_font_size_override("font_size", 16)
	price_label.add_theme_color_override("font_color", UITokens.AMBER_500 if current_stones >= offer_cost else UITokens.VERMILION_500)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(price_label)

func _offer_decision_hint(offer: Dictionary) -> Dictionary:
	var offer_id := str(offer.get("id", ""))
	if _owns_artifact_id(offer_id):
		return {"text": "◆ 已有同名，可用于合成", "color": UITokens.JADE_500}
	var candidates: Array[Dictionary] = []
	var system_tag := _offer_system_tag(offer)
	candidates.append({"tag": system_tag, "count": int(current_system_counts.get(system_tag, 0)), "thresholds": SYSTEM_THRESHOLDS.get(system_tag, [2])})
	for attribute_tag in offer.get("attribute_tags", [_offer_attribute_tag(offer)]):
		var normalized := str(attribute_tag)
		candidates.append({"tag": normalized, "count": int(current_attribute_counts.get(normalized, 0)), "thresholds": ATTRIBUTE_THRESHOLDS.get(normalized, [2])})
	for candidate in candidates:
		var target := _next_synergy_target(int(candidate["count"]), candidate["thresholds"])
		if int(candidate["count"]) < target and int(candidate["count"]) + 1 >= target:
			return {"text": "◆ 购买后激活 %s %d" % [candidate["tag"], target], "color": UITokens.AMBER_500}
	if not candidates.is_empty():
		var first := candidates[0]
		var target := _next_synergy_target(int(first["count"]), first["thresholds"])
		return {"text": "◇ 推进 %s %d/%d" % [first["tag"], mini(int(first["count"]) + 1, target), target], "color": UITokens.PLAYER_CYAN}
	return {"text": "◇ 查看详情判断构筑", "color": UITokens.PAPER_200}

func _owns_artifact_id(artifact_id: String) -> bool:
	if artifact_id.is_empty():
		return false
	for stack in current_battle_slots + current_bag_slots:
		var artifact_stack := stack as ArtifactStack
		if artifact_stack != null and artifact_stack.artifact_data != null and artifact_stack.artifact_data.id == artifact_id:
			return true
	return false

func _make_offer_tooltip(offer: Dictionary) -> String:
	var lines: Array[String] = [
		"%s %s" % [offer.get("display_name", "未知法宝"), _make_stars(int(offer.get("star_level", 1)))],
		"%s / %s" % [_offer_system_tag(offer), _offer_attribute_tag(offer)],
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
	if offer.has("attribute_display"):
		return str(offer["attribute_display"])
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
	shop_frame.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.98), UITokens.AMBER_500.darkened(0.35), 2, UITokens.RADIUS_CARD, 6))
	battle_frame.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.98), UITokens.PLAYER_CYAN.darkened(0.30), 2, UITokens.RADIUS_CARD, 6))
	bag_frame.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_950, 0.90), UITokens.INK_800, 1, UITokens.RADIUS_CARD, 6))
	synergy_frame.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.98), UITokens.AMBER_500.darkened(0.42), 2, UITokens.RADIUS_CARD, 6))
	title_label.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	title_label.add_theme_color_override("font_color", UITokens.PAPER_100)
	stone_label.add_theme_font_size_override("font_size", UITokens.FONT_HEADING_SM)
	stone_label.add_theme_color_override("font_color", UITokens.AMBER_500)
	cultivation_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY_SM)
	cultivation_label.add_theme_color_override("font_color", UITokens.PLAYER_CYAN)
	reroll_button.custom_minimum_size = Vector2(118, 48)
	breakthrough_button.custom_minimum_size = Vector2(130, 48)
	spirit_gathering_button.custom_minimum_size = Vector2(118, 48)
	spirit_gathering_label.custom_minimum_size = UITokens.MIN_TARGET
	reroll_button.focus_mode = Control.FOCUS_ALL
	breakthrough_button.focus_mode = Control.FOCUS_ALL
	spirit_gathering_button.focus_mode = Control.FOCUS_ALL
	continue_button.focus_mode = Control.FOCUS_ALL
	reroll_button.mouse_filter = Control.MOUSE_FILTER_STOP
	breakthrough_button.mouse_filter = Control.MOUSE_FILTER_STOP
	spirit_gathering_button.mouse_filter = Control.MOUSE_FILTER_STOP
	spirit_gathering_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	spirit_gathering_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY_SM)
	spirit_gathering_label.add_theme_color_override("font_color", UITokens.PLAYER_CYAN)
	battle_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY)
	battle_label.add_theme_color_override("font_color", UITokens.PLAYER_CYAN)
	bag_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY_SM)
	bag_label.add_theme_color_override("font_color", UITokens.PAPER_200)
	synergy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	synergy_label.add_theme_constant_override("line_separation", 4)

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var aspect: float = viewport_size.x / viewport_size.y
	compact_layout = viewport_size.y <= 720.0
	offer_scroll.custom_minimum_size.y = 148.0 if compact_layout else clampf(viewport_size.y * 0.26, 176.0, 300.0)
	root_box.add_theme_constant_override("separation", 8 if compact_layout else 10)
	left_column.add_theme_constant_override("separation", 6 if compact_layout else 10)
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

	var frame_width: float = minf(viewport_size.x, viewport_size.y * 16.0 / 9.0)
	var safe_content_width: float = frame_width * (1.0 - UITokens.SAFE_MARGIN_RATIO * 2.0)
	var available_left_width: float = maxf(520.0, safe_content_width - side_width - 14.0)
	var left_width: float = clampf(available_left_width, 520.0, 1180.0)
	var offer_columns: int = 4 if debug_catalog_mode else maxi(1, current_offers.size())
	offer_box.columns = offer_columns
	var offer_gap: float = 8.0 * float(maxi(0, offer_columns - 1))
	var offer_width: float = floor((left_width - offer_gap) / float(offer_columns))
	offer_card_size = Vector2(clampf(offer_width, 112.0, 230.0), 144.0 if compact_layout else 176.0 if aspect < 1.7 else 168.0)

	var responsive_battle_count: float = maxf(1.0, float(maxi(1, current_battle_slots.size())))
	var battle_width: float = floor((left_width - 8.0 * (responsive_battle_count - 1.0)) / responsive_battle_count)
	battle_slot_size = Vector2(clampf(battle_width, 152.0, 250.0), 56.0 if compact_layout else 72.0)

	var responsive_bag_count: float = maxf(1.0, float(maxi(1, current_bag_slots.size())))
	var bag_width: float = floor((left_width - 8.0 * (responsive_bag_count - 1.0)) / responsive_bag_count)
	bag_slot_size = Vector2(clampf(bag_width, 92.0, 165.0), 48.0 if compact_layout else 58.0)

func _apply_offer_card_style(button: Button, offer: Dictionary = {}) -> void:
	var bg: Color = Color(UITokens.INK_900, 0.98)
	var border: Color = _tier_border_color(str(offer.get("tier", "")))
	if bool(offer.get("locked", false)):
		border = Color(1.0, 0.78, 0.22)
	button.add_theme_stylebox_override("normal", _make_card_style(bg, border, 2))
	button.add_theme_stylebox_override("hover", _make_card_style(bg.lightened(0.08), border.lightened(0.22), 3))
	button.add_theme_stylebox_override("pressed", _make_card_style(bg.darkened(0.08), border.lightened(0.38), 3))
	button.add_theme_stylebox_override("disabled", _make_card_style(Color(0.06, 0.06, 0.08, 0.86), Color(0.23, 0.23, 0.27), 1))
	button.add_theme_stylebox_override("focus", UITokens.focus_style())

func _apply_lock_button_style(button: Button, locked: bool) -> void:
	var bg: Color = Color(0.22, 0.18, 0.08, 0.96) if locked else Color(0.08, 0.095, 0.12, 0.96)
	var border: Color = Color(1.0, 0.78, 0.22) if locked else Color(0.42, 0.46, 0.52)
	button.add_theme_stylebox_override("normal", _make_card_style(bg, border, 1))
	button.add_theme_stylebox_override("hover", _make_card_style(bg.lightened(0.12), border.lightened(0.20), 1))
	button.add_theme_stylebox_override("pressed", _make_card_style(bg.darkened(0.08), border.lightened(0.32), 1))
	button.add_theme_stylebox_override("focus", UITokens.focus_style())
	button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.36) if locked else Color(0.78, 0.82, 0.88))

func _tier_border_color(tier: String) -> Color:
	return UITokens.rarity_color(tier)

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	return UITokens.style(bg_color, border_color, border_width, UITokens.RADIUS_CARD, 10)

func _make_card_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	return UITokens.style(bg_color, border_color, border_width, UITokens.RADIUS_CARD, 7)
