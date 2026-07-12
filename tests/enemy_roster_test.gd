extends Node

func _ready() -> void:
	var player := load("res://scenes/Player.tscn").instantiate() as Player
	add_child(player)
	player.global_position = Vector2.ZERO
	var ranged := load("res://scenes/EnemyRanged.tscn").instantiate() as EnemyRanged
	add_child(ranged)
	ranged.global_position = Vector2(260, 0)
	ranged.setup(player)
	ranged.windup_time = .05
	ranged.attack_timer = 0.0
	await get_tree().create_timer(.30).timeout
	var projectiles := get_tree().get_nodes_in_group("enemy_projectiles")
	if projectiles.size() != 1:
		return _fail("RANGED_PROJECTILE_COUNT_%d" % projectiles.size())
	var projectile := projectiles[0] as EnemyProjectile
	var locked_direction := projectile.direction
	player.global_position = Vector2(0, 160)
	await get_tree().process_frame
	if not projectile.direction.is_equal_approx(locked_direction):
		return _fail("RANGED_PROJECTILE_TRACKED_PLAYER")

	var charger := load("res://scenes/EnemyCharger.tscn").instantiate() as EnemyCharger
	add_child(charger)
	charger.global_position = Vector2(180, 0)
	charger.setup(player)
	charger.windup_time = .06
	charger.recovery_time = .08
	charger.dash_duration = .06
	charger.cooldown = 0.0
	player.global_position = Vector2.ZERO
	await get_tree().create_timer(.02).timeout
	var dash_direction := charger.locked_direction
	player.global_position = Vector2(0, 180)
	await get_tree().create_timer(.08).timeout
	if not charger.locked_direction.is_equal_approx(dash_direction):
		return _fail("CHARGER_RETARGETED_DURING_WINDUP")
	await get_tree().create_timer(.14).timeout
	if charger.state != EnemyCharger.State.RECOVERY and charger.state != EnemyCharger.State.CHASE:
		return _fail("CHARGER_NO_RECOVERY")

	for wave in EnemyBalanceConfig.TOTAL_WAVES:
		var config := EnemyBalanceConfig.wave(wave + 1)
		if config.weights.has("ranged") and wave + 1 < 6: return _fail("RANGED_EARLY")
		if config.weights.has("charger") and wave + 1 < 8: return _fail("CHARGER_EARLY")
		if wave == 0 and not is_equal_approx(float(config.enemy_count_multiplier), 1.0): return _fail("WAVE_1_COUNT_CHANGED")
		if wave >= 1 and not is_equal_approx(float(config.enemy_count_multiplier), 1.5): return _fail("LATE_COUNT_NOT_150_PERCENT")
	print("ENEMY_ROSTER_TEST_OK")
	get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
