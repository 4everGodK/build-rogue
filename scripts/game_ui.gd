extends CanvasLayer
class_name GameUI

@onready var root: Control = $Root
@onready var resource_panel: PanelContainer = $Root/ResourcePanel
@onready var hp_label: Label = $Root/ResourcePanel/ResourceMargin/ResourceVBox/HpLabel
@onready var stone_label: Label = $Root/ResourcePanel/ResourceMargin/ResourceVBox/StoneLabel
@onready var wave_panel: PanelContainer = $Root/WavePanel
@onready var wave_label: Label = $Root/WavePanel/WaveMargin/WaveHBox/WaveLabel
@onready var timer_label: Label = $Root/WavePanel/WaveMargin/WaveHBox/TimerLabel
@onready var enemy_label: Label = $Root/WavePanel/WaveMargin/WaveHBox/EnemyLabel
@onready var synergy_panel: PanelContainer = $Root/SynergyPanel
@onready var synergy_label: RichTextLabel = $Root/SynergyPanel/SynergyMargin/SynergyLabel
@onready var artifact_bar: PanelContainer = $Root/ArtifactBar
@onready var artifact_slots: HBoxContainer = $Root/ArtifactBar/ArtifactMargin/ArtifactSlots

const SYSTEM_TAGS: Array[String] = ["剑修", "法修", "体修", "阵法", "召唤", "魔修"]
const ATTRIBUTE_TAGS: Array[String] = ["火", "风", "毒", "雷", "水", "土", "金", "木", "暗"]
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
	"雷": [2],
	"水": [2],
	"土": [2],
	"金": [2],
	"木": [2],
	"暗": [2],
}

const COLOR_INACTIVE: String = "#858992"
const COLOR_CLOSE: String = "#79b8ff"
const COLOR_ACTIVE: String = "#7ee36d"
const COLOR_ADVANCED: String = "#f1c45d"
const COLOR_COMPLETE: String = "#ff73d1"
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
	"雷": "属性羁绊预留：雷属性 Build 方向",
	"水": "属性羁绊预留：水属性 Build 方向",
	"土": "属性羁绊预留：土属性 Build 方向",
	"金": "属性羁绊预留：金属性 Build 方向",
	"木": "属性羁绊预留：木属性 Build 方向",
	"暗": "属性羁绊预留：暗属性 Build 方向",
}

var current_wave: int = 1

func _ready() -> void:
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_apply_styles()
	_apply_responsive_layout()
	set_synergies({}, {})

func _on_viewport_size_changed() -> void:
	if is_node_ready():
		_apply_responsive_layout()

func set_hp(current_hp: int, maximum_hp: int) -> void:
	hp_label.text = "生命：%d / %d" % [current_hp, maximum_hp]

func set_shield(_current_shield: float, _maximum_shield: float) -> void:
	pass

func set_spirit_stones(amount: int) -> void:
	stone_label.text = "◆ %d" % amount

func set_wave_status(wave: int, _status: String) -> void:
	current_wave = maxi(1, wave)
	set_wave_info(current_wave, 0.0, 0)

func set_wave_info(wave: int, elapsed_seconds: float, remaining_enemies: int) -> void:
	current_wave = maxi(1, wave)
	wave_label.text = "第 %d 波" % current_wave
	timer_label.text = _format_time(elapsed_seconds)
	enemy_label.text = "剩余敌人：%d" % maxi(0, remaining_enemies)

func set_synergies(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	var lines: Array[String] = ["[b][color=#f2d27b]体系[/color][/b]"]
	for tag in _sorted_synergy_tags(SYSTEM_TAGS, system_counts, SYSTEM_THRESHOLDS):
		lines.append(_format_synergy_line(tag, int(system_counts.get(tag, 0)), SYSTEM_THRESHOLDS.get(tag, [2])))
	lines.append("")
	lines.append("[b][color=#f2d27b]属性[/color][/b]")
	for tag in _sorted_synergy_tags(ATTRIBUTE_TAGS, attribute_counts, ATTRIBUTE_THRESHOLDS):
		lines.append(_format_synergy_line(tag, int(attribute_counts.get(tag, 0)), ATTRIBUTE_THRESHOLDS.get(tag, [2])))
	synergy_label.text = "\n".join(lines)
	synergy_label.tooltip_text = ""

func set_equipped_artifacts(battle_slots: Array, artifact_instances: Array = []) -> void:
	if not is_node_ready():
		return
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
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(92, 68)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.06, 0.07, 0.09, 0.74), Color(0.36, 0.42, 0.48, 0.78), 1, 5))

	var margin: MarginContainer = MarginContainer.new()
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
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.90, 0.88, 0.76))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	var star_label: Label = Label.new()
	star_label.text = stack.get_star_text()
	star_label.clip_text = true
	star_label.add_theme_font_size_override("font_size", 11)
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
	var total: int = maxi(0, int(floor(seconds)))
	return "%02d:%02d" % [int(total / 60), total % 60]

func _apply_styles() -> void:
	resource_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.045, 0.055, 0.72), Color(0.30, 0.36, 0.40, 0.58), 1, 6))
	wave_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.045, 0.055, 0.72), Color(0.42, 0.36, 0.20, 0.62), 1, 6))
	synergy_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.045, 0.055, 0.64), Color(0.28, 0.34, 0.38, 0.55), 1, 6))
	artifact_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.035, 0.045, 0.055, 0.68), Color(0.30, 0.36, 0.40, 0.58), 1, 6))

	hp_label.add_theme_font_size_override("font_size", 16)
	hp_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.74))
	stone_label.add_theme_font_size_override("font_size", 15)
	stone_label.add_theme_color_override("font_color", Color(0.50, 1.0, 0.62))
	wave_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_font_size_override("font_size", 16)
	enemy_label.add_theme_font_size_override("font_size", 14)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.55))
	timer_label.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0))
	enemy_label.add_theme_color_override("font_color", Color(0.84, 0.88, 0.92))
	synergy_label.add_theme_font_size_override("normal_font_size", 12)
	synergy_label.add_theme_font_size_override("bold_font_size", 13)
	synergy_label.mouse_filter = Control.MOUSE_FILTER_STOP
	synergy_label.add_theme_constant_override("line_separation", 4)

func _apply_responsive_layout() -> void:
	var viewport_size: Vector2 = root.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var synergy_width: float = clampf(viewport_size.x * 0.145, 154.0, 190.0)
	synergy_panel.offset_left = 12.0
	synergy_panel.offset_right = 12.0 + synergy_width
	synergy_panel.offset_top = maxf(96.0, viewport_size.y * 0.16)
	synergy_panel.offset_bottom = synergy_panel.offset_top + minf(330.0, viewport_size.y * 0.46)

	var bar_height: float = minf(88.0, viewport_size.y * 0.13)
	var bar_width: float = minf(viewport_size.x * 0.70, 760.0)
	artifact_bar.offset_left = -bar_width * 0.5
	artifact_bar.offset_right = bar_width * 0.5
	artifact_bar.offset_top = -bar_height - 12.0
	artifact_bar.offset_bottom = -12.0

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
