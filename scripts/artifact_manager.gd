extends Node
class_name ArtifactManager

signal synergies_updated(result: Dictionary)

@export var held_artifacts: Array[Resource] = []
@export var print_debug_on_ready: bool = true
@export var print_debug_on_update: bool = true

var last_result: Dictionary = {}

func _ready() -> void:
	recalculate(false)
	if print_debug_on_ready:
		print_debug_summary()

func set_held_artifacts(next_artifacts: Array[Resource]) -> void:
	held_artifacts = next_artifacts
	recalculate(print_debug_on_update)

func add_artifact(instance: ArtifactInstance) -> void:
	if instance == null:
		return
	held_artifacts.append(instance)
	recalculate(print_debug_on_update)

func recalculate(should_print: bool = false) -> Dictionary:
	last_result = SynergySystem.calculate(held_artifacts)
	synergies_updated.emit(last_result)
	if should_print and is_inside_tree():
		print_debug_summary()
	return last_result

func print_debug_summary() -> void:
	print(SynergySystem.describe(last_result))
