extends "res://src/cards/card.gd"

var name_ui
var phase_ui
var cardtext_ui

var phase : Game.Game_Phases

func populate(data):
	super.populate(data)

	name_ui = get_node("Name")
	phase_ui = get_node("Phase")
	cardtext_ui = get_node("Text/card_text")

	phase = data.phase
	update_cardtext()
	
func update_cardtext():
	super.update_cardtext()
	name_ui.text = card_name
	
	match phase:
		Game.Game_Phases.Any_Phase:
			phase_ui.text = "ANY PHASE"
		Game.Game_Phases.Call_BB:
			phase_ui.text = "CALL YOUR B.B.'S"
		Game.Game_Phases.Dress_Up:
			phase_ui.text = "DRESS UP"
		Game.Game_Phases.Dance_Off:
			phase_ui.text = "DANCE OFF"
	
	cardtext_ui.text = text
