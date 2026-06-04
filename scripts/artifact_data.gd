extends Resource
class_name ArtifactData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_enum("剑修", "法修", "体修", "阵法", "召唤", "魔修") var system_tag: String = "剑修"
@export_enum("金", "木", "水", "火", "土", "风", "雷", "毒", "暗") var attribute_tag: String = "金"
@export_enum("melee", "projectile", "orbit", "beam", "formation", "summon") var attack_template: String = "projectile"

@export var damage: float = 10.0
@export var cooldown: float = 1.0
@export var range: float = 320.0
@export var radius: float = 32.0
@export var projectile_speed: float = 420.0
@export var projectile_pierce: int = 0
@export var projectile_bounce: int = 0
@export var duration: float = 0.16
@export var tick_interval: float = 0.5
@export var count: int = 1
@export var life_cost_percent: float = 0.0

# Optional parameters already useful to the first templates.
@export var rotation_speed: float = 3.0
@export var hit_interval: float = 0.4
@export var explosion_radius: float = 0.0
@export var visual_color: Color = Color.WHITE
@export var price: int = 6

func to_offer() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"tags": [system_tag, attribute_tag],
		"attack_template": attack_template,
		"level": 1,
		"price": price,
	}
