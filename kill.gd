extends Area2D

@onready var timer = $Timer
@onready var audio_stream_player_2d = $AudioStreamPlayer2D

var player: CharacterBody2D
@export var health = 3

func _ready():
	Engine.time_scale = 1
	player = get_parent().get_node("CharacterBody2D")

func _on_body_entered(_body):
	if player and is_instance_valid(player):
		player.queue_free() 
	audio_stream_player_2d.play()
	Engine.time_scale = 0.5  
	timer.start()

func _on_timer_timeout():
	Engine.time_scale = 1.0  
	get_tree().reload_current_scene()  
