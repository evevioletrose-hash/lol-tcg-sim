extends "res://src/phases/phase.gd"

var bbs_played_p1 = 0
var bbs_played_p2 = 0
var player_passed = false

func initialize(current_game: Game):
	super.initialize(current_game)
	game.state.connect("turn_player_changed", _turn_player_changed)


func start_phase():
	game.get_node("phasetext").text = "Call your B.B.'s!"

func prompt_player():
	pass
	
func player_has_bb_in_play() -> bool:
	if game.state.turn_board.get_bbs_in_play().size() == 0:
		return false
	else:
		return true
	
func _turn_player_changed(new_player : Game.Players):
	pass
