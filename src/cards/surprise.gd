extends "res://src/cards/card.gd"

var name_ui
var phase_ui
var cardtext_ui

var phase : Game.Game_Phases
var printed_phase: String = ""

func populate(data):
	super.populate(data)

	name_ui = get_node("Card/Name")
	phase_ui = get_node("Card/Phase")
	cardtext_ui = get_node("Card/Text/card_text")

	phase = data.phase
	printed_phase = str(data.get("printed_phase", ""))
	update_cardtext()
	
func update_cardtext():
	super.update_cardtext()
	name_ui.text = card_name
	
	# Display evidence, not the legacy runtime fallback for an unknown phase.
	phase_ui.text = printed_phase.to_upper() if not printed_phase.strip_edges().is_empty() else "PHASE NOT CATALOGUED"

	cardtext_ui.text = text
