extends Node3D

@export var interact_hint: String = "Press E to sit down"
@export_node_path("Marker3D") var sit_position_path: NodePath = ^"SitPosition"
@export_node_path("Node") var computer_path: NodePath

var is_occupied: bool = false

@onready var sit_position: Marker3D = get_node(sit_position_path)
@onready var computer: Node = get_node_or_null(computer_path)


func _ready() -> void:
	add_to_group("interactable")
	_update_hint()


func interact() -> void:
	if is_occupied:
		var player := get_tree().current_scene.get_node_or_null("Player")
		if player and player.has_method("leave_sitting"):
			player.leave_sitting()
	else:
		sit()


func sit() -> void:
	var player := get_tree().current_scene.get_node_or_null("Player")
	if not player or not player.has_method("enter_sitting"):
		return
	is_occupied = true
	GameState.player_sat_at_pc.emit()
	if computer and computer.has_method("set_player_at_pc"):
		computer.set_player_at_pc(true)
	_update_hint()
	player.enter_sitting(sit_position, self)


func stand() -> void:
	is_occupied = false
	GameState.player_left_pc.emit()
	if computer and computer.has_method("set_player_at_pc"):
		computer.set_player_at_pc(false)
	_update_hint()


func _update_hint() -> void:
	interact_hint = "Press E to stand up" if is_occupied else "Press E to sit down"
