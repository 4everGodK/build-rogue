extends Node

const EXPECTED := {
	"dagger": ["毒", "金"],
	"blood_sword": ["火", "毒"],
	"brush": ["木", "毒"],
	"soul_banner": ["木", "毒"],
	"iron_guard_puppet": ["土", "金"],
	"heaven_eye": ["水", "雷"],
	"guqin": ["水", "木"],
	"giant_sword_art": ["金", "土"],
	"body_barrier": ["水", "土"],
}

func _ready() -> void:
	var slots: Array = []
	for artifact_id in EXPECTED:
		var data := load("res://data/artifacts/%s.tres" % artifact_id) as ArtifactData
		if data == null:
			return _fail("MISSING_%s" % artifact_id)
		if data.get_attribute_tags() != EXPECTED[artifact_id]:
			return _fail("BAD_TAGS_%s_%s" % [artifact_id, data.get_attribute_tags()])
		slots.append(ArtifactStack.new(data, 1))

	var manager := SynergyManager.new()
	add_child(manager)
	manager.recalculate(slots)
	var expected_counts := {"金": 3, "木": 3, "水": 3, "火": 1, "土": 3, "雷": 1, "毒": 4}
	if manager.attribute_counts != expected_counts:
		return _fail("BAD_COUNTS_%s" % manager.attribute_counts)

	var enemy := load("res://scenes/EnemyBasic.tscn").instantiate() as Enemy
	enemy.max_hp = 100.0
	add_child(enemy)
	enemy.set_physics_process(false)
	manager.effects["metal_low_hp_ratio"] = .5
	manager.effects["metal_damage_multiplier"] = .25
	manager.effects["poison_dps_multiplier"] = .22
	manager.effects["poison_duration"] = 4.0
	manager.apply_attribute_on_hit(load("res://data/artifacts/dagger.tres"), enemy, 20.0, self, enemy.global_position, .25)
	if enemy.hp > 95.01 or enemy.poison_stacks.size() != 1:
		return _fail("DUAL_EFFECT_NOT_APPLIED_hp=%s_poison=%s" % [enemy.hp, enemy.poison_stacks.size()])

	print("DUAL_ATTRIBUTE_ARTIFACT_TEST_OK counts=%s" % manager.attribute_counts)
	enemy.queue_free()
	manager.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
