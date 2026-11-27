extends Node
class_name Zone

signal on_card_added(card)
signal on_card_removed(card)

@onready
var board = get_parent()

var allowed_card_types : Array[Game.Card_Types]
var public : bool = false
var face_up : bool = true

var cards : Array[Card]

@onready
var container = get_node("Container")

func shuffle():
	cards.shuffle()
	
func add_card(card : Card):
	if(card.zone != null):
		card.zone.emit_signal("on_card_removed", card)
	
	card.set_face(face_up)
	card.reparent(container)
	card.zone = self
	emit_signal("on_card_added", card)

func add_to_top(card : Card):
	cards.push_front(card)
	add_card(card)

func add_to_bottom(card : Card):
	cards.push_back(card)
	add_card(card)
	
func set_cards(new_cards):
	for card in new_cards:
		add_to_top(card)

func take_from_top() -> Card:
	if(cards.size() > 0):
		return cards.pop_front()
	else:
		return null

func remove_from_play():
	queue_free()

func draw(count : int = 1, destination: Zone = null):
	for i in count:
		var card = take_from_top()
		if(card == null):
			return
		if destination == null:
			destination = board.hand
		destination.add_to_top(card)
	
