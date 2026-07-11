extends SceneTree

func _initialize() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var scene := Node.new()
	root.add_child(scene)
	current_scene = scene
	var manager: Node = load("res://scripts/combat/hit_stop_manager.gd").new()
	scene.add_child(manager)
	var combat_node := Area2D.new()
	combat_node.add_to_group("combat_logic")
	scene.add_child(combat_node)
	manager.request_hit_stop("freed-object-regression", 0.01)
	combat_node.queue_free()
	await create_timer(0.05).timeout
	await process_frame
	print("HIT_STOP_FREED_OBJECT_TEST_OK")
	quit()
