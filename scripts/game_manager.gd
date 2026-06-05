extends Node
class_name GameManager

@export var battle_duration: float = 60.0
@export var reroll_cost: int = 3
@export var grant_test_artifacts: bool = true
@export_enum("剑修", "法修", "体修", "阵法", "魔修") var test_system: String = "剑修"

@export var player_path: NodePath
@export var spawner_path: NodePath
@export var projectile_container_path: NodePath
@export var ui_path: NodePath
@export var shop_path: NodePath
@export var initial_artifact_panel_path: NodePath
@export var initial_artifact_offer_count: int = 3

var player: Player
var spawner: EnemySpawner
var projectile_container: Node2D
var game_ui: GameUI
var shop_panel: ShopPanel
var initial_artifact_panel: InitialArtifactPanel
var wave: int = 1
var battle_time_left: float = 0.0
var in_battle: bool = false

const TEST_SYSTEM_KEYS := {
	KEY_1: "剑修",
	KEY_2: "法修",
	KEY_3: "体修",
	KEY_4: "阵法",
	KEY_5: "魔修",
}

func _ready() -> void:
	call_deferred("_initialize")

func _initialize() -> void:
	randomize()
	player = get_node(player_path)
	spawner = get_node(spawner_path)
	projectile_container = get_node(projectile_container_path)
	game_ui = get_node(ui_path)
	shop_panel = get_node(shop_path)
	initial_artifact_panel = get_node(initial_artifact_panel_path)
	player.artifact_manager.configure(player, projectile_container)
	player.hp_changed.connect(game_ui.set_hp)
	player.shield_changed.connect(game_ui.set_shield)
	player.gold_changed.connect(_on_gold_changed)
	player.artifacts_changed.connect(game_ui.set_artifacts)
	player.died.connect(_on_player_died)
	shop_panel.buy_requested.connect(_on_shop_buy_requested)
	shop_panel.reroll_requested.connect(_on_shop_reroll_requested)
	shop_panel.continue_requested.connect(_start_next_wave)
	initial_artifact_panel.artifact_selected.connect(_on_initial_artifact_selected)
	game_ui.set_hp(player.hp, player.max_hp)
	game_ui.set_shield(player.shield, player.shield_limit)
	game_ui.set_gold(player.gold)
	if grant_test_artifacts:
		_load_test_system(test_system)
		_start_battle()
	else:
		_open_initial_artifact_selection()

func _process(delta: float) -> void:
	if not in_battle:
		return
	battle_time_left -= delta
	game_ui.set_wave_time(wave, battle_time_left)
	if battle_time_left <= 0.0:
		_end_battle()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed:
		return
	if key_event.keycode == KEY_T and in_battle:
		_end_battle()
	elif TEST_SYSTEM_KEYS.has(key_event.keycode):
		_load_test_system(str(TEST_SYSTEM_KEYS[key_event.keycode]))

func _start_battle() -> void:
	in_battle = true
	battle_time_left = battle_duration
	shop_panel.close_shop()
	player.artifact_manager.refresh_persistent_artifacts()
	spawner.start_battle(player)
	game_ui.set_wave_time(wave, battle_time_left)

func _end_battle() -> void:
	in_battle = false
	spawner.stop_battle()
	_clear_battlefield()
	shop_panel.open_shop(wave, ArtifactCatalog.random_offer(3), player.gold, reroll_cost)

func _open_initial_artifact_selection() -> void:
	initial_artifact_panel.open_choices(ArtifactCatalog.random_offer(initial_artifact_offer_count))

func _on_initial_artifact_selected(artifact: Dictionary) -> void:
	initial_artifact_panel.close_choices()
	player.add_artifact(artifact)
	_start_battle()

func _start_next_wave() -> void:
	wave += 1
	_start_battle()

func _clear_battlefield() -> void:
	for body in get_tree().get_nodes_in_group("enemies"):
		body.queue_free()
	for attack in projectile_container.get_children():
		if not attack is OrbitAttackNode and not attack is FormationAttackNode:
			attack.queue_free()

func _load_test_system(system_tag: String) -> void:
	player.clear_artifacts()
	for attack in projectile_container.get_children():
		attack.queue_free()
	for id in ArtifactCatalog.ids_for_system(system_tag):
		player.add_artifact(ArtifactCatalog.get_artifact(id))

func _on_gold_changed(value: int) -> void:
	game_ui.set_gold(value)
	if shop_panel.visible:
		shop_panel.refresh_gold(value, reroll_cost)

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
