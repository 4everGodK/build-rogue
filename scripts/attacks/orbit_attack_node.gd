extends Node2D
class_name OrbitAttackNode

var player: Node2D
var data: ArtifactData
var angle: float = 0.0
var orbiters: Array[Area2D] = []
var last_hits: Dictionary = {}

func setup(owner_player: Node2D, artifact_data: ArtifactData) -> void:
	player = owner_player
	data = artifact_data
	global_position = player.global_position
	z_index = 1
	for index in maxi(1, data.count):
		var orbiter := Area2D.new()
		orbiter.collision_layer = 0
		orbiter.collision_mask = 2
		orbiter.monitoring = true
		var shape := CircleShape2D.new()
		shape.radius = 7.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		orbiter.add_child(collision)
		var visual := ArtifactVisuals.make_orbiter_visual(data)
		orbiter.add_child(visual)
		add_child(orbiter)
		orbiters.append(orbiter)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		queue_free()
		return
	global_position = player.global_position
	angle += data.rotation_speed * delta
	for index in orbiters.size():
		var orbiter := orbiters[index]
		var orbit_angle := angle + TAU * float(index) / float(orbiters.size())
		orbiter.position = Vector2(cos(orbit_angle), sin(orbit_angle)) * data.radius
		orbiter.rotation = orbit_angle + PI * 0.5
		for body in orbiter.get_overlapping_bodies():
			_try_hit(body, orbiter)

func _try_hit(body: Node, orbiter: Area2D) -> void:
	if not body.has_method("take_damage"):
		return
	var key := "%s:%s" % [orbiter.get_instance_id(), body.get_instance_id()]
	var now := Time.get_ticks_msec() * 0.001
	if now - float(last_hits.get(key, -INF)) < data.hit_interval:
		return
	last_hits[key] = now
	body.call("take_damage", data.damage, player)
	HitEffectManager.spawn_hit(get_tree(), orbiter.global_position, "sword", orbiter.global_transform.x, 14.0)
	_flash_orbiter(orbiter)

func _flash_orbiter(orbiter: Area2D) -> void:
	orbiter.modulate = Color(1.8, 1.8, 1.4, 1.0)
	var tween := get_tree().create_tween()
	tween.tween_property(orbiter, "modulate", Color.WHITE, 0.1)
