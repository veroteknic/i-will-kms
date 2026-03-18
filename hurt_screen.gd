extends CanvasLayer

@onready var overlay: ColorRect = $Control/ColorRect

@export var flash_alpha: float = 0.22
@export var fade_time: float = 0.16

var flash_tween: Tween

func _ready() -> void:
	if overlay:
		overlay.color = Color(1, 0, 0, 0)

func flash() -> void:
	if not overlay:
		return
	if flash_tween:
		flash_tween.kill()
	overlay.color = Color(1, 0, 0, flash_alpha)
	flash_tween = create_tween()
	flash_tween.tween_property(overlay, "color:a", 0.0, fade_time)
