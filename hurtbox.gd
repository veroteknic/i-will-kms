class_name HurtBox
extends Area2D


signal received_damage(damage: int)
signal received_hit(source: Area2D)


@export var health: Health
@export var debug_logs: bool = true
@export_range(0.05, 2.0, 0.01, "suffix:s") var contact_damage_interval: float = 0.4
@export_range(0.0, 2.0, 0.01, "suffix:s") var post_hit_invincibility_time: float = 0.35

var overlap_hitboxes: Dictionary = {}
var contact_tick_accumulator: float = 0.0

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	if overlap_hitboxes.is_empty():
		contact_tick_accumulator = 0.0
		return

	contact_tick_accumulator += delta
	if contact_tick_accumulator < contact_damage_interval:
		return
	contact_tick_accumulator = 0.0

	for key in overlap_hitboxes.keys():
		var area: Area2D = overlap_hitboxes.get(key)
		if area and is_instance_valid(area):
			_apply_hitbox_damage(area)

func _on_area_entered(area: Area2D) -> void:
	if area is HitBox:
		overlap_hitboxes[area.get_instance_id()] = area
		_apply_hitbox_damage(area)


func _on_area_exited(area: Area2D) -> void:
	if area is HitBox:
		overlap_hitboxes.erase(area.get_instance_id())


func _apply_hitbox_damage(area: Area2D) -> void:
	if not health:
		return
	if not area or not is_instance_valid(area):
		return
	if not area is HitBox:
		return

	var hitbox := area as HitBox
	if debug_logs:
		print("[HurtBox] hit by HitBox. incoming_damage=", hitbox.damage)

	var previous_health := health.health
	health.health -= hitbox.damage
	var applied_damage := previous_health - health.health
	if applied_damage > 0:
		if post_hit_invincibility_time > 0.0 and health.has_method("set_temporary_immortality"):
			health.set_temporary_immortality(post_hit_invincibility_time)
		if debug_logs:
			print("[HurtBox] applied_damage=", applied_damage, " remaining_health=", health.health)
		received_damage.emit(applied_damage)
		received_hit.emit(area)
	elif debug_logs:
		print("[HurtBox] no damage applied")
