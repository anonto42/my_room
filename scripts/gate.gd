extends Node3D

@export var interact_hint: String = "Press E to open gate"
@export var room_controller_path: NodePath

var is_open := false

@onready var room_controller: Node = get_node_or_null(room_controller_path)
@onready var door_panel: Node3D = get_node_or_null("DoorPanel")


func _ready() -> void:
	add_to_group("interactable")
	_update_hint()


func interact() -> void:
	is_open = not is_open
	_update_hint()
	if door_panel:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(door_panel, "rotation_degrees:y", -68.0 if is_open else 0.0, 0.55)
	if room_controller and room_controller.has_method("show_room_message"):
		room_controller.show_room_message("This feature is coming soon" if is_open else "Gate closed")


func _update_hint() -> void:
	interact_hint = "Press E to close gate" if is_open else "Press E to open gate"
