extends RefCounted
class_name CombatStats

var enabled: bool = true
var wave_number: int = 0
var artifact_rows: Dictionary = {}
var synergy_rows: Dictionary = {}

func begin_wave(number: int) -> void:
	wave_number = number
	artifact_rows.clear()
	synergy_rows.clear()

func record_artifact_damage(data: ArtifactData, amount: float) -> void:
	if not enabled or data == null or amount <= 0.0:
		return
	var row := _artifact_row(data)
	row["damage"] = float(row.get("damage", 0.0)) + amount

func record_artifact_heal(data: ArtifactData, amount: float) -> void:
	if not enabled or data == null or amount <= 0.0:
		return
	var row := _artifact_row(data)
	row["healing"] = float(row.get("healing", 0.0)) + amount

func record_synergy_damage(label: String, amount: float) -> void:
	if not enabled or label.is_empty() or amount <= 0.0:
		return
	var row := _synergy_row(label)
	row["damage"] = float(row.get("damage", 0.0)) + amount

func record_synergy_heal(label: String, amount: float) -> void:
	if not enabled or label.is_empty() or amount <= 0.0:
		return
	var row := _synergy_row(label)
	row["healing"] = float(row.get("healing", 0.0)) + amount

func record_synergy_effect(label: String, count: int = 1) -> void:
	if not enabled or label.is_empty() or count <= 0:
		return
	var row := _synergy_row(label)
	row["count"] = int(row.get("count", 0)) + count

func set_synergy_count(label: String, count: int, unit: String = "次") -> void:
	if not enabled or label.is_empty() or count < 0:
		return
	var row := _synergy_row(label)
	row["count"] = count
	row["count_unit"] = unit

func artifact_summary() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in artifact_rows.values():
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_total: float = float(a.get("damage", 0.0)) + float(a.get("healing", 0.0))
		var b_total: float = float(b.get("damage", 0.0)) + float(b.get("healing", 0.0))
		return a_total > b_total
	)
	return rows

func synergy_summary() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in synergy_rows.values():
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_total: float = float(a.get("damage", 0.0)) + float(a.get("healing", 0.0)) + float(a.get("count", 0))
		var b_total: float = float(b.get("damage", 0.0)) + float(b.get("healing", 0.0)) + float(b.get("count", 0))
		return a_total > b_total
	)
	return rows

func _artifact_row(data: ArtifactData) -> Dictionary:
	if not artifact_rows.has(data.id):
		artifact_rows[data.id] = {
			"id": data.id,
			"name": data.display_name,
			"damage": 0.0,
			"healing": 0.0,
		}
	return artifact_rows[data.id]

func _synergy_row(label: String) -> Dictionary:
	if not synergy_rows.has(label):
		synergy_rows[label] = {
			"name": label,
			"damage": 0.0,
			"healing": 0.0,
			"count": 0,
			"count_unit": "次",
		}
	return synergy_rows[label]
