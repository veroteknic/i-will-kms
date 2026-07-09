extends "res://weapon_base.gd"
const BOOLET = preload("res://boolet.tscn")
const GRENADE = preload("res://grenade.tscn")
const GRENADE_THROW_FORCE = 600.0
const GRENADE_COOLDOWN = 1.5
const GRENADE_VELOCITY_INHERIT = 0.6
const SHOTGUN_RELOAD_SFX: AudioStream = preload("res://Mechanism -  Designed Mega Steam Lever-004b.wav")
const PISTOL_SHOT_SOUNDS: Array[AudioStream] = [
	preload("res://Shoot1.ogg.mp3")
]
const SHOTGUN_SHOT_SOUNDS: Array[AudioStream] = [
	preload("res://Steampunk Weapons - Shotgun 2 - Shot - 03.wav"),
	preload("res://Steampunk Weapons - Shotgun 2 - Shot - 05.wav")
]

@export_group("Shotgun")
@export var shotgun_pellet_count: int = 6
@export_range(0.0, 360.0, 0.1, "suffix:deg") var shotgun_spread_degrees: float = 14.0
@export_range(0.01, 2.0, 0.01, "suffix:s") var shotgun_fire_cooldown: float = 0.55
@export var shotgun_muzzle_local_offset: Vector2 = Vector2(28.0, -7.0)

@onready var gun_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shotgun_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D2") as AnimatedSprite2D
@onready var shotgun_muzzle: Marker2D = get_node_or_null("Marker2D2") as Marker2D
@onready var shot_sfx_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var shotgun_reload_sfx_player: AudioStreamPlayer2D = get_node_or_null("ShotgunReloadSfx") as AudioStreamPlayer2D
var grenade_cooldown_timer = 0.0
var primary_cooldown_timer: float = 0.0
var is_shotgun_equipped: bool = false
var shotgun_reloading: bool = false
var _shotgun_reload_fallback_timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func _weapon_ready() -> void:
	_rng.randomize()
	_ensure_shotgun_reload_sfx_player()
	if shotgun_reload_sfx_player and is_instance_valid(shotgun_reload_sfx_player):
		if not shotgun_reload_sfx_player.finished.is_connected(_on_shotgun_reload_sfx_finished):
			shotgun_reload_sfx_player.finished.connect(_on_shotgun_reload_sfx_finished)
	if gun_sprite:
		gun_sprite.visible = true
		gun_sprite.play("idle")
		gun_sprite.animation_finished.connect(_on_animation_finished)
	if shotgun_sprite:
		shotgun_sprite.visible = false
		shotgun_sprite.play("idle")
		shotgun_sprite.animation_finished.connect(_on_animation_finished)
	equip_pistol()


func _weapon_process(delta: float) -> void:
	_sync_shotgun_muzzle()
	grenade_cooldown_timer = max(0.0, grenade_cooldown_timer - delta)
	primary_cooldown_timer = maxf(0.0, primary_cooldown_timer - delta)
	if shotgun_reloading:
		_shotgun_reload_fallback_timer = maxf(0.0, _shotgun_reload_fallback_timer - delta)
		if _shotgun_reload_fallback_timer <= 0.0:
			if not shotgun_reload_sfx_player or not is_instance_valid(shotgun_reload_sfx_player) or not shotgun_reload_sfx_player.playing:
				shotgun_reloading = false


func _on_primary_action() -> void:
	if is_shotgun_equipped and shotgun_reloading:
		return
	if primary_cooldown_timer > 0.0:
		return

	_play_primary_shot_sound()
	if get_parent() and get_parent().has_method("add_screenshake"):
		get_parent().add_screenshake(get_parent().screenshake_shoot_amount)

	if is_shotgun_equipped:
		if not shotgun_muzzle or not is_instance_valid(shotgun_muzzle):
			return
		if shotgun_sprite:
			shotgun_sprite.play("shoot")
		var base_angle: float = (get_global_mouse_position() - shotgun_muzzle.global_position).angle()
		var spread_half: float = shotgun_spread_degrees * 0.5
		for i in range(maxi(shotgun_pellet_count, 1)):
			var pellet = BOOLET.instantiate()
			get_tree().root.add_child(pellet)
			pellet.global_position = shotgun_muzzle.global_position
			var offset_deg: float = _rng.randf_range(-spread_half, spread_half)
			pellet.rotation = base_angle + deg_to_rad(offset_deg)
		_begin_shotgun_reload()
		return

	if not muzzle:
		return

	if gun_sprite:
		gun_sprite.play("shoot")
	var bullet_instance = BOOLET.instantiate()
	get_tree().root.add_child(bullet_instance)
	bullet_instance.global_position = muzzle.global_position
	bullet_instance.rotation = (get_global_mouse_position() - muzzle.global_position).angle()


func _on_secondary_action() -> void:
	if grenade_cooldown_timer > 0.0 or not muzzle:
		return

	var grenade_instance = GRENADE.instantiate()
	get_tree().root.add_child(grenade_instance)
	grenade_instance.global_position = muzzle.global_position
	var throw_direction: Vector2 = (get_global_mouse_position() - muzzle.global_position).normalized()
	var inherited_velocity := Vector2.ZERO
	var owner_body := get_parent() as CharacterBody2D
	if owner_body:
		inherited_velocity = owner_body.velocity * GRENADE_VELOCITY_INHERIT
	grenade_instance.linear_velocity = throw_direction * GRENADE_THROW_FORCE + inherited_velocity
	grenade_cooldown_timer = GRENADE_COOLDOWN


func _on_animation_finished() -> void:
	if gun_sprite and gun_sprite.animation == "shoot":
		gun_sprite.play("idle")
	if shotgun_sprite and shotgun_sprite.animation == "shoot":
		shotgun_sprite.play("idle")


func equip_pistol() -> void:
	is_shotgun_equipped = false
	shotgun_reloading = false
	_shotgun_reload_fallback_timer = 0.0
	if shotgun_reload_sfx_player and is_instance_valid(shotgun_reload_sfx_player):
		shotgun_reload_sfx_player.stop()
	if gun_sprite:
		gun_sprite.visible = true
		gun_sprite.play("idle")
	if shotgun_sprite:
		shotgun_sprite.visible = false


func equip_shotgun() -> void:
	is_shotgun_equipped = true
	if gun_sprite:
		gun_sprite.visible = false
	if shotgun_sprite:
		shotgun_sprite.visible = true
		shotgun_sprite.play("idle")
	_sync_shotgun_muzzle()


func _sync_shotgun_muzzle() -> void:
	if not shotgun_muzzle or not is_instance_valid(shotgun_muzzle):
		return
	if not shotgun_sprite or not is_instance_valid(shotgun_sprite):
		return
	shotgun_muzzle.global_position = shotgun_sprite.to_global(shotgun_muzzle_local_offset)


func _ensure_shotgun_reload_sfx_player() -> void:
	if shotgun_reload_sfx_player and is_instance_valid(shotgun_reload_sfx_player):
		if SHOTGUN_RELOAD_SFX:
			shotgun_reload_sfx_player.stream = SHOTGUN_RELOAD_SFX
		if not shotgun_reload_sfx_player.finished.is_connected(_on_shotgun_reload_sfx_finished):
			shotgun_reload_sfx_player.finished.connect(_on_shotgun_reload_sfx_finished)
		return
	shotgun_reload_sfx_player = AudioStreamPlayer2D.new()
	shotgun_reload_sfx_player.name = "ShotgunReloadSfx"
	if SHOTGUN_RELOAD_SFX:
		shotgun_reload_sfx_player.stream = SHOTGUN_RELOAD_SFX
	add_child(shotgun_reload_sfx_player)
	shotgun_reload_sfx_player.finished.connect(_on_shotgun_reload_sfx_finished)


func _play_shotgun_reload_sound() -> void:
	_ensure_shotgun_reload_sfx_player()
	if not shotgun_reload_sfx_player or not is_instance_valid(shotgun_reload_sfx_player):
		return
	if not shotgun_reload_sfx_player.stream and SHOTGUN_RELOAD_SFX:
		shotgun_reload_sfx_player.stream = SHOTGUN_RELOAD_SFX
	shotgun_reload_sfx_player.stop()
	shotgun_reload_sfx_player.play()


func _begin_shotgun_reload() -> void:
	shotgun_reloading = true
	_shotgun_reload_fallback_timer = shotgun_fire_cooldown
	if SHOTGUN_RELOAD_SFX:
		_shotgun_reload_fallback_timer = maxf(_shotgun_reload_fallback_timer, SHOTGUN_RELOAD_SFX.get_length())
	_play_shotgun_reload_sound()


func _on_shotgun_reload_sfx_finished() -> void:
	shotgun_reloading = false
	_shotgun_reload_fallback_timer = 0.0


func _play_primary_shot_sound() -> void:
	if not shot_sfx_player or not is_instance_valid(shot_sfx_player):
		return
	var pool: Array[AudioStream] = SHOTGUN_SHOT_SOUNDS if is_shotgun_equipped else PISTOL_SHOT_SOUNDS
	if pool.is_empty():
		shot_sfx_player.play()
		return
	shot_sfx_player.stream = pool[_rng.randi_range(0, pool.size() - 1)]
	shot_sfx_player.pitch_scale = _rng.randf_range(0.96, 1.04)
	shot_sfx_player.play()


func _on_timer_timeout() -> void:
	pass
