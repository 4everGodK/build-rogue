extends CanvasLayer

const NUMBER_SCRIPT := preload("res://scripts/combat/pooled_damage_number.gd")
const INITIAL_POOL_SIZE := 32
const DOT_MERGE_WINDOW_MSEC := 120

var available: Array[Label] = []
var active_by_target: Dictionary = {}

func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	for index in INITIAL_POOL_SIZE:
		available.append(_create_number(index))

func show_damage(hit_data: Dictionary, profile: Dictionary) -> void:
	var target: Node = hit_data.get("target_enemy")
	var is_continuous := bool(hit_data.get("is_continuous", false))
	var target_key := target.get_instance_id() if is_instance_valid(target) else 0
	var now := Time.get_ticks_msec()
	if is_continuous and active_by_target.has(target_key):
		var entry: Dictionary = active_by_target[target_key]
		var number: Label = entry.get("number")
		if is_instance_valid(number) and bool(number.get("active")) and now - int(entry.get("time", 0)) <= DOT_MERGE_WINDOW_MSEC:
			number.call("merge_damage", float(hit_data.get("actual_damage", 0.0)), bool(hit_data.get("is_kill", false)))
			entry["time"] = now
			active_by_target[target_key] = entry
			return
	var number := _acquire()
	var style := str(profile.get("damage_number_style", "normal"))
	number.call("play", hit_data.get("hit_position", Vector2.ZERO), float(hit_data.get("actual_damage", 0.0)), style, bool(hit_data.get("is_critical", false)), bool(hit_data.get("is_kill", false)))
	number.set_meta("target_key", target_key)
	if is_continuous:
		active_by_target[target_key] = {"number": number, "time": now}

func _create_number(index: int) -> Label:
	var number: Label = NUMBER_SCRIPT.new()
	number.name = "DamageNumber%d" % index
	number.add_theme_font_size_override("font_size", 18)
	number.connect("released", _release)
	add_child(number)
	return number

func _acquire() -> Label:
	if available.is_empty():
		return _create_number(get_child_count())
	return available.pop_back()

func _release(number: Label) -> void:
	var target_key := int(number.get_meta("target_key", 0))
	if active_by_target.has(target_key) and active_by_target[target_key].get("number") == number:
		active_by_target.erase(target_key)
	number.remove_meta("target_key")
	if not available.has(number):
		available.append(number)
