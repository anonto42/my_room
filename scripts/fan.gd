extends Node3D

@export var interact_hint: String = "Press E to turn on fan"
@export var max_rotation_speed_degrees: float = 300.0

var is_on: bool = false
var _rotation_speed: float = 0.0
var _speed_tween: Tween

@onready var fan_blade: MeshInstance3D = $FanBlade
@onready var hum: AudioStreamPlayer3D = get_node_or_null("FanHum")


func _ready() -> void:
	add_to_group("interactable")
	_update_hint()


func _process(delta: float) -> void:
	if absf(_rotation_speed) > 0.01:
		fan_blade.rotate_y(deg_to_rad(_rotation_speed) * delta)


func interact() -> void:
	set_power(not is_on)


func set_power(value: bool) -> void:
	if is_on == value:
		return
	is_on = value
	GameState.fan_is_on = is_on
	GameState.fan_toggled.emit(is_on)
	if _speed_tween:
		_speed_tween.kill()
	_speed_tween = create_tween()
	_speed_tween.tween_property(self, "_rotation_speed", max_rotation_speed_degrees if is_on else 0.0, 0.5)
	if hum:
		if is_on:
			hum.play()
		else:
			hum.stop()
	_update_hint()


func _update_hint() -> void:
	interact_hint = "Press E to turn off fan" if is_on else "Press E to turn on fan"
