extends Node
class_name ShopManager

signal offers_changed(offers: Array)
signal shop_message(message: String)
signal purchase_completed

const BUY_COST: int = 3
const REROLL_COST: int = 1
const OFFER_COUNT: int = 5

var current_offers: Array = []
var economy: EconomyManager
var inventory: ArtifactInventory

func configure(next_economy: EconomyManager, next_inventory: ArtifactInventory) -> void:
	economy = next_economy
	inventory = next_inventory

func generate_offers() -> void:
	current_offers.clear()
	var ids: Array = ArtifactCatalog.all_ids()
	ids.shuffle()
	for index in mini(OFFER_COUNT, ids.size()):
		var data: ArtifactData = ArtifactCatalog.get_data(str(ids[index]))
		if data != null:
			current_offers.append(data)
	while current_offers.size() < OFFER_COUNT:
		current_offers.append(null)
	offers_changed.emit(get_offer_dictionaries())

func buy_offer(index: int) -> void:
	if index < 0 or index >= current_offers.size():
		return
	if economy == null or inventory == null:
		return
	var offer_data: ArtifactData = current_offers[index] as ArtifactData
	if offer_data == null:
		return
	if not economy.spend_spirit_stones(BUY_COST):
		shop_message.emit("灵石不足")
		return
	if not inventory.add_artifact(offer_data):
		economy.add_spirit_stones(BUY_COST)
		shop_message.emit("储物袋已满")
		return
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
		offer["price"] = BUY_COST
		offer["star_level"] = 1
		result.append(offer)
	return result
