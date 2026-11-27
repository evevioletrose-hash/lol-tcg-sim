extends Node
class_name Card

var catalogue_id: String
var setNum : int
var number : int
var card_name : String
var artwork : String
var rank : int
var text : String
var club : Game.Clubs
var type : Game.Card_Types

var rank_ui
var cardnum_ui
var cardback_ui
var card_ui

var selected = false
var zone : Zone
var face_up = true

@onready
var can_play = get_node("Card/img/can_play")


func populate(data):
	cardnum_ui = get_node("Card/img/card_num")
	rank_ui = get_node("Card/img/card_rank")
	cardback_ui = get_node("Card/img/back")
	card_ui = get_node("Card")
	# card_number,Have,Name,type,rank,style,groove,text,club,phase
	catalogue_id = data.number
	var data_card_num = catalogue_id.split('-')
	setNum = int(data_card_num[0])
	number = int(data_card_num[1])
	card_name = data.name
	rank = data.rank
	text = data.text
	type = data.type
	
	if data.get("club") != null:
		club = data.club
	
func update_cardtext():
	rank_ui.text = str(rank)
	cardnum_ui.text = catalogue_id

func set_face(up = true):
	if up:
		cardback_ui.visible = false
		face_up = true
	else:
		cardback_ui.visible = true
		face_up = false

func highlight():
	if(!selected):
		card_ui.position.y = -350
	
func unhighlight():
	if(!selected):
		card_ui.position.y = 0
	
func select():
	selected = true
	card_ui.position.y = -550

func unselect():
	selected = false
	card_ui.position.y = 0

func set_can_play(val : bool):
	can_play.visible = val
