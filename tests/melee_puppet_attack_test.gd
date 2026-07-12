extends Node

func _ready() -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	add_child(player)
	var enemy_scene := load("res://scenes/EnemyBasic.tscn") as PackedScene
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.max_hp = 100.0
	# Enemies do not collide with summons, so exact overlap is a normal combat case.
	enemy.global_position = Vector2.ZERO
	add_child(enemy)
	enemy.set_physics_process(false)
	var data := load("res://data/artifacts/sword_puppet.tres") as ArtifactData
	var controller := SummonController.new()
	add_child(controller)
	controller.setup(player, data)
	await get_tree().create_timer(1.2).timeout
	var unit: SummonUnit = controller.units[0] if not controller.units.is_empty() else null
	if enemy.hp >= enemy.max_hp:
		push_error("MELEE_PUPPET_DID_NOT_ATTACK state=%s target=%s cooldown=%s position=%s" % [unit.state if unit != null else "missing", unit.target if unit != null else null, unit.attack_cooldown if unit != null else -1.0, unit.global_position if unit != null else Vector2.ZERO])
		get_tree().quit(1)
		return
	print("MELEE_PUPPET_ATTACK_TEST_OK damage=%s" % (enemy.max_hp - enemy.hp))
	get_tree().quit()
