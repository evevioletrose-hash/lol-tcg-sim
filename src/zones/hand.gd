extends "res://src/zones/zone.gd"
class_name Hand

func _ready() -> void:
	connect("on_card_added", on_add)
	connect("on_card_removed", on_remove)
	
func on_add(card):
	card.get_node("Button").connect("mouse_entered", card.highlight)
	card.get_node("Button").connect("mouse_exited", card.unhighlight)

func on_remove(card):
	card.get_node("Button").disconnect("mouse_entered", card.highlight)
	card.get_node("Button").disconnect("mouse_exited", card.unhighlight)
	card.unselect()
	card.unhighlight()
