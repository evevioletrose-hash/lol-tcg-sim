extends "res://src/zones/zone.gd"
class_name DeckZone

func _init() -> void:
	face_up = false


func _on_button_pressed() -> void:
	draw(1)
