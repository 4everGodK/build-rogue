extends Node2D
class_name ArenaMap

@export var arena_size: Vector2 = Vector2(2000.0, 1200.0)
@export var grid_size: float = 100.0
@export var obstacle_color: Color = Color(0.18, 0.2, 0.24, 1.0)

func _ready() -> void:
	_spawn_obstacles()
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
