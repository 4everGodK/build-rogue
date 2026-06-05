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
@export var starting_spirit_stones: int = 3

var player: Player
var attack_container: Node2D
var wave_manager: WaveManager
var economy_manager: EconomyManager
var inventory: ArtifactInventory
var synergy_manager: SynergyManager
var shop_manager: ShopManager
var game_ui: GameUI
var shop_panel: ShopPanel
var in_shop: bool = false

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

	player.artifact_manager.configure(player, attack_container)
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
	wave_manager.enemy_killed.connect(economy_manager.add_spirit_stones)
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

func _on_shop_continue_requested() -> void:
	_start_battle()

func _on_wave_started(wave_number: int) -> void:
	game_ui.set_wave_status(wave_number, "战斗中")

func _on_wave_cleared(wave_number: int) -> void:
	game_ui.set_wave_status(wave_number, "商店阶段")
	_enter_shop(wave_number)

func _on_inventory_changed() -> void:
	player.artifact_manager.sync_from_battle_slots(inventory.battle_slots)
	synergy_manager.recalculate(inventory.battle_slots)
	if in_shop:
		shop_panel.set_inventory(inventory.battle_slots, inventory.bag_slots)

func _on_synergies_changed(system_counts: Dictionary, attribute_counts: Dictionary) -> void:
	if in_shop:
		shop_panel.set_synergies(system_counts, attribute_counts)

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

func _clear_attack_nodes() -> void:
	for attack in attack_container.get_children():
		attack.queue_free()

func _on_player_died() -> void:
	player.set_battle_paused(true)
	wave_manager.pause_wave(true)
	game_ui.set_wave_status(wave_manager.wave_number, "已失败")
