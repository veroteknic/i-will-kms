class_name Health
extends Node


signal max_health_changed(diff: int)
signal health_changed(diff: int)
signal health_depleted


@export var max_health: int = 3 : set = set_max_health, get = get_max_health
@export var immortality: bool = false : set = set_immortality, get = get_immortality
@export var debug_logs: bool = true

var immortality_timer: Timer = null

@onready var health: int = max_health : set = set_health, get = get_health


func set_max_health(value: int):
	var clamped_value = 1 if value <= 0 else value
	
	if not clamped_value == max_health:
		var difference = clamped_value - max_health
		max_health = clamped_value
		max_health_changed.emit(difference)
		if debug_logs:
			print("[Health] max_health changed by ", difference, " -> ", max_health)
		
		if health > max_health:
			health = max_health


func get_max_health() -> int:
	return max_health


func set_immortality(value: bool):
	immortality = value
	if debug_logs:
		print("[Health] immortality set to ", immortality)


func get_immortality() -> bool:
	return immortality


func set_temporary_immortality(time: float):
	if immortality_timer == null:
		immortality_timer = Timer.new()
		immortality_timer.one_shot = true
		add_child(immortality_timer)
	
	if immortality_timer.timeout.is_connected(set_immortality):
		immortality_timer.timeout.disconnect(set_immortality)
	
	immortality_timer.set_wait_time(time)
	immortality_timer.timeout.connect(set_immortality.bind(false))
	immortality = true
	if debug_logs:
		print("[Health] temporary immortality for ", time, "s")
	immortality_timer.start()


func set_health(value: int):
	if value < health and immortality:
		if debug_logs:
			print("[Health] damage blocked by immortality. health=", health, " attempted=", value)
		return
	
	var clamped_value = clampi(value, 0, max_health)
	
	if clamped_value != health:
		var difference = clamped_value - health
		health = clamped_value
		health_changed.emit(difference)
		if debug_logs:
			print("[Health] health changed by ", difference, " -> ", health, "/", max_health)
		
		if health == 0:
			health_depleted.emit()
			if debug_logs:
				print("[Health] depleted")


func get_health():
	return health
