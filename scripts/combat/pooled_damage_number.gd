extends Label

signal released(number)

var active: bool = false
var elapsed: float = 0.0
var lifetime: float = 0.35
var velocity: Vector2 = Vector2.ZERO
var amount: float = 0.0
var start_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(world_position: Vector2, damage: float, style: String, is_critical: bool, is_kill: bool) -> void:
	active = true
	visible = true
	elapsed = 0.0
	amount = damage
	text = str(int(ceil(amount)))
	global_position = _world_to_screen(world_position) + Vector2(randf_range(-8.0, 8.0), -26.0)
	var size_multiplier := 1.0
	var color := Color(1.0, 0.93, 0.52, 1.0)
	if style == "healing":
		color = Color(0.38, 1.0, 0.55, 1.0)
	elif style == "continuous":
		size_multiplier = 0.75
		color = Color(0.72, 0.95, 0.48, 1.0)
	elif is_critical:
		size_multiplier = 1.35
		color = Color(1.0, 0.44, 0.2, 1.0)
	if is_kill:
		size_multiplier *= 1.12
	start_scale = Vector2.ONE * size_multiplier
	scale = start_scale
	modulate = color
	velocity = Vector2(randf_range(-12.0, 12.0), -86.0 if is_critical else -64.0)

func merge_damage(extra_damage: float, is_kill: bool) -> void:
	amount += maxf(0.0, extra_damage)
	text = str(int(ceil(amount)))
	elapsed = minf(elapsed, 0.08)
	if is_kill:
		start_scale *= 1.12
		scale = start_scale

func release_now() -> void:
	if not active:
		return
	active = false
	visible = false
	released.emit(self)

func _process(delta: float) -> void:
	if not active:
		return
	elapsed += delta
	global_position += velocity * delta
	velocity.y += 70.0 * delta
	modulate.a = clampf(1.0 - elapsed / lifetime, 0.0, 1.0)
	if elapsed >= lifetime:
		release_now()

func _world_to_screen(world_position: Vector2) -> Vector2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform() * world_position if viewport != null else world_position
