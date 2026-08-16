extends Node

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3440, 1440),
]

func _ready() -> void:
	if ProjectSettings.get_setting("display/window/size/viewport_width") != 1280:
		return _fail("LOGICAL_VIEWPORT_WIDTH")
	if ProjectSettings.get_setting("display/window/size/viewport_height") != 720:
		return _fail("LOGICAL_VIEWPORT_HEIGHT")
	if ProjectSettings.get_setting("display/window/stretch/mode") != "canvas_items":
		return _fail("STRETCH_MODE")
	if ProjectSettings.get_setting("display/window/stretch/aspect") != "keep":
		return _fail("STRETCH_ASPECT")
	if absf(float(ProjectSettings.get_setting("gui/timers/tooltip_delay_sec")) - .3) > .001:
		return _fail("TOOLTIP_DELAY")
	if load("res://themes/cloud_paper_theme.tres") == null:
		return _fail("SHARED_THEME_MISSING")

	for resolution in RESOLUTIONS:
		await _verify_resolution(resolution)

	print("UI_FOUNDATION_TEST_OK resolutions=%s" % [RESOLUTIONS])
	get_tree().quit()

func _verify_resolution(resolution: Vector2i) -> void:
	get_window().size = resolution
	await get_tree().process_frame
	await get_tree().process_frame

	var hud := load("res://ui/GameUI.tscn").instantiate() as GameUI
	add_child(hud)
	await get_tree().process_frame
	hud.set_shield(25.0, 50.0)
	if not hud.shield_row.visible or hud.shield_bar.value != 25.0:
		return _fail("SHIELD_HUD_%s" % resolution)
	hud.set_synergies(
		{"剑修": 6, "法修": 4, "体修": 3, "召唤": 2, "魔修": 2},
		{"金": 4, "木": 3, "水": 2, "火": 2, "土": 2, "雷": 2, "毒": 2}
	)
	if hud._relevant_synergy_entries(hud.current_system_counts, hud.current_attribute_counts).size() > 4:
		return _fail("HUD_SYNERGY_LIMIT_%s" % resolution)
	if hud.safe_area.size.x > 1280.1 or hud.safe_area.size.y > 720.1:
		return _fail("HUD_SAFE_AREA_OVERSIZE_%s_%s" % [resolution, hud.safe_area.size])
	hud.queue_free()
	await get_tree().process_frame

	var shop := load("res://ui/ShopPanel.tscn").instantiate() as ShopPanel
	add_child(shop)
	var dagger_data := load("res://data/artifacts/dagger.tres") as ArtifactData
	var dagger_stack := ArtifactStack.new(dagger_data, 1)
	var offers: Array = []
	for index in 5:
		offers.append({
			"id": "test_%d" % index,
			"display_name": "样板法宝%d" % (index + 1),
			"system_tag": "剑修",
			"attribute_tag": "金",
			"attribute_tags": ["金"],
			"description": "用于验证商店信息层级与焦点路径。",
			"cost": 10 + index,
			"damage": 12.0,
			"cooldown": 1.0,
			"star_level": 1,
			"locked": false,
		})
	shop.open_shop(1, offers, 100, [dagger_stack, null, null, null, null], [null, null, null, null, null, null, null, null], {"剑修": 2}, {"金": 1})
	await get_tree().process_frame
	await get_tree().process_frame
	if shop.offer_buttons.size() != 5:
		return _fail("SHOP_OFFERS_%s" % resolution)
	if shop.offer_buttons[0].focus_mode != Control.FOCUS_ALL or not shop.offer_buttons[0].has_focus():
		return _fail("SHOP_ENTRY_FOCUS_%s" % resolution)
	if shop.sell_zone.focus_mode != Control.FOCUS_ALL:
		return _fail("SHOP_SELL_FOCUS_%s" % resolution)
	for button in shop.offer_buttons + shop.lock_buttons + shop.battle_slot_buttons + shop.bag_slot_buttons:
		var control := button as Control
		if is_instance_valid(control) and control.focus_mode == Control.FOCUS_NONE:
			return _fail("SHOP_FOCUS_NONE_%s" % resolution)
	var focus_controls: Array[Control] = [shop.reroll_button, shop.breakthrough_button, shop.spirit_gathering_button, shop.continue_button, shop.sell_zone]
	focus_controls.append_array(shop._valid_focus_controls(shop.lock_buttons))
	focus_controls.append_array(shop._valid_focus_controls(shop.offer_buttons))
	focus_controls.append_array(shop._valid_focus_controls(shop.battle_slot_buttons))
	focus_controls.append_array(shop._valid_focus_controls(shop.bag_slot_buttons))
	if not _focus_graph_reaches_all(shop.offer_buttons[0], focus_controls):
		return _fail("SHOP_FOCUS_DEAD_END_%s" % resolution)
	var signals := {"buy": -1, "sell_area": "", "sell_index": -1, "continue": false}
	shop.buy_requested.connect(func(index: int) -> void: signals["buy"] = index)
	shop.sell_requested.connect(func(area: String, index: int) -> void:
		signals["sell_area"] = area
		signals["sell_index"] = index
	)
	shop.continue_requested.connect(func() -> void: signals["continue"] = true)
	shop.offer_buttons[0].pressed.emit()
	shop.battle_slot_buttons[0].pressed.emit()
	shop.sell_zone.pressed.emit()
	shop.continue_button.pressed.emit()
	if signals != {"buy": 0, "sell_area": "battle", "sell_index": 0, "continue": true}:
		return _fail("SHOP_CONTROLLER_FLOW_%s_%s" % [resolution, signals])
	var safe_area := shop.get_node("Panel/MarginContainer") as Control
	if safe_area.size.x > 1280.1 or safe_area.size.y > 720.1:
		return _fail("SHOP_SAFE_AREA_OVERSIZE_%s_%s" % [resolution, safe_area.size])
	shop.queue_free()
	await get_tree().process_frame

func _focus_graph_reaches_all(start: Control, targets: Array[Control]) -> bool:
	var pending: Array[Control] = [start]
	var visited: Dictionary = {}
	while not pending.is_empty():
		var current := pending.pop_front() as Control
		if not is_instance_valid(current) or visited.has(current):
			continue
		visited[current] = true
		for path in [current.focus_neighbor_left, current.focus_neighbor_right, current.focus_neighbor_top, current.focus_neighbor_bottom]:
			if not (path as NodePath).is_empty():
				var neighbor := current.get_node_or_null(path) as Control
				if is_instance_valid(neighbor) and not visited.has(neighbor):
					pending.append(neighbor)
	for target in targets:
		if is_instance_valid(target) and target.visible and not bool(target.get("disabled")) and not visited.has(target):
			return false
	return true

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
