extends Node

const EXPECTED_PROFILES := {
	"dagger": "light",
	"poison_needle": "light",
	"copper_coin": "light",
	"poison_bug": "light",
	"one_handed_sword": "medium",
	"fist": "medium",
	"palm": "medium",
	"flying_sword": "medium",
	"fire_orb": "medium",
	"sword_puppet": "medium",
	"crossbow_puppet": "medium",
	"ghost": "medium",
	"two_handed_sword": "heavy",
	"kick": "heavy",
	"long_spear": "heavy",
	"roar": "heavy",
	"iron_guard_puppet": "heavy",
	"blood_slash": "explosion",
	"thorn_armor": "explosion",
	"body_barrier": "explosion",
	"giant_sword_art": "explosion",
	"golden_body_avatar": "explosion",
	"fire_gourd": "continuous",
	"soul_banner": "continuous",
	"turret": "summon",
}

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	for profile_name in ["light", "medium", "heavy", "explosion", "continuous", "summon"]:
		var profile := HitFeedbackProfile.resolve(profile_name)
		_expect(is_equal_approx(float(profile.get("hit_stop_seconds", -1.0)), 0.0), "%s should not have default Hit Stop" % profile_name)
	_expect(float(HitFeedbackProfile.resolve("heavy").get("screen_shake_strength", 0.0)) > 0.0, "heavy should retain screen shake")
	_expect(float(HitFeedbackProfile.resolve("explosion").get("screen_shake_strength", 0.0)) > 0.0, "explosion should retain screen shake")
	_expect(is_equal_approx(float(HitFeedbackProfile.resolve("medium").get("screen_shake_strength", -1.0)), 0.0), "medium should not shake")

	var positive_hit_stop_ids: Array[String] = []
	for artifact_id in EXPECTED_PROFILES:
		var path := "res://data/artifacts/%s.tres" % artifact_id
		var data := load(path) as ArtifactData
		_expect(data != null, "failed to load %s" % path)
		if data == null:
			continue
		_expect(data.hit_feedback_profile == EXPECTED_PROFILES[artifact_id], "%s profile mismatch" % artifact_id)
		if data.hit_stop_seconds > 0.0:
			positive_hit_stop_ids.append(artifact_id)
		_expect(data.hit_stop_seconds <= 0.05, "%s Hit Stop exceeds 0.05 seconds" % artifact_id)
	positive_hit_stop_ids.sort()
	_expect(positive_hit_stop_ids == ["giant_sword_art", "golden_body_avatar"], "unexpected Hit Stop allowlist: %s" % str(positive_hit_stop_ids))

	var giant := load("res://data/artifacts/giant_sword_art.tres") as ArtifactData
	var avatar := load("res://data/artifacts/golden_body_avatar.tres") as ArtifactData
	_expect(is_equal_approx(giant.hit_stop_seconds, 0.035), "giant sword Hit Stop should be 0.035")
	_expect(is_equal_approx(avatar.hit_stop_seconds, 0.04), "golden avatar Hit Stop should be 0.04")
	_expect(is_equal_approx(giant.screen_shake_strength, 6.0), "giant sword shake should be 6")
	_expect(is_equal_approx(avatar.screen_shake_strength, 7.0), "golden avatar shake should be 7")
	_run_feedback_smoke(giant)

	var combat_node := Node.new()
	combat_node.add_to_group("combat_logic")
	add_child(combat_node)
	var seen_before := HitStopManager.seen_attack_ids.size()
	HitStopManager.request_hit_stop("same-attack-policy-test", 0.2)
	HitStopManager.request_hit_stop("same-attack-policy-test", 0.01)
	_expect(HitStopManager.seen_attack_ids.size() == seen_before + 1, "same attack id should be deduplicated")
	_expect(HitStopManager.stop_ends_at_msec - Time.get_ticks_msec() <= 50, "Hit Stop manager hard cap should be 0.05 seconds")
	OS.delay_msec(60)
	HitStopManager.call("_process", 0.0)
	await get_tree().process_frame
	_expect(HitStopManager.frozen_nodes.is_empty(), "combat nodes should resume after Hit Stop")
	await get_tree().create_timer(0.45).timeout
	for child in get_children():
		child.queue_free()
	await get_tree().process_frame

	if failures.is_empty():
		print("HIT_FEEDBACK_POLICY_TEST_OK")
		get_tree().quit()
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run_feedback_smoke(giant: ArtifactData) -> void:
	var player := Node2D.new()
	player.add_to_group("player")
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	player.add_child(camera)
	add_child(player)
	var enemy_scene := load("res://scenes/EnemyBasic.tscn") as PackedScene
	var enemy := enemy_scene.instantiate() as Enemy
	enemy.max_hp = 100.0
	enemy.global_position = Vector2(80.0, 0.0)
	add_child(enemy)
	var one_handed := load("res://data/artifacts/one_handed_sword.tres") as ArtifactData
	var number_available_before := DamageNumberPool.available.size()
	var effect_available_before := HitEffectPool.available.size()
	var stop_seen_before := HitStopManager.seen_attack_ids.size()
	var shake_seen_before := ScreenShakeManager.seen_attack_ids.size()
	var killed := HitFeedbackManager.deal_damage(enemy, 5.0, player, one_handed, self, {
		"attack_instance_id": "one-handed-smoke",
		"hit_origin": player.global_position,
	})
	_expect(not killed and is_equal_approx(enemy.hp, 95.0), "one-handed hit should apply actual damage")
	_expect(float(enemy.hit_flash_material.get_shader_parameter("flash_amount")) > 0.0, "one-handed hit should flash the enemy")
	_expect(enemy.hit_squash_tween != null, "one-handed hit should start squash recovery")
	_expect(enemy.knockback_velocity.length() >= 34.9, "one-handed hit should apply medium knockback")
	_expect(DamageNumberPool.available.size() == number_available_before - 1, "one-handed hit should acquire a pooled damage number")
	_expect(HitEffectPool.available.size() == effect_available_before - 1, "one-handed hit should acquire a pooled hit effect")
	_expect(HitStopManager.seen_attack_ids.size() == stop_seen_before, "one-handed hit must not request Hit Stop")
	_expect(ScreenShakeManager.seen_attack_ids.size() == shake_seen_before, "one-handed hit must not request screen shake")

	var second_enemy := enemy_scene.instantiate() as Enemy
	second_enemy.max_hp = 500.0
	second_enemy.global_position = Vector2(120.0, 0.0)
	add_child(second_enemy)
	var giant_attack_id := "giant-multi-target-smoke"
	stop_seen_before = HitStopManager.seen_attack_ids.size()
	shake_seen_before = ScreenShakeManager.seen_attack_ids.size()
	HitFeedbackManager.deal_damage(enemy, 5.0, player, giant, self, {
		"attack_instance_id": giant_attack_id,
		"hit_origin": player.global_position,
		"effect_origin": Vector2(100.0, 0.0),
	})
	HitFeedbackManager.deal_damage(second_enemy, 5.0, player, giant, self, {
		"attack_instance_id": giant_attack_id,
		"hit_origin": player.global_position,
		"effect_origin": Vector2(100.0, 0.0),
	})
	_expect(HitStopManager.seen_attack_ids.size() == stop_seen_before + 1, "giant multi-target hit should request Hit Stop once")
	_expect(ScreenShakeManager.seen_attack_ids.size() == shake_seen_before + 1, "giant multi-target hit should shake once")
