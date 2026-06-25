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

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"
const WAVE_1_ROOM_DURATION: float = 30.0
const WAVE_2_ROOM_DURATION: float = 40.0
const WAVE_3_ROOM_DURATION: float = 50.0
const LATE_ROOM_DURATION: float = 60.0
const ENEMY_SPIRIT_STONE_DROP_MULTIPLIER: float = 0.5
const ROOM_CLEAR_SPIRIT_STONES: int = 20
const BOSS_MATERIAL_BY_WAVE: Dictionary = {
	5: 0,
	9: 1,
	13: 2,
	17: 3,
}
const BOSS_OVERTIME_BURN_MAX_HP_PER_SECOND: float = 0.05

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

func _ready() -> void:
	call_deferred("_initialize")

func _process(delta: float) -> void:
	if player == null or wave_manager == null or game_ui == null:
		return
	if not in_shop and not run_ended and wave_manager.active:
		wave_elapsed_time += delta
	if boss_overtime_burning and not in_shop and not run_ended:
		_apply_boss_overtime_burn(delta)
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
	player.artifact_manager.configure(player, attack_container)
	player.artifact_manager.set_synergy_manager(synergy_manager)
	player.artifact_manager.set_destiny_manager(destiny_manager)
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
	synergy_manager.reset_battle_effects()
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	combat_room_timer.stop_room()
	_clear_attack_nodes()
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
	shop_panel.open_shop(
		cleared_wave,
		shop_manager.get_offer_dictionaries(),
		economy_manager.spirit_stones,
		inventory.battle_slots,
		inventory.bag_slots,
		synergy_manager.system_counts,
		synergy_manager.attribute_counts
	)
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
		if destiny_manager != null and destiny_manager.supports_all_in_extra_encounter() and economy_manager.spirit_stones > 0:
			choices.append({
				"id": "__all_in_extra_encounter",
				"name": "梭哈梭哈",
				"category": "天命",
				"description": "花费当前所有灵石，额外选择1个奇遇。",
			})
		encounter_panel.open_choices(choices)
	else:
		_enter_shop(cleared_wave)

func _on_encounter_selected(encounter_id: String) -> void:
	if encounter_manager == null:
		return
	if encounter_id == "__all_in_extra_encounter":
		_on_all_in_extra_encounter_selected()
		return
	var encounter: Dictionary = encounter_manager.select_encounter(encounter_id)
	if encounter.is_empty():
		return
	if encounter_panel != null:
		encounter_panel.close_panel()
	_apply_encounter_immediate_effects(encounter)
	var cleared_wave: int = pending_encounter_wave
	pending_encounter_wave = -1
	_enter_shop(cleared_wave)
	_show_shop_message("已选择奇遇：%s" % str(encounter.get("name", "奇遇")))

func _on_all_in_extra_encounter_selected() -> void:
	if destiny_manager == null or encounter_panel == null or encounter_manager == null:
		return
	if not destiny_manager.consume_all_in_extra_encounter_available():
		return
	var spent: int = economy_manager.spirit_stones
	if spent <= 0:
		return
	economy_manager.spend_spirit_stones(spent)
	encounter_panel.open_choices(encounter_manager.get_choices(1))

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
		multiplier *= encounter_manager.get_damage_multiplier(active_synergy_count)
	player.set_run_damage_multiplier(multiplier)

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
	if destiny_manager == null or inventory == null or player == null:
		return
	var star3_count: int = 0
	for raw_stack in inventory.battle_slots:
		var stack: ArtifactStack = raw_stack as ArtifactStack
		if stack != null and stack.star_level >= 3:
			star3_count += 1
	destiny_manager.set_star3_battle_count(star3_count)
	player.set_destiny_max_hp_flat_penalty(destiny_manager.get_star3_max_hp_penalty())

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
	_award_room_clear_spirit_stones()
	game_ui.set_wave_status(wave_number, "商店阶段")
	_update_battle_ui(true)
	if pending_encounter_wave == wave_number and encounter_manager != null and encounter_panel != null:
		_show_encounter_selection(wave_number)
		return
	_enter_shop(wave_number)

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
	_apply_destiny_runtime_modifiers()
	player.set_body_synergy(
		float(synergy_manager.get_effect_value("body_max_hp_multiplier", 1.0)),
		float(synergy_manager.get_effect_value("body_size_multiplier", 1.0))
	)
	if in_shop:
		shop_panel.set_synergies(system_counts, attribute_counts)
		shop_panel.set_message(_shop_status_text())

func _on_shop_offers_changed(offers: Array) -> void:
	if in_shop and shop_panel.visible:
		shop_panel.set_reroll_cost(shop_manager.get_reroll_cost())
		shop_panel.set_offers(offers)
		shop_panel.set_economy(economy_manager.spirit_stones)

func _on_spirit_stones_changed(amount: int) -> void:
	game_ui.set_spirit_stones(amount)
	if in_shop:
		shop_panel.set_economy(amount)

func _show_shop_message(message: String) -> void:
	if in_shop:
		shop_panel.set_message(message)

func _shop_status_text() -> String:
	var prefix: String = ""
	if wave_manager != null and wave_manager.wave_number > 0 and not debug_test_room:
		prefix = "本房间击杀 %d，获得灵石 %d。 " % [room_kill_count, room_spirit_stones]
	var material_text: String = ""
	if cultivation_manager != null and not cultivation_manager.is_max_realm():
		var material_state: String = "已获得" if cultivation_manager.has_required_material() else "未获得%s" % cultivation_manager.get_required_material_name()
		material_text = "突破材料：%s。 " % material_state
	return prefix + material_text + _synergy_effect_text()

func _on_breakthrough_requested() -> void:
	var gain_multiplier: float = destiny_manager.get_cultivation_gain_multiplier() if destiny_manager != null else 1.0
	var life_cost: int = destiny_manager.get_cultivation_life_cost() if destiny_manager != null else 0
	var stones_before: int = economy_manager.spirit_stones
	cultivation_manager.try_breakthrough(economy_manager, gain_multiplier, player, life_cost)
	if destiny_manager != null:
		destiny_manager.record_shop_spend(maxi(0, stones_before - economy_manager.spirit_stones))
	_update_shop_cultivation()

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

func _award_room_clear_spirit_stones() -> void:
	if ROOM_CLEAR_SPIRIT_STONES <= 0:
		return
	var reward_multiplier: float = destiny_manager.get_spirit_stone_reward_multiplier() if destiny_manager != null else 1.0
	var reward: int = maxi(0, int(round(float(ROOM_CLEAR_SPIRIT_STONES) * reward_multiplier)))
	room_spirit_stones += reward
	economy_manager.add_spirit_stones(reward)
	run_summary.record_spirit_stones(reward)

func _on_boss_defeated(defeated_wave_number: int) -> void:
	if BOSS_MATERIAL_BY_WAVE.has(defeated_wave_number):
		cultivation_manager.add_breakthrough_material(int(BOSS_MATERIAL_BY_WAVE[defeated_wave_number]))
		_update_shop_cultivation()
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
		var revive_ratio: float = encounter_manager.consume_revive_ratio()
		if revive_ratio > 0.0:
			player.revive_with_hp_ratio(revive_ratio)
			game_ui.set_wave_status(wave_manager.wave_number, "复活")
			return
	run_ended = true
	_stop_boss_overtime_burn()
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
	_award_room_clear_spirit_stones()
	_stop_boss_overtime_burn()
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
