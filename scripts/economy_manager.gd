extends Node
class_name EconomyManager

signal spirit_stones_changed(amount: int)

var spirit_stones: int = 0

func add_spirit_stones(amount: int) -> void:
	spirit_stones += max(0, amount)
	spirit_stones_changed.emit(spirit_stones)

func spend_spirit_stones(amount: int) -> bool:
	if spirit_stones < amount:
		return false
	spirit_stones -= amount
	spirit_stones_changed.emit(spirit_stones)
	return true

func reset(value: int = 0) -> void:
	spirit_stones = max(0, value)
	spirit_stones_changed.emit(spirit_stones)
