extends Area2D
class_name HealingEssence

var tracker = null
var collected: bool = false
var visual_root: Node2D

func setup(next_tracker) -> void:
	tracker = next_tracker

func _ready() -> void:
	add_to_group("healing_essences")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)
	_build_visual()
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if visual_root != null:
		visual_root.position.y = sin(Time.get_ticks_msec() * 0.004) * 4.0
		visual_root.rotation += delta * 0.7

func _on_body_entered(body: Node) -> void:
	if collected or not body is Player:
		return
	var healed: float = tracker.try_consume(body) if tracker != null else 0.0
	if healed <= 0.0:
		return
	collected = true
	monitoring = false
	_play_collect(body as Node2D)

func _build_visual() -> void:
	visual_root = Node2D.new()
	add_child(visual_root)
	var glow := Polygon2D.new()
	glow.color = Color(0.2, 1.0, 0.68, 0.35)
	glow.polygon = _circle_points(13.0, 24)
	visual_root.add_child(glow)
	var core := Polygon2D.new()
	core.color = Color(0.75, 1.0, 0.82, 0.95)
	core.polygon = _circle_points(6.5, 18)
	visual_root.add_child(core)

func _play_collect(target: Node2D) -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_position", target.global_position, 0.16)
	tween.parallel().tween_property(self, "scale", Vector2(0.2, 0.2), 0.16)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)

func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
