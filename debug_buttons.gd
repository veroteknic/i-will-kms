extends Control

@onready var result_label = $VBoxContainer/ResultLabel


func _ready() -> void:
	print("Debug scene loaded")
	result_label.text = "Ready - Click a button"


func _on_button_1_pressed() -> void:
	print("Button 1 pressed!")
	result_label.text = "Button 1 WORKS!"


func _on_button_2_pressed() -> void:
	print("Button 2 pressed!")
	result_label.text = "Button 2 WORKS!"


func _on_button_3_pressed() -> void:
	print("Button 3 pressed - changing scene...")
	result_label.text = "Going to map..."
	get_tree().change_scene_to_file("res://map.tscn")
