extends Control
class_name ResultPanel

signal restart_requested
signal main_menu_requested

@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var detail_label: Label = $Panel/MarginContainer/VBoxContainer/DetailLabel
@onready var restart_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/RestartButton
@onready var menu_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonRow/MenuButton

func _ready() -> void:
	hide()
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	menu_button.pressed.connect(func() -> void: main_menu_requested.emit())

func show_result(title: String, details: String, restart_text: String = "再来一局") -> void:
	title_label.text = title
	detail_label.text = details
	restart_button.text = restart_text
	show()
