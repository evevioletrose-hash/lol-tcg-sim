extends Node
class_name Main

var sample_deck = [
	"1-182",
	"1-182",
	"1-182",
	"1-182",
	"1-182",
	"1-182",
	"1-182",
	"1-182",
	"1-182",
	"1-182",
]

var item_deck = [
	"1-313",
	"1-313",
	"1-313",
	"1-313",
	"1-313",
	"1-313",
	"1-182",
	"1-313",
	"1-313",
	"1-313",
	"1-313",
]
func _ready() -> void:
	var game = preload("res://src/game.tscn").instantiate()
	add_child(game)
	# Restoration checkpoint: load the catalogue and display the existing board.
	# The original match setup and card library will be restored separately.
	game.load_cardlist()
	game.get_node("phasetext").text = "Restoration"
	game.set_info("Catalogue: %d cards loaded" % game.card_database.size())
	print("LOL_RESTORATION catalogue=%d" % game.card_database.size())
	# game.initialize_game(item_deck, sample_deck)
	# game.open_library()
	
