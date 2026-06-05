extends Resource
class_name ArtifactData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_enum("剑修", "法修", "体修", "阵法", "召唤", "魔修") var system_tag: String = "剑修"
@export_enum("金", "木", "水", "火", "土", "风", "雷", "毒", "暗") var attribute_tag: String = "金"
@export_enum("melee", "projectile", "orbit", "beam", "formation", "line_delayed", "summon") var attack_template: String = "projectile"
@export_enum("slash", "stab", "circle", "line", "projectile", "beam", "aura") var attack_shape: String = "projectile"
@export_enum("damage", "slow", "attack_speed", "heal", "shield", "damage_reduction") var effect_type: String = "damage"

@export var damage: float = 10.0
@export var cooldown: float = 1.0
@export var range: float = 320.0
@export var radius: float = 32.0
@export var width: float = 20.0
@export var length: float = 80.0
@export var projectile_speed: float = 420.0
@export var projectile_pierce: int = 0
@export var projectile_bounce: int = 0
@export var bounce_count: int = 0
@export var bounce_range: float = 150.0
@export var duration: float = 0.16
@export var tick_interval: float = 0.5
@export var count: int = 1
@export var max_targets: int = 0
@export var life_cost_percent: float = 0.0
@export var rotation_speed: float = 3.0
@export var hit_interval: float = 0.4
@export var explosion_radius: float = 0.0
@export var debuff_duration: float = 0.0
@export var damage_reduction_percent: float = 0.0
@export var slow_percent: float = 0.0
@export var attack_speed_bonus: float = 0.0
@export var heal_amount: float = 0.0
@export var shield_amount: float = 0.0
@export var shield_max: float = 0.0
@export var delayed_strike_count: int = 3
@export var delayed_strike_delay: float = 0.3
@export var delayed_strike_interval: float = 0.15
@export var visual_color: Color = Color.WHITE
@export var price: int = 6

func to_offer() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"icon": icon,
		"system_tag": system_tag,
		"attribute_tag": attribute_tag,
		"tags": [system_tag, attribute_tag],
		"attack_template": attack_template,
		"level": 1,
		"price": price,
	}
