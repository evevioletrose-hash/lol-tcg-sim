extends Node
class_name DanceFloor

var deck_zone : DeckZone
var discard_zone : DiscardZone
var bb_zones : Array[BBZone]
var item_zones : Array[ItemZone]
var hand : Hand

func _ready() -> void:
	get_nodes()
	
func initialize(deck):
	deck_zone.set_cards(deck)

func get_nodes():
	deck_zone = get_node("DeckZone")
	discard_zone = get_node("DiscardZone")
	hand = get_node("Hand")
	
	bb_zones = [
		get_node("BBZone"),
		get_node("BBZone2"),
		get_node("BBZone3"),
		get_node("BBZone4"),	
	]
	
	item_zones = [
		get_node("ItemZone"),
		get_node("ItemZone2"),
		get_node("ItemZone3"),
		get_node("ItemZone4"),	
	]
	
func get_bbs_in_play() -> Array[Card]:
	var bbs = []
	for bb_zone in bb_zones:
		if bb_zone.cards.size() == 1:
			bbs.append(bb_zone.cards[0])
	return bbs
