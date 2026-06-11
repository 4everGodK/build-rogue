extends Resource
class_name ArtifactData

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export_enum("剑修", "法修", "体修", "召唤", "魔修") var system_tag: String = "剑修"
@export_enum("金", "木", "水", "火", "土", "雷", "毒") var attribute_tag: String = "金"
@export_enum("melee", "projectile", "orbit", "beam", "formation", "line_delayed", "summon", "target_aoe", "soul_banner") var attack_template: String = "projectile"
@export_enum("slash", "stab", "circle", "line", "cone", "head_slash", "projectile", "beam", "aura") var attack_shape: String = "projectile"
@export_enum("damage", "slow", "attack_speed", "heal", "shield", "damage_reduction", "counter_damage", "avatar_slam") var effect_type: String = "damage"

@export var damage: float = 10.0
@export var max_hp_damage_coefficient: float = 0.0
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
@export var life_cost_flat: float = 0.0
@export var life_cost_min_hp_ratio: float = 0.0
@export var kill_heal_amount: float = 0.0
@export var rotation_speed: float = 3.0
@export var hit_interval: float = 0.4
@export var explosion_radius: float = 0.0
@export var debuff_duration: float = 0.0
@export var damage_reduction_percent: float = 0.0
@export var slow_percent: float = 0.0
@export var attack_speed_bonus: float = 0.0
@export var poison_dps: float = 0.0
@export var poison_duration: float = 0.0
@export var poison_can_stack: bool = true
@export var knockback_force: float = 0.0
@export var counter_range: float = 0.0
@export var counter_speed: float = 620.0
@export var heal_amount: float = 0.0
@export var shield_amount: float = 0.0
@export var shield_max: float = 0.0
@export var delayed_strike_count: int = 3
@export var delayed_strike_delay: float = 0.3
@export var delayed_strike_interval: float = 0.15
@export var visual_color: Color = Color.WHITE
@export var price: int = 6
@export_enum("凡器", "法器", "灵器", "灵宝", "仙宝") var tier: String = "凡器"
@export var cost: int = 0
@export var cultivation_requirement: String = ""
@export var shop_weight: float = 1.0

const ACTIVE_ATTRIBUTE_TAGS: Array[String] = ["金", "木", "水", "火", "土", "雷", "毒"]
const LEGACY_ATTRIBUTE_FALLBACKS: Dictionary = {
	"风": "雷",
	"暗": "毒",
}

@export_group("Summon")
@export var summon_base_count: int = 0
@export var summon_hp: float = 0.0
@export var summon_attack: float = 0.0
@export var summon_attack_speed: float = 1.0
@export var summon_move_speed: float = 0.0
@export var summon_combat_radius: float = 0.0
@export var summon_return_radius: float = 0.0
@export var summon_respawn_time: float = 0.0
@export var summon_behavior_type: String = ""
@export_multiline var summon_special_effect: String = ""
@export var summon_death_burst: bool = false

@export_group("Star Growth")
@export var star2_damage_mult: float = 0.0
@export var star2_cooldown_mult: float = 0.0
@export var star3_damage_mult: float = 0.0
@export var star3_cooldown_mult: float = 0.0

@export_group("Runtime Upgrade Bonuses")
@export var crit_chance: float = 0.0
@export var crit_damage_mult: float = 2.0
@export var extra_melee_wave_damage_mult: float = 0.0
@export var extra_melee_wave_range: float = 90.0
@export var extra_melee_wave_width: float = 22.0
@export var projectile_return_count: int = 0
@export var poison_explosion_radius: float = 0.0
@export var poison_explosion_damage_mult: float = 0.0
@export var shield_knockback_force: float = 0.0
@export var movement_speed_bonus: float = 0.0
@export var melee_arc_multiplier: float = 1.0

func get_attribute_tag() -> String:
	var normalized: String = str(LEGACY_ATTRIBUTE_FALLBACKS.get(attribute_tag, attribute_tag))
	return normalized if normalized in ACTIVE_ATTRIBUTE_TAGS else "金"

func get_shop_cost() -> int:
	return cost if cost > 0 else CultivationManager.cost_for_tier(tier)

func to_offer() -> Dictionary:
	var normalized_attribute: String = get_attribute_tag()
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"icon": icon,
		"system_tag": system_tag,
		"attribute_tag": normalized_attribute,
		"tags": [system_tag, normalized_attribute],
		"attack_template": attack_template,
		"level": 1,
		"tier": tier,
		"cost": get_shop_cost(),
		"cultivation_requirement": cultivation_requirement,
		"shop_weight": shop_weight,
		"price": get_shop_cost(),
		"damage": damage,
		"max_hp_damage_coefficient": max_hp_damage_coefficient,
		"cooldown": cooldown,
		"range": range,
		"radius": radius,
		"width": width,
		"length": length,
		"projectile_pierce": projectile_pierce,
		"projectile_bounce": projectile_bounce,
		"bounce_count": bounce_count,
		"explosion_radius": explosion_radius,
		"tick_interval": tick_interval,
		"count": count,
		"life_cost_percent": life_cost_percent,
		"life_cost_flat": life_cost_flat,
		"life_cost_min_hp_ratio": life_cost_min_hp_ratio,
		"kill_heal_amount": kill_heal_amount,
		"damage_reduction_percent": damage_reduction_percent,
		"slow_percent": slow_percent,
		"attack_speed_bonus": attack_speed_bonus,
		"poison_dps": poison_dps,
		"poison_duration": poison_duration,
		"knockback_force": knockback_force,
		"counter_range": counter_range,
		"heal_amount": heal_amount,
		"shield_amount": shield_amount,
		"shield_max": shield_max,
		"star2_damage_mult": star2_damage_mult,
		"star2_cooldown_mult": star2_cooldown_mult,
		"star3_damage_mult": star3_damage_mult,
		"star3_cooldown_mult": star3_cooldown_mult,
		"summon_base_count": summon_base_count,
		"summon_hp": summon_hp,
		"summon_attack": summon_attack,
		"summon_attack_speed": summon_attack_speed,
		"summon_move_speed": summon_move_speed,
		"summon_combat_radius": summon_combat_radius,
		"summon_return_radius": summon_return_radius,
		"summon_respawn_time": summon_respawn_time,
		"summon_behavior_type": summon_behavior_type,
		"summon_special_effect": summon_special_effect,
	}
