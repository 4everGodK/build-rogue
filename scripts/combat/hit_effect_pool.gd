extends Node2D

const EFFECT_SCRIPT := preload("res://scripts/combat/pooled_hit_effect.gd")
const INITIAL_POOL_SIZE := 40

var available: Array[Node2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in INITIAL_POOL_SIZE:
		available.append(_create_effect(index))

func show_hit(hit_data: Dictionary, profile: Dictionary, spawn_main_effect: bool) -> void:
	var profile_name := str(profile.get("name", "medium"))
	var effect_scale := maxf(0.1, float(profile.get("hit_effect_scale", 1.0)))
	var hit_position: Vector2 = hit_data.get("hit_position", Vector2.ZERO)
	var origin: Vector2 = hit_data.get("hit_origin", hit_position)
	var direction := origin.direction_to(hit_position)
	if profile_name == "explosion":
		_show(hit_position, "light", 9.0 * effect_scale, direction, Color(1.0, 0.78, 0.34, 0.9))
		if spawn_main_effect:
			_show(hit_data.get("effect_origin", origin), "explosion", 34.0 * effect_scale, direction, Color(1.0, 0.48, 0.16, 0.82))
		return
	var radius := 10.0
	match profile_name:
		"medium": radius = 20.0
		"heavy": radius = 34.0
		"continuous": radius = 7.0
		"summon": radius = 14.0
	_show(hit_position, profile_name, radius * effect_scale, direction, _color_for(profile_name))

func show_death(hit_data: Dictionary) -> void:
	_show(hit_data.get("hit_position", Vector2.ZERO), "heavy", 26.0, Vector2.UP, Color(1.0, 0.92, 0.58, 0.9))

func show_cosmetic(position: Vector2, profile_name: String = "light", effect_scale: float = 1.0, direction: Vector2 = Vector2.RIGHT) -> void:
	var radius := 10.0
	match profile_name:
		"medium": radius = 20.0
		"heavy", "explosion": radius = 34.0
		"continuous": radius = 7.0
		"summon": radius = 14.0
	_show(position, profile_name, radius * maxf(0.1, effect_scale), direction, _color_for(profile_name))

func _show(position: Vector2, kind: String, radius: float, direction: Vector2, color: Color) -> void:
	var effect := _acquire()
	effect.call("play", position, kind, radius, direction, color)

func _create_effect(index: int) -> Node2D:
	var effect: Node2D = EFFECT_SCRIPT.new()
	effect.name = "HitEffect%d" % index
	effect.connect("released", _release)
	add_child(effect)
	return effect

func _acquire() -> Node2D:
	if available.is_empty():
		return _create_effect(get_child_count())
	return available.pop_back()

func _release(effect: Node2D) -> void:
	if not available.has(effect):
		available.append(effect)

func _color_for(profile_name: String) -> Color:
	match profile_name:
		"continuous": return Color(0.48, 0.95, 0.32, 0.78)
		"heavy": return Color(1.0, 0.72, 0.28, 0.92)
		"summon": return Color(0.66, 0.88, 1.0, 0.82)
		_: return Color(0.94, 0.98, 1.0, 0.9)
