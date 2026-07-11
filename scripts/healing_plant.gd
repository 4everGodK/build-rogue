extends StaticBody2D
class_name HealingPlant

signal plant_destroyed(plant)

const HealingEssenceScript := preload("res://scripts/healing_essence.gd")

var max_hp: float = 35.0
var hp: float = 35.0
var dying: bool = false
var tracker = null
var plant_radius: float = 16.0
var visual_root: Node2D

func setup(config: Dictionary, next_tracker) -> void:
	max_hp = maxf(1.0, float(config.get("max_hp", max_hp)))
	hp = max_hp
	plant_radius = maxf(6.0, float(config.get("plant_radius", plant_radius)))
	tracker = next_tracker

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("healing_plants")
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = plant_radius
	shape.shape = circle
	add_child(shape)
	_build_visual()

func take_damage(amount: float, _source = null) -> bool:
	if dying or amount <= 0.0:
		return false
	hp -= amount
	if hp <= 0.0:
		_destroy()
		return true
	return false

func play_hit_flash(duration: float) -> void:
	if visual_root == null or duration <= 0.0:
		return
	visual_root.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := get_tree().create_tween()
	tween.tween_property(visual_root, "modulate", Color.WHITE, duration)

func play_hit_squash(target_scale: Vector2, duration: float) -> void:
	if visual_root == null or duration <= 0.0:
		return
	visual_root.scale = target_scale
	var tween := get_tree().create_tween()
	tween.tween_property(visual_root, "scale", Vector2.ONE, duration)

func apply_knockback(_direction: Vector2, _force: float) -> void:
	pass

func get_hp_ratio() -> float:
	return clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)

func _build_visual() -> void:
	visual_root = Node2D.new()
	add_child(visual_root)
	var glow := Polygon2D.new()
	glow.color = Color(0.06, 0.95, 0.48, 0.18)
	glow.polygon = _circle_points(plant_radius * 1.65, 28)
	visual_root.add_child(glow)
	for index in 5:
		var blade := Polygon2D.new()
		var height: float = plant_radius * randf_range(1.0, 1.45)
		var width: float = plant_radius * 0.28
		blade.polygon = PackedVector2Array([
			Vector2(-width, 0.0),
			Vector2(0.0, -height),
			Vector2(width, 0.0),
		])
		blade.position = Vector2(randf_range(-5.0, 5.0), plant_radius * 0.35)
		blade.rotation = deg_to_rad(lerpf(-34.0, 34.0, float(index) / 4.0))
		blade.color = Color(0.1, 0.86, 0.38, 0.92)
		visual_root.add_child(blade)
	var cap := Polygon2D.new()
	cap.position = Vector2(0.0, -plant_radius * 0.65)
	cap.color = Color(0.35, 1.0, 0.66, 0.9)
	cap.polygon = _circle_points(plant_radius * 0.55, 16)
	visual_root.add_child(cap)

func _flash_hit() -> void:
	if visual_root == null:
		return
	visual_root.modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween := get_tree().create_tween()
	tween.tween_property(visual_root, "position:x", randf_range(-3.0, 3.0), 0.035)
	tween.tween_property(visual_root, "position:x", 0.0, 0.035)
	tween.parallel().tween_property(visual_root, "modulate", Color.WHITE, 0.12)

func _destroy() -> void:
	if dying:
		return
	dying = true
	plant_destroyed.emit(self)
	_spawn_essence()
	_spawn_destroy_vfx()
	var tween := get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.16)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.16)
	tween.tween_callback(queue_free)

func _spawn_essence() -> void:
	var essence := HealingEssenceScript.new()
	essence.global_position = global_position
	essence.call("setup", tracker)
	get_tree().current_scene.add_child(essence)

func _spawn_destroy_vfx() -> void:
	var ring := Line2D.new()
	ring.closed = true
	ring.width = 3.0
	ring.default_color = Color(0.35, 1.0, 0.55, 0.7)
	ring.points = _circle_points(plant_radius * 1.2, 28)
	ring.global_position = global_position
	get_tree().current_scene.add_child(ring)
	var tween := get_tree().create_tween()
	tween.tween_property(ring, "scale", Vector2(2.2, 2.2), 0.26)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.26)
	tween.tween_callback(ring.queue_free)

func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * float(index) / float(count)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
