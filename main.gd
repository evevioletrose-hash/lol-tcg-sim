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
	##game.initialize_game(item_deck, sample_deck)
	game.open_library()
	
