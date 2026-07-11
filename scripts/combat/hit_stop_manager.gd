extends Node

const MERGE_WINDOW_MSEC := 80
const ATTACK_ID_RETENTION_MSEC := 2000

var seen_attack_ids: Dictionary = {}
var frozen_nodes: Dictionary = {}
var stop_ends_at_msec: int = 0
var merge_window_ends_at_msec: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func request_hit_stop(attack_instance_id: Variant, duration: float) -> void:
	if duration <= 0.0:
		return
	duration = minf(duration, 0.05)
	var key := str(attack_instance_id)
	var now := Time.get_ticks_msec()
	if seen_attack_ids.has(key):
		return
	seen_attack_ids[key] = now
	_cleanup_seen(now)
	var requested_end := now + int(ceil(duration * 1000.0))
	if now <= merge_window_ends_at_msec:
		stop_ends_at_msec = maxi(stop_ends_at_msec, requested_end)
	else:
		merge_window_ends_at_msec = now + MERGE_WINDOW_MSEC
		stop_ends_at_msec = requested_end
	if frozen_nodes.is_empty():
		_freeze_combat_logic()

func _process(_delta: float) -> void:
	if not frozen_nodes.is_empty() and Time.get_ticks_msec() >= stop_ends_at_msec:
		_restore_combat_logic()

func _freeze_combat_logic() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	_collect_and_freeze(scene)

func _collect_and_freeze(node: Node) -> void:
	if _is_combat_logic(node):
		var instance_id := node.get_instance_id()
		if not frozen_nodes.has(instance_id):
			frozen_nodes[instance_id] = {
				"node_ref": weakref(node),
				"process_mode": node.process_mode,
			}
		node.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		return
	for child in node.get_children():
		_collect_and_freeze(child)

func _is_combat_logic(node: Node) -> bool:
	if node.is_in_group("player") or node.is_in_group("enemies") or node.is_in_group("summons") or node.is_in_group("combat_logic"):
		return true
	var script := node.get_script() as Script
	return script != null and script.resource_path.begins_with("res://scripts/attacks/")

func _restore_combat_logic() -> void:
	for entry_value in frozen_nodes.values():
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var node_ref: Variant = entry.get("node_ref")
		if node_ref == null or not node_ref.has_method("get_ref"):
			continue
		var raw_node: Variant = node_ref.get_ref()
		if not is_instance_valid(raw_node) or not raw_node is Node:
			continue
		var node := raw_node as Node
		node.set_deferred("process_mode", int(entry.get("process_mode", Node.PROCESS_MODE_INHERIT)))
	frozen_nodes.clear()

func _cleanup_seen(now: int) -> void:
	for key in seen_attack_ids.keys():
		if now - int(seen_attack_ids[key]) > ATTACK_ID_RETENTION_MSEC:
			seen_attack_ids.erase(key)
