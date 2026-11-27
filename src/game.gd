extends Node2D

class_name Game



var card_database = {}


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

func add_card_db(card_data):
	# Some numbered rows are placeholders; the final B.B. row has no phase column.
	if card_data.size() < 8:
		if not card_data.is_empty() and not card_data[0].strip_edges().is_empty():
			push_warning("Incomplete card row: " + card_data[0])
		return
	var card_number = card_data[0].strip_edges()
	var card_name = card_data[1].strip_edges()
	if card_name.is_empty():
		return
	if not card_number.contains("-"):
		push_warning("Invalid card number: " + card_number)
		return
	var card_type = get_card_type(card_data[2].strip_edges())
	if card_type == Card_Types.Unknown:
		push_warning("Unknown card type for " + card_number)
		return
	if card_type == Card_Types.Surprise and card_data.size() < 9:
		push_warning("Missing Surprise phase: " + card_number)
		return
	if card_database.has(card_number):
		push_warning("Duplicate card number: " + card_number)
		return

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
		card_data_object.phase = get_game_phase(card_data[8].strip_edges())

	card_database[card_number] = card_data_object

func load_cardlist():
	card_database.clear()
	var csv = FileAccess.open("res://cardlist.txt", FileAccess.READ)
	if csv == null:
		push_error("Could not open cardlist.txt")
		return
	while not csv.eof_reached():
		var line = csv.get_line()
		if not line.strip_edges().is_empty():
			add_card_db(line.split("\t"))

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
	
	
	
	
func spawn_card(card_number : String) -> Card:
	var card_data = card_database.get(card_number)
	if card_data == null:
		push_warning("Unknown card number: " + card_number)
		return null
	
	var card_object : Card
	match card_data.type:
		Card_Types.BB:
			card_object = load("res://src/cards/BB.tscn").instantiate()
		Card_Types.Surprise:
			card_object = load("res://src/cards/Surprise.tscn").instantiate()
		Card_Types.Item:
			card_object = load("res://src/cards/Item.tscn").instantiate()
		_:
			push_warning("No card scene for " + card_number)
			return null
	add_child(card_object)
	card_object.populate(card_data)
	return card_object
	
func open_library():
	var library = load("res://src/card_viewer/card_library.tscn").instantiate()
	add_child(library)
