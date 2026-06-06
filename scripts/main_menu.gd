extends Control
class_name MainMenu

const GAME_SCENE: String = "res://scenes/Main.tscn"

@onready var start_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/StartButton
@onready var quit_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton

func _ready() -> void:
	start_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	quit_button.pressed.connect(func() -> void: get_tree().quit())
