extends Control


func _ready() -> void:
	pass


func _on_retry_button_pressed() -> void:
	get_tree().change_scene_to_file("res://map.tscn")


func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://startup_sequence.tscn")
