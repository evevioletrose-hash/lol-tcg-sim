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
	Item
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
	Art
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
	var club_names = [
		"Theater",
		"Opposites",
		"Glam",
		"Glee",
		"Hip Hop",
		"Glitterati",
		"Dance",
		"Cosplay",
		"Chill Out",
		"Swim",
		"Athletic",
		"Pop",
		"Spirit",
		"Spooky",
		"Sleepover",
		"Retro",
		"Storybook",
		"Art"
	]
	
	var club_num = club_names.find(club_name)
	if club_num == -1:
		print("Error: couldn't find club " + club_name)
		return Clubs.Theater
	return Clubs.get(club_name.replace(" ", "_"))
	
func get_card_type(card_type) -> Card_Types:
	match card_type:
		"Items":
			return Card_Types.Item
		"BB":
			return Card_Types.BB
		"Surprise":
			return Card_Types.Surprise
	return Card_Types.BB

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
	if card_data[0] == "":
		print("Error: Card has no number")
		return
	if not card_data[0].contains("-"):
		print("Error: Card doesn't have a valid number")
		return
		
	var card_data_object = {
		# card_number,Have,Name,type,rank,style,groove,text,club,phase
		"number": card_data[0],
		"name": card_data[1],
		"type": get_card_type(card_data[2]),
		"rank": int(card_data[3]),
		"text": card_data[6]
	}
	
	if card_data_object.type == Card_Types.BB:
		card_data_object.style = card_data[4]
		card_data_object.groove = card_data[5]
	
	elif card_data_object.type == Card_Types.Surprise:
		card_data_object.phase = get_game_phase(card_data[8])
	
	if card_data[8] != "":
		card_data_object.club = get_club_from_name(card_data[7])
	
	card_database[card_data[0]] = card_data_object
	

func load_cardlist():
	var csv = FileAccess.open("res://cardlist.txt",FileAccess.READ )
	
	if csv:
		while not csv.eof_reached():
			var line = csv.get_line()
			var card_data = line.split("	")
			add_card_db(card_data)

func get_cards_from_deck(deck) -> Array[Card]:
	var deck_objects : Array[Card]
	for card_num in deck:
		deck_objects.push_front(spawn_card(card_num))
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
	
	var card_object : Card
	match card_data.type:
		Card_Types.BB:
			card_object = load("res://src/cards/BB.tscn").instantiate()
		Card_Types.Surprise:
			card_object = load("res://src/cards/Surprise.tscn").instantiate()
		Card_Types.Item:
			card_object = load("res://src/cards/Item.tscn").instantiate()
	add_child(card_object)
	card_object.populate(card_data)
	return card_object
	
func open_library():
	var library = load("res://src/card_viewer/card_library.tscn").instantiate()
	add_child(library)
