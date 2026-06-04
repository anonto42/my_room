extends Node3D

@export var interact_hint: String = "Press E to turn on PC"
@export_node_path("OmniLight3D") var monitor_glow_path: NodePath

var is_powered_on: bool = false
var current_active_monitor: int = 0
var player_at_pc: bool = false

var monitor_glow: OmniLight3D
@onready var startup_sound: AudioStreamPlayer3D = get_node_or_null("PCStartup")
@onready var hum: AudioStreamPlayer3D = get_node_or_null("PCHum")


func _ready() -> void:
	add_to_group("interactable")
	_apply_power_state()


func interact() -> void:
	if is_powered_on:
		power_off()
	else:
		power_on()


func power_on() -> void:
	is_powered_on = true
	GameState.pc_is_on = true
	GameState.pc_toggled.emit(true)
	if startup_sound:
		startup_sound.play()
	if hum:
		hum.play()
	_apply_power_state()


func power_off() -> void:
	is_powered_on = false
	GameState.pc_is_on = false
	GameState.pc_toggled.emit(false)
	if hum:
		hum.stop()
	_apply_power_state()


func set_player_at_pc(value: bool) -> void:
	player_at_pc = value
	_apply_power_state()


func _apply_power_state() -> void:
	monitor_glow = get_node_or_null(monitor_glow_path)
	interact_hint = "Press E to turn off PC" if is_powered_on else "Press E to turn on PC"
	if monitor_glow:
		monitor_glow.light_energy = 0.5 if is_powered_on else 0.0
	for monitor in get_tree().get_nodes_in_group("monitor_screen"):
		if not is_ancestor_of(monitor):
			continue
		var screen_mesh := monitor.get_node_or_null("MeshInstance3D") as MeshInstance3D
		var screen_ui := monitor.get_node_or_null("ScreenViewport/ScreenUI")
		if screen_ui:
			screen_ui.visible = is_powered_on
		if screen_mesh:
			var mat := screen_mesh.get_surface_override_material(0) as StandardMaterial3D
			if mat:
				mat.emission_energy_multiplier = 0.5 if is_powered_on else 0.0
