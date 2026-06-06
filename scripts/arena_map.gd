extends Node2D
class_name ArenaMap

@export var arena_size: Vector2 = Vector2(2000.0, 1200.0)
@export var grid_size: float = 100.0
@export var obstacle_color: Color = Color(0.18, 0.2, 0.24, 1.0)

func _ready() -> void:
	_spawn_obstacles()
	_spawn_decorations()
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-arena_size * 0.5, arena_size)
	draw_rect(rect, Color(0.055, 0.07, 0.09, 1.0), true)
	var grid_color := Color(0.15, 0.18, 0.22, 0.55)
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), grid_color, 1.0)
		x += grid_size
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), grid_color, 1.0)
		y += grid_size

func _spawn_obstacles() -> void:
	var obstacles := [
		Rect2(Vector2(-520, -260), Vector2(150, 60)),
		Rect2(Vector2(350, -180), Vector2(180, 70)),
		Rect2(Vector2(-130, 230), Vector2(220, 55)),
		Rect2(Vector2(650, 250), Vector2(120, 120)),
		Rect2(Vector2(-760, 250), Vector2(120, 120)),
	]
	for rect in obstacles:
		var body := StaticBody2D.new()
		body.collision_layer = 4
		body.collision_mask = 0
		add_child(body)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = rect.size
		shape.position = rect.position + rect.size * 0.5
		shape.shape = rectangle
		body.add_child(shape)
		var visual := Polygon2D.new()
		visual.position = shape.position
		visual.polygon = PackedVector2Array([
			Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
			Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
			rect.size * 0.5,
			Vector2(-rect.size.x * 0.5, rect.size.y * 0.5),
		])
		visual.color = obstacle_color
		body.add_child(visual)

func _spawn_decorations() -> void:
	var stones := [
		Vector2(-760, -420),
		Vector2(-360, 360),
		Vector2(180, -420),
		Vector2(720, -80),
		Vector2(520, 420),
	]
	for position in stones:
		_add_stone(position)

	var trees := [
		Vector2(-880, -120),
		Vector2(-620, 430),
		Vector2(-120, -470),
		Vector2(420, -360),
		Vector2(860, 300),
	]
	for position in trees:
		_add_tree(position)

func _add_stone(position: Vector2) -> void:
	var stone := Polygon2D.new()
	stone.position = position
	stone.polygon = PackedVector2Array([
		Vector2(-18, -10),
		Vector2(-4, -20),
		Vector2(18, -12),
		Vector2(22, 8),
		Vector2(6, 20),
		Vector2(-20, 12),
	])
	stone.color = Color(0.26, 0.29, 0.32, 1.0)
	add_child(stone)

func _add_tree(position: Vector2) -> void:
	var trunk := Polygon2D.new()
	trunk.position = position + Vector2(0, 16)
	trunk.polygon = PackedVector2Array([
		Vector2(-5, -14),
		Vector2(5, -14),
		Vector2(7, 16),
		Vector2(-7, 16),
	])
	trunk.color = Color(0.28, 0.16, 0.08, 1.0)
	add_child(trunk)

	var crown := Polygon2D.new()
	crown.position = position
	var points := PackedVector2Array()
	for index in 18:
		var angle := TAU * float(index) / 18.0
		var radius: float = 26.0 if index % 2 == 0 else 20.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	crown.polygon = points
	crown.color = Color(0.08, 0.28, 0.16, 1.0)
	add_child(crown)
