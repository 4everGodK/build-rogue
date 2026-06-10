extends Node
class_name ShopManager

signal offers_changed(offers: Array)
signal shop_message(message: String)
signal purchase_completed

const REROLL_COST: int = 1
const OFFER_COUNT: int = 5

var current_offers: Array = []
var economy: EconomyManager
var inventory: ArtifactInventory
var cultivation: CultivationManager
var unlimited_catalog_mode: bool = false

func configure(next_economy: EconomyManager, next_inventory: ArtifactInventory, next_cultivation: CultivationManager = null) -> void:
	economy = next_economy
	inventory = next_inventory
	cultivation = next_cultivation

func generate_offers() -> void:
	current_offers.clear()
	unlimited_catalog_mode = false
	for _index in range(OFFER_COUNT):
		current_offers.append(_roll_offer())
	offers_changed.emit(get_offer_dictionaries())

func generate_all_offers() -> void:
	current_offers.clear()
	unlimited_catalog_mode = true
	var ids: Array = ArtifactCatalog.all_ids()
	ids.sort()
	for raw_id in ids:
		var data: ArtifactData = ArtifactCatalog.get_data(str(raw_id))
		if data != null:
			current_offers.append(data)
	offers_changed.emit(get_offer_dictionaries())

func _roll_offer() -> ArtifactData:
	var tier: String = cultivation.roll_shop_tier() if cultivation != null else "凡器"
	var ids: Array[String] = _ids_for_tier(tier)
	if ids.is_empty():
		ids = _ids_for_any_available_tier()
	if ids.is_empty():
		return null
	var total_weight: float = 0.0
	for id in ids:
		var weighted_data := ArtifactCatalog.get_data(id)
		if weighted_data != null:
			total_weight += maxf(0.0, weighted_data.shop_weight)
	if total_weight <= 0.0:
		return ArtifactCatalog.get_data(ids.pick_random())
	var roll: float = randf() * total_weight
	var running: float = 0.0
	for id in ids:
		var picked_data := ArtifactCatalog.get_data(id)
		if picked_data == null:
			continue
		running += maxf(0.0, picked_data.shop_weight)
		if roll <= running:
			return picked_data
	return ArtifactCatalog.get_data(ids.back())

func _ids_for_tier(tier: String) -> Array[String]:
	var result: Array[String] = []
	for raw_id in ArtifactCatalog.all_ids():
		var id := str(raw_id)
		var data := ArtifactCatalog.get_data(id)
		if data != null and data.tier == tier and _meets_cultivation_requirement(data):
			result.append(id)
	return result

func _ids_for_any_available_tier() -> Array[String]:
	var result: Array[String] = []
	for raw_id in ArtifactCatalog.all_ids():
		var id := str(raw_id)
		var data := ArtifactCatalog.get_data(id)
		if data != null and _meets_cultivation_requirement(data):
			result.append(id)
	return result

func _meets_cultivation_requirement(data: ArtifactData) -> bool:
	if data.cultivation_requirement.is_empty() or cultivation == null:
		return true
	var required_index: int = CultivationManager.REALMS.find(data.cultivation_requirement)
	return required_index < 0 or cultivation.realm_index >= required_index

func buy_offer(index: int) -> void:
	if index < 0 or index >= current_offers.size():
		return
	if economy == null or inventory == null:
		return
	var offer_data: ArtifactData = current_offers[index] as ArtifactData
	if offer_data == null:
		return
	var cost: int = offer_data.get_shop_cost()
	if not economy.spend_spirit_stones(cost):
		shop_message.emit("灵石不足")
		return
	if not inventory.add_artifact(offer_data):
		economy.add_spirit_stones(cost)
		shop_message.emit("储物袋已满")
		return
	if not unlimited_catalog_mode:
		current_offers[index] = null
	offers_changed.emit(get_offer_dictionaries())
	purchase_completed.emit()

func reroll() -> void:
	if economy == null:
		return
	if not economy.spend_spirit_stones(REROLL_COST):
		shop_message.emit("灵石不足")
		return
	generate_offers()

func get_offer_dictionaries() -> Array:
	var result: Array = []
	for data in current_offers:
		if data == null:
			result.append({})
			continue
		var offer: Dictionary = data.to_offer()
		offer["star_level"] = 1
		result.append(offer)
	return result
