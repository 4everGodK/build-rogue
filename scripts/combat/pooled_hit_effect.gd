extends Node2D

signal released(effect)

var active: bool = false
var elapsed: float = 0.0
var lifetime: float = 0.16
var effect_kind: String = "light"
var effect_radius: float = 10.0
var direction: Vector2 = Vector2.RIGHT
var effect_color: Color = Color.WHITE

func _ready() -> void:
	visible = false
	z_as_relative = false
	z_index = 80
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(world_position: Vector2, kind: String, radius: float, next_direction: Vector2, color: Color) -> void:
	active = true
	visible = true
	elapsed = 0.0
	effect_kind = kind
	effect_radius = radius
	direction = next_direction.normalized() if next_direction != Vector2.ZERO else Vector2.RIGHT
	effect_color = color
	global_position = world_position
	scale = Vector2.ONE
	modulate = Color.WHITE
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	var progress := clampf(elapsed / lifetime, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.55, 1.65, progress)
	modulate.a = 1.0 - progress
	if elapsed >= lifetime:
		active = false
		visible = false
		released.emit(self)

func _draw() -> void:
	match effect_kind:
		"heavy", "explosion":
			draw_arc(Vector2.ZERO, effect_radius, 0.0, TAU, 32, effect_color, 3.0)
			for index in 8:
				var ray := Vector2.RIGHT.rotated(TAU * float(index) / 8.0)
				draw_line(ray * effect_radius * 0.35, ray * effect_radius, effect_color, 2.0)
		"medium":
			for index in 6:
				var ray := Vector2.RIGHT.rotated(TAU * float(index) / 6.0)
				draw_line(ray * 2.0, ray * effect_radius, effect_color, 2.0)
		"continuous":
			for index in 3:
				var point := Vector2.RIGHT.rotated(TAU * float(index) / 3.0) * effect_radius * 0.55
				draw_circle(point, maxf(1.5, effect_radius * 0.16), effect_color)
		_:
			draw_circle(Vector2.ZERO, effect_radius * 0.32, effect_color)
			draw_line(-direction * effect_radius, direction * effect_radius, effect_color, 2.0)
