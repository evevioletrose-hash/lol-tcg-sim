extends Control
class_name Phase

var game

func initialize(current_game: Game):
	game = current_game
	start_phase()
	
func start_phase():
	pass

func prompt_player():
	pass

func resolve_phase():
	queue_free()
