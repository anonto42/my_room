extends Node3D

@export var site_id: StringName
@export var site_title: String = "City site"
@export var story_flag: StringName
@export var visit_message: String = "City system scanned"
@export var interact_hint: String = "Press E to inspect city site"
@export var room_controller_path: NodePath

@onready var room_controller: Node = get_node_or_null(room_controller_path)


func _ready() -> void:
	add_to_group("interactable")


func interact() -> void:
	if room_controller and room_controller.has_method("visit_city_site"):
		room_controller.visit_city_site(site_id, site_title, story_flag, visit_message)
