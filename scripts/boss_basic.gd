extends Enemy
class_name BossBasic

@export var charge_cooldown: float = 4.0
@export var charge_warning_time: float = 0.7
@export var charge_speed: float = 520.0
@export var charge_duration: float = 0.42
@export var bullet_cooldown: float = 3.2
@export var bullet_count: int = 14
@export var bullet_damage: int = 8

var charge_timer: float = 2.0
var bullet_timer: float = 3.0
var charging: bool = false
var charge_time_left: float = 0.0
var charge_direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if dying:
		return
	if charging:
		_process_charge(delta)
		return
	super._physics_process(delta)
	charge_timer -= delta
	bullet_timer -= delta
	if charge_timer <= 0.0:
		charge_timer = charge_cooldown
		_start_charge_warning()
	elif bullet_timer <= 0.0:
		bullet_timer = bullet_cooldown
		_fire_ring()

func _process_charge(delta: float) -> void:
	charge_time_left -= delta
	velocity = charge_direction * charge_speed
	move_and_slide()
	if is_instance_valid(player) and global_position.distance_to(player.global_position) <= contact_radius + 8.0:
		_try_contact_damage(player)
	if charge_time_left <= 0.0:
		charging = false
		velocity = Vector2.ZERO

func _start_charge_warning() -> void:
	if not is_instance_valid(player):
		return
	charge_direction = global_position.direction_to(player.global_position)
	if charge_direction == Vector2.ZERO:
		charge_direction = Vector2.RIGHT
	_show_charge_warning(charge_direction)
	await get_tree().create_timer(charge_warning_time).timeout
	if dying or not is_instance_valid(player):
		return
	charging = true
	charge_time_left = charge_duration

func _show_charge_warning(direction: Vector2) -> void:
	var line := Line2D.new()
	line.add_to_group("boss_projectiles")
	line.width = 8.0
	line.default_color = Color(1.0, 0.12, 0.08, 0.42)
	line.points = PackedVector2Array([global_position, global_position + direction * 520.0])
	get_tree().current_scene.add_child(line)
	var tween := get_tree().create_tween()
	tween.tween_property(line, "modulate:a", 0.0, charge_warning_time)
	tween.tween_callback(line.queue_free)

func _fire_ring() -> void:
	for index in bullet_count:
		var angle := TAU * float(index) / float(bullet_count)
		var bullet := BossBullet.new()
		get_tree().current_scene.add_child(bullet)
		bullet.setup(global_position, Vector2(cos(angle), sin(angle)), bullet_damage)
