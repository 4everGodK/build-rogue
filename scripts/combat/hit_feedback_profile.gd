extends Resource
class_name HitFeedbackProfile

const PROFILE_DEFAULTS: Dictionary = {
	"light": {
		"flash_duration": 0.04,
		"squash_scale": Vector2(1.04, 0.96),
		"squash_duration": 0.06,
		"hit_stop_seconds": 0.0,
		"knockback_force": 0.0,
		"screen_shake_strength": 0.0,
		"screen_shake_duration": 0.0,
		"hit_effect_scale": 1.0,
		"hit_sound_id": "hit_light",
		"damage_number_style": "normal",
	},
	"medium": {
		"flash_duration": 0.06,
		"squash_scale": Vector2(1.08, 0.92),
		"squash_duration": 0.08,
		"hit_stop_seconds": 0.0,
		"knockback_force": 35.0,
		"screen_shake_strength": 0.0,
		"screen_shake_duration": 0.0,
		"hit_effect_scale": 1.0,
		"hit_sound_id": "hit_medium",
		"damage_number_style": "normal",
	},
	"heavy": {
		"flash_duration": 0.09,
		"squash_scale": Vector2(1.14, 0.86),
		"squash_duration": 0.12,
		"hit_stop_seconds": 0.0,
		"knockback_force": 90.0,
		"screen_shake_strength": 2.0,
		"screen_shake_duration": 0.08,
		"hit_effect_scale": 1.0,
		"hit_sound_id": "hit_heavy",
		"damage_number_style": "normal",
	},
	"explosion": {
		"flash_duration": 0.08,
		"squash_scale": Vector2(1.10, 0.90),
		"squash_duration": 0.10,
		"hit_stop_seconds": 0.0,
		"knockback_force": 110.0,
		"screen_shake_strength": 3.0,
		"screen_shake_duration": 0.12,
		"hit_effect_scale": 1.0,
		"hit_sound_id": "hit_explosion",
		"damage_number_style": "normal",
	},
	"continuous": {
		"flash_duration": 0.02,
		"squash_scale": Vector2.ONE,
		"squash_duration": 0.0,
		"hit_stop_seconds": 0.0,
		"knockback_force": 0.0,
		"screen_shake_strength": 0.0,
		"screen_shake_duration": 0.0,
		"hit_effect_scale": 0.75,
		"hit_sound_id": "hit_continuous",
		"damage_number_style": "continuous",
	},
	"summon": {
		"flash_duration": 0.04,
		"squash_scale": Vector2(1.03, 0.97),
		"squash_duration": 0.05,
		"hit_stop_seconds": 0.0,
		"knockback_force": 20.0,
		"screen_shake_strength": 0.0,
		"screen_shake_duration": 0.0,
		"hit_effect_scale": 0.75,
		"hit_sound_id": "hit_summon",
		"damage_number_style": "normal",
	},
}

static func resolve(profile_name: String, artifact_data: ArtifactData = null) -> Dictionary:
	var normalized := profile_name if PROFILE_DEFAULTS.has(profile_name) else "medium"
	var result: Dictionary = PROFILE_DEFAULTS[normalized].duplicate(true)
	result["name"] = normalized
	if artifact_data == null:
		return result
	if artifact_data.hit_stop_seconds >= 0.0:
		result["hit_stop_seconds"] = artifact_data.hit_stop_seconds
	if artifact_data.knockback_force >= 0.0:
		result["knockback_force"] = artifact_data.knockback_force
	if artifact_data.screen_shake_strength >= 0.0:
		result["screen_shake_strength"] = artifact_data.screen_shake_strength
	if artifact_data.screen_shake_duration >= 0.0:
		result["screen_shake_duration"] = artifact_data.screen_shake_duration
	if artifact_data.hit_effect_scale >= 0.0:
		result["hit_effect_scale"] = artifact_data.hit_effect_scale
	if not artifact_data.hit_sound_id.is_empty():
		result["hit_sound_id"] = artifact_data.hit_sound_id
	if not artifact_data.damage_number_style.is_empty() and artifact_data.damage_number_style != "default":
		result["damage_number_style"] = artifact_data.damage_number_style
	return result
