@tool
extends EditorPlugin

func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("TypeWriterLabel", "RichTextLabel", preload("./classes/type_writer_label.gd"), preload("./classes/type_writer_label_icon.svg"))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type("TypeWriterLabel")
