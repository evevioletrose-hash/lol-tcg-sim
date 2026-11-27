extends Node2D

class_name Game



var card_database = {}
var catalogue = preload("res://src/cards/card_catalogue.gd").new()
var catalogue_loaded: bool = false


@onready
var infobox = get_node("info") 
@onready
var infotext = get_node("info/Label")
@onready
var context = get_node("ContextMenu")
@onready
var board = get_node("Board")
@onready
var state = get_node("State")

func set_info(text):
	infobox.visible = true
	infotext.text = text
	if text == "":
		infobox.visible = false

enum Players {
	P1,
	P2
}

enum Game_Phases {
	Any_Phase,
	Call_BB,
	Dress_Up,
	Dance_Off,
	Start_Game,
}

enum Card_Types {
	BB,
	Surprise,
	Item,
	Place,
	Unknown
}

enum Clubs {
	Theater,
	Opposites,
	Glam,
	Glee,
	Hip_Hop,
	Glitterati,
	Dance,
	Cosplay,
	Chill_Out,
	Swim,
	Athletic,
	Pop,
	Spirit,
	Spooky,
	Sleepover,
	Retro,
	Storybook,
	Art,
	Rock,
	Stem,
	Unknown
}

enum Zone_Flags {
	Your_Discard,
	Your_Deck,
	Your_BB_Zones,
	Your_Item_Zones,
	Your_Hand,
	Opponent_Discard,
	Opponent_Deck,
	Opponent_BB_Zones,
	Opponent_Item_Zones,
}

enum Type_Flags {
	BB,
	Item,
	Any
}



func get_club_from_name(club_name: String) -> Clubs:
	var key = club_name.strip_edges().replace(" ", "_")
	if Clubs.has(key):
		return Clubs[key]
	push_warning("Unknown club: " + club_name)
	return Clubs.Unknown

func get_card_type(card_type) -> Card_Types:
	match card_type:
		"Items":
			return Card_Types.Item
		"BB":
			return Card_Types.BB
		"Surprise":
			return Card_Types.Surprise
		"Place":
			return Card_Types.Place
	return Card_Types.Unknown

func get_game_phase(game_phase) -> Game_Phases:
	match game_phase:
		"Any Phase":
			return Game_Phases.Any_Phase
		"Call your B.B.'s":
			return Game_Phases.Call_BB
		"Dress Up":
			return Game_Phases.Dress_Up
		"Dance Off":
			return Game_Phases.Dance_Off
	return Game_Phases.Any_Phase

func project_card_data(card_data, warn: bool = true) -> Dictionary:
	# Some numbered rows are placeholders; the final B.B. row has no phase column.
	if card_data.size() < 8:
		if warn and not card_data.is_empty() and not card_data[0].strip_edges().is_empty():
			push_warning("Incomplete card row: " + card_data[0])
		return {}
	var card_number = card_data[0].strip_edges()
	var card_name = card_data[1].strip_edges()
	if card_name.is_empty():
		return {}
	if not card_number.contains("-"):
		if warn:
			push_warning("Invalid card number: " + card_number)
		return {}
	var card_type = get_card_type(card_data[2].strip_edges())
	if card_type == Card_Types.Unknown:
		if warn:
			push_warning("Unknown card type for " + card_number)
		return {}

	var card_data_object = {
		"number": card_number,
		"name": card_name,
		"type": card_type,
		"rank": int(card_data[3]),
		"text": card_data[6]
	}
	if card_type == Card_Types.BB:
		# Preserve unknown printed stats instead of inventing numeric values.
		card_data_object.style = card_data[4]
		card_data_object.groove = card_data[5]
		if not card_data[7].strip_edges().is_empty():
			card_data_object.club = get_club_from_name(card_data[7])
		else:
			card_data_object.club = Clubs.Unknown
	elif card_type == Card_Types.Surprise:
		card_data_object.phase = get_game_phase(card_data[8].strip_edges() if card_data.size() >= 9 else "")

	return card_data_object

func add_card_db(card_data):
	var data = project_card_data(card_data)
	if not data.is_empty():
		card_database[data.number] = data

func refresh_card_definition(id: String) -> void:
	card_database.erase(id)
	var data = project_card_data(catalogue.legacy_row(catalogue.records[id]), false)
	if not data.is_empty():
		card_database[id] = data

func load_cardlist():
	card_database.clear()
	catalogue_loaded = catalogue.load_records()
	if not catalogue_loaded:
		for problem in catalogue.errors:
			push_error(problem)
		return
	var ids = catalogue.records.keys()
	ids.sort()
	for id in ids:
		add_card_db(catalogue.legacy_row(catalogue.records[id]))
	print("LOL_CATALOGUE slots=%d typed=%d incomplete=%d" % [
		catalogue.records.size(), card_database.size(),
		catalogue.records.size() - card_database.size()
	])

func get_cards_from_deck(deck) -> Array[Card]:
	var deck_objects : Array[Card]
	for card_num in deck:
		var card = spawn_card(card_num)
		if card != null:
			deck_objects.push_front(card)
	return deck_objects



func initialize_game(deck, deck2):
	load_cardlist()

	var p1Deck = get_cards_from_deck(deck)
	var p2Deck = get_cards_from_deck(deck2)
	
	state.initialize(self)
	state.load_deck(Players.P1, p1Deck)
	state.load_deck(Players.P2, p2Deck)
	state.set_phase(Game_Phases.Start_Game)
	
	
	
	
func spawn_card(card_number : String, presentation_parent: Node = null) -> Card:
	var card_data = card_database.get(card_number)
	if card_data == null:
		push_warning("Unknown card number: " + card_number)
		return null
	
	return spawn_card_definition(card_data, presentation_parent)

func spawn_card_definition(card_data: Dictionary, presentation_parent: Node = null) -> Card:
	var card_object : Card
	match card_data.type:
		Card_Types.BB:
			card_object = load("res://src/cards/BB.tscn").instantiate()
		Card_Types.Surprise:
			card_object = load("res://src/cards/Surprise.tscn").instantiate()
		Card_Types.Item:
			card_object = load("res://src/cards/Item.tscn").instantiate()
		_:
			push_warning("No card scene for " + str(card_data.number))
			return null
	if presentation_parent == null:
		presentation_parent = self
	presentation_parent.add_child(card_object)
	card_object.populate(card_data)
	return card_object
	
func open_library(archivist: bool = false):
	board.hide()
	infobox.hide()
	context.hide()
	get_node("phasetext").hide()
	var library = load("res://src/card_viewer/card_library.tscn").instantiate()
	if not library.has_method("setup"):
		library.free()
		push_error("Could not initialize card library script")
		return null
	# Screen UI must not inherit the dance floor's canvas transforms or layout.
	var ui_layer = CanvasLayer.new()
	ui_layer.name = "WorkshopUI"
	ui_layer.layer = 10
	add_child(ui_layer)
	ui_layer.add_child(library)
	library.setup(self, archivist)
	return library
