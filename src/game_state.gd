extends Node

signal player_played_card(player : Game.Players, card : Card)
signal phases_changed(new_phase : Game.Game_Phases)
signal turn_player_switched(new_turn_player : Game.Players)
signal priority_passed(priority_player : Game.Players)

var board_1 : DanceFloor
var board_2 : DanceFloor

var my_player : Game.Players
var my_board : DanceFloor

var opponent : Game.Players
var opp_board : DanceFloor

var phase_state : Phase
var current_phase : Game.Game_Phases

var turn_player : Game.Players
var turn_board : DanceFloor

var prio_player : Game.Players
var prio_board : DanceFloor

func get_board_by_player(player : Game.Players):
	if player == Game.Players.P1:
		return board_1
	else:
		return board_2

func initialize(game : Game):
	board_1 = game.get_node("Board/P1 Board")
	board_2 = game.get_node("Board/P2 Board")

func try_play_card(card, zone):
	pass

func load_deck(player, deck_cards : Array[Card]):
	get_board_by_player(player).deck_zone.set_cards(deck_cards)

func get_active_board() -> DanceFloor:
	if prio_board != null:
		return prio_board
	else:
		return turn_board
		
func set_priority(player : Game.Players):
	prio_player = player
	prio_board = get_board_by_player(player)
	emit_signal("priority_passed", player)

func change_turn_player():
	if turn_player == Game.Players.P1:
		set_turn_player(Game.Players.P2)
	else:
		set_turn_player(Game.Players.P1)

func set_my_player(player : Game.Players):
	my_player = player
	my_board = get_board_by_player(player)

func set_turn_player(new_player : Game.Players):
	if new_player != turn_player:
		emit_signal("turn_player_switched", new_player)
	
	turn_player = new_player
	turn_board = get_board_by_player(new_player)

func draw(player: Game.Players, count : int):
	var board = get_board_by_player(player)
	board.deck_zone.draw(count)
	
func set_phase(phase : Game.Game_Phases):
	# Create a new phase object
	var new_phase
	match phase:
		Game.Game_Phases.Start_Game:
			new_phase = load("res://src/phases/new_game.tscn").instantiate()
		Game.Game_Phases.Call_BB:
			new_phase = load("res://src/phases/call_bb_phase.tscn").instantiate()
	add_child(new_phase)
	new_phase.initialize(get_parent())
	phase_state = new_phase
	current_phase = phase
