extends "res://src/phases/phase.gd"

func initialize(current_game: Game):
	super.initialize(current_game)

func start_phase():
	# Shuffle Decks
	# Each player draws 5 cards
	game.state.draw(Game.Players.P1, 5)
	game.state.draw(Game.Players.P2, 5)
	
	# Decide who goes first
	var firstPlayer = randi()%2 + 1
	game.state.set_turn_player(firstPlayer)

	# Move to the CallBB phase
	game.state.set_phase(Game.Game_Phases.Call_BB)
	resolve_phase()
