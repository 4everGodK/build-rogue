extends Node

func _ready() -> void:
	var ui := load("res://ui/GameUI.tscn").instantiate() as GameUI
	add_child(ui)
	await get_tree().process_frame
	var data := load("res://data/artifacts/dagger.tres") as ArtifactData
	var stack := ArtifactStack.new(data, 2)
	ui.set_equipped_artifacts([stack], [])
	await get_tree().process_frame
	var root := ui.get_node("Root") as Control
	var bar := ui.get_node("Root/ArtifactBar") as Control
	var slots := ui.get_node("Root/ArtifactBar/ArtifactMargin/ArtifactSlots") as Control
	if root.mouse_filter == Control.MOUSE_FILTER_IGNORE or bar.mouse_filter == Control.MOUSE_FILTER_IGNORE or slots.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return _fail("TOOLTIP_ANCESTOR_IGNORES_MOUSE")
	if slots.get_child_count() != 1:
		return _fail("BATTLE_ARTIFACT_CARD_MISSING")
	var card := slots.get_child(0) as Control
	if card == null or card.mouse_filter != Control.MOUSE_FILTER_STOP:
		return _fail("BATTLE_ARTIFACT_CARD_CANNOT_HOVER")
	var tooltip := card.tooltip_text
	for expected in [data.display_name, data.system_tag, data.get_attribute_display(), data.description]:
		if not tooltip.contains(expected):
			return _fail("TOOLTIP_MISSING_%s" % expected)
	print("BATTLE_ARTIFACT_TOOLTIP_TEST_OK")
	ui.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
