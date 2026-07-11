extends Node

const PROFILE_BY_ARTIFACT: Dictionary = {
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
	"turret": "summon",
}

const SPECIAL_SHAKE: Dictionary = {
	"giant_sword_art": Vector2(6.0, 0.18),
	"golden_body_avatar": Vector2(7.0, 0.20),
	"blood_slash": Vector2(3.0, 0.10),
	"thorn_armor": Vector2(2.0, 0.08),
}

const SOUND_PATHS: Dictionary = {
	"hit_light": "res://audio/hit/hit_light.ogg",
	"hit_medium": "res://audio/hit/hit_medium.ogg",
	"hit_heavy": "res://audio/hit/hit_heavy.ogg",
	"hit_explosion": "res://audio/hit/hit_explosion.ogg",
	"hit_continuous": "res://audio/hit/hit_continuous.ogg",
	"hit_summon": "res://audio/hit/hit_summon.ogg",
}

var _attack_serial: int = 0
var _attack_ids_by_source: Dictionary = {}
var _main_effect_attack_ids: Dictionary = {}
var _sound_last_played_msec: Dictionary = {}
var _explosion_sound_attack_ids: Dictionary = {}
var _continuous_visual_last_msec: Dictionary = {}
var _audio_players: Array[AudioStreamPlayer] = []
var _audio_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in 8:
		var player := AudioStreamPlayer.new()
		player.name = "HitAudio%d" % index
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_audio_players.append(player)

func deal_damage(target: Node, amount: float, source: Node, artifact_data: ArtifactData, attack_source: Node, options: Dictionary = {}) -> bool:
	if target == null or not is_instance_valid(target) or not target.has_method("take_damage") or amount <= 0.0:
		return false
	var before_hp := _read_hp(target)
	var killed := bool(target.call("take_damage", amount, source))
	var after_hp := _read_hp(target)
	var actual_damage := amount
	if before_hp >= 0.0 and after_hp >= 0.0:
		actual_damage = maxf(0.0, before_hp - after_hp)
	if actual_damage <= 0.0:
		return killed
	var profile_name := str(options.get("profile", _profile_for(artifact_data)))
	if bool(options.get("is_continuous", false)):
		profile_name = "continuous"
	var attack_instance_id: Variant = options.get("attack_instance_id", _attack_id_for(attack_source))
	var hit_position := (target as Node2D).global_position if target is Node2D else Vector2.ZERO
	var hit_origin := (source as Node2D).global_position if source is Node2D else hit_position
	var hit_data := {
		"attack_source": source,
		"attack_node": attack_source,
		"target_enemy": target,
		"hit_position": options.get("hit_position", hit_position),
		"hit_origin": options.get("hit_origin", hit_origin),
		"effect_origin": options.get("effect_origin", options.get("hit_origin", hit_origin)),
		"actual_damage": actual_damage,
		"is_critical": bool(options.get("is_critical", false)),
		"is_kill": killed,
		"profile_name": profile_name,
		"attack_instance_id": attack_instance_id,
		"is_continuous": bool(options.get("is_continuous", false)),
		"artifact_data": artifact_data,
	}
	play_hit_feedback(hit_data)
	return killed

func play_hit_feedback(hit_data: Dictionary) -> void:
	var target: Node = hit_data.get("target_enemy")
	if target == null or not is_instance_valid(target):
		return
	var data := hit_data.get("artifact_data") as ArtifactData
	var profile := HitFeedbackProfile.resolve(str(hit_data.get("profile_name", "medium")), data)
	_apply_special_overrides(profile, data)
	var attack_id: Variant = hit_data.get("attack_instance_id", "")
	var continuous_visual_allowed := _allow_continuous_visual(hit_data)
	var main_effect := true
	if str(profile.get("name", "")) == "explosion":
		main_effect = _claim_once(_main_effect_attack_ids, attack_id)

	# Required ordering: flash, squash, effect, number, sound, knockback, shake, stop, death.
	if continuous_visual_allowed and target.has_method("play_hit_flash"):
		target.call("play_hit_flash", float(profile.get("flash_duration", 0.0)))
	if target.has_method("play_hit_squash") and float(profile.get("squash_duration", 0.0)) > 0.0:
		target.call("play_hit_squash", profile.get("squash_scale", Vector2.ONE), float(profile.get("squash_duration", 0.0)))
	if continuous_visual_allowed:
		HitEffectPool.show_hit(hit_data, profile, main_effect)
	DamageNumberPool.show_damage(hit_data, profile)
	_play_hit_sound(hit_data, profile)
	_apply_knockback(hit_data, profile)
	ScreenShakeManager.request_shake(attack_id, float(profile.get("screen_shake_strength", 0.0)), float(profile.get("screen_shake_duration", 0.0)))
	if not bool(hit_data.get("is_continuous", false)) and str(profile.get("name", "")) != "summon":
		HitStopManager.request_hit_stop(attack_id, float(profile.get("hit_stop_seconds", 0.0)))
	if bool(hit_data.get("is_kill", false)):
		HitEffectPool.show_death(hit_data)

func play_area_feedback(source: Node, artifact_data: ArtifactData, attack_source: Node, center: Vector2, attack_instance_id: Variant, profile_name: String = "explosion") -> void:
	var profile := HitFeedbackProfile.resolve(profile_name, artifact_data)
	_apply_special_overrides(profile, artifact_data)
	var hit_data := {
		"attack_source": source,
		"attack_node": attack_source,
		"target_enemy": null,
		"hit_position": center,
		"hit_origin": center,
		"effect_origin": center,
		"actual_damage": 0.0,
		"is_critical": false,
		"is_kill": false,
		"profile_name": profile_name,
		"attack_instance_id": attack_instance_id,
		"is_continuous": false,
		"artifact_data": artifact_data,
	}
	var main_effect := _claim_once(_main_effect_attack_ids, attack_instance_id)
	HitEffectPool.show_hit(hit_data, profile, main_effect)
	_play_hit_sound(hit_data, profile)
	ScreenShakeManager.request_shake(attack_instance_id, float(profile.get("screen_shake_strength", 0.0)), float(profile.get("screen_shake_duration", 0.0)))
	HitStopManager.request_hit_stop(attack_instance_id, float(profile.get("hit_stop_seconds", 0.0)))

func begin_attack(attack_source: Node) -> String:
	_attack_serial += 1
	var source_id := attack_source.get_instance_id() if is_instance_valid(attack_source) else 0
	var attack_id := "%s:%s" % [source_id, _attack_serial]
	if is_instance_valid(attack_source):
		_attack_ids_by_source[source_id] = {"id": attack_id, "time": Time.get_ticks_msec()}
	return attack_id

func _attack_id_for(attack_source: Node) -> String:
	var now := Time.get_ticks_msec()
	if not is_instance_valid(attack_source):
		_attack_serial += 1
		return "detached:%s" % _attack_serial
	var source_id := attack_source.get_instance_id()
	if _attack_ids_by_source.has(source_id):
		var entry: Dictionary = _attack_ids_by_source[source_id]
		if now - int(entry.get("time", 0)) <= 60:
			return str(entry.get("id", ""))
	return begin_attack(attack_source)

func _profile_for(data: ArtifactData) -> String:
	if data == null:
		return "medium"
	if not data.hit_feedback_profile.is_empty() and data.hit_feedback_profile != "default":
		return data.hit_feedback_profile
	if PROFILE_BY_ARTIFACT.has(data.id):
		return str(PROFILE_BY_ARTIFACT[data.id])
	if data.attack_template == "summon":
		return "summon"
	return "medium"

func _apply_special_overrides(profile: Dictionary, data: ArtifactData) -> void:
	if data == null or not SPECIAL_SHAKE.has(data.id):
		return
	var special: Vector2 = SPECIAL_SHAKE[data.id]
	if data.screen_shake_strength < 0.0:
		profile["screen_shake_strength"] = special.x
	if data.screen_shake_duration < 0.0:
		profile["screen_shake_duration"] = special.y

func _apply_knockback(hit_data: Dictionary, profile: Dictionary) -> void:
	var target: Node = hit_data.get("target_enemy")
	var force := float(profile.get("knockback_force", 0.0))
	if force <= 0.0 or target == null or not target.has_method("apply_knockback"):
		return
	var hit_position: Vector2 = hit_data.get("hit_position", Vector2.ZERO)
	var hit_origin: Vector2 = hit_data.get("hit_origin", hit_position)
	var direction := hit_origin.direction_to(hit_position)
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var resistance_value = target.get("knockback_resistance")
	var resistance := float(resistance_value) if resistance_value != null else 1.0
	target.call("apply_knockback", direction, force * resistance)

func _play_hit_sound(hit_data: Dictionary, profile: Dictionary) -> void:
	var sound_id := str(profile.get("hit_sound_id", ""))
	if sound_id.is_empty():
		return
	var profile_name := str(profile.get("name", "medium"))
	var attack_id: Variant = hit_data.get("attack_instance_id", "")
	if profile_name == "explosion" and not _claim_once(_explosion_sound_attack_ids, attack_id):
		return
	var interval_msec := 50
	if bool(hit_data.get("is_continuous", false)):
		interval_msec = 250
	elif profile_name == "summon":
		interval_msec = 100
	var now := Time.get_ticks_msec()
	if now - int(_sound_last_played_msec.get(sound_id, -100000)) < interval_msec:
		return
	_sound_last_played_msec[sound_id] = now
	var path := str(SOUND_PATHS.get(sound_id, sound_id))
	if not ResourceLoader.exists(path):
		return
	var stream := load(path) as AudioStream
	if stream == null or _audio_players.is_empty():
		return
	var player := _audio_players[_audio_index % _audio_players.size()]
	_audio_index += 1
	player.stream = stream
	player.play()

func _claim_once(registry: Dictionary, attack_id: Variant) -> bool:
	var key := str(attack_id)
	var now := Time.get_ticks_msec()
	for old_key in registry.keys():
		if now - int(registry[old_key]) > 2000:
			registry.erase(old_key)
	if registry.has(key):
		return false
	registry[key] = now
	return true

func _allow_continuous_visual(hit_data: Dictionary) -> bool:
	if not bool(hit_data.get("is_continuous", false)):
		return true
	var target: Node = hit_data.get("target_enemy")
	var key := target.get_instance_id() if is_instance_valid(target) else 0
	var now := Time.get_ticks_msec()
	if now - int(_continuous_visual_last_msec.get(key, -100000)) < 120:
		return false
	_continuous_visual_last_msec[key] = now
	return true

func _read_hp(target: Node) -> float:
	var value = target.get("hp")
	return float(value) if value != null else -1.0
