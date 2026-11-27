extends PanelContainer

signal Resolve_Prompt(card : Card)

var possible_targets

var selection

var resolution_calls : Array[Callable]

@onready
var label = get_node("hbox/Label")
@onready
var button = get_node("hbox/Button")

func on_resolve(method : Callable):
	resolution_calls.append(method)

func _ready() -> void:
	button.pressed.connect(btn_click)
	

func prompt_selection(text, targets, player):
	possible_targets = targets
	for target in targets:
		target.get_node("Button").pressed.connect(select_card.bind(target))
		target.set_can_play(true)
	label.text = text
		
func btn_click():
	if is_valid():
		resolve()
		
func select_card(target):
	if selection != null:
		selection.unselect()
	target.select()
	selection = target
		
func is_valid():
	if selection == null:
		return false
	if possible_targets.find(selection) != -1:
		return true
	else:
		return false

func resolve():
	var solution = selection
	emit_signal("Resolve_Prompt", selection)
	selection.unselect()
	for target in possible_targets:
		target.set_can_play(false)
		target.get_node("Button").pressed.disconnect(select_card)
	for call_item in resolution_calls:
		call_item.call(solution)
	queue_free()
