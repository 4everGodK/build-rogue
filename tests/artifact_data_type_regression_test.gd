extends Node

func _ready() -> void:
	var stacks: Array = []
	for raw_id in ArtifactCatalog.all_ids():
		var data := ArtifactCatalog.get_data(str(raw_id))
		if not data is ArtifactData:
			return _fail("CATALOG_NON_ARTIFACT_%s" % raw_id)
		var duplicate := data.duplicate(true)
		if not duplicate is ArtifactData:
			return _fail("DUPLICATE_NON_ARTIFACT_%s" % raw_id)
		var stack := ArtifactStack.new(data, 1)
		stacks.append(stack)
		if stack.get_combat_tooltip().is_empty():
			return _fail("EMPTY_TOOLTIP_%s" % raw_id)
		ArtifactStarConfig.describe_star_effect(data, 1)

	var manager := ShopManager.new()
	add_child(manager)
	manager.generate_all_offers()
	var offers := manager.get_offer_dictionaries()
	if offers.size() != ArtifactCatalog.all_ids().size():
		return _fail("SHOP_OFFER_COUNT")
	for offer in offers:
		ArtifactStarConfig.describe_offer(offer, 1)
	manager.current_offers[0] = null
	manager.locked_offers[0] = false
	manager.generate_offers(false)

	print("ARTIFACT_DATA_TYPE_REGRESSION_TEST_OK artifacts=%d" % offers.size())
	manager.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
