extends Resource
class_name ArtifactData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var attribute_tags: Array[String] = []
@export var type_tags: Array[String] = []
@export_multiline var attack_description: String = ""
@export_enum("projectile", "explosive_projectile", "chain_projectile", "melee", "orbit", "summon", "area", "burst", "returning_projectile", "scatter_projectile", "bounce_projectile", "body_strike") var attack_type: String = "projectile"
@export var base_damage: float = 1.0
@export var base_cooldown: float = 1.0
@export_range(1, 3, 1) var default_level: int = 1
@export_range(1, 3, 1) var default_star: int = 1
@export var prototype_implemented: bool = true
@export_multiline var implementation_note: String = ""

func get_valid_attribute_tags() -> Array[String]:
	return ArtifactTag.filter_attribute_tags(attribute_tags)

func get_valid_type_tags() -> Array[String]:
	return ArtifactTag.filter_type_tags(type_tags)
