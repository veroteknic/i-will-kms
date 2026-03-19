extends CanvasLayer

@onready var hearts: Array = [$HBoxContainer/Heart1, $HBoxContainer/Heart2, $HBoxContainer/Heart3]


func update_hearts(current_health: int) -> void:
	for i in range(hearts.size()):
		var heart = hearts[i]
		if i < current_health:
			heart.get_node("AnimatedSprite2D").play("full")
		else:
			heart.get_node("AnimatedSprite2D").play("empty")
