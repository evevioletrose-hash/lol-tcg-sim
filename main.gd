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
	if "--profile-test" in OS.get_cmdline_user_args():
		get_tree().quit(preload("res://src/profiles/profile_store_test.gd").new().run())
		return
	var game = preload("res://src/game.tscn").instantiate()
	add_child(game)
	game.load_cardlist()
	if not game.catalogue_loaded:
		push_error("LOL_CATALOGUE load failed")
		get_tree().quit(1)
		return
	print("LOL_RESTORATION catalogue=%d" % game.card_database.size())
	if "--board" in OS.get_cmdline_user_args():
		game.get_node("phasetext").text = "Restoration"
		game.set_info("Catalogue: %d cards loaded" % game.card_database.size())
		return

	var editor_test = "--catalogue-editor-test" in OS.get_cmdline_user_args()
	var reconciliation_test = "--catalogue-reconciliation-test" in OS.get_cmdline_user_args()
	var provenance_test = "--catalogue-provenance-test" in OS.get_cmdline_user_args()
	var archivist = editor_test or reconciliation_test or provenance_test or "--catalogue-editor" in OS.get_cmdline_user_args()
	if archivist and not OS.has_feature("editor"):
		push_error("Catalogue editor is only available in editor builds")
		get_tree().quit(1)
		return
	var library = game.open_library(archivist)
	var testing = editor_test or reconciliation_test or provenance_test or "--card-workshop-test" in OS.get_cmdline_user_args()
	if library == null or not library.has_method("run_smoke_test"):
		push_error("LOL_WORKSHOP initialization failed")
		if testing:
			get_tree().quit(1)
		return
	# Containers lay out their children on deferred notifications.
	await get_tree().process_frame
	await get_tree().process_frame
	if testing:
		if provenance_test:
			get_tree().quit(library.run_provenance_test())
		elif reconciliation_test:
			get_tree().quit(library.run_reconciliation_test())
		else:
			get_tree().quit(library.run_editor_test() if editor_test else library.run_smoke_test())
	else:
		if not archivist:
			library.attach_profiles(preload("res://src/profiles/profile_store.gd").new())
		library.report_layout()
	# game.initialize_game(item_deck, sample_deck)
