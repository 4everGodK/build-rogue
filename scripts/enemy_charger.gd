extends Enemy
class_name EnemyCharger

enum State { CHASE, WINDUP, DASH, RECOVERY }
@export var trigger_distance := 230.0
@export var windup_time := .85
@export var dash_speed := 260.0
@export var dash_duration := .62
@export var recovery_time := 1.0
@export var dash_cooldown := 5.0
@export var dash_damage := 9
@export var simultaneous_charge_cap := 3

var state := State.CHASE
var state_timer := 1.5
var cooldown := 1.5
var locked_direction := Vector2.RIGHT
var dash_hit := false
var warning_line: Line2D

func _process_movement_behavior(delta: float) -> void:
	cooldown -= delta
	state_timer -= delta
	var target := _current_target()
	if not is_instance_valid(target): return
	match state:
		State.CHASE:
			_chase(delta, target)
			if cooldown <= 0.0 and global_position.distance_to(target.global_position) <= trigger_distance and get_tree().get_nodes_in_group("charging_enemies").size() < simultaneous_charge_cap: _start_windup(target)
		State.WINDUP:
			velocity = Vector2.ZERO
			move_and_slide()
			if state_timer <= 0.0: _start_dash()
		State.DASH:
			velocity = locked_direction * dash_speed + knockback_velocity
			move_and_slide()
			clamp_to_arena()
			if not dash_hit and global_position.distance_to(target.global_position) <= contact_radius + 10.0:
				target.take_damage(dash_damage)
				dash_hit = true
			if state_timer <= 0.0: _start_recovery()
		State.RECOVERY:
			velocity = Vector2.ZERO
			move_and_slide()
			if state_timer <= 0.0:
				state = State.CHASE
				cooldown = dash_cooldown
				visual.modulate = Color.WHITE

func _chase(delta: float, target: Node2D) -> void:
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * move_speed * _current_speed_multiplier() + knockback_velocity
	move_and_slide()
	clamp_to_arena()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	if global_position.distance_to(target.global_position) <= contact_radius: _try_contact_damage(target)

func _start_windup(target: Node2D) -> void:
	state = State.WINDUP
	add_to_group("charging_enemies")
	state_timer = windup_time
	locked_direction = global_position.direction_to(target.global_position)
	if locked_direction == Vector2.ZERO: locked_direction = Vector2.RIGHT
	visual.modulate = Color(1.7, .58, .22, 1.0)
	warning_line = Line2D.new()
	warning_line.width = 5.0
	warning_line.default_color = Color(1.0, .18, .05, .55)
	warning_line.points = PackedVector2Array([Vector2.ZERO, locked_direction * 360.0])
	add_child(warning_line)

func _start_dash() -> void:
	if is_instance_valid(warning_line): warning_line.queue_free()
	state = State.DASH
	state_timer = dash_duration
	dash_hit = false

func _start_recovery() -> void:
	remove_from_group("charging_enemies")
	state = State.RECOVERY
	state_timer = recovery_time
	visual.modulate = Color(.55, .55, .55, 1.0)

func _apply_special_damage_scaling(multiplier: float) -> void:
	dash_damage = maxi(1, int(ceil(float(dash_damage) * multiplier)))
