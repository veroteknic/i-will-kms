extends "res://weapon_base.gd"

const BOOLET = preload("res://boolet.tscn")

@export var pellet_count: int = 6
@export_range(0.0, 60.0, 0.1, "suffix:deg") var spread_degrees: float = 14.0
@export_range(0.01, 2.0, 0.01, "suffix:s") var fire_cooldown: float = 0.55

var _cooldown_timer: float = 0.0
var _rng := RandomNumberGenerator.new()

@onready var gun_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _weapon_ready() -> void:
	_rng.randomize()
	if gun_sprite:
		gun_sprite.play("idle")
		gun_sprite.animation_finished.connect(_on_animation_finished)


func _weapon_process(delta: float) -> void:
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)


func _on_primary_action() -> void:
	if _cooldown_timer > 0.0 or not muzzle:
		return

	$AudioStreamPlayer2D.play()
	if get_parent() and get_parent().has_method("add_screenshake"):
		get_parent().add_screenshake(get_parent().screenshake_shoot_amount)
	if gun_sprite:
		gun_sprite.play("shoot")

	var spread_half: float = spread_degrees * 0.5
	for i in range(maxi(pellet_count, 1)):
		var pellet = BOOLET.instantiate()
		get_tree().root.add_child(pellet)
		pellet.global_position = muzzle.global_position
		var offset_deg: float = _rng.randf_range(-spread_half, spread_half)
		pellet.rotation = global_rotation + deg_to_rad(offset_deg)

	_cooldown_timer = fire_cooldown


func _on_secondary_action() -> void:
	pass


func _on_animation_finished() -> void:
	if gun_sprite and gun_sprite.animation == "shoot":
		gun_sprite.play("idle")
