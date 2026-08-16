extends CanvasLayer
class_name GameUI

@onready var root: Control = $Root
@onready var safe_area: UISafeAreaControl = $Root/SafeArea
@onready var resource_panel: PanelContainer = $Root/SafeArea/ResourcePanel
@onready var hp_bar: ProgressBar = $Root/SafeArea/ResourcePanel/ResourceMargin/ResourceVBox/HpRow/HpBar
@onready var hp_label: Label = $Root/SafeArea/ResourcePanel/ResourceMargin/ResourceVBox/HpRow/HpLabel
@onready var shield_row: HBoxContainer = $Root/SafeArea/ResourcePanel/ResourceMargin/ResourceVBox/ShieldRow
@onready var shield_bar: ProgressBar = $Root/SafeArea/ResourcePanel/ResourceMargin/ResourceVBox/ShieldRow/ShieldBar
@onready var shield_label: Label = $Root/SafeArea/ResourcePanel/ResourceMargin/ResourceVBox/ShieldRow/ShieldLabel
@onready var stone_label: Label = $Root/SafeArea/ResourcePanel/ResourceMargin/ResourceVBox/StoneLabel
@onready var wave_panel: PanelContainer = $Root/SafeArea/WavePanel
@onready var wave_label: Label = $Root/SafeArea/WavePanel/WaveMargin/WaveHBox/WaveLabel
@onready var timer_label: Label = $Root/SafeArea/WavePanel/WaveMargin/WaveHBox/TimerLabel
@onready var enemy_label: Label = $Root/SafeArea/WavePanel/WaveMargin/WaveHBox/EnemyLabel
@onready var synergy_panel: PanelContainer = $Root/SafeArea/SynergyPanel
@onready var synergy_label: RichTextLabel = $Root/SafeArea/SynergyPanel/SynergyMargin/SynergyLabel
@onready var artifact_bar: PanelContainer = $Root/SafeArea/ArtifactBar
@onready var artifact_slots: HBoxContainer = $Root/SafeArea/ArtifactBar/ArtifactMargin/ArtifactSlots

const SYSTEM_TAGS: Array[String] = ["剑修", "法修", "体修", "召唤", "魔修"]
const ATTRIBUTE_TAGS: Array[String] = ["火", "毒", "雷", "水", "土", "金", "木"]
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
	"雷": [2, 4, 6],
	"水": [2, 4, 6],
	"土": [2, 4, 6],
	"金": [2, 4, 6],
	"木": [2, 4, 6],
}

const COLOR_INACTIVE: String = "#858992"
const COLOR_CLOSE: String = "#79b8ff"
const COLOR_ACTIVE: String = "#7ee36d"
const COLOR_ADVANCED: String = "#f1c45d"
const COLOR_COMPLETE: String = "#ff73d1"
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

var current_wave: int = 1
var current_system_counts: Dictionary = {}
var current_attribute_counts: Dictionary = {}
var current_destiny_summary: Dictionary = {}
var current_encounter_summaries: Array = []
var battle_artifact_tooltip: PanelContainer
var battle_artifact_tooltip_label: RichTextLabel
var battle_artifact_tooltip_card: Control
var battle_artifact_tooltip_hide_request: int = 0

func _ready() -> void:
	# The full-screen root must allow mouse traversal so the battle artifact cards
	# can receive hover events. PASS keeps gameplay input propagation intact.
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	artifact_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	artifact_bar.get_node("ArtifactMargin").mouse_filter = Control.MOUSE_FILTER_PASS
	artifact_slots.mouse_filter = Control.MOUSE_FILTER_PASS
	_create_battle_artifact_tooltip()
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_styles()
	_apply_responsive_layout()
	set_synergies({}, {})

func _on_viewport_size_changed() -> void:
	if is_node_ready():
		_apply_responsive_layout()

func set_hp(current_hp: int, maximum_hp: int) -> void:
	var safe_maximum := maxi(1, maximum_hp)
	hp_bar.max_value = safe_maximum
	hp_bar.value = clampi(current_hp, 0, safe_maximum)
	hp_label.text = "%d / %d" % [maxi(0, current_hp), safe_maximum]
	var is_low_health := float(current_hp) / float(safe_maximum) <= 0.30
	hp_label.text = ("▲ " if is_low_health else "") + hp_label.text
	hp_label.add_theme_color_override("font_color", UITokens.VERMILION_500 if is_low_health else UITokens.TEXT_LIGHT)

func set_shield(current_shield: float, maximum_shield: float) -> void:
	var safe_maximum := maxf(0.0, maximum_shield)
	var safe_current := clampf(current_shield, 0.0, safe_maximum) if safe_maximum > 0.0 else 0.0
	shield_row.visible = safe_maximum > 0.0 or safe_current > 0.0
	shield_bar.max_value = maxf(1.0, safe_maximum)
	shield_bar.value = safe_current
	shield_label.text = "%d / %d" % [ceili(safe_current), ceili(safe_maximum)]

func set_spirit_stones(amount: int) -> void:
	stone_label.text = "◆ 灵石 %d" % amount

func set_wave_status(wave: int, _status: String) -> void:
	current_wave = maxi(1, wave)
	set_wave_info(current_wave, 0.0, 0)

func set_wave_info(wave: int, remaining_seconds: float, remaining_enemies: int) -> void:
	current_wave = maxi(1, wave)
	wave_label.text = "第 %d 波" % current_wave
	timer_label.text = "剩余 %s" % _format_time(remaining_seconds)
	enemy_label.text = "敌 %d" % maxi(0, remaining_enemies)

func set_synergies(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	current_system_counts = system_counts.duplicate(true)
	current_attribute_counts = attribute_counts.duplicate(true)
	var lines: Array[String] = ["[b][color=#f3e8ce]构筑状态[/color][/b]"]
	var entries := _relevant_synergy_entries(system_counts, attribute_counts)
	if entries.is_empty():
		lines.append("[color=#8b9696]◇ 羁绊尚未成形[/color]")
	else:
		for entry in entries:
			lines.append(_format_compact_synergy(entry))
	synergy_label.text = "\n".join(lines)
	synergy_label.tooltip_text = ""
	synergy_panel.visible = true

func set_run_modifiers(destiny_summary: Dictionary, encounter_summaries: Array) -> void:
	current_destiny_summary = destiny_summary.duplicate(true)
	current_encounter_summaries = encounter_summaries.duplicate(true)
	set_synergies(current_system_counts, current_attribute_counts)

func _relevant_synergy_entries(system_counts: Dictionary, attribute_counts: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for tag in SYSTEM_TAGS:
		entries.append(_make_synergy_entry(tag, int(system_counts.get(tag, 0)), SYSTEM_THRESHOLDS.get(tag, [2]), true))
	for tag in ATTRIBUTE_TAGS:
		entries.append(_make_synergy_entry(tag, int(attribute_counts.get(tag, 0)), ATTRIBUTE_THRESHOLDS.get(tag, [2]), false))
	entries = entries.filter(func(entry: Dictionary) -> bool:
		return int(entry["tier"]) > 0 or (int(entry["count"]) > 0 and int(entry["distance"]) <= 1)
	)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["tier"]) != int(b["tier"]):
			return int(a["tier"]) > int(b["tier"])
		if int(a["distance"]) != int(b["distance"]):
			return int(a["distance"]) < int(b["distance"])
		return int(a["count"]) > int(b["count"])
	)
	if entries.size() > 4:
		entries.resize(4)
	return entries

func _make_synergy_entry(tag: String, count: int, thresholds: Array, is_system: bool) -> Dictionary:
	var target := _next_synergy_target(count, thresholds)
	return {
		"tag": tag,
		"count": count,
		"target": target,
		"tier": _synergy_tier(count, thresholds),
		"max_tier": thresholds.size(),
		"distance": maxi(0, target - count),
		"thresholds": thresholds,
		"is_system": is_system,
	}

func _format_compact_synergy(entry: Dictionary) -> String:
	var tier := int(entry["tier"])
	var distance := int(entry["distance"])
	var marker := "◆" if tier > 0 else "◇"
	var state := "已激活" if tier > 0 else "差 %d" % distance
	var color := COLOR_ACTIVE if tier == 1 else COLOR_ADVANCED if tier > 1 else COLOR_CLOSE
	if tier >= int(entry["max_tier"]):
		color = COLOR_COMPLETE
	var tag := str(entry["tag"])
	var hint := _synergy_hint_text(tag, int(entry["count"]), entry["thresholds"])
	return "[color=%s][hint=%s]%s %s  %d/%d  %s[/hint][/color]" % [
		color,
		_bbcode_hint(hint),
		marker,
		tag,
		mini(int(entry["count"]), int(entry["target"])),
		int(entry["target"]),
		state,
	]

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

func set_equipped_artifacts(battle_slots: Array, artifact_instances: Array = []) -> void:
	if not is_node_ready():
		return
	_hide_battle_artifact_tooltip()
	for child in artifact_slots.get_children():
		child.queue_free()
	var instance_index: int = 0
	var visible_count: int = 0
	for raw_stack in battle_slots:
		var stack: ArtifactStack = raw_stack as ArtifactStack
		if stack == null or stack.artifact_data == null:
			continue
		var instance: ArtifactInstance
		if instance_index < artifact_instances.size():
			instance = artifact_instances[instance_index] as ArtifactInstance
		instance_index += 1
		artifact_slots.add_child(_make_artifact_slot(stack, instance))
		visible_count += 1
	artifact_bar.visible = visible_count > 0
	_apply_responsive_layout()

func _make_artifact_slot(stack: ArtifactStack, instance: ArtifactInstance) -> Control:
	var panel := Button.new()
	panel.text = ""
	panel.custom_minimum_size = Vector2(104, 72)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.focus_mode = Control.FOCUS_ALL
	panel.tooltip_text = ""
	panel.mouse_entered.connect(_request_show_battle_artifact_tooltip.bind(stack, panel))
	panel.mouse_exited.connect(_request_hide_battle_artifact_tooltip.bind(panel))
	panel.focus_entered.connect(_request_show_battle_artifact_tooltip.bind(stack, panel))
	panel.focus_exited.connect(_request_hide_battle_artifact_tooltip.bind(panel))
	var card_style := UITokens.style(Color(0.06, 0.09, 0.10, 0.86), _tier_border_color(stack.artifact_data.tier), 2, UITokens.RADIUS_CARD, 6)
	panel.add_theme_stylebox_override("normal", card_style)
	panel.add_theme_stylebox_override("hover", UITokens.style(Color(0.10, 0.15, 0.16, 0.94), UITokens.PAPER_200, 2, UITokens.RADIUS_CARD, 6))
	panel.add_theme_stylebox_override("focus", UITokens.focus_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)

	var box: VBoxContainer = VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_theme_constant_override("separation", 5)
	box.add_child(top_row)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = stack.artifact_data.icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.custom_minimum_size = Vector2(30, 30)
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(icon_rect)

	var text_box: VBoxContainer = VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	top_row.add_child(text_box)

	var name_label: Label = Label.new()
	name_label.text = stack.artifact_data.display_name
	name_label.clip_text = true
	name_label.add_theme_font_size_override("font_size", UITokens.FONT_CAPTION)
	name_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.76))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var star_label: Label = Label.new()
	star_label.text = stack.get_star_text()
	star_label.clip_text = true
	star_label.add_theme_font_size_override("font_size", UITokens.FONT_CAPTION)
	star_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.25))
	star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(star_label)

	var cooldown_bar: ProgressBar = ProgressBar.new()
	cooldown_bar.custom_minimum_size = Vector2(0, 5)
	cooldown_bar.show_percentage = false
	cooldown_bar.min_value = 0.0
	cooldown_bar.max_value = 1.0
	cooldown_bar.value = _cooldown_ready_ratio(instance)
	cooldown_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_bar.add_theme_stylebox_override("background", _make_panel_style(Color(0.02, 0.025, 0.03, 0.75), Color(0, 0, 0, 0), 0, 2))
	cooldown_bar.add_theme_stylebox_override("fill", _make_panel_style(Color(0.38, 0.80, 1.0, 0.78), Color(0, 0, 0, 0), 0, 2))
	box.add_child(cooldown_bar)

	if cooldown_bar.value < 1.0:
		icon_rect.modulate = Color(0.48, 0.52, 0.56, 0.86)
	return panel

func _create_battle_artifact_tooltip() -> void:
	battle_artifact_tooltip = PanelContainer.new()
	battle_artifact_tooltip.name = "BattleArtifactTooltip"
	battle_artifact_tooltip.visible = false
	battle_artifact_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_artifact_tooltip.z_index = 320
	battle_artifact_tooltip.anchor_left = 0.5
	battle_artifact_tooltip.anchor_top = 1.0
	battle_artifact_tooltip.anchor_right = 0.5
	battle_artifact_tooltip.anchor_bottom = 1.0
	battle_artifact_tooltip.offset_left = -220.0
	battle_artifact_tooltip.offset_top = -310.0
	battle_artifact_tooltip.offset_right = 220.0
	battle_artifact_tooltip.offset_bottom = -112.0
	battle_artifact_tooltip.add_theme_stylebox_override("panel", UITokens.style(UITokens.PAPER_100, UITokens.INK_950, 2, UITokens.RADIUS_CARD, UITokens.SPACING_LG))
	root.add_child(battle_artifact_tooltip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_artifact_tooltip.add_child(margin)

	battle_artifact_tooltip_label = RichTextLabel.new()
	battle_artifact_tooltip_label.bbcode_enabled = false
	battle_artifact_tooltip_label.fit_content = false
	battle_artifact_tooltip_label.scroll_active = true
	battle_artifact_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	battle_artifact_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_artifact_tooltip_label.add_theme_font_size_override("normal_font_size", UITokens.FONT_BODY)
	battle_artifact_tooltip_label.add_theme_color_override("default_color", UITokens.TEXT_DARK)
	margin.add_child(battle_artifact_tooltip_label)

func _request_show_battle_artifact_tooltip(stack: ArtifactStack, card: Control) -> void:
	if stack == null or stack.artifact_data == null or battle_artifact_tooltip == null:
		return
	battle_artifact_tooltip_hide_request += 1
	var request_id := battle_artifact_tooltip_hide_request
	await get_tree().create_timer(UITokens.TOOLTIP_DELAY).timeout
	if request_id != battle_artifact_tooltip_hide_request or not is_instance_valid(card):
		return
	var is_hovered := card.get_global_rect().has_point(get_viewport().get_mouse_position())
	if not is_hovered and not card.has_focus():
		return
	battle_artifact_tooltip_label.text = stack.get_combat_tooltip()
	battle_artifact_tooltip.visible = true
	battle_artifact_tooltip_card = card

func _request_hide_battle_artifact_tooltip(card: Control) -> void:
	battle_artifact_tooltip_hide_request += 1
	var request_id := battle_artifact_tooltip_hide_request
	await get_tree().create_timer(UITokens.TOOLTIP_HIDE_GRACE).timeout
	if request_id != battle_artifact_tooltip_hide_request:
		return
	if is_instance_valid(card):
		if card.has_focus() or card.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return
	_hide_battle_artifact_tooltip()

func _hide_battle_artifact_tooltip() -> void:
	if battle_artifact_tooltip != null:
		battle_artifact_tooltip.visible = false
	battle_artifact_tooltip_card = null

func _cooldown_ready_ratio(instance: ArtifactInstance) -> float:
	if instance == null or instance.data == null:
		return 1.0
	if instance.data.attack_template in ["orbit", "formation", "summon"]:
		return 1.0
	var cooldown: float = maxf(0.05, instance.data.cooldown)
	return clampf(1.0 - maxf(0.0, instance.cooldown_remaining) / cooldown, 0.0, 1.0)

func _format_synergy_line(tag: String, count: int, thresholds: Array) -> String:
	var target: int = _next_synergy_target(count, thresholds)
	var tier: int = _synergy_tier(count, thresholds)
	var color: String = _synergy_color(count, target, tier, thresholds.size())
	return "[color=%s][hint=%s]%s  %d/%d[/hint][/color]" % [color, _synergy_hint_text(tag, count, thresholds), tag, mini(count, target), target]

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

func _synergy_color(count: int, target: int, tier: int, max_tier: int) -> String:
	if tier >= max_tier:
		return COLOR_COMPLETE
	if tier >= 2:
		return COLOR_ADVANCED
	if tier >= 1:
		return COLOR_ACTIVE
	if count > 0 and count >= target - 1:
		return COLOR_CLOSE
	return COLOR_INACTIVE

func _format_time(seconds: float) -> String:
	var total: int = int(floor(absf(seconds)))
	var prefix: String = "+" if seconds < 0.0 else ""
	return "%s%02d:%02d" % [prefix, int(total / 60), total % 60]

func _apply_styles() -> void:
	resource_panel.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.88), UITokens.INK_800, 1))
	wave_panel.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.88), UITokens.AMBER_500.darkened(0.42), 1))
	synergy_panel.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.84), UITokens.INK_800, 1))
	artifact_bar.add_theme_stylebox_override("panel", UITokens.style(Color(UITokens.INK_900, 0.86), UITokens.INK_800, 1))

	hp_bar.add_theme_stylebox_override("fill", UITokens.style(UITokens.VERMILION_500, Color.TRANSPARENT, 0, UITokens.RADIUS_TAG, 0))
	shield_bar.add_theme_stylebox_override("fill", UITokens.style(UITokens.PLAYER_CYAN, Color.TRANSPARENT, 0, UITokens.RADIUS_TAG, 0))
	hp_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY_SM)
	shield_label.add_theme_font_size_override("font_size", UITokens.FONT_CAPTION)
	stone_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY_SM)
	stone_label.add_theme_color_override("font_color", UITokens.AMBER_500)
	wave_label.add_theme_font_size_override("font_size", UITokens.FONT_BODY_SM)
	timer_label.add_theme_font_size_override("font_size", UITokens.FONT_HEADING)
	enemy_label.add_theme_font_size_override("font_size", UITokens.FONT_CAPTION)
	wave_label.add_theme_color_override("font_color", UITokens.PAPER_200)
	timer_label.add_theme_color_override("font_color", UITokens.TEXT_LIGHT)
	enemy_label.add_theme_color_override("font_color", UITokens.PAPER_200)
	synergy_label.add_theme_font_size_override("normal_font_size", UITokens.FONT_BODY_SM)
	synergy_label.add_theme_font_size_override("bold_font_size", UITokens.FONT_BODY)
	synergy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	synergy_label.add_theme_constant_override("line_separation", UITokens.SPACING_XS)
	for label in [hp_label, shield_label, stone_label, wave_label, timer_label, enemy_label]:
		UITokens.apply_dynamic_text_readability(label)

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = safe_area.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var synergy_width: float = clampf(viewport_size.x * 0.22, 220.0, 280.0)
	synergy_panel.offset_left = -synergy_width
	synergy_panel.offset_right = 0.0
	synergy_panel.offset_top = 76.0
	synergy_panel.offset_bottom = minf(232.0, viewport_size.y * 0.38)

	var bar_height: float = minf(96.0, viewport_size.y * 0.15)
	var bar_width: float = minf(viewport_size.x * 0.78, 840.0)
	artifact_bar.offset_left = -bar_width * 0.5
	artifact_bar.offset_right = bar_width * 0.5
	artifact_bar.offset_top = -bar_height
	artifact_bar.offset_bottom = 0.0

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return UITokens.style(bg_color, border_color, border_width, radius, 0)

func _tier_border_color(tier: String) -> Color:
	return UITokens.rarity_color(tier)
