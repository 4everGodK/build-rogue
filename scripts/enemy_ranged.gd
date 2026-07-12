extends Enemy
class_name EnemyRanged

@export var ideal_distance := 270.0
@export var retreat_distance := 185.0
@export var approach_distance := 350.0
@export var attack_interval := 3.0
@export var windup_time := 0.5
@export var projectile_speed := 300.0
@export var projectile_damage := 7
@export var global_projectile_cap := 18
@export var first_attack_grace := 1.4

var attack_timer := first_attack_grace
var winding_up := false
var locked_target := Vector2.ZERO

func _process_movement_behavior(delta: float) -> void:
	attack_timer -= delta
	var target := _current_target()
	if not is_instance_valid(target): return
	if winding_up:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var distance := global_position.distance_to(target.global_position)
	var direction := global_position.direction_to(target.global_position)
	if distance > approach_distance:
		velocity = direction * move_speed * _current_speed_multiplier()
	elif distance < retreat_distance:
		velocity = -direction * move_speed * _current_speed_multiplier()
	else:
		velocity = direction.rotated(PI * .5) * move_speed * .32 * _current_speed_multiplier()
	velocity += knockback_velocity
	move_and_slide()
	clamp_to_arena()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
	if distance <= contact_radius: _try_contact_damage(target)
	if attack_timer <= 0.0 and get_tree().get_nodes_in_group("enemy_projectiles").size() < global_projectile_cap:
		_begin_windup(target.global_position)

func _begin_windup(target_position: Vector2) -> void:
	winding_up = true
	locked_target = target_position
	visual.modulate = Color(1.6, .65, .45, 1.0)
	await get_tree().create_timer(windup_time).timeout
	if dying: return
	visual.modulate = Color.WHITE
	_fire()
	winding_up = false
	attack_timer = attack_interval

func _fire() -> void:
	if get_tree().get_nodes_in_group("enemy_projectiles").size() >= global_projectile_cap: return
	var projectile := preload("res://scenes/EnemyProjectile.tscn").instantiate() as EnemyProjectile
	get_tree().current_scene.add_child(projectile)
	projectile.setup(global_position, locked_target, projectile_damage, projectile_speed)

func _apply_special_damage_scaling(multiplier: float) -> void:
	projectile_damage = maxi(1, int(ceil(float(projectile_damage) * multiplier)))
