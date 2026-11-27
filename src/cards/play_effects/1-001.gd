extends "res://src/cards/play_effects/play_effect.gd"

## Turn one face-down B.B. face up.
## Unwired prototype: multiple-target selection is deferred.
func on_play(game: Game):
	var bbs = game.state.board_1.get_bbs_in_play() + game.state.board_2.get_bbs_in_play()
	var targets = []
	for bb in bbs:
		if not bb.face_up:
			targets.append(bb)
	match targets.size():
		0:
			resolve()
		1:
			targets[0].set_face(true)
			resolve()
		_:
			push_warning("Pop Heart: target selection not implemented yet")
