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
	game.load_cardlist()
	print("LOL_RESTORATION catalogue=%d" % game.card_database.size())
	if "--board" in OS.get_cmdline_user_args():
		game.get_node("phasetext").text = "Restoration"
		game.set_info("Catalogue: %d cards loaded" % game.card_database.size())
		return

	var library = game.open_library()
	var testing = "--card-workshop-test" in OS.get_cmdline_user_args()
	if library == null or not library.has_method("run_smoke_test"):
		push_error("LOL_WORKSHOP initialization failed")
		if testing:
			get_tree().quit(1)
		return
	# Containers lay out their children on deferred notifications.
	await get_tree().process_frame
	await get_tree().process_frame
	if testing:
		get_tree().quit(library.run_smoke_test())
	else:
		library.report_layout()
	# game.initialize_game(item_deck, sample_deck)
