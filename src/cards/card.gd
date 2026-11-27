extends Control
class_name Card

var catalogue_id: String
var setNum : int
var number : int
var card_name : String
var artwork : String
var artwork_status: String = "unmapped"
var artwork_panel: ColorRect
var artwork_texture: TextureRect
var artwork_placeholder: Label
const ArtworkResolver = preload("res://src/cards/card_artwork.gd")
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
	bind_artwork(str(data.get("edition", "tabletop")))
	
	if data.get("club") != null:
		club = data.club
	
# Shared artwork aperture, with the landscape Place using the same components.
func bind_artwork(edition: String = "tabletop") -> void:
	artwork_panel = get_node("Card/img/Artwork")
	artwork_texture = artwork_panel.get_node("Texture")
	artwork_placeholder = artwork_panel.get_node("Placeholder")
	artwork_panel.position = Vector2(10, 58)
	artwork_panel.size = Vector2(310, 218)
	match type:
		Game.Card_Types.BB:
			artwork_panel.position = Vector2(12, 88)
			artwork_panel.size = Vector2(307, 182)
		Game.Card_Types.Item:
			artwork_panel.position = Vector2(12, 88)
			artwork_panel.size = Vector2(307, 182)
		Game.Card_Types.Surprise:
			artwork_panel.position = Vector2(12, 99)
			artwork_panel.size = Vector2(307, 171)
		Game.Card_Types.Place:
			_layout_landscape()
			artwork_panel.position = Vector2(12, 62)
			artwork_panel.size = Vector2(203, 235)
	var resolved = ArtworkResolver.resolve(edition, catalogue_id)
	artwork = resolved.path
	artwork_status = resolved.status
	artwork_texture.texture = resolved.texture
	artwork_texture.visible = resolved.texture != null
	artwork_placeholder.visible = resolved.texture == null
	artwork_placeholder.text = "Artwork unavailable" if artwork_status == "missing_resource" else "Artwork not yet catalogued"
	artwork_panel.visible = face_up

func presentation_size() -> Vector2:
	return Vector2(442, 333) if type == Game.Card_Types.Place else Vector2(333, 442)

func _layout_landscape() -> void:
	card_ui.size = Vector2(436, 331)
	var frame: Control = card_ui.get_node("img")
	frame.size = Vector2(436, 331)
	cardnum_ui.position = Vector2(15, 303)
	rank_ui.position = Vector2(387, 303)
	card_ui.get_node("img/RankCaption").position = Vector2(326, 303)
	can_play.size = Vector2(438, 329)
	# A physically rotated card shows the same portrait back, rotated with it.
	cardback_ui.position = Vector2(436, 0)
	cardback_ui.rotation_degrees = 90.0

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
	if is_instance_valid(artwork_panel):
		artwork_panel.visible = face_up
	# Hide front content explicitly; rounded card back corners cannot expose labels.
	if is_instance_valid(card_ui):
		for child in card_ui.get_children():
			if child != card_ui.get_node("img") and child is CanvasItem:
				child.visible = face_up
		cardnum_ui.visible = face_up
		rank_ui.visible = face_up
		card_ui.get_node("img/RankCaption").visible = face_up

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
