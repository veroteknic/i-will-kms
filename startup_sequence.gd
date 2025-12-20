extends Control

const GAME_SCENE := preload("res://map.tscn")

@onready var fade := $ColorRect

func _ready():
	pass
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("skip"):
		SceneTransition.change_scene_to_file("res://map.tscn")
func _on_rich_text_label_typewriting_done() -> void:
	fade.modulate.a = 1.0
	SceneTransition.change_scene_to_file("res://map.tscn")
