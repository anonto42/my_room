extends Node3D

@export var interact_hint: String = "Press E to open gate"
@export var room_controller_path: NodePath

var is_open := false

@onready var room_controller: Node = get_node_or_null(room_controller_path)
@onready var door_panel: Node3D = get_node_or_null("DoorPanel")
@onready var door_blocker: StaticBody3D = get_node_or_null("StaticBody3D")


func _ready() -> void:
	add_to_group("interactable")
	_update_hint()


func interact() -> void:
	is_open = not is_open
	_update_hint()
	_set_blocker_enabled(not is_open)
	if door_panel:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(door_panel, "rotation_degrees:y", -68.0 if is_open else 0.0, 0.55)
	if room_controller:
		if room_controller.has_method("set_current_zone") and is_open:
			room_controller.set_current_zone(&"city_threshold")
		if room_controller.has_method("show_world_message"):
			room_controller.show_world_message("New Harbor City is open" if is_open else "Gate closed")


func _update_hint() -> void:
	interact_hint = "Press E to close gate" if is_open else "Press E to open gate"


func _set_blocker_enabled(value: bool) -> void:
	if not door_blocker:
		return
	door_blocker.collision_layer = 2 if value else 0
	door_blocker.collision_mask = 1 if value else 0
