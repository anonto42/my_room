extends Node3D

@export var control_id: StringName
@export var room_controller_path: NodePath
@export var label: String = "Switch"
@export var is_on: bool = false

var interact_hint: String = ""

@onready var room_controller: Node = get_node_or_null(room_controller_path)
@onready var indicator: MeshInstance3D = get_node_or_null("Indicator")


func _ready() -> void:
	add_to_group("interactable")
	_update_hint()
	_update_indicator()


func interact() -> void:
	if room_controller and room_controller.has_method("toggle_switch_control"):
		room_controller.toggle_switch_control(control_id)


func set_switch_state(value: bool) -> void:
	is_on = value
	_update_hint()
	_update_indicator()


func _update_hint() -> void:
	interact_hint = "Press E to turn %s %s" % ["off" if is_on else "on", label]


func _update_indicator() -> void:
	if not indicator:
		return
	var mat := indicator.get_surface_override_material(0) as StandardMaterial3D
	if not mat:
		return
	mat.albedo_color = Color(0.25, 0.95, 0.35) if is_on else Color(0.85, 0.15, 0.12)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 0.8 if is_on else 0.2
