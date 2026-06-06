extends Node
class_name GameManager

@export var player_path: NodePath
@export var attack_container_path: NodePath
@export var wave_manager_path: NodePath
@export var economy_manager_path: NodePath
@export var inventory_path: NodePath
@export var synergy_manager_path: NodePath
@export var shop_manager_path: NodePath
@export var ui_path: NodePath
@export var shop_path: NodePath
@export var result_panel_path: NodePath
@export var run_summary_path: NodePath
@export var starting_spirit_stones: int = 3

const MAIN_MENU_SCENE: String = "res://scenes/MainMenu.tscn"

var player: Player
var attack_container: Node2D
var wave_manager: WaveManager
var economy_manager: EconomyManager
var inventory: ArtifactInventory
var synergy_manager: SynergyManager
var shop_manager: ShopManager
var game_ui: GameUI
var shop_panel: ShopPanel
var result_panel: ResultPanel
var run_summary: RunSummary
var in_shop: bool = false
var run_ended: bool = false

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	randomize()
	player = get_node(player_path)
	attack_container = get_node(attack_container_path)
	wave_manager = get_node(wave_manager_path)
	economy_manager = get_node(economy_manager_path)
	inventory = get_node(inventory_path)
	synergy_manager = get_node(synergy_manager_path)
	shop_manager = get_node(shop_manager_path)
	game_ui = get_node(ui_path)
	shop_panel = get_node(shop_path)
	result_panel = get_node(result_panel_path)
	run_summary = get_node(run_summary_path)

	run_summary.start_run()
	player.artifact_manager.configure(player, attack_container)
	player.artifact_manager.set_synergy_manager(synergy_manager)
	wave_manager.configure(player)
	shop_manager.configure(economy_manager, inventory)

	player.hp_changed.connect(game_ui.set_hp)
	player.shield_changed.connect(game_ui.set_shield)
	player.died.connect(_on_player_died)
	economy_manager.spirit_stones_changed.connect(_on_spirit_stones_changed)
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory.inventory_message.connect(_show_shop_message)
	synergy_manager.synergies_changed.connect(_on_synergies_changed)
	shop_manager.offers_changed.connect(_on_shop_offers_changed)
	shop_manager.shop_message.connect(_show_shop_message)
	shop_panel.buy_requested.connect(shop_manager.buy_offer)
	shop_panel.reroll_requested.connect(shop_manager.reroll)
	shop_panel.continue_requested.connect(_on_shop_continue_requested)
	shop_panel.inventory_move_requested.connect(inventory.move_stack)
	result_panel.restart_requested.connect(_restart_run)
	result_panel.main_menu_requested.connect(_return_to_main_menu)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)

	game_ui.set_hp(player.hp, player.max_hp)
	game_ui.set_shield(player.shield, player.shield_limit)
	economy_manager.reset(starting_spirit_stones)
	_on_inventory_changed()
	game_ui.set_wave_status(1, "准备阶段")
	_enter_shop(0)

func _start_battle() -> void:
	in_shop = false
	shop_panel.close_shop()
	player.set_battle_paused(false)
	wave_manager.start_next_wave()

func _enter_shop(cleared_wave: int) -> void:
	in_shop = true
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	_clear_attack_nodes()
	shop_manager.generate_offers()
	shop_panel.open_shop(
		cleared_wave,
		shop_manager.get_offer_dictionaries(),
		economy_manager.spirit_stones,
		inventory.battle_slots,
		inventory.bag_slots,
		synergy_manager.system_counts,
		synergy_manager.attribute_counts
	)
	shop_panel.set_message(_synergy_effect_text())

func _on_shop_continue_requested() -> void:
	if run_ended:
		return
	_start_battle()

func _on_wave_started(wave_number: int) -> void:
	game_ui.set_wave_status(wave_number, "战斗中")

func _on_wave_cleared(wave_number: int) -> void:
	if wave_number >= 5:
		_on_demo_completed()
		return
	game_ui.set_wave_status(wave_number, "商店阶段")
	_enter_shop(wave_number)

func _on_inventory_changed() -> void:
	synergy_manager.recalculate(inventory.battle_slots)
	player.artifact_manager.sync_from_battle_slots(inventory.battle_slots)
	if in_shop:
		shop_panel.set_inventory(inventory.battle_slots, inventory.bag_slots)

func _on_synergies_changed(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	player.set_body_synergy(
		int(synergy_manager.get_effect_value("body_max_hp_bonus", 0)),
		bool(synergy_manager.get_effect_value("body_counter_enabled", false)),
		float(synergy_manager.get_effect_value("body_counter_damage", 8.0))
	)
	if in_shop:
		shop_panel.set_synergies(system_counts, attribute_counts)
		shop_panel.set_message(_synergy_effect_text())

func _on_shop_offers_changed(offers: Array) -> void:
	if in_shop and shop_panel.visible:
		shop_panel.set_offers(offers)

func _on_spirit_stones_changed(amount: int) -> void:
	game_ui.set_spirit_stones(amount)
	if in_shop:
		shop_panel.set_economy(amount)

func _show_shop_message(message: String) -> void:
	if in_shop:
		shop_panel.set_message(message)

func _on_enemy_killed(gold_reward: int) -> void:
	run_summary.record_kill(gold_reward)
	economy_manager.add_spirit_stones(gold_reward)

func _synergy_effect_text() -> String:
	var parts: Array[String] = []
	var sword := float(synergy_manager.get_effect_value("sword_double_chance", 0.0))
	if sword > 0.0:
		parts.append("剑修: %d%%双击" % int(round(sword * 100.0)))
	var extra: int = int(synergy_manager.get_effect_value("projectile_extra_count", 0))
	if extra > 0:
		parts.append("法修: 额外发射物+%d" % extra)
	var formation := float(synergy_manager.get_effect_value("formation_radius_multiplier", 1.0))
	if formation > 1.0:
		parts.append("阵法: 范围+%d%%" % int(round((formation - 1.0) * 100.0)))
	if int(synergy_manager.get_effect_value("body_max_hp_bonus", 0)) > 0:
		parts.append("体修: 生命+20")
	if bool(synergy_manager.get_effect_value("body_counter_enabled", false)):
		parts.append("体修: 受伤反震")
	if float(synergy_manager.get_effect_value("demon_low_hp_magic_damage_multiplier", 1.0)) > 1.0:
		parts.append("魔修: 低血增伤")
	return "羁绊效果: 无" if parts.is_empty() else "羁绊效果: " + "；".join(parts)

func _clear_attack_nodes() -> void:
	for attack in attack_container.get_children():
		attack.queue_free()
	for projectile in get_tree().get_nodes_in_group("boss_projectiles"):
		projectile.queue_free()

func _on_player_died() -> void:
	if run_ended:
		return
	run_ended = true
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
