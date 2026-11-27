extends Control

# This workshop inspects definitions. It does not create a match or run powers.
var game: Game
var preview: Card
var selected_id: String = ""

@onready var search: LineEdit = $Margin/Layout/Body/Catalogue/Search
@onready var type_filter: OptionButton = $Margin/Layout/Body/Catalogue/TypeFilter
@onready var count_label: Label = $Margin/Layout/Body/Catalogue/Count
@onready var cards: ItemList = $Margin/Layout/Body/Catalogue/Cards
@onready var preview_holder: Control = $Margin/Layout/Body/Inspection/Preview
@onready var details: RichTextLabel = $Margin/Layout/Body/Inspection/Details

func setup(source: Game) -> void:
	game = source
	type_filter.add_item("All types")
	type_filter.add_item("B.B.", Game.Card_Types.BB + 1)
	type_filter.add_item("Item", Game.Card_Types.Item + 1)
	type_filter.add_item("Surprise", Game.Card_Types.Surprise + 1)
	type_filter.add_item("Place", Game.Card_Types.Place + 1)
	search.text_changed.connect(_on_search_changed)
	type_filter.item_selected.connect(_on_filter_changed)
	cards.item_selected.connect(_on_card_selected)
	refresh_list()

func _on_search_changed(_value: String) -> void:
	refresh_list()

func _on_filter_changed(_index: int) -> void:
	refresh_list()

func _on_card_selected(index: int) -> void:
	show_card(str(cards.get_item_metadata(index)))

func type_name(value: int) -> String:
	match value:
		Game.Card_Types.BB: return "B.B."
		Game.Card_Types.Item: return "Item"
		Game.Card_Types.Surprise: return "Surprise"
		Game.Card_Types.Place: return "Place"
	return "Unknown"

func club_name(data: Dictionary) -> String:
	if not data.has("club"):
		return ""
	return str(Game.Clubs.keys()[data.club]).replace("_", " ")

func phase_name(data: Dictionary) -> String:
	if not data.has("phase"):
		return ""
	match data.phase:
		Game.Game_Phases.Any_Phase: return "Any Phase"
		Game.Game_Phases.Call_BB: return "Call Your B.B.s"
		Game.Game_Phases.Dress_Up: return "Dress Up"
		Game.Game_Phases.Dance_Off: return "Dance Off"
	return "Unknown"

func refresh_list() -> void:
	var previous_id = selected_id
	cards.clear()
	var ids = game.card_database.keys()
	ids.sort()
	var query = search.text.strip_edges().to_lower()
	var filter_id = type_filter.get_selected_id()
	var selection_index = -1
	for id in ids:
		var data: Dictionary = game.card_database[id]
		if filter_id > 0 and data.type != filter_id - 1:
			continue
		var searchable = "%s %s %s %s %s" % [id, data.name, club_name(data), data.text, phase_name(data)]
		if not searchable.to_lower().contains(query):
			continue
		var index = cards.add_item("%s  %s" % [id, data.name])
		cards.set_item_metadata(index, id)
		if id == previous_id:
			selection_index = index
	count_label.text = "%d / %d cards" % [cards.item_count, game.card_database.size()]
	if cards.item_count == 0:
		clear_preview()
		details.text = "No matching cards."
		return
	if selection_index < 0:
		selection_index = 0
	cards.select(selection_index)
	_on_card_selected(selection_index)

func clear_preview() -> void:
	if is_instance_valid(preview):
		preview.free()
	preview = null
	selected_id = ""

func show_card(id: String) -> void:
	clear_preview()
	selected_id = id
	var data: Dictionary = game.card_database[id]
	var lines: PackedStringArray = [
		data.name, id, type_name(data.type), "Rank: %s" % data.rank
	]
	if data.type == Game.Card_Types.BB:
		lines.append("Club: " + club_name(data))
		lines.append("Starting Style: " + str(data.style))
		lines.append("Starting Groove: " + str(data.groove))
	elif data.type == Game.Card_Types.Surprise:
		lines.append("Phase: " + phase_name(data))
	lines.append("")
	lines.append(data.text)
	if data.type == Game.Card_Types.Place:
		lines.append("")
		lines.append("Place preview not implemented yet.")
	else:
		preview = game.spawn_card(id, preview_holder)
		if preview is Control:
			var visual = preview as Control
			visual.set_anchors_preset(Control.PRESET_TOP_LEFT)
			visual.position = Vector2.ZERO
			visual.size = Vector2(333, 442)
			visual.get_node("Button").mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.text = "\n".join(lines)

func run_smoke_test() -> int:
	var counts: Dictionary = {}
	var failures: Array[String] = []
	for id in game.card_database:
		var data: Dictionary = game.card_database[id]
		show_card(id)
		var kind = type_name(data.type)
		counts[kind] = counts.get(kind, 0) + 1
		if data.type == Game.Card_Types.Place:
			if preview != null:
				failures.append(id + ": unexpected Place scene")
		elif preview == null:
			failures.append(id + ": missing preview")
		else:
			if preview.card_name != data.name or preview.catalogue_id != id:
				failures.append(id + ": identity mismatch")
			if preview.cardnum_ui.text != id or preview.rank_ui.text != str(data.rank):
				failures.append(id + ": printed identity mismatch")
			if data.type == Game.Card_Types.BB:
				if preview.get_node("Card/Style").text != data.style or preview.get_node("Card/Groove").text != data.groove:
					failures.append(id + ": stat mismatch")
			if preview.get_node("Card/Text/card_text").text != data.text:
				failures.append(id + ": effect text mismatch")
	clear_preview()
	if counts != {"B.B.": 161, "Item": 70, "Surprise": 75, "Place": 5}:
		failures.append("Unexpected catalogue counts")
	for failure in failures:
		push_error(failure)
	print("LOL_WORKSHOP counts=%s failures=%d" % [str(counts), failures.size()])
	return 0 if failures.is_empty() else 1
