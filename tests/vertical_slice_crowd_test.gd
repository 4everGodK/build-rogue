extends Node2D

const COUNTS: Array[int] = [30, 50, 80]
const ENEMY_SCENES: Array[PackedScene] = [
	preload("res://scenes/EnemyBasic.tscn"),
	preload("res://scenes/EnemyRanged.tscn"),
	preload("res://scenes/EnemyCharger.tscn"),
]

var player: Player
var hud: GameUI
var crowd_root: Node2D

func _ready() -> void:
	player = load("res://scenes/Player.tscn").instantiate() as Player
	player.position = Vector2.ZERO
	add_child(player)
	crowd_root = Node2D.new()
	crowd_root.name = "Crowd"
	add_child(crowd_root)
	hud = load("res://ui/GameUI.tscn").instantiate() as GameUI
	add_child(hud)
	hud.set_hp(100, 100)
	hud.set_shield(40.0, 60.0)
	hud.set_wave_info(8, 42.0, 0)
	hud.set_synergies({"剑修": 3, "法修": 1, "召唤": 2}, {"金": 2, "雷": 1, "木": 2})
	await get_tree().process_frame

	var center := get_viewport_rect().size * .5
	for panel in [hud.resource_panel, hud.wave_panel, hud.synergy_panel, hud.artifact_bar]:
		if (panel as Control).get_global_rect().has_point(center):
			return _fail("HUD_BLOCKS_PLAYER_CENTER_%s" % (panel as Node).name)

	for count in COUNTS:
		await _run_crowd_case(count)
	print("VERTICAL_SLICE_CROWD_TEST_OK counts=%s" % [COUNTS])
	get_tree().quit()

func _run_crowd_case(count: int) -> void:
	for child in crowd_root.get_children():
		child.queue_free()
	await get_tree().process_frame
	for index in count:
		var enemy := ENEMY_SCENES[index % ENEMY_SCENES.size()].instantiate() as Enemy
		var ring := index % 4
		var angle := TAU * float(index) / float(count) + float(ring) * .17
		var radius := 125.0 + float(ring) * 72.0
		enemy.position = Vector2(cos(angle), sin(angle)) * radius
		enemy.contact_damage = 0
		enemy.setup(player)
		crowd_root.add_child(enemy)
	hud.set_wave_info(8, 42.0, count)
	await get_tree().physics_frame
	if crowd_root.get_child_count() != count:
		return _fail("CROWD_COUNT_%d_%d" % [count, crowd_root.get_child_count()])
	var start_usec := Time.get_ticks_usec()
	for _frame in 90:
		await get_tree().physics_frame
	var average_frame_ms := float(Time.get_ticks_usec() - start_usec) / 90000.0
	print("CROWD_CASE count=%d average_physics_frame_ms=%.3f" % [count, average_frame_ms])

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)

