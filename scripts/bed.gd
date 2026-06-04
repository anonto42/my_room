extends Node3D

@export var interact_hint: String = "Press E to sleep"
@export_node_path("Marker3D") var sleep_position_path: NodePath = ^"SleepPosition"

@onready var sleep_position: Marker3D = get_node(sleep_position_path)


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player and player.has_method("enter_sleep"):
		player.enter_sleep(sleep_position)
