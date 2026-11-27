extends "res://src/cards/play_effects/play_effect.gd"

## turn one face down bb face up
func on_play():
	var bbs = Game.get_all_bbs_in_play()
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
		2:
			
