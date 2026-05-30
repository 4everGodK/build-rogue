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
var poison_stacks: Array[Dictionary] = []

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

	_process_poison(delta)

func setup(target_player: Player) -> void:
	player = target_player

func take_damage(amount: float) -> bool:
	hp -= amount
	flash_time = 0.08
	if hp <= 0.0:
		died.emit(gold_reward)
		queue_free()
		return true
	return false

func apply_poison(dps: float, duration: float, can_stack: bool) -> void:
	if dps <= 0.0 or duration <= 0.0:
		return
	if not can_stack:
		poison_stacks.clear()
	poison_stacks.append({"dps": dps, "time_left": duration})

func get_hp_ratio() -> float:
	return hp / max_hp

func _process_poison(delta: float) -> void:
	if poison_stacks.is_empty():
		return

	var total_damage: float = 0.0
	for index in range(poison_stacks.size() - 1, -1, -1):
		var poison: Dictionary = poison_stacks[index]
		total_damage += float(poison.get("dps", 0.0)) * delta
		poison["time_left"] = float(poison.get("time_left", 0.0)) - delta
		if float(poison["time_left"]) <= 0.0:
			poison_stacks.remove_at(index)
		else:
			poison_stacks[index] = poison

	if total_damage > 0.0:
		take_damage(total_damage)

func _on_contact_area_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(contact_damage)
