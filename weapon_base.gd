class_name WeaponBase
extends Node2D

@export_group("Aiming")
@export var look_dead_zone: float = 30.0
@export var aim_flip_deadzone: float = 8.0
@export_range(1.0, 40.0, 0.1) var aim_turn_lerp_speed: float = 18.0

@export_group("Input")
@export var primary_action: StringName = &"pewpew"
@export var secondary_action: StringName = &"grenade"

@onready var muzzle: Marker2D = $Marker2D
@onready var pose_player: AnimationPlayer = get_parent().get_node("AnimationPlayer") as AnimationPlayer
@onready var player_body: Node2D = get_parent() as Node2D

var flipped: bool = false
var facing_left: bool = false
var _current_pose_animation: StringName = &""
var _aim_initialized: bool = false


func _ready() -> void:
	_weapon_ready()
	_update_pose_animation()


func _process(delta: float) -> void:
	_weapon_process(delta)
	_update_facing_and_rotation(delta)
	_handle_weapon_input()


func _weapon_ready() -> void:
	pass


func _weapon_process(_delta: float) -> void:
	pass


func _on_primary_action() -> void:
	pass


func _on_secondary_action() -> void:
	pass


func _update_facing_and_rotation(delta: float) -> void:
	var mouse: Vector2 = get_global_mouse_position()
	var reference_x: float = global_position.x
	if player_body and is_instance_valid(player_body):
		reference_x = player_body.global_position.x
	var x_delta: float = mouse.x - reference_x
	var should_flip: bool = facing_left
	if x_delta > aim_flip_deadzone:
		should_flip = false
	elif x_delta < -aim_flip_deadzone:
		should_flip = true
	facing_left = should_flip

	if should_flip != flipped:
		flipped = should_flip
		_update_pose_animation()

	if global_position.distance_to(mouse) > look_dead_zone:
		var aim_dir: Vector2 = mouse - global_position
		var target_angle: float = aim_dir.angle()
		if not _aim_initialized:
			rotation = target_angle
			_aim_initialized = true
		else:
			var t: float = 1.0 - exp(-aim_turn_lerp_speed * maxf(delta, 0.0))
			rotation = lerp_angle(rotation, target_angle, t)


func _handle_weapon_input() -> void:
	if primary_action != StringName() and Input.is_action_just_pressed(primary_action):
		_on_primary_action()
	if secondary_action != StringName() and Input.is_action_just_pressed(secondary_action):
		_on_secondary_action()


func _update_pose_animation() -> void:
	if not pose_player or not is_instance_valid(pose_player):
		return
	var target_animation: StringName = &"gun left" if flipped else &"gun right"
	if _current_pose_animation == target_animation:
		return
	_current_pose_animation = target_animation
	pose_player.play(target_animation)
