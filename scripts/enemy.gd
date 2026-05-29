extends CharacterBody2D
class_name Enemy

signal died(gold_reward: int)

@export var max_hp: float = 20.0
@export var move_speed: float = 80.0
@export var contact_damage: int = 8
@export var gold_reward: int = 2

var hp: float = max_hp
var player: Player
var flash_time: float = 0.0

@onready var visual: Polygon2D = $Visual

func _physics_process(delta: float) -> void:
	if is_instance_valid(player):
		velocity = global_position.direction_to(player.global_position) * move_speed
		move_and_slide()
		if global_position.distance_to(player.global_position) <= 24.0:
			player.take_damage(contact_damage)

	if flash_time > 0.0:
		flash_time -= delta
		visual.modulate = Color(1.0, 0.45, 0.45)
	else:
		visual.modulate = Color.WHITE

func setup(target_player: Player) -> void:
	player = target_player

func take_damage(amount: float) -> void:
	hp -= amount
	flash_time = 0.08
	if hp <= 0.0:
		died.emit(gold_reward)
		queue_free()

func _on_contact_area_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(contact_damage)
