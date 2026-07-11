extends Node
class_name GameManager

@export var player_path: NodePath
@export var attack_container_path: NodePath
@export var wave_manager_path: NodePath
@export var economy_manager_path: NodePath
@export var cultivation_manager_path: NodePath
@export var inventory_path: NodePath
@export var synergy_manager_path: NodePath
@export var shop_manager_path: NodePath
@export var destiny_manager_path: NodePath
@export var encounter_manager_path: NodePath
@export var combat_room_timer_path: NodePath
@export var ui_path: NodePath
@export var shop_path: NodePath
@export var destiny_panel_path: NodePath
@export var encounter_panel_path: NodePath
@export var result_panel_path: NodePath
@export var run_summary_path: NodePath
@export var starting_spirit_stones: int = 20
@export var room_duration: float = 30.0
@export var debug_test_room: bool = false
@export var debug_shop_toggle_key: int = KEY_B
@export var show_combat_stats_panel: bool = true

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"
const WAVE_1_ROOM_DURATION: float = 30.0
const WAVE_2_ROOM_DURATION: float = 40.0
const WAVE_3_ROOM_DURATION: float = 50.0
const LATE_ROOM_DURATION: float = 60.0
const ENEMY_SPIRIT_STONE_DROP_MULTIPLIER: float = 0.0
const SPIRIT_GATHERING_COST: int = 100
const SPIRIT_GATHERING_RETURN: int = 110
const SPIRIT_GATHERING_MAX_LAYERS: int = 3
const ROOM_CLEAR_CULTIVATION: int = 20
const ROOM_CLEAR_SPIRIT_STONES_BY_RANGE: Array[Dictionary] = [
	{"min": 1, "max": 4, "reward": 60},
	{"min": 5, "max": 8, "reward": 70},
	{"min": 9, "max": 12, "reward": 80},
	{"min": 13, "max": 16, "reward": 90},
	{"min": 17, "max": 20, "reward": 100},
]
const BOSS_OVERTIME_BURN_MAX_HP_PER_SECOND: float = 0.05
const CombatStatsScript := preload("res://scripts/combat_stats.gd")
const BattleEnvironmentConfigScript := preload("res://data/battle_environment_config.gd")
const BattleHealingTrackerScript := preload("res://scripts/battle_healing_tracker.gd")
const BattleEnvironmentSpawnerScript := preload("res://scripts/battle_environment_spawner.gd")

var player: Player
var attack_container: Node2D
var wave_manager: WaveManager
var economy_manager: EconomyManager
var cultivation_manager: CultivationManager
var inventory: ArtifactInventory
var synergy_manager: SynergyManager
var shop_manager: ShopManager
var destiny_manager = null
var encounter_manager = null
var combat_room_timer: CombatRoomTimer
var game_ui: GameUI
var shop_panel: ShopPanel
var destiny_panel = null
var encounter_panel = null
var result_panel: ResultPanel
var run_summary: RunSummary
var in_shop: bool = false
var run_ended: bool = false
var wave_elapsed_time: float = 0.0
var room_kill_count: int = 0
var room_spirit_stones: int = 0
var artifact_hud_refresh_remaining: float = 0.0
var pending_encounter_wave: int = -1
var boss_overtime_burning: bool = false
var boss_overtime_burn_accumulator: float = 0.0
var enemy_spirit_stone_drop_accumulator: float = 0.0
var spirit_gathering_layers: int = 0
var pending_spirit_gathering_return: int = 0
var combat_stats = null
var combat_stats_overlay: CanvasLayer
var battle_healing_tracker = null
var battle_environment_spawner: Node

func _ready() -> void:
	call_deferred("_initialize")

func _process(delta: float) -> void:
	if player == null or wave_manager == null or game_ui == null:
		return
	if not in_shop and not run_ended and wave_manager.active:
		wave_elapsed_time += delta
	if boss_overtime_burning and not in_shop and not run_ended:
		_apply_boss_overtime_burn(delta)
	if encounter_manager != null and not in_shop and not run_ended and player.hp > 0:
		if encounter_manager.try_consume_low_hp_rescue(wave_manager.wave_number, player.get_hp_ratio()):
			player.grant_invincible(2.0)
			player.heal(float(player.max_hp) * 0.1)
	game_ui.set_wave_info(maxi(1, wave_manager.wave_number), _current_room_time_left(), wave_manager.alive_enemies)
	artifact_hud_refresh_remaining -= delta
	if artifact_hud_refresh_remaining <= 0.0:
		artifact_hud_refresh_remaining = 0.12
		_apply_destiny_runtime_modifiers()
		_update_battle_ui(true)

func _unhandled_input(event: InputEvent) -> void:
	if not debug_test_room or run_ended:
		return
	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == debug_shop_toggle_key:
		if in_shop:
			_close_debug_shop()
		else:
			_enter_shop(wave_manager.wave_number)

func _initialize() -> void:
	randomize()
	player = get_node(player_path)
	attack_container = get_node(attack_container_path)
	wave_manager = get_node(wave_manager_path)
	economy_manager = get_node(economy_manager_path)
	cultivation_manager = get_node(cultivation_manager_path)
	inventory = get_node(inventory_path)
	synergy_manager = get_node(synergy_manager_path)
	shop_manager = get_node(shop_manager_path)
	if not String(destiny_manager_path).is_empty():
		destiny_manager = get_node_or_null(destiny_manager_path)
	if not String(encounter_manager_path).is_empty():
		encounter_manager = get_node_or_null(encounter_manager_path)
	combat_room_timer = get_node(combat_room_timer_path)
	game_ui = get_node(ui_path)
	shop_panel = get_node(shop_path)
	if not String(destiny_panel_path).is_empty():
		destiny_panel = get_node_or_null(destiny_panel_path) as Control
	if not String(encounter_panel_path).is_empty():
		encounter_panel = get_node_or_null(encounter_panel_path) as Control
	result_panel = get_node(result_panel_path)
	run_summary = get_node(run_summary_path)

	run_summary.start_run()
	combat_stats = CombatStatsScript.new()
	combat_stats.enabled = show_combat_stats_panel
	player.set_combat_stats(combat_stats)
	synergy_manager.set_combat_stats(combat_stats)
	var plant_config: Dictionary = BattleEnvironmentConfigScript.healing_plant()
	battle_healing_tracker = BattleHealingTrackerScript.new()
	battle_healing_tracker.configure(plant_config)
	battle_environment_spawner = BattleEnvironmentSpawnerScript.new()
	add_child(battle_environment_spawner)
	battle_environment_spawner.configure(player, wave_manager.arena_size, plant_config, battle_healing_tracker)
	player.artifact_manager.configure(player, attack_container)
	player.artifact_manager.set_synergy_manager(synergy_manager)
	player.artifact_manager.set_destiny_manager(destiny_manager)
	player.artifact_manager.set_encounter_manager(encounter_manager)
	wave_manager.configure(player)
	shop_manager.configure(economy_manager, inventory, cultivation_manager, destiny_manager, encounter_manager)

	player.hp_changed.connect(game_ui.set_hp)
	player.shield_changed.connect(game_ui.set_shield)
	player.died.connect(_on_player_died)
	economy_manager.spirit_stones_changed.connect(_on_spirit_stones_changed)
	cultivation_manager.cultivation_changed.connect(_on_cultivation_changed)
	cultivation_manager.cultivation_message.connect(_show_shop_message)
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory.inventory_message.connect(_show_shop_message)
	synergy_manager.synergies_changed.connect(_on_synergies_changed)
	shop_manager.offers_changed.connect(_on_shop_offers_changed)
	shop_manager.shop_message.connect(_show_shop_message)
	shop_panel.buy_requested.connect(shop_manager.buy_offer)
	shop_panel.lock_requested.connect(shop_manager.toggle_offer_lock)
	shop_panel.reroll_requested.connect(shop_manager.reroll)
	shop_panel.breakthrough_requested.connect(_on_breakthrough_requested)
	shop_panel.spirit_gathering_requested.connect(_on_spirit_gathering_requested)
	shop_panel.continue_requested.connect(_on_shop_continue_requested)
	shop_panel.inventory_move_requested.connect(inventory.move_stack)
	shop_panel.sell_requested.connect(_on_sell_requested)
	if destiny_panel != null:
		destiny_panel.destiny_selected.connect(_on_destiny_selected)
	if encounter_panel != null:
		encounter_panel.encounter_selected.connect(_on_encounter_selected)
	result_panel.restart_requested.connect(_restart_run)
	result_panel.main_menu_requested.connect(_return_to_main_menu)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	wave_manager.boss_defeated.connect(_on_boss_defeated)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	combat_room_timer.room_finished.connect(_on_room_timer_finished)

	game_ui.set_hp(player.hp, player.max_hp)
	game_ui.set_shield(player.shield, player.shield_limit)
	economy_manager.reset(starting_spirit_stones)
	if debug_test_room:
		economy_manager.set_unlimited(true)
	if destiny_manager != null:
		destiny_manager.reset()
	if encounter_manager != null:
		encounter_manager.reset()
	cultivation_manager.reset()
	_on_inventory_changed()
	_refresh_run_modifier_display()
	game_ui.set_wave_status(1, "准备阶段")
	_update_battle_ui(true)
	if debug_test_room:
		_start_battle()
	elif destiny_manager != null and destiny_panel != null:
		_show_destiny_selection()
	else:
		_enter_shop(0)

func _start_battle() -> void:
	in_shop = false
	shop_panel.close_shop()
	synergy_manager.reset_battle_effects()
	_prepare_spirit_gathering_return()
	if destiny_manager != null:
		destiny_manager.begin_battle(economy_manager.spirit_stones)
	player.set_battle_paused(false)
	room_kill_count = 0
	room_spirit_stones = 0
	_stop_boss_overtime_burn()
	wave_manager.start_next_wave()
	_apply_destiny_runtime_modifiers()
	player.artifact_manager.refresh_persistent_artifacts()
	if debug_test_room:
		combat_room_timer.stop_room()
	else:
		combat_room_timer.start_room(_room_duration_for_wave(wave_manager.wave_number))
	_update_battle_ui(true)

func _room_duration_for_wave(wave_number: int) -> float:
	if wave_number == 1:
		return WAVE_1_ROOM_DURATION
	if wave_number == 2:
		return WAVE_2_ROOM_DURATION
	if wave_number == 3:
		return WAVE_3_ROOM_DURATION
	return LATE_ROOM_DURATION

func _current_room_time_left() -> float:
	if combat_room_timer == null or not combat_room_timer.active:
		return 0.0
	return combat_room_timer.time_left

func _enter_shop(cleared_wave: int) -> void:
	in_shop = true
	_stop_boss_overtime_burn()
	if battle_environment_spawner != null and battle_environment_spawner.has_method("end_wave"):
		battle_environment_spawner.call("end_wave")
	synergy_manager.reset_battle_effects()
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	combat_room_timer.stop_room()
	_clear_attack_nodes()
	_return_spirit_gathering()
	_apply_destiny_runtime_modifiers()
	shop_manager.set_shop_wave(cleared_wave)
	if destiny_manager != null:
		destiny_manager.begin_shop(economy_manager.spirit_stones)
	if encounter_manager != null:
		encounter_manager.begin_shop()
	if debug_test_room:
		shop_manager.generate_all_offers()
	else:
		shop_manager.generate_offers()
	_update_shop_cultivation()
	shop_panel.set_debug_catalog_mode(debug_test_room)
	shop_panel.set_reroll_cost(shop_manager.get_reroll_cost())
	_update_shop_spirit_gathering()
	shop_panel.open_shop(
		cleared_wave,
		shop_manager.get_offer_dictionaries(),
		economy_manager.spirit_stones,
		inventory.battle_slots,
		inventory.bag_slots,
		synergy_manager.system_counts,
		synergy_manager.attribute_counts
	)
	_refresh_run_modifier_display()
	shop_panel.set_message(_shop_status_text())

func _show_destiny_selection() -> void:
	player.set_battle_paused(true)
	shop_panel.close_shop()
	if destiny_panel != null and destiny_manager != null:
		destiny_panel.open_choices(destiny_manager.get_starting_choices(3))

func _on_destiny_selected(destiny_id: String) -> void:
	if destiny_manager == null or not destiny_manager.select_destiny(destiny_id):
		return
	if destiny_panel != null:
		destiny_panel.close_panel()
	economy_manager.add_spirit_stones(destiny_manager.get_starting_stones_bonus())
	player.set_destiny_max_hp_multiplier(destiny_manager.get_max_hp_multiplier())
	_apply_destiny_slot_modifier()
	_apply_destiny_enemy_modifier()
	_update_destiny_star3_hp_penalty()
	_apply_destiny_runtime_modifiers()
	_refresh_run_modifier_display()
	_enter_shop(0)
	_show_shop_message("已选择天命：%s" % destiny_manager.get_destiny_name())

func _show_encounter_selection(cleared_wave: int) -> void:
	in_shop = false
	player.set_battle_paused(true)
	shop_panel.close_shop()
	game_ui.set_wave_status(cleared_wave, "奇遇")
	if encounter_panel != null and encounter_manager != null:
		var choice_count: int = 3
		if destiny_manager != null:
			destiny_manager.begin_encounter()
			choice_count += destiny_manager.get_encounter_choice_bonus()
			if wave_manager != null and wave_manager.is_boss_wave(cleared_wave):
				choice_count += destiny_manager.get_boss_extra_encounter_options()
		var choices: Array[Dictionary] = encounter_manager.get_choices(choice_count)
		encounter_panel.open_choices(choices)
	else:
		_enter_shop(cleared_wave)

func _on_encounter_selected(encounter_id: String) -> void:
	if encounter_manager == null:
		return
	var encounter: Dictionary = encounter_manager.select_encounter(encounter_id)
	if encounter.is_empty():
		return
	if encounter_panel != null:
		encounter_panel.close_panel()
	if bool(encounter.get("all_in_all_encounters", false)):
		_spend_all_for_all_in_encounter()
		for extra_encounter in encounter_manager.get_all_other_encounters(str(encounter.get("id", ""))):
			encounter_manager.record_selected_encounter(extra_encounter)
			encounter_manager.apply_encounter_effects(extra_encounter)
			_apply_encounter_immediate_effects(extra_encounter)
	_apply_encounter_immediate_effects(encounter)
	_refresh_run_modifier_display()
	var cleared_wave: int = pending_encounter_wave
	pending_encounter_wave = -1
	_enter_shop(cleared_wave)
	_show_shop_message("已选择奇遇：%s" % str(encounter.get("name", "奇遇")))


func _spend_all_for_all_in_encounter() -> void:
	if economy_manager != null and economy_manager.spirit_stones > 0:
		economy_manager.spend_spirit_stones(economy_manager.spirit_stones)
	spirit_gathering_layers = 0
	pending_spirit_gathering_return = 0
	_update_shop_spirit_gathering()

func _apply_encounter_immediate_effects(encounter: Dictionary) -> void:
	var synergy_tag: String = str(encounter.get("synergy_tag", ""))
	if not synergy_tag.is_empty():
		synergy_manager.add_synergy_bonus(synergy_tag, 1)
	if int(encounter.get("spirit_stones", 0)) > 0:
		economy_manager.add_spirit_stones(int(encounter["spirit_stones"]))
	if bool(encounter.get("random_star_up", false)):
		inventory.upgrade_random_artifact_star()
	if bool(encounter.get("reroll_higher_tier", false)):
		inventory.reroll_all_to_higher_tier()
	_on_inventory_changed()
	_apply_destiny_runtime_modifiers()

func _apply_destiny_runtime_modifiers() -> void:
	if player == null:
		return
	var cleared_waves: int = maxi(0, wave_manager.wave_number - 1) if wave_manager != null else 0
	var active_synergy_count: int = synergy_manager.get_active_synergy_count() if synergy_manager != null else 0
	var hp_ratio: float = player.get_hp_ratio()
	var multiplier: float = destiny_manager.get_damage_multiplier(cleared_waves, active_synergy_count, hp_ratio) if destiny_manager != null else 1.0
	if encounter_manager != null:
		multiplier *= encounter_manager.get_damage_multiplier(active_synergy_count, hp_ratio)
	player.set_run_damage_multiplier(multiplier)
	player.set_run_max_hp_multiplier(encounter_manager.get_max_hp_multiplier() if encounter_manager != null else 1.0)
	player.set_run_move_speed_multiplier(encounter_manager.get_move_speed_multiplier() if encounter_manager != null else 1.0)

func _apply_destiny_slot_modifier() -> void:
	if inventory == null or cultivation_manager == null:
		return
	var delta: int = destiny_manager.get_battle_slot_delta() if destiny_manager != null else 0
	inventory.set_battle_slot_count(cultivation_manager.get_battle_slot_count() + delta)

func _apply_destiny_enemy_modifier() -> void:
	if wave_manager == null:
		return
	var multiplier: float = destiny_manager.get_enemy_stat_multiplier() if destiny_manager != null else 1.0
	wave_manager.set_destiny_enemy_stat_multiplier(multiplier)

func _update_destiny_star3_hp_penalty() -> void:
	if inventory == null or player == null:
		return
	var star3_count: int = 0
	for raw_stack in inventory.battle_slots:
		var stack: ArtifactStack = raw_stack as ArtifactStack
		if stack != null and stack.star_level >= 3:
			star3_count += 1
	if destiny_manager != null:
		destiny_manager.set_star3_battle_count(star3_count)
	var penalty: int = destiny_manager.get_star3_max_hp_penalty() if destiny_manager != null else 0
	if encounter_manager != null:
		penalty += encounter_manager.get_star3_max_hp_penalty(star3_count)
	player.set_destiny_max_hp_flat_penalty(penalty)

func _apply_player_current_hp_loss(ratio: float) -> void:
	if player == null or ratio <= 0.0:
		return
	var amount: int = int(ceil(float(player.hp) * clampf(ratio, 0.0, 1.0)))
	if amount > 0:
		player.take_environment_damage(amount)

func _close_debug_shop() -> void:
	in_shop = false
	shop_panel.close_shop()
	player.set_battle_paused(false)
	wave_manager.pause_wave(false)
	if battle_environment_spawner != null and battle_environment_spawner.has_method("set_paused"):
		battle_environment_spawner.call("set_paused", false)

func _on_shop_continue_requested() -> void:
	if run_ended:
		return
	if debug_test_room:
		_close_debug_shop()
		return
	_start_battle()

func _on_wave_started(wave_number: int) -> void:
	wave_elapsed_time = 0.0
	_stop_boss_overtime_burn()
	if combat_stats != null:
		combat_stats.enabled = show_combat_stats_panel
		combat_stats.begin_wave(wave_number)
	if battle_healing_tracker != null:
		battle_healing_tracker.begin_wave()
	if battle_environment_spawner != null and battle_environment_spawner.has_method("begin_wave"):
		battle_environment_spawner.call("begin_wave")
	if destiny_manager != null and wave_manager.is_boss_wave(wave_number):
		_apply_player_current_hp_loss(destiny_manager.get_boss_start_current_hp_loss_ratio())
		if run_ended:
			return
	game_ui.set_wave_status(wave_number, "战斗中")
	_update_battle_ui(true)

func _on_wave_cleared(wave_number: int) -> void:
	if destiny_manager != null:
		_apply_player_current_hp_loss(destiny_manager.get_post_wave_current_hp_loss_ratio())
		if run_ended:
			return
	_award_room_clear_economy(wave_number)
	if battle_environment_spawner != null and battle_environment_spawner.has_method("end_wave"):
		battle_environment_spawner.call("end_wave")
	game_ui.set_wave_status(wave_number, "商店阶段")
	_update_battle_ui(true)
	if _should_show_combat_stats():
		_show_combat_stats_panel(wave_number)
		return
	_continue_after_combat_stats(wave_number)

func _continue_after_combat_stats(wave_number: int) -> void:
	if pending_encounter_wave == wave_number and encounter_manager != null and encounter_panel != null:
		_show_encounter_selection(wave_number)
		return
	_enter_shop(wave_number)

func _should_show_combat_stats() -> bool:
	return show_combat_stats_panel and combat_stats != null and combat_stats.enabled and not run_ended

func _show_combat_stats_panel(cleared_wave: int) -> void:
	_close_combat_stats_panel()
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	if battle_environment_spawner != null and battle_environment_spawner.has_method("set_paused"):
		battle_environment_spawner.call("set_paused", true)
	combat_room_timer.stop_room()
	game_ui.set_wave_status(cleared_wave, "战斗统计")

	combat_stats_overlay = CanvasLayer.new()
	combat_stats_overlay.name = "CombatStatsOverlay"
	combat_stats_overlay.layer = 80
	add_child(combat_stats_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	combat_stats_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -360.0
	panel.offset_top = -250.0
	panel.offset_right = 360.0
	panel.offset_bottom = 250.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.07, 0.06, 0.96)
	panel_style.border_color = Color(0.95, 0.72, 0.32, 0.9)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	combat_stats_overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title := Label.new()
	title.text = "第%d关战斗统计" % cleared_wave
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)

	var report := RichTextLabel.new()
	report.bbcode_enabled = true
	report.fit_content = false
	report.scroll_active = true
	report.custom_minimum_size = Vector2(0.0, 350.0)
	report.text = _build_combat_stats_text()
	root.add_child(report)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(button_row)

	var continue_button := Button.new()
	continue_button.text = "继续"
	continue_button.custom_minimum_size = Vector2(150.0, 42.0)
	continue_button.pressed.connect(func() -> void:
		_close_combat_stats_panel()
		_continue_after_combat_stats(cleared_wave)
	)
	button_row.add_child(continue_button)

func _close_combat_stats_panel() -> void:
	if is_instance_valid(combat_stats_overlay):
		combat_stats_overlay.queue_free()
	combat_stats_overlay = null

func _build_combat_stats_text() -> String:
	if combat_stats == null:
		return "暂无统计。"
	var lines: Array[String] = []
	lines.append("[b]法宝[/b]")
	var artifact_rows: Array = combat_stats.artifact_summary()
	if artifact_rows.is_empty():
		lines.append("  暂无法宝伤害或回复记录。")
	else:
		for row in artifact_rows:
			lines.append("  %s    伤害：%s    回复/护盾：%s" % [
				str(row.get("name", "未知法宝")),
				_format_stat_number(float(row.get("damage", 0.0))),
				_format_stat_number(float(row.get("healing", 0.0))),
			])
	lines.append("")
	lines.append("[b]羁绊[/b]")
	var synergy_rows: Array = combat_stats.synergy_summary()
	if synergy_rows.is_empty():
		lines.append("  本关暂无可统计的羁绊额外效果。")
	else:
		for row in synergy_rows:
			var parts: Array[String] = [str(row.get("name", "未知羁绊"))]
			var damage: float = float(row.get("damage", 0.0))
			var healing: float = float(row.get("healing", 0.0))
			var count: int = int(row.get("count", 0))
			if damage > 0.0:
				parts.append("额外伤害：%s" % _format_stat_number(damage))
			if healing > 0.0:
				parts.append("回复/护盾：%s" % _format_stat_number(healing))
			if count > 0:
				parts.append("触发：%d次" % count)
			lines.append("  " + "    ".join(parts))
	return "\n".join(lines)

func _format_stat_number(value: float) -> String:
	if absf(value - round(value)) < 0.05:
		return str(int(round(value)))
	return "%.1f" % value

func _on_room_timer_finished() -> void:
	if run_ended or in_shop:
		return
	if wave_manager.is_boss_wave(wave_manager.wave_number) and wave_manager.has_alive_boss():
		_start_boss_overtime_burn()
		game_ui.set_wave_status(wave_manager.wave_number, "击败Boss")
		return
	_finish_room_after_timer()

func _on_inventory_changed() -> void:
	synergy_manager.recalculate(inventory.battle_slots)
	_update_destiny_star3_hp_penalty()
	player.artifact_manager.sync_from_battle_slots(inventory.battle_slots)
	game_ui.set_equipped_artifacts(inventory.battle_slots, player.artifact_manager.artifacts)
	_apply_destiny_runtime_modifiers()
	if in_shop:
		shop_panel.set_inventory(inventory.battle_slots, inventory.bag_slots)

func _on_synergies_changed(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	game_ui.set_synergies(system_counts, attribute_counts)
	_refresh_run_modifier_display()
	_apply_destiny_runtime_modifiers()
	player.set_body_synergy(
		float(synergy_manager.get_effect_value("body_max_hp_multiplier", 1.0)),
		float(synergy_manager.get_effect_value("body_size_multiplier", 1.0))
	)
	if in_shop:
		shop_panel.set_synergies(system_counts, attribute_counts)
		_refresh_run_modifier_display()
		shop_panel.set_message(_shop_status_text())

func _refresh_run_modifier_display() -> void:
	var destiny_summary: Dictionary = destiny_manager.get_selected_summary() if destiny_manager != null and destiny_manager.has_method("get_selected_summary") else {}
	var encounter_summaries: Array = encounter_manager.get_selected_summaries() if encounter_manager != null and encounter_manager.has_method("get_selected_summaries") else []
	if game_ui != null and game_ui.has_method("set_run_modifiers"):
		game_ui.set_run_modifiers(destiny_summary, encounter_summaries)
	if shop_panel != null and shop_panel.has_method("set_run_modifiers"):
		shop_panel.set_run_modifiers(destiny_summary, encounter_summaries)

func _on_shop_offers_changed(offers: Array) -> void:
	if in_shop and shop_panel.visible:
		shop_panel.set_reroll_cost(shop_manager.get_reroll_cost())
		shop_panel.set_offers(offers)
		shop_panel.set_economy(economy_manager.spirit_stones)

func _on_spirit_stones_changed(amount: int) -> void:
	game_ui.set_spirit_stones(amount)
	if in_shop:
		shop_panel.set_economy(amount)
		_update_shop_spirit_gathering()

func _show_shop_message(message: String) -> void:
	if in_shop:
		shop_panel.set_message(message)

func _shop_status_text() -> String:
	var prefix: String = ""
	if wave_manager != null and wave_manager.wave_number > 0 and not debug_test_room:
		prefix = "本房间击杀 %d，获得灵石 %d。 " % [room_kill_count, room_spirit_stones]
	return prefix + _synergy_effect_text()

func _on_breakthrough_requested() -> void:
	var gain_multiplier: float = destiny_manager.get_cultivation_gain_multiplier() if destiny_manager != null else 1.0
	var life_cost: int = destiny_manager.get_cultivation_life_cost() if destiny_manager != null else 0
	var stones_before: int = economy_manager.spirit_stones
	cultivation_manager.try_breakthrough(economy_manager, gain_multiplier, player, life_cost)
	if destiny_manager != null:
		destiny_manager.record_shop_spend(maxi(0, stones_before - economy_manager.spirit_stones))
	_update_shop_cultivation()

func _on_spirit_gathering_requested() -> void:
	if economy_manager == null:
		return
	if encounter_manager != null and encounter_manager.is_spirit_gathering_disabled():
		_show_shop_message("当前奇遇效果：无法聚灵")
		return
	if spirit_gathering_layers >= SPIRIT_GATHERING_MAX_LAYERS:
		_show_shop_message("聚灵已达上限")
		return
	if not economy_manager.spend_spirit_stones(SPIRIT_GATHERING_COST):
		_show_shop_message("灵石不足")
		return
	spirit_gathering_layers += 1
	if destiny_manager != null:
		destiny_manager.record_shop_spend(SPIRIT_GATHERING_COST)
	_update_shop_spirit_gathering()
	_show_shop_message("聚灵成功：下回合返还%d灵石" % SPIRIT_GATHERING_RETURN)

func _prepare_spirit_gathering_return() -> void:
	if spirit_gathering_layers <= 0:
		return
	pending_spirit_gathering_return += spirit_gathering_layers * SPIRIT_GATHERING_RETURN
	spirit_gathering_layers = 0

func _return_spirit_gathering() -> void:
	if pending_spirit_gathering_return <= 0 or economy_manager == null:
		return
	var returned: int = pending_spirit_gathering_return
	pending_spirit_gathering_return = 0
	economy_manager.add_spirit_stones(returned)
	run_summary.record_spirit_stones(returned)
	room_spirit_stones += returned

func _update_shop_spirit_gathering() -> void:
	if shop_panel == null:
		return
	var disabled: bool = encounter_manager != null and encounter_manager.is_spirit_gathering_disabled()
	shop_panel.set_spirit_gathering(SPIRIT_GATHERING_COST, spirit_gathering_layers, SPIRIT_GATHERING_MAX_LAYERS, disabled)

func _on_cultivation_changed(_realm: String, _realm_index: int) -> void:
	_apply_destiny_slot_modifier()
	_update_shop_cultivation()

func _update_shop_cultivation() -> void:
	if shop_panel == null or cultivation_manager == null:
		return
	shop_panel.set_cultivation(
		cultivation_manager.get_realm(),
		cultivation_manager.get_breakthrough_cost(),
		cultivation_manager.is_max_realm(),
		cultivation_manager.get_cultivation_progress(),
		cultivation_manager.get_breakthrough_requirement(),
		cultivation_manager.get_cultivation_gain_per_click(),
		cultivation_manager.get_required_material_name(),
		cultivation_manager.has_required_material(),
		cultivation_manager.is_cultivation_full()
	)

func _on_sell_requested(from_area: String, from_index: int) -> void:
	var value: int = inventory.sell_stack(from_area, from_index)
	if value <= 0:
		_show_shop_message("无法出售")
		return
	economy_manager.add_spirit_stones(value)
	_show_shop_message("出售获得 %d 灵石" % value)

func _on_enemy_killed(gold_reward: int) -> void:
	var awarded_stones: int = _scaled_enemy_spirit_stones(gold_reward)
	run_summary.record_kill(awarded_stones)
	room_kill_count += 1
	room_spirit_stones += awarded_stones
	if awarded_stones > 0:
		economy_manager.add_spirit_stones(awarded_stones)
	_update_battle_ui(false)

func _scaled_enemy_spirit_stones(base_reward: int) -> int:
	if base_reward <= 0:
		return 0
	var reward_multiplier: float = destiny_manager.get_spirit_stone_reward_multiplier() if destiny_manager != null else 1.0
	enemy_spirit_stone_drop_accumulator += float(base_reward) * ENEMY_SPIRIT_STONE_DROP_MULTIPLIER * reward_multiplier
	var awarded_stones: int = int(floor(enemy_spirit_stone_drop_accumulator))
	enemy_spirit_stone_drop_accumulator -= float(awarded_stones)
	return awarded_stones

func _award_room_clear_economy(wave_number: int) -> void:
	var base_reward: int = _room_clear_spirit_stones_for_wave(wave_number)
	if encounter_manager != null:
		base_reward += encounter_manager.get_extra_room_clear_stones()
	var reward_multiplier: float = destiny_manager.get_spirit_stone_reward_multiplier() if destiny_manager != null else 1.0
	var reward: int = maxi(0, int(round(float(base_reward) * reward_multiplier)))
	if reward > 0:
		room_spirit_stones += reward
		economy_manager.add_spirit_stones(reward)
		run_summary.record_spirit_stones(reward)
	if cultivation_manager != null:
		cultivation_manager.add_cultivation(ROOM_CLEAR_CULTIVATION)
		_update_shop_cultivation()

func _room_clear_spirit_stones_for_wave(wave_number: int) -> int:
	for config in ROOM_CLEAR_SPIRIT_STONES_BY_RANGE:
		if wave_number >= int(config["min"]) and wave_number <= int(config["max"]):
			return int(config["reward"])
	return 100

func _on_boss_defeated(defeated_wave_number: int) -> void:
	if defeated_wave_number == wave_manager.wave_number and not in_shop and not run_ended:
		if wave_manager.is_boss_wave(defeated_wave_number):
			pending_encounter_wave = defeated_wave_number
		if combat_room_timer != null and combat_room_timer.time_left <= 0.0:
			_finish_room_after_timer()

func _finish_room_after_timer() -> void:
	_stop_boss_overtime_burn()
	if wave_manager.is_final_boss_wave(wave_manager.wave_number):
		_on_demo_completed()
	else:
		wave_manager.finish_current_room(true)

func _start_boss_overtime_burn() -> void:
	boss_overtime_burning = true
	boss_overtime_burn_accumulator = 0.0

func _stop_boss_overtime_burn() -> void:
	boss_overtime_burning = false
	boss_overtime_burn_accumulator = 0.0

func _apply_boss_overtime_burn(delta: float) -> void:
	if player == null or not player.has_method("take_environment_damage"):
		return
	boss_overtime_burn_accumulator += float(player.max_hp) * BOSS_OVERTIME_BURN_MAX_HP_PER_SECOND * delta
	var damage: int = int(floor(boss_overtime_burn_accumulator))
	if damage <= 0:
		return
	boss_overtime_burn_accumulator -= float(damage)
	player.call("take_environment_damage", damage)

func _update_battle_ui(refresh_artifacts: bool = false) -> void:
	if game_ui == null or wave_manager == null or player == null or inventory == null:
		return
	game_ui.set_wave_info(maxi(1, wave_manager.wave_number), _current_room_time_left(), wave_manager.alive_enemies)
	if refresh_artifacts:
		game_ui.set_equipped_artifacts(inventory.battle_slots, player.artifact_manager.artifacts)

func _synergy_effect_text() -> String:
	var parts: Array[String] = []
	var sword_per_stack: float = float(synergy_manager.get_effect_value("sword_attack_speed_per_stack", 0.0))
	var sword_max_stacks: int = int(synergy_manager.get_effect_value("sword_attack_speed_max_stacks", 0))
	if sword_per_stack > 0.0:
		parts.append("剑修: 每次伤害攻速+%d%%，上限%d层" % [int(round(sword_per_stack * 100.0)), sword_max_stacks])
	var extra: int = int(synergy_manager.get_effect_value("projectile_extra_count", 0))
	if extra > 0:
		parts.append("法修: 额外发射物+%d" % extra)
	var summon_extra: int = int(synergy_manager.get_effect_value("summon_extra_count", 0))
	if summon_extra > 0:
		parts.append("召唤: 数量+%d" % summon_extra)
	if float(synergy_manager.get_effect_value("summon_respawn_time_multiplier", 1.0)) < 1.0:
		parts.append("召唤: 重生-50%")
	if bool(synergy_manager.get_effect_value("summon_death_burst_enabled", false)):
		parts.append("召唤: 死亡灵力冲击")
	var body_hp: float = float(synergy_manager.get_effect_value("body_max_hp_multiplier", 1.0))
	var body_size: float = float(synergy_manager.get_effect_value("body_size_multiplier", 1.0))
	if body_hp > 1.0 or body_size > 1.0:
		parts.append("体修: 生命+%d%% 体型+%d%%" % [
			int(round((body_hp - 1.0) * 100.0)),
			int(round((body_size - 1.0) * 100.0)),
		])
	if float(synergy_manager.get_effect_value("demon_low_hp_magic_damage_multiplier", 1.0)) > 1.0:
		parts.append("魔修: 低血增伤")
	return "羁绊效果: 无" if parts.is_empty() else "羁绊效果: " + "；".join(parts)

func _clear_attack_nodes() -> void:
	if player != null and player.artifact_manager != null:
		player.artifact_manager.dispose_persistent_artifacts()
	for attack in attack_container.get_children():
		attack.queue_free()
	for projectile in get_tree().get_nodes_in_group("boss_projectiles"):
		projectile.queue_free()

func _on_player_died() -> void:
	if run_ended:
		return
	if encounter_manager != null:
		var revive: Dictionary = encounter_manager.consume_revive()
		var revive_ratio: float = float(revive.get("revive_ratio", 0.0))
		if revive_ratio > 0.0:
			_apply_destiny_runtime_modifiers()
			player.revive_with_hp_ratio(revive_ratio)
			game_ui.set_wave_status(wave_manager.wave_number, "复活")
			return
	run_ended = true
	_stop_boss_overtime_burn()
	if battle_environment_spawner != null and battle_environment_spawner.has_method("end_wave"):
		battle_environment_spawner.call("end_wave")
	synergy_manager.reset_battle_effects()
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	_clear_attack_nodes()
	game_ui.set_wave_status(wave_manager.wave_number, "已失败")
	result_panel.show_result("你陨落了", _death_summary_text(), "重新开始")

func _on_demo_completed() -> void:
	if run_ended:
		return
	run_ended = true
	in_shop = false
	_award_room_clear_economy(wave_manager.wave_number)
	_stop_boss_overtime_burn()
	if battle_environment_spawner != null and battle_environment_spawner.has_method("end_wave"):
		battle_environment_spawner.call("end_wave")
	if combat_room_timer != null:
		combat_room_timer.stop_room()
	synergy_manager.reset_battle_effects()
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	_clear_attack_nodes()
	game_ui.set_wave_status(wave_manager.wave_number, "Demo通关")
	result_panel.show_result("渡劫成功", _victory_summary_text(), "再来一局")

func _death_summary_text() -> String:
	return "到达波次: %d\n击杀数: %d\n灵石数: %d" % [
		wave_manager.wave_number,
		run_summary.kill_count,
		economy_manager.spirit_stones,
	]

func _victory_summary_text() -> String:
	return "通关时间: %s\n击杀数: %d\n最终Build:\n%s\n\n激活羁绊:\n%s" % [
		run_summary.format_elapsed_time(),
		run_summary.kill_count,
		run_summary.build_text(inventory.battle_slots),
		run_summary.synergy_text(synergy_manager.system_counts),
	]

func _restart_run() -> void:
	get_tree().reload_current_scene()

func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
