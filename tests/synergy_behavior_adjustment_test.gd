extends Node

func _ready() -> void:
	var expected_water := {2: .1, 4: .2, 6: .2}
	for tier in SynergyManager.WATER_HEAL_TIERS:
		if not is_equal_approx(float(tier.heal), float(expected_water[int(tier.required)])):
			return _fail("WATER_HEAL_%s" % tier)
	var body_barrier := load("res://data/artifacts/body_barrier.tres") as ArtifactData
	if body_barrier == null or not is_equal_approx(body_barrier.heal_amount, .5):
		return _fail("BODY_BARRIER_HEAL_%s" % (body_barrier.heal_amount if body_barrier != null else -1.0))
	var expected_metal := {2: .5, 4: 1.0, 6: 2.0}
	for tier in SynergyManager.METAL_LOW_HP_TIERS:
		if not is_equal_approx(float(tier.hp_ratio), .5):
			return _fail("METAL_HP_THRESHOLD_%s" % tier)
		if not is_equal_approx(float(tier.damage_multiplier), float(expected_metal[int(tier.required)])):
			return _fail("METAL_DAMAGE_MULTIPLIER_%s" % tier)
	var manager := SynergyManager.new()
	add_child(manager)
	var stats := CombatStats.new()
	stats.begin_wave(1)
	manager.set_combat_stats(stats)
	var artifact_manager := ArtifactManager.new()
	add_child(artifact_manager)
	artifact_manager.set_synergy_manager(manager)
	manager.effects["sword_attack_speed_per_stack"] = .02
	manager.effects["sword_attack_speed_max_stacks"] = 20
	manager.sword_attack_speed_stacks = 10
	var sword := load("res://data/artifacts/dagger.tres") as ArtifactData
	var non_sword := load("res://data/artifacts/fire_orb.tres") as ArtifactData
	if artifact_manager.get_sword_artifact_cooldown_multiplier(sword) >= 1.0:
		return _fail("SWORD_SPEED_NOT_APPLIED")
	if not is_equal_approx(artifact_manager.get_sword_artifact_cooldown_multiplier(non_sword), 1.0):
		return _fail("SWORD_SPEED_LEAKED_TO_OTHER_SYSTEM")
	manager.sword_attack_speed_stacks = 0
	for _index in 30:
		manager.notify_artifact_damage(sword)
	var sword_row: Dictionary = stats.synergy_rows.get("剑修：攻速层数", {})
	if int(sword_row.get("count", -1)) != 20 or str(sword_row.get("count_unit", "")) != "层":
		return _fail("SWORD_FINAL_STACK_STATS_%s" % sword_row)

	var primary := _enemy(Vector2.ZERO)
	var nearby_a := _enemy(Vector2(30, 0))
	var nearby_b := _enemy(Vector2(60, 0))
	manager.effects["fire_explosion_radius"] = 80.0
	manager.effects["fire_explosion_damage_multiplier"] = .35
	manager.apply_attribute_on_hit(load("res://data/artifacts/blood_sword.tres"), primary, 20.0, self, Vector2.ZERO, 1.0)
	if not is_equal_approx(primary.hp, 93.0):
		return _fail("FIRE_PRIMARY_NOT_EXPLODED_%s" % primary.hp)

	primary.hp = 100.0
	nearby_a.hp = 100.0
	nearby_b.hp = 100.0
	manager.effects["earth_shockwave_radius"] = 80.0
	manager.effects["earth_shockwave_damage_multiplier"] = .25
	manager.effects["earth_slow_percent"] = .20
	manager.effects["earth_slow_duration"] = 1.0
	manager.apply_attribute_on_hit(load("res://data/artifacts/giant_sword_art.tres"), primary, 20.0, self)
	if not primary.slow_effects.has("attribute_earth") or not nearby_a.slow_effects.has("attribute_earth"):
		return _fail("EARTH_SLOW_MISSING")
	if not is_equal_approx(nearby_a.hp, 95.0):
		return _fail("EARTH_DAMAGE_WRONG_%s" % nearby_a.hp)

	primary.hp = 100.0
	nearby_a.hp = 100.0
	nearby_b.hp = 100.0
	manager.effects["lightning_chain_targets"] = 2
	manager.effects["lightning_chain_damage_multiplier"] = .5
	manager.effects["lightning_chain_range"] = 220.0
	manager.effects["lightning_chain_falloff"] = 1.0
	manager.apply_attribute_on_hit(load("res://data/artifacts/heaven_eye.tres"), primary, 20.0, self)
	if not is_equal_approx(nearby_a.hp, 90.0) or not is_equal_approx(nearby_b.hp, 90.0):
		return _fail("LIGHTNING_NOT_EQUAL_%s_%s" % [nearby_a.hp, nearby_b.hp])

	print("SYNERGY_BEHAVIOR_ADJUSTMENT_TEST_OK")
	for enemy in [primary, nearby_a, nearby_b]: enemy.queue_free()
	manager.queue_free()
	artifact_manager.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _enemy(position: Vector2) -> Enemy:
	var enemy := load("res://scenes/EnemyBasic.tscn").instantiate() as Enemy
	enemy.max_hp = 100.0
	enemy.global_position = position
	add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
