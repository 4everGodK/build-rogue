extends Node
class_name EconomyManager

signal spirit_stones_changed(amount: int)

var spirit_stones: int = 0
var unlimited_spirit_stones: bool = false

func add_spirit_stones(amount: int) -> void:
	spirit_stones += max(0, amount)
	spirit_stones_changed.emit(spirit_stones)

func spend_spirit_stones(amount: int) -> bool:
	if unlimited_spirit_stones:
		spirit_stones_changed.emit(spirit_stones)
		return true
	if spirit_stones < amount:
		return false
	spirit_stones -= amount
	spirit_stones_changed.emit(spirit_stones)
	return true

func reset(value: int = 0) -> void:
	spirit_stones = max(0, value)
	spirit_stones_changed.emit(spirit_stones)

func set_unlimited(enabled: bool, display_value: int = 999999) -> void:
	unlimited_spirit_stones = enabled
	if enabled:
		spirit_stones = max(spirit_stones, display_value)
	spirit_stones_changed.emit(spirit_stones)
