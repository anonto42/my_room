extends Node3D
class_name Interactable

@export var interact_hint: String = "Press E to use"

func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	pass
