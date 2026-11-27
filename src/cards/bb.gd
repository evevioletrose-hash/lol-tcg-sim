extends "res://src/cards/card.gd"

var base_style
var base_groove

var ui_style
var ui_groove
var ui_name
var ui_club
var ui_text


func populate(data):
	super.populate(data)
	ui_style = get_node("Card/Style")
	ui_groove = get_node("Card/Groove")
	ui_name = get_node("Card/Name")
	ui_club = get_node("Card/Club")
	ui_text = get_node("Card/Text/card_text")	
	
	base_style = data.style
	base_groove = data.groove
	
	update_cardtext()


func update_cardtext():
	super.update_cardtext()
	ui_style.text = base_style
	ui_groove.text = base_groove
	ui_name.text = card_name
	ui_club.text = "Club not catalogued" if club == Game.Clubs.Unknown else Game.Clubs.keys()[club].replace("_", " ") + " Club"
	ui_text.text = text
	
