extends Node

const ATTACK_ID_RETENTION_MSEC := 2000

var seen_attack_ids: Dictionary = {}
var camera: Camera2D
var base_offset: Vector2 = Vector2.ZERO
var strength: float = 0.0
var duration: float = 0.0
var time_left: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func request_shake(attack_instance_id: Variant, next_strength: float, next_duration: float) -> void:
	if next_strength <= 0.0 or next_duration <= 0.0:
		return
	var key := str(attack_instance_id)
	var now := Time.get_ticks_msec()
	if seen_attack_ids.has(key):
		return
	seen_attack_ids[key] = now
	_cleanup_seen(now)
	_resolve_camera()
	if camera == null:
		return
	if time_left <= 0.0:
		base_offset = camera.offset
	strength = maxf(strength, next_strength)
	duration = maxf(duration, next_duration)
	time_left = maxf(time_left, next_duration)

func _process(delta: float) -> void:
	if time_left <= 0.0:
		return
	if not is_instance_valid(camera):
		_resolve_camera()
	if camera == null:
		time_left = 0.0
		return
	time_left = maxf(0.0, time_left - delta)
	var falloff := time_left / maxf(0.001, duration)
	camera.offset = base_offset + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff
	if time_left <= 0.0:
		camera.offset = base_offset
		strength = 0.0
		duration = 0.0

func _resolve_camera() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		camera = null
		return
	camera = (players[0] as Node).get_node_or_null("Camera2D") as Camera2D

func _cleanup_seen(now: int) -> void:
	for key in seen_attack_ids.keys():
		if now - int(seen_attack_ids[key]) > ATTACK_ID_RETENTION_MSEC:
			seen_attack_ids.erase(key)
