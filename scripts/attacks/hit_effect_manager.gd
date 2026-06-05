extends RefCounted
class_name HitEffectManager

static func spawn_hit(tree: SceneTree, position: Vector2, kind: String = "flash", direction: Vector2 = Vector2.RIGHT, radius: float = 18.0) -> void:
	if tree == null or tree.current_scene == null:
		return
	match kind:
		"fire":
			_spawn_ring(tree, position, Color(1.0, 0.38, 0.05, 0.55), radius, radius * 2.3, 0.18)
			_spawn_sparks(tree, position, Color(1.0, 0.62, 0.12, 0.85), 8, radius * 0.9)
		"lightning":
			_spawn_flash(tree, position, Color(0.82, 0.95, 1.0, 0.95), radius * 0.8, 0.12)
			_spawn_zap(tree, position, direction, Color(0.65, 0.95, 1.0, 0.95), radius * 2.0)
		"poison":
			_spawn_splash(tree, position, Color(0.35, 1.0, 0.18, 0.75), radius, 7)
		"ink":
			_spawn_splash(tree, position, Color(0.02, 0.02, 0.025, 0.85), radius * 1.2, 9)
		"sound":
			_spawn_ring(tree, position, Color(0.62, 1.0, 0.88, 0.52), radius * 0.6, radius * 2.0, 0.18)
			_spawn_ring(tree, position, Color(0.62, 1.0, 0.88, 0.24), radius * 1.0, radius * 2.8, 0.22)
		"coin":
			_spawn_flash(tree, position, Color(1.0, 0.82, 0.25, 0.95), radius, 0.12)
			_spawn_sparks(tree, position, Color(1.0, 0.82, 0.25, 0.9), 6, radius)
		"sword":
			_spawn_flash(tree, position, Color(0.92, 0.98, 1.0, 0.95), radius, 0.12)
			_spawn_arc(tree, position, direction, Color(0.85, 0.95, 1.0, 0.7), radius * 1.4)
		"blood":
			_spawn_arc(tree, position, direction, Color(0.95, 0.03, 0.08, 0.75), radius * 1.5)
			_spawn_splash(tree, position, Color(0.78, 0.0, 0.08, 0.65), radius, 5)
		"shield":
			_spawn_ring(tree, position, Color(1.0, 0.84, 0.22, 0.55), radius, radius * 1.9, 0.22)
		_:
			_spawn_flash(tree, position, Color(1.0, 1.0, 1.0, 0.85), radius, 0.12)

static func spawn_coin_path(tree: SceneTree, from: Vector2, to: Vector2) -> void:
	if tree == null or tree.current_scene == null:
		return
	var line := Line2D.new()
	line.width = 3.0
	line.default_color = Color(1.0, 0.78, 0.18, 0.55)
	line.points = PackedVector2Array([from, to])
	tree.current_scene.add_child(line)
	var tween := tree.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.16)
	tween.tween_callback(line.queue_free)

static func _spawn_flash(tree: SceneTree, position: Vector2, color: Color, radius: float, duration: float) -> void:
	var flash := Polygon2D.new()
	flash.polygon = _circle_points(radius, 18)
	flash.color = color
	flash.global_position = position
	tree.current_scene.add_child(flash)
	var tween := tree.create_tween()
	tween.tween_property(flash, "scale", Vector2(1.8, 1.8), duration)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, duration)
	tween.tween_callback(flash.queue_free)

static func _spawn_ring(tree: SceneTree, position: Vector2, color: Color, start_radius: float, end_radius: float, duration: float) -> void:
	var ring := Line2D.new()
	ring.width = 5.0
	ring.default_color = color
	ring.closed = true
	ring.points = _circle_points(start_radius, 40)
	ring.global_position = position
	tree.current_scene.add_child(ring)
	var tween := tree.create_tween()
	ring.scale = Vector2.ONE
	tween.tween_property(ring, "scale", Vector2.ONE * (end_radius / maxf(1.0, start_radius)), duration)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, duration)
	tween.tween_callback(ring.queue_free)

static func _spawn_sparks(tree: SceneTree, position: Vector2, color: Color, count: int, length: float) -> void:
	for index in count:
		var angle := TAU * float(index) / float(count)
		var line := Line2D.new()
		line.width = 2.5
		line.default_color = color
		line.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * length])
		line.global_position = position
		tree.current_scene.add_child(line)
		var tween := tree.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.14)
		tween.tween_callback(line.queue_free)

static func _spawn_splash(tree: SceneTree, position: Vector2, color: Color, radius: float, count: int) -> void:
	for index in count:
		var dot := Polygon2D.new()
		var dot_radius := radius * randf_range(0.12, 0.28)
		dot.polygon = _circle_points(dot_radius, 10)
		dot.color = color
		dot.global_position = position + Vector2.RIGHT.rotated(TAU * float(index) / float(count)) * randf_range(radius * 0.15, radius * 0.65)
		tree.current_scene.add_child(dot)
		var tween := tree.create_tween()
		tween.tween_property(dot, "scale", Vector2(1.8, 1.8), 0.15)
		tween.parallel().tween_property(dot, "modulate:a", 0.0, 0.15)
		tween.tween_callback(dot.queue_free)

static func _spawn_zap(tree: SceneTree, position: Vector2, direction: Vector2, color: Color, length: float) -> void:
	var line := Line2D.new()
	line.width = 4.0
	line.default_color = color
	var right := direction.normalized()
	if right == Vector2.ZERO:
		right = Vector2.RIGHT
	var normal := right.orthogonal()
	line.points = PackedVector2Array([
		-right * length * 0.45,
		-right * length * 0.2 + normal * 6.0,
		right * length * 0.08 - normal * 7.0,
		right * length * 0.42,
	])
	line.global_position = position
	tree.current_scene.add_child(line)
	var tween := tree.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

static func _spawn_arc(tree: SceneTree, position: Vector2, direction: Vector2, color: Color, radius: float) -> void:
	var arc := Line2D.new()
	arc.width = 5.0
	arc.default_color = color
	var points := PackedVector2Array()
	for index in 8:
		var t := -0.65 + 1.3 * float(index) / 7.0
		points.append(Vector2(cos(t), sin(t)) * radius)
	arc.points = points
	arc.global_position = position
	arc.rotation = direction.angle()
	tree.current_scene.add_child(arc)
	var tween := tree.create_tween()
	tween.tween_property(arc, "modulate:a", 0.0, 0.15)
	tween.tween_callback(arc.queue_free)

static func _circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in segments:
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
