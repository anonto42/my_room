extends Node3D

@export var interact_hint: String = "Press E to turn on AC"

var is_on: bool = false
var _air_tween: Tween

@onready var hum: AudioStreamPlayer3D = get_node_or_null("ACHum")
@onready var cold_air: CPUParticles3D = get_node_or_null("ColdAir")
@onready var status_light: MeshInstance3D = get_node_or_null("StatusLight")
@onready var air_streams: Array[Node] = [
	get_node_or_null("AirStream1"),
	get_node_or_null("AirStream2"),
	get_node_or_null("AirStream3")
]


func _ready() -> void:
	add_to_group("interactable")
	_update_visuals()


func interact() -> void:
	set_power(not is_on)


func set_power(value: bool) -> void:
	if is_on == value:
		return
	is_on = value
	GameState.ac_is_on = is_on
	GameState.ac_toggled.emit(is_on)
	_update_visuals()


func _update_visuals() -> void:
	interact_hint = "Press E to turn off AC" if is_on else "Press E to turn on AC"
	_update_status_light()
	_update_airflow_animation()
	if hum:
		if is_on:
			hum.play()
		else:
			hum.stop()
	if cold_air:
		cold_air.emitting = is_on


func _update_status_light() -> void:
	if not status_light:
		return
	var mat := status_light.get_surface_override_material(0) as StandardMaterial3D
	if not mat:
		return
	mat.albedo_color = Color(0.1, 0.85, 1.0) if is_on else Color(0.85, 0.15, 0.12)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 1.4 if is_on else 0.25


func _update_airflow_animation() -> void:
	if _air_tween:
		_air_tween.kill()
	for stream in air_streams:
		if stream:
			stream.visible = is_on
			stream.scale = Vector3.ONE
	if not is_on:
		return
	_air_tween = create_tween()
	_air_tween.set_loops()
	for stream in air_streams:
		if not stream:
			continue
		_air_tween.parallel().tween_property(stream, "position:z", 0.78, 0.55).from(0.32)
		_air_tween.parallel().tween_property(stream, "scale:z", 1.35, 0.55).from(0.45)
		_air_tween.parallel().tween_property(stream, "scale:y", 0.55, 0.55).from(1.0)
	_air_tween.tween_interval(0.05)
