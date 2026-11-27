extends "res://src/cards/card.gd"
var name_ui
var cardtext_ui


func populate(data):
	super.populate(data)
	name_ui = get_node("Card/Name")
	cardtext_ui = get_node("Card/Text/card_text")	
	
	update_cardtext()

func update_cardtext():
	super.update_cardtext()
	name_ui.text = card_name
	cardtext_ui.text = text
