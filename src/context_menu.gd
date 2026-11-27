extends VBoxContainer

var items = []

func add_context(btn_text, callable):
	var button = Button.new()
	button.text = btn_text
	button.pressed = callable
	items.append(button)
	
func remove_context(btn_text):
	for item in items:
		if item.text == btn_text:
			items.remove(item)
			item.queue_free()
