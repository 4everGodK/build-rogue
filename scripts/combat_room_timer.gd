extends Node
class_name CombatRoomTimer

signal room_started(duration: float)
signal room_finished

const DEFAULT_ROOM_DURATION: float = 30.0

var duration: float = DEFAULT_ROOM_DURATION
var time_left: float = 0.0
var active: bool = false
var finished_emitted: bool = false

func start_room(next_duration: float = DEFAULT_ROOM_DURATION) -> void:
	duration = maxf(1.0, next_duration)
	time_left = duration
	active = true
	finished_emitted = false
	room_started.emit(duration)

func stop_room() -> void:
	active = false
	time_left = 0.0
	finished_emitted = false

func _process(delta: float) -> void:
	if not active:
		return
	time_left -= delta
	if time_left <= 0.0 and not finished_emitted:
		finished_emitted = true
		room_finished.emit()
