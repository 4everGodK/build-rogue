extends Node
class_name ShopManager

signal offers_changed(offers: Array)
signal shop_message(message: String)
signal purchase_completed

const REROLL_COST: int = 1
const REROLL_COST_GROWTH: int = 1
const OFFER_COUNT: int = 5

var current_offers: Array = []
var locked_offers: Array[bool] = []
var economy: EconomyManager
var inventory: ArtifactInventory
var cultivation: CultivationManager
var unlimited_catalog_mode: bool = false
var reroll_count: int = 0

func configure(next_economy: EconomyManager, next_inventory: ArtifactInventory, next_cultivation: CultivationManager = null) -> void:
	economy = next_economy
	inventory = next_inventory
	cultivation = next_cultivation

func generate_offers(reset_reroll_count: bool = true) -> void:
	if reset_reroll_count:
		reroll_count = 0
	var previous_offers: Array = current_offers.duplicate()
	var previous_locks: Array[bool] = locked_offers.duplicate()
	current_offers.clear()
	locked_offers.clear()
	unlimited_catalog_mode = false
	for index in range(OFFER_COUNT):
		var keep_locked: bool = index < previous_locks.size() and previous_locks[index]
		var locked_data: ArtifactData = previous_offers[index] as ArtifactData if index < previous_offers.size() else null
		if keep_locked and locked_data != null:
			current_offers.append(locked_data)
			locked_offers.append(true)
		else:
			current_offers.append(_roll_offer())
			locked_offers.append(false)
	offers_changed.emit(get_offer_dictionaries())

func generate_all_offers() -> void:
	reroll_count = 0
	current_offers.clear()
	locked_offers.clear()
	unlimited_catalog_mode = true
	var ids: Array = ArtifactCatalog.all_ids()
	ids.sort()
	for raw_id in ids:
		var data: ArtifactData = ArtifactCatalog.get_data(str(raw_id))
		if data != null:
			current_offers.append(data)
			locked_offers.append(false)
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
		_set_offer_locked(index, false)
	offers_changed.emit(get_offer_dictionaries())
	purchase_completed.emit()

func reroll() -> void:
	if economy == null:
		return
	if not economy.spend_spirit_stones(get_reroll_cost()):
		shop_message.emit("灵石不足")
		return
	reroll_count += 1
	generate_offers(false)

func get_reroll_cost() -> int:
	return REROLL_COST + reroll_count * REROLL_COST_GROWTH

func toggle_offer_lock(index: int) -> void:
	if unlimited_catalog_mode:
		return
	if index < 0 or index >= current_offers.size():
		return
	if current_offers[index] == null:
		return
	_ensure_lock_size()
	locked_offers[index] = not locked_offers[index]
	offers_changed.emit(get_offer_dictionaries())

func get_offer_dictionaries() -> Array:
	_ensure_lock_size()
	var result: Array = []
	for index in range(current_offers.size()):
		var data: ArtifactData = current_offers[index] as ArtifactData
		if data == null:
			result.append({})
			continue
		var offer: Dictionary = data.to_offer()
		offer["star_level"] = 1
		offer["locked"] = locked_offers[index]
		result.append(offer)
	return result

func _set_offer_locked(index: int, locked: bool) -> void:
	_ensure_lock_size()
	if index >= 0 and index < locked_offers.size():
		locked_offers[index] = locked

func _ensure_lock_size() -> void:
	while locked_offers.size() < current_offers.size():
		locked_offers.append(false)
	if locked_offers.size() > current_offers.size():
		locked_offers.resize(current_offers.size())
