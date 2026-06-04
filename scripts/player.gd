extends CharacterBody3D

const WALK_SPEED = 4.0
const GRAVITY = -9.8
const MOUSE_SENSITIVITY = 0.002
const TRACKPAD_PAN_SENSITIVITY = 0.012
const KEYBOARD_LOOK_SPEED = 2.4
const INTERACT_DISTANCE = 2.5
const HEAD_CLAMP_UP = -70.0
const HEAD_CLAMP_DOWN = 80.0

var is_sitting: bool = false
var is_sleeping: bool = false
var current_interact_target: Node = null
var input_locked: bool = false
var external_camera_view: bool = false

signal sat_down
signal stood_up
signal fell_asleep
signal woke_up

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hand_left: MeshInstance3D = $Head/HandLeft
@onready var hand_right: MeshInstance3D = $Head/HandRight
@onready var interact_ray: RayCast3D = $InteractRay
@onready var interact_detector: Area3D = get_node_or_null("InteractDetector")
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _hud_prompt: Label
var _fade_overlay: ColorRect
var _spawn_transform: Transform3D
var _standing_head_transform: Transform3D
var _sit_source: Node = null
var _sleep_can_wake: bool = false
var _sleep_return_transform: Transform3D
var _sleep_return_head_transform: Transform3D
var _nearby_interactables: Array[Node] = []
var _nearby_interactable_counts: Dictionary = {}
var _standing_collision_layer: int = 0
var _standing_collision_mask: int = 0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	interact_ray.target_position = Vector3(0, 0, -INTERACT_DISTANCE)
	interact_ray.enabled = true
	interact_ray.collide_with_areas = true
	if interact_detector:
		interact_detector.body_entered.connect(_on_interact_detector_entered)
		interact_detector.body_exited.connect(_on_interact_detector_exited)
		interact_detector.area_entered.connect(_on_interact_detector_entered)
		interact_detector.area_exited.connect(_on_interact_detector_exited)
	_spawn_transform = global_transform
	_standing_head_transform = head.transform
	_standing_collision_layer = collision_layer
	_standing_collision_mask = collision_mask
	hand_left.visible = false
	hand_right.visible = false
	var ui := get_tree().current_scene.get_node_or_null("UI")
	if ui:
		_hud_prompt = ui.get_node_or_null("InteractPrompt")
		_fade_overlay = ui.get_node_or_null("FadeOverlay")
	_set_prompt("")


func _unhandled_input(event: InputEvent) -> void:
	if external_camera_view:
		return
	if event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	if event is InputEventMouseMotion and not input_locked and not is_sleeping:
		_handle_mouse_look(event.relative)
	if event is InputEventPanGesture and not input_locked and not is_sleeping:
		_handle_trackpad_pan(event.delta)
	if event.is_action_pressed("interact") or event.is_action_pressed("stand_up"):
		if input_locked:
			return
		if is_sleeping:
			if _sleep_can_wake:
				_finish_sleep()
			return
		if is_sitting:
			leave_sitting()
			return
		_update_interact_target()
		if current_interact_target and current_interact_target.has_method("interact"):
			current_interact_target.interact()


func _physics_process(delta: float) -> void:
	if external_camera_view:
		velocity = Vector3.ZERO
		_set_prompt("")
		return
	_update_interact_target()
	if not input_locked and not is_sleeping:
		_handle_keyboard_look(delta)
	if is_sitting or is_sleeping or input_locked:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * WALK_SPEED if direction else move_toward(velocity.x, 0.0, WALK_SPEED)
	velocity.z = direction.z * WALK_SPEED if direction else move_toward(velocity.z, 0.0, WALK_SPEED)
	move_and_slide()


func _handle_mouse_look(relative: Vector2) -> void:
	if is_sitting:
		rotate_y(-relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x - relative.y * MOUSE_SENSITIVITY, deg_to_rad(HEAD_CLAMP_UP), deg_to_rad(HEAD_CLAMP_DOWN))
	else:
		rotate_y(-relative.x * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x - relative.y * MOUSE_SENSITIVITY, deg_to_rad(HEAD_CLAMP_UP), deg_to_rad(HEAD_CLAMP_DOWN))


func _handle_trackpad_pan(delta: Vector2) -> void:
	rotate_y(-delta.x * TRACKPAD_PAN_SENSITIVITY)
	head.rotation.x = clamp(head.rotation.x - delta.y * TRACKPAD_PAN_SENSITIVITY, deg_to_rad(HEAD_CLAMP_UP), deg_to_rad(HEAD_CLAMP_DOWN))


func _handle_keyboard_look(delta: float) -> void:
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look == Vector2.ZERO:
		return
	rotate_y(-look.x * KEYBOARD_LOOK_SPEED * delta)
	head.rotation.x = clamp(head.rotation.x - look.y * KEYBOARD_LOOK_SPEED * delta, deg_to_rad(HEAD_CLAMP_UP), deg_to_rad(HEAD_CLAMP_DOWN))


func _update_interact_target() -> void:
	interact_ray.global_position = camera.global_position
	interact_ray.global_rotation = camera.global_rotation
	interact_ray.force_raycast_update()
	if is_sleeping:
		_set_prompt("Press E to get up | Press C for CCTV views" if _sleep_can_wake else "Press C for CCTV views")
		return
	if is_sitting:
		_set_prompt("Press E to stand up")
		return
	current_interact_target = null
	if interact_ray.is_colliding():
		current_interact_target = _resolve_interactable(interact_ray.get_collider())
	if not current_interact_target:
		current_interact_target = _get_best_nearby_interactable()
	if current_interact_target:
		_set_prompt(str(current_interact_target.get("interact_hint")))
	else:
		_set_prompt("")


func _resolve_interactable(node: Object) -> Node:
	var current := node as Node
	while current:
		if current.has_meta("interactable_owner"):
			return current.get_meta("interactable_owner")
		if current.is_in_group("interactable") and current.has_method("interact"):
			return current
		current = current.get_parent()
	return null


func _get_best_nearby_interactable() -> Node:
	var best: Node = null
	var best_score := -INF
	var camera_forward := -camera.global_transform.basis.z.normalized()
	for target in _nearby_interactables:
		if not is_instance_valid(target) or not target.has_method("interact"):
			continue
		var target_3d := target as Node3D
		if not target_3d:
			continue
		var to_target := target_3d.global_position - camera.global_position
		var distance := to_target.length()
		if distance <= 0.001 or distance > INTERACT_DISTANCE + 0.8:
			continue
		var direction := to_target / distance
		var facing := camera_forward.dot(direction)
		if facing < -0.15:
			continue
		var score := facing * 2.0 - distance * 0.25
		if score > best_score:
			best_score = score
			best = target
	return best


func _on_interact_detector_entered(node: Node) -> void:
	var interactable := _resolve_interactable(node)
	if not interactable:
		return
	_nearby_interactable_counts[interactable] = int(_nearby_interactable_counts.get(interactable, 0)) + 1
	if not _nearby_interactables.has(interactable):
		_nearby_interactables.append(interactable)


func _on_interact_detector_exited(node: Node) -> void:
	var interactable := _resolve_interactable(node)
	if not interactable or not _nearby_interactable_counts.has(interactable):
		return
	var count := int(_nearby_interactable_counts[interactable]) - 1
	if count <= 0:
		_nearby_interactable_counts.erase(interactable)
		_nearby_interactables.erase(interactable)
	else:
		_nearby_interactable_counts[interactable] = count


func _set_prompt(text: String) -> void:
	if not _hud_prompt:
		return
	_hud_prompt.text = text
	_hud_prompt.visible = not text.is_empty()


func set_external_camera_view(is_active: bool) -> void:
	external_camera_view = is_active
	if is_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		velocity = Vector3.ZERO
		_set_prompt("")
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func enter_sitting(sit_position: Marker3D, source: Node) -> void:
	if input_locked or is_sitting or is_sleeping:
		return
	input_locked = true
	_sit_source = source
	is_sitting = true
	GameState.player_is_sitting = true
	hand_left.visible = true
	hand_right.visible = true
	_standing_collision_layer = collision_layer
	_standing_collision_mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	var sit_body_position := sit_position.global_position - (sit_position.global_transform.basis * head.position)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", sit_body_position, 0.8)
	tween.parallel().tween_property(self, "global_rotation", sit_position.global_rotation, 0.8)
	tween.parallel().tween_property(head, "rotation", Vector3.ZERO, 0.8)
	tween.finished.connect(func() -> void:
		input_locked = false
		sat_down.emit()
	)


func leave_sitting() -> void:
	if input_locked or not is_sitting:
		return
	input_locked = true
	var stand_pos := global_position + (global_transform.basis.z * -0.9)
	stand_pos.y = _spawn_transform.origin.y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", stand_pos, 0.8)
	tween.parallel().tween_property(head, "transform", _standing_head_transform, 0.8)
	tween.finished.connect(func() -> void:
		is_sitting = false
		input_locked = false
		collision_layer = _standing_collision_layer
		collision_mask = _standing_collision_mask
		hand_left.visible = false
		hand_right.visible = false
		GameState.player_is_sitting = false
		if _sit_source and _sit_source.has_method("stand"):
			_sit_source.stand()
		stood_up.emit()
	)


func enter_sleep(sleep_position: Marker3D) -> void:
	if input_locked or is_sleeping:
		return
	input_locked = true
	is_sleeping = true
	_sleep_can_wake = false
	_sleep_return_transform = global_transform
	_sleep_return_head_transform = head.transform
	GameState.player_is_sleeping = true
	fell_asleep.emit()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "global_position", sleep_position.global_position, 1.5)
	tween.parallel().tween_property(camera, "global_rotation", sleep_position.global_rotation, 1.5)
	if _fade_overlay:
		tween.parallel().tween_property(_fade_overlay, "color", Color(0, 0, 0, 1), 1.5)
	tween.finished.connect(func() -> void:
		GameState.player_slept.emit()
		await get_tree().create_timer(2.0).timeout
		_sleep_can_wake = true
		input_locked = false
		_set_prompt("Press E to get up | Press C for CCTV views")
	)


func _finish_sleep() -> void:
	input_locked = true
	_sleep_can_wake = false
	global_transform = _sleep_return_transform
	head.transform = _sleep_return_head_transform
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	var tween := create_tween()
	if _fade_overlay:
		tween.tween_property(_fade_overlay, "color", Color(0, 0, 0, 0), 1.0)
	tween.finished.connect(func() -> void:
		is_sleeping = false
		input_locked = false
		GameState.player_is_sleeping = false
		woke_up.emit()
	)
