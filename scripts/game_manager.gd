extends Node
class_name GameManager

@export var battle_duration: float = 60.0
@export var reroll_cost: int = 3

@export var player_path: NodePath
@export var spawner_path: NodePath
@export var projectile_container_path: NodePath
@export var ui_path: NodePath
@export var shop_path: NodePath
@export var synergy_manager_path: NodePath

var player: Player
var spawner: EnemySpawner
var projectile_container: Node2D
var game_ui: GameUI
var shop_panel: ShopPanel
var synergy_manager: SynergyManager

var wave: int = 1
var battle_time_left: float = 0.0
var in_battle: bool = false

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	randomize()
	player = get_node(player_path)
	spawner = get_node(spawner_path)
	projectile_container = get_node(projectile_container_path)
	game_ui = get_node(ui_path)
	shop_panel = get_node(shop_path)
	synergy_manager = get_node(synergy_manager_path)

	player.artifact_controller.configure(player, projectile_container, synergy_manager)
	player.hp_changed.connect(game_ui.set_hp)
	player.gold_changed.connect(_on_gold_changed)
	player.artifacts_changed.connect(_on_artifacts_changed)
	player.died.connect(_on_player_died)
	synergy_manager.synergies_changed.connect(game_ui.set_synergies)

	shop_panel.buy_requested.connect(_on_shop_buy_requested)
	shop_panel.reroll_requested.connect(_on_shop_reroll_requested)
	shop_panel.continue_requested.connect(_start_next_wave)

	game_ui.set_hp(player.hp, player.max_hp)
	game_ui.set_gold(player.gold)
	game_ui.set_artifacts(player.artifact_inventory)

	# Start with one sword so the prototype immediately demonstrates auto combat.
	player.add_artifact(ArtifactCatalog.get_artifact("gold_sword"))
	synergy_manager.recalculate(player.artifact_inventory)
	_start_battle()

func _process(delta: float) -> void:
	if not in_battle:
		return

	battle_time_left -= delta
	game_ui.set_wave_time(wave, battle_time_left)
	if battle_time_left <= 0.0:
		_end_battle()

func _unhandled_input(event: InputEvent) -> void:
	# Debug helper for fast prototype testing: press T to jump to the shop.
	if event is InputEventKey and event.pressed and event.keycode == KEY_T and in_battle:
		_end_battle()

func _start_battle() -> void:
	in_battle = true
	battle_time_left = battle_duration
	shop_panel.close_shop()
	spawner.start_battle(player)
	game_ui.set_wave_time(wave, battle_time_left)

func _end_battle() -> void:
	in_battle = false
	spawner.stop_battle()
	_clear_battlefield()
	shop_panel.open_shop(wave, ArtifactCatalog.random_offer(3), player.gold, reroll_cost)

func _start_next_wave() -> void:
	wave += 1
	_start_battle()

func _clear_battlefield() -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		body.queue_free()
	for projectile in projectile_container.get_children():
		projectile.queue_free()

func _on_gold_changed(gold: int) -> void:
	game_ui.set_gold(gold)
	if shop_panel.visible:
		shop_panel.refresh_gold(gold, reroll_cost)

func _on_artifacts_changed(artifacts: Array) -> void:
	game_ui.set_artifacts(artifacts)
	synergy_manager.recalculate(artifacts)

func _on_shop_buy_requested(artifact: Dictionary) -> void:
	var price: int = artifact.get("price", 0)
	if player.spend_gold(price):
		player.add_artifact(artifact)
		shop_panel.refresh_gold(player.gold, reroll_cost)

func _on_shop_reroll_requested() -> void:
	if player.spend_gold(reroll_cost):
		shop_panel.open_shop(wave, ArtifactCatalog.random_offer(3), player.gold, reroll_cost)

func _on_player_died() -> void:
	in_battle = false
	spawner.stop_battle()
	_clear_battlefield()
	shop_panel.open_shop(wave, ArtifactCatalog.random_offer(3), player.gold, reroll_cost)
