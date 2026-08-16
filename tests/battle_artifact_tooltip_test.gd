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
	var bar := ui.get_node("Root/SafeArea/ArtifactBar") as Control
	var slots := ui.get_node("Root/SafeArea/ArtifactBar/ArtifactMargin/ArtifactSlots") as Control
	if root.mouse_filter == Control.MOUSE_FILTER_IGNORE or bar.mouse_filter == Control.MOUSE_FILTER_IGNORE or slots.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return _fail("TOOLTIP_ANCESTOR_IGNORES_MOUSE")
	if slots.get_child_count() != 1:
		return _fail("BATTLE_ARTIFACT_CARD_MISSING")
	var card := slots.get_child(0) as Control
	if card == null or card.mouse_filter != Control.MOUSE_FILTER_STOP:
		return _fail("BATTLE_ARTIFACT_CARD_CANNOT_HOVER")
	card.grab_focus()
	await get_tree().create_timer(UITokens.TOOLTIP_DELAY + .05).timeout
	var explicit_tooltip := ui.get_node("Root/BattleArtifactTooltip") as PanelContainer
	if explicit_tooltip == null or not explicit_tooltip.visible:
		return _fail("EXPLICIT_BATTLE_TOOLTIP_NOT_SHOWN")
	var explicit_text := ui.battle_artifact_tooltip_label.text
	for expected in [data.display_name, data.system_tag, data.get_attribute_display(), data.description]:
		if not explicit_text.contains(expected):
			return _fail("EXPLICIT_TOOLTIP_MISSING_%s" % expected)
	card.release_focus()
	await get_tree().create_timer(.1).timeout
	ui._hide_battle_artifact_tooltip()
	if explicit_tooltip.visible:
		return _fail("EXPLICIT_BATTLE_TOOLTIP_NOT_HIDDEN")
	print("BATTLE_ARTIFACT_TOOLTIP_TEST_OK")
	ui.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
