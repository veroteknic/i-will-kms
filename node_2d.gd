extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func change_scene_to_file(target: String) -> void:
	$AnimationPlayer.play("dissolve")
	await($AnimationPlayer.animation_finished)
	get_tree().change_scene_to_file(target)
	$AnimationPlayer.play_backwards("dissolve")
#i added a transition
