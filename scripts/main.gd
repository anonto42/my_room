extends Node3D

const LAYER_WORLD := 1
const LAYER_INTERACTABLE := 2
const MONITOR_X_POSITIONS: Array[float] = [-1.45, -0.45, 0.55, 1.55]
const MONITOR_Y_ROTATIONS: Array[float] = [-14.0, -5.0, 5.0, 14.0]

var _materials: Dictionary = {}
var _player: CharacterBody3D
var _player_camera: Camera3D
var _cctv_cameras: Array[Camera3D] = []
var _camera_view_index := 0
var _fan: Node
var _ac: Node
var _room_lights: Array[Light3D] = []
var _switch_buttons: Dictionary = {}
var _message_label: Label
var _message_tween: Tween


func _ready() -> void:
	_ensure_input_map()
	_make_materials()
	_create_room()
	_create_furniture()
	_create_lighting()
	_create_ui()
	_create_player()
	_create_cctv_cameras()
	GameState.fan_toggled.connect(_on_device_state_changed)
	GameState.ac_toggled.connect(_on_device_state_changed)
	_sync_switch_states()


func _ensure_input_map() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("look_left", KEY_LEFT)
	_add_key_action("look_right", KEY_RIGHT)
	_add_key_action("look_up", KEY_UP)
	_add_key_action("look_down", KEY_DOWN)
	_add_key_action("interact", KEY_E)
	_add_key_action("stand_up", KEY_E)
	_add_key_action("toggle_camera_view", KEY_C)


func _add_key_action(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.physical_keycode == keycode:
			return
	var key := InputEventKey.new()
	key.physical_keycode = keycode
	InputMap.action_add_event(action, key)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera_view"):
		_toggle_camera_view()


func _make_materials() -> void:
	_materials.floor = _material(Color(0.45, 0.32, 0.2))
	_materials.wall = _material(Color(0.78, 0.76, 0.7))
	_materials.ceiling = _material(Color(0.9, 0.88, 0.82))
	_materials.bed = _material(Color(0.35, 0.48, 0.58))
	_materials.pillow = _material(Color(0.9, 0.9, 0.86))
	_materials.dark = _material(Color(0.04, 0.045, 0.05))
	_materials.desk = _material(Color(0.24, 0.16, 0.1))
	_materials.metal = _material(Color(0.25, 0.25, 0.27))
	_materials.ac = _material(Color(0.86, 0.88, 0.86))
	_materials.ac_off = _material(Color(0.85, 0.15, 0.12), Color(0.85, 0.05, 0.03), 0.25)
	_materials.ac_on = _material(Color(0.1, 0.85, 1.0), Color(0.1, 0.85, 1.0), 1.4)
	_materials.airflow = _material(Color(0.45, 0.9, 1.0, 0.38), Color(0.25, 0.8, 1.0), 0.5)
	_materials.hand = _material(Color(0.62, 0.43, 0.33))
	_materials.light = _material(Color(1.0, 0.94, 0.72), Color(1.0, 0.85, 0.45), 1.2)
	_materials.switch_panel = _material(Color(0.93, 0.92, 0.86))
	_materials.switch_button = _material(Color(0.18, 0.2, 0.22))
	_materials.sign = _material(Color(0.08, 0.08, 0.07))
	_materials.door = _material(Color(0.34, 0.19, 0.1))
	_materials.door_trim = _material(Color(0.08, 0.06, 0.04))
	_materials.guitar_electric = _material(Color(0.85, 0.08, 0.12))
	_materials.guitar_acoustic = _material(Color(0.72, 0.42, 0.18))
	_materials.guitar_bass = _material(Color(0.08, 0.12, 0.16))
	_materials.guitar_neck = _material(Color(0.48, 0.28, 0.12))
	_materials.guitar_string = _material(Color(0.78, 0.78, 0.74))


func _material(color: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = energy
	return mat


func _create_room() -> void:
	var room := Node3D.new()
	room.name = "Room"
	add_child(room)
	_box(room, "Floor", Vector3(10, 0.2, 10), Vector3(0, -0.1, 0), _materials.floor, true)
	_box(room, "WallNorth", Vector3(10, 3, 0.2), Vector3(0, 1.5, -5), _materials.wall, true)
	_box(room, "WallSouth", Vector3(10, 3, 0.2), Vector3(0, 1.5, 5), _materials.wall, true)
	_box(room, "WallEast", Vector3(0.2, 3, 10), Vector3(5, 1.5, 0), _materials.wall, true)
	_box(room, "WallWest", Vector3(0.2, 3, 10), Vector3(-5, 1.5, 0), _materials.wall, true)
	_box(room, "Ceiling", Vector3(10, 0.2, 10), Vector3(0, 3.1, 0), _materials.ceiling, true)
	_label(room, "MY ROOM", Vector3(0, 2.05, 4.86), Vector3(0, 180, 0), 34)
	_create_gate(room)


func _create_gate(parent: Node3D) -> void:
	var gate := Node3D.new()
	gate.name = "Gate"
	gate.position = Vector3(3.0, 1.05, 4.86)
	_box(gate, "DoorFrameTop", Vector3(1.65, 0.16, 0.12), Vector3(0, 1.1, 0), _materials.door_trim, false)
	_box(gate, "DoorFrameLeft", Vector3(0.16, 2.25, 0.12), Vector3(-0.88, 0, 0), _materials.door_trim, false)
	_box(gate, "DoorFrameRight", Vector3(0.16, 2.25, 0.12), Vector3(0.88, 0, 0), _materials.door_trim, false)
	var panel := Node3D.new()
	panel.name = "DoorPanel"
	panel.position = Vector3(0, 0, -0.04)
	gate.add_child(panel)
	_box(panel, "DoorBody", Vector3(1.42, 2.05, 0.1), Vector3.ZERO, _materials.door, false)
	_box(panel, "DoorInset", Vector3(1.08, 1.42, 0.11), Vector3(0, 0.1, -0.01), _materials.door_trim, false)
	_box(panel, "DoorHandle", Vector3(0.1, 0.1, 0.12), Vector3(-0.48, -0.05, -0.11), _materials.metal, false)
	_label(gate, "GATE", Vector3(0, 1.38, -0.08), Vector3(0, 180, 0), 24)
	_add_collision_owner(gate, Vector3(1.8, 2.2, 0.6), Vector3(0, 0, -0.18))
	_add_area(gate, "InteractArea", Vector3(2.1, 2.5, 1.2), Vector3(0, 0, -0.35))
	gate.script = load("res://scripts/gate.gd")
	gate.set("room_controller_path", get_path())
	parent.add_child(gate)


func _create_furniture() -> void:
	var furniture := Node3D.new()
	furniture.name = "Furniture"
	add_child(furniture)
	_create_bed(furniture)
	_create_fan(furniture)
	_create_ac(furniture)
	_create_computer_desk(furniture)
	_create_switchboard(furniture)
	_create_guitar_wall(furniture)


func _create_bed(parent: Node3D) -> void:
	var bed := Node3D.new()
	bed.name = "Bed"
	bed.position = Vector3(-3.1, 0.25, -2.8)
	_box(bed, "MeshInstance3D", Vector3(2.1, 0.5, 3.0), Vector3.ZERO, _materials.bed, false)
	_box(bed, "Pillow", Vector3(1.8, 0.18, 0.55), Vector3(0, 0.35, -1.05), _materials.pillow, false)
	_add_collision_owner(bed, Vector3(2.1, 0.6, 3.0), Vector3.ZERO)
	_add_area(bed, "InteractArea", Vector3(2.6, 1.4, 3.4), Vector3(0, 0.5, 0))
	var sleep := Marker3D.new()
	sleep.name = "SleepPosition"
	sleep.position = Vector3(0, 0.75, -0.25)
	sleep.rotation_degrees = Vector3(0, 180, 90)
	bed.add_child(sleep)
	_label(bed, "BED", Vector3(0, 0.85, 1.65), Vector3(-22, 0, 0), 22)
	bed.script = load("res://scripts/bed.gd")
	parent.add_child(bed)


func _create_fan(parent: Node3D) -> void:
	var fan := Node3D.new()
	fan.name = "Fan"
	fan.position = Vector3(-3.1, 2.75, -2.8)
	_box(fan, "CeilingMount", Vector3(0.55, 0.12, 0.55), Vector3(0, 0.18, 0), _materials.metal, false)
	_box(fan, "FanBase", Vector3(0.18, 0.5, 0.18), Vector3(0, -0.12, 0), _materials.metal, false)
	_box(fan, "FanHub", Vector3(0.42, 0.16, 0.42), Vector3(0, -0.42, 0), _materials.metal, false)
	_box(fan, "FanBlade", Vector3(1.8, 0.04, 0.18), Vector3(0, -0.42, 0), _materials.dark, false)
	var blade_cross := _box(fan, "FanBladeCross", Vector3(0.18, 0.04, 1.8), Vector3(0, -0.42, 0), _materials.dark, false)
	blade_cross.name = "FanBladeCross"
	_add_collision_owner(fan, Vector3(2.0, 0.7, 2.0), Vector3(0, -0.25, 0))
	_add_area(fan, "InteractArea", Vector3(2.4, 2.2, 2.4), Vector3(0, -0.85, 0))
	fan.script = load("res://scripts/fan.gd")
	parent.add_child(fan)
	_fan = fan
	_label(fan, "FAN", Vector3(0, -0.9, 0), Vector3.ZERO, 20)


func _create_ac(parent: Node3D) -> void:
	var ac := Node3D.new()
	ac.name = "AC"
	ac.position = Vector3(0, 2.25, -4.88)
	_box(ac, "MeshInstance3D", Vector3(1.7, 0.45, 0.25), Vector3.ZERO, _materials.ac, false)
	_box(ac, "Vent", Vector3(1.45, 0.06, 0.05), Vector3(0, -0.16, 0.16), _materials.dark, false)
	_box(ac, "StatusLight", Vector3(0.12, 0.12, 0.05), Vector3(0.68, 0.04, 0.16), _materials.ac_off, false)
	for i in range(3):
		var stream := _box(ac, "AirStream%d" % (i + 1), Vector3(0.18, 0.04, 0.75), Vector3(-0.45 + float(i) * 0.45, -0.42, 0.48), _materials.airflow, false)
		stream.visible = false
	_add_collision_owner(ac, Vector3(1.7, 0.55, 0.3), Vector3.ZERO)
	_add_area(ac, "InteractArea", Vector3(2.2, 1.4, 1.1), Vector3(0, -0.3, 0.25))
	var particles := CPUParticles3D.new()
	particles.name = "ColdAir"
	particles.amount = 24
	particles.lifetime = 1.2
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = Vector3(0.8, 0.02, 0.02)
	particles.direction = Vector3(0, -0.4, 1)
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.8
	particles.emitting = false
	ac.add_child(particles)
	_label(ac, "AC", Vector3(0, -0.42, 0.16), Vector3.ZERO, 20)
	ac.script = load("res://scripts/ac.gd")
	parent.add_child(ac)
	_ac = ac


func _create_computer_desk(parent: Node3D) -> void:
	var computer := Node3D.new()
	computer.name = "ComputerDesk"
	computer.position = Vector3(0, 0, -4.15)
	var desk := _box(computer, "Desk", Vector3(4.0, 0.18, 1.0), Vector3(0, 0.75, 0), _materials.desk, false)
	_add_collision_child(desk, Vector3(4.0, 0.2, 1.0), Vector3.ZERO)
	_box(computer, "Keyboard", Vector3(1.0, 0.05, 0.28), Vector3(-0.25, 0.9, 0.22), _materials.dark, false)
	_box(computer, "Mouse", Vector3(0.25, 0.06, 0.36), Vector3(0.65, 0.92, 0.22), _materials.dark, false)
	var tower := _box(computer, "PCTower", Vector3(0.45, 1.0, 0.65), Vector3(2.25, 0.5, 0.0), _materials.dark, false)
	_add_collision_owner(computer, Vector3(0.55, 1.1, 0.75), tower.position)
	_add_area(computer, "PowerButtonArea", Vector3(0.9, 1.4, 1.1), tower.position)
	for i in range(4):
		_create_monitor(computer, i)
	var chair := Node3D.new()
	chair.name = "GamingChair"
	chair.position = Vector3(0, 0.55, 1.35)
	_box(chair, "MeshInstance3D", Vector3(0.9, 1.1, 0.9), Vector3(0, 0, 0), _materials.dark, false)
	_add_collision_owner(chair, Vector3(1.1, 1.2, 1.1), Vector3.ZERO)
	_add_area(chair, "InteractArea", Vector3(1.6, 1.6, 1.6), Vector3.ZERO)
	var sit := Marker3D.new()
	sit.name = "SitPosition"
	sit.position = Vector3(0, 0.95, -0.05)
	sit.rotation_degrees = Vector3(0, 180, 0)
	chair.add_child(sit)
	chair.script = load("res://scripts/gaming_chair.gd")
	chair.set("computer_path", NodePath(".."))
	computer.add_child(chair)
	_label(computer, "PC", Vector3(0, 1.95, 0.15), Vector3.ZERO, 24)
	_label(chair, "CHAIR", Vector3(0, 0.85, 0.65), Vector3.ZERO, 18)
	computer.script = load("res://scripts/computer.gd")
	parent.add_child(computer)


func _create_switchboard(parent: Node3D) -> void:
	var board := Node3D.new()
	board.name = "SwitchBoard"
	board.position = Vector3(-4.88, 1.35, 2.25)
	parent.add_child(board)
	_box(board, "Panel", Vector3(0.08, 0.95, 1.25), Vector3.ZERO, _materials.switch_panel, false)
	_label(board, "SWITCH BOARD", Vector3(0.07, 0.58, 0), Vector3(0, 90, 0), 16)
	_create_switch_button(board, "LightsSwitch", "lights", "room lights", Vector3(0.09, 0.22, -0.36))
	_create_switch_button(board, "FanSwitch", "fan", "fan", Vector3(0.09, 0.0, 0.0))
	_create_switch_button(board, "ACSwitch", "ac", "AC", Vector3(0.09, -0.22, 0.36))


func _create_switch_button(parent: Node3D, node_name: String, control_id: StringName, label: String, pos: Vector3) -> void:
	var button := Node3D.new()
	button.name = node_name
	button.position = pos
	_box(button, "ButtonFace", Vector3(0.12, 0.16, 0.28), Vector3.ZERO, _materials.switch_button, false)
	var indicator_mat := _material(Color(0.85, 0.15, 0.12), Color(0.85, 0.15, 0.12), 0.2)
	_box(button, "Indicator", Vector3(0.13, 0.05, 0.05), Vector3(0.07, 0.0, -0.16), indicator_mat, false)
	_label(button, label.to_upper(), Vector3(0.1, 0.0, 0.24), Vector3(0, 90, 0), 14)
	_add_collision_owner(button, Vector3(0.45, 0.28, 0.42), Vector3.ZERO)
	_add_area(button, "InteractArea", Vector3(0.75, 0.42, 0.58), Vector3.ZERO)
	button.script = load("res://scripts/switch_button.gd")
	button.set("control_id", control_id)
	button.set("room_controller_path", get_path())
	button.set("label", label)
	parent.add_child(button)
	_switch_buttons[control_id] = button


func _create_guitar_wall(parent: Node3D) -> void:
	var wall := Node3D.new()
	wall.name = "GuitarWall"
	wall.position = Vector3(4.86, 1.55, -2.65)
	parent.add_child(wall)
	_label(wall, "GUITARS", Vector3(-0.08, 1.0, 0), Vector3(0, -90, 0), 22)
	_create_wall_guitar(wall, "ElectricGuitar", "ELECTRIC", Vector3(-0.08, 0.0, -1.15), _materials.guitar_electric, 0.82)
	_create_wall_guitar(wall, "AcousticGuitar", "ACOUSTIC", Vector3(-0.08, 0.0, 0.0), _materials.guitar_acoustic, 1.02)
	_create_wall_guitar(wall, "BassGuitar", "BASS", Vector3(-0.08, 0.0, 1.15), _materials.guitar_bass, 0.92)


func _create_wall_guitar(parent: Node3D, node_name: String, label_text: String, pos: Vector3, body_mat: Material, body_width: float) -> void:
	var guitar := Node3D.new()
	guitar.name = node_name
	guitar.position = pos
	parent.add_child(guitar)
	_box(guitar, "WallHook", Vector3(0.12, 0.12, 0.42), Vector3(0, 0.72, 0), _materials.metal, false)
	_box(guitar, "Neck", Vector3(0.08, 1.08, 0.08), Vector3(0, 0.22, 0), _materials.guitar_neck, false)
	_box(guitar, "Headstock", Vector3(0.12, 0.22, 0.16), Vector3(0, 0.86, 0), _materials.guitar_neck, false)
	_box(guitar, "Body", Vector3(0.16, 0.62, body_width), Vector3(0, -0.58, 0), body_mat, false)
	_box(guitar, "Pickguard", Vector3(0.18, 0.24, body_width * 0.45), Vector3(-0.01, -0.48, 0), _materials.pillow, false)
	_box(guitar, "Bridge", Vector3(0.2, 0.06, body_width * 0.55), Vector3(-0.02, -0.72, 0), _materials.metal, false)
	for i in range(4):
		var offset := -0.12 + float(i) * 0.08
		_box(guitar, "String%d" % (i + 1), Vector3(0.025, 1.35, 0.012), Vector3(-0.06, -0.02, offset), _materials.guitar_string, false)
	_label(guitar, label_text, Vector3(-0.08, -1.03, 0), Vector3(0, -90, 0), 13)


func _create_monitor(parent: Node3D, index: int) -> void:
	var monitor := Node3D.new()
	monitor.name = "Monitor%d" % (index + 1)
	monitor.add_to_group("monitor_screen")
	var x: float = MONITOR_X_POSITIONS[index]
	monitor.position = Vector3(x, 1.45, -0.36)
	monitor.rotation_degrees.y = MONITOR_Y_ROTATIONS[index]
	parent.add_child(monitor)
	var screen_mat := _material(Color.BLACK)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.1, 0.3)
	screen_mat.emission_energy_multiplier = 0.0
	var screen := _box(monitor, "MeshInstance3D", Vector3(0.9, 0.52, 0.04), Vector3.ZERO, screen_mat, false)
	var viewport := SubViewport.new()
	viewport.name = "ScreenViewport"
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	monitor.add_child(viewport)
	var ui := _create_screen_ui()
	viewport.add_child(ui)
	var mat := screen.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_texture = viewport.get_texture()


func _create_screen_ui() -> Control:
	var ui := Control.new()
	ui.name = "ScreenUI"
	ui.script = load("res://scripts/screen_ui.gd")
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color("#1a1a2e")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(bg)
	var icons := GridContainer.new()
	icons.name = "DesktopIcons"
	icons.columns = 1
	icons.position = Vector2(32, 32)
	icons.size = Vector2(220, 420)
	ui.add_child(icons)
	for label in ["Files", "Music", "Browser"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(140, 64)
		icons.add_child(button)
	var window_layer := Control.new()
	window_layer.name = "WindowLayer"
	window_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(window_layer)
	var taskbar := Panel.new()
	taskbar.name = "Taskbar"
	taskbar.anchor_left = 0.0
	taskbar.anchor_right = 1.0
	taskbar.anchor_top = 1.0
	taskbar.anchor_bottom = 1.0
	taskbar.offset_top = -40.0
	ui.add_child(taskbar)
	var start := Button.new()
	start.name = "StartButton"
	start.text = "Start"
	start.position = Vector2(8, 4)
	start.size = Vector2(90, 32)
	taskbar.add_child(start)
	var clock := Label.new()
	clock.name = "ClockLabel"
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock.anchor_left = 1.0
	clock.anchor_right = 1.0
	clock.offset_left = -120.0
	clock.offset_right = -16.0
	clock.offset_top = 10.0
	clock.offset_bottom = 32.0
	taskbar.add_child(clock)
	var tray := HBoxContainer.new()
	tray.name = "SystemTray"
	tray.anchor_left = 1.0
	tray.anchor_right = 1.0
	tray.offset_left = -210.0
	tray.offset_right = -130.0
	tray.offset_top = 8.0
	tray.offset_bottom = 32.0
	taskbar.add_child(tray)
	return ui


func _create_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1, 3)
	player.collision_layer = LAYER_WORLD
	player.collision_mask = LAYER_WORLD | LAYER_INTERACTABLE
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	shape.shape = capsule
	player.add_child(shape)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.65, 0)
	player.add_child(head)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	head.add_child(camera)
	_player_camera = camera
	var left := _hand("HandLeft", Vector3(-0.25, -0.25, -0.45))
	head.add_child(left)
	var right := _hand("HandRight", Vector3(0.25, -0.25, -0.45))
	head.add_child(right)
	var ray := RayCast3D.new()
	ray.name = "InteractRay"
	ray.position = head.position
	ray.target_position = Vector3(0, 0, -2.5)
	ray.collision_mask = LAYER_WORLD | LAYER_INTERACTABLE
	ray.collide_with_areas = true
	player.add_child(ray)
	var detector := Area3D.new()
	detector.name = "InteractDetector"
	detector.position = head.position
	detector.collision_layer = 0
	detector.collision_mask = LAYER_INTERACTABLE
	player.add_child(detector)
	var detector_shape := CollisionShape3D.new()
	detector_shape.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 2.8
	detector_shape.shape = sphere
	detector.add_child(detector_shape)
	var anim := AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	player.add_child(anim)
	player.script = load("res://scripts/player.gd")
	add_child(player)
	_player = player


func _create_cctv_cameras() -> void:
	var target := Vector3(0, 1.0, 0)
	_create_cctv_camera(1, Vector3(4.55, 2.65, 4.55), target)
	_create_cctv_camera(2, Vector3(-4.55, 2.65, 4.55), target)
	_create_cctv_camera(3, Vector3(-4.55, 2.65, -4.55), target)
	_create_cctv_camera(4, Vector3(4.55, 2.65, -4.55), target)


func _create_cctv_camera(index: int, position: Vector3, target: Vector3) -> void:
	var cctv_camera := Camera3D.new()
	cctv_camera.name = "CCTVCamera%d" % index
	cctv_camera.position = position
	cctv_camera.fov = 82.0
	cctv_camera.current = false
	add_child(cctv_camera)
	cctv_camera.look_at(target, Vector3.UP)
	_cctv_cameras.append(cctv_camera)
	var mount := Node3D.new()
	mount.name = "CCTVMount%d" % index
	mount.position = position
	add_child(mount)
	_box(mount, "CameraBody", Vector3(0.38, 0.24, 0.5), Vector3.ZERO, _materials.dark, false)
	_box(mount, "CameraLens", Vector3(0.18, 0.18, 0.18), Vector3(0, 0, -0.32), _materials.metal, false)
	mount.look_at(target, Vector3.UP)


func _toggle_camera_view() -> void:
	if not _player_camera or _cctv_cameras.is_empty():
		return
	_camera_view_index = (_camera_view_index + 1) % (_cctv_cameras.size() + 1)
	_player_camera.current = _camera_view_index == 0
	for i in range(_cctv_cameras.size()):
		_cctv_cameras[i].current = _camera_view_index == i + 1
	if _player and _player.has_method("set_external_camera_view"):
		_player.set_external_camera_view(_camera_view_index != 0)
	if _camera_view_index == 0:
		show_room_message("Player view")
	else:
		show_room_message("CCTV view %d of %d" % [_camera_view_index, _cctv_cameras.size()])


func toggle_switch_control(control_id: StringName) -> void:
	match control_id:
		&"lights":
			set_room_lights_on(not GameState.room_light_on)
		&"fan":
			if _fan and _fan.has_method("set_power"):
				_fan.set_power(not GameState.fan_is_on)
			_sync_switch_states()
		&"ac":
			if _ac and _ac.has_method("set_power"):
				_ac.set_power(not GameState.ac_is_on)
			_sync_switch_states()


func set_room_lights_on(value: bool) -> void:
	GameState.room_light_on = value
	GameState.room_light_toggled.emit(value)
	for light in _room_lights:
		if not is_instance_valid(light):
			continue
		match light.name:
			"RoomLight":
				light.light_energy = 1.75 if value else 0.12
			"BedLight":
				light.light_energy = 0.95 if value else 0.0
			"SwitchBoardLight":
				light.light_energy = 0.55 if value else 0.08
			"GuitarWallLight":
				light.light_energy = 0.85 if value else 0.0
			_:
				light.light_energy = 0.6 if value else 0.0
	_sync_switch_states()


func _sync_switch_states() -> void:
	_set_switch_state(&"lights", GameState.room_light_on)
	_set_switch_state(&"fan", GameState.fan_is_on)
	_set_switch_state(&"ac", GameState.ac_is_on)


func _set_switch_state(control_id: StringName, value: bool) -> void:
	var button := _switch_buttons.get(control_id) as Node
	if button and button.has_method("set_switch_state"):
		button.set_switch_state(value)


func _on_device_state_changed(_is_on: bool) -> void:
	_sync_switch_states()


func show_room_message(text: String) -> void:
	if not _message_label:
		return
	if _message_tween:
		_message_tween.kill()
	_message_label.text = text
	_message_label.visible = true
	_message_label.modulate = Color(1, 1, 1, 1)
	_message_tween = create_tween()
	_message_tween.tween_interval(2.2)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.6)
	_message_tween.finished.connect(func() -> void:
		_message_label.visible = false
	)


func _hand(name: String, pos: Vector3) -> MeshInstance3D:
	var hand := MeshInstance3D.new()
	hand.name = name
	hand.position = pos
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.08, 0.28)
	hand.mesh = mesh
	hand.set_surface_override_material(0, _materials.hand)
	return hand


func _label(parent: Node3D, text: String, pos: Vector3, rot: Vector3, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.name = "%sLabel" % text.replace(" ", "")
	label.text = text
	label.position = pos
	label.rotation_degrees = rot
	label.font_size = font_size
	label.pixel_size = 0.01
	label.modulate = Color(0.98, 0.96, 0.82)
	label.outline_modulate = Color(0, 0, 0, 0.85)
	label.outline_size = 8
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label


func _create_lighting() -> void:
	var lighting := Node3D.new()
	lighting.name = "Lighting"
	add_child(lighting)
	var room_light := OmniLight3D.new()
	room_light.name = "RoomLight"
	room_light.light_color = Color("#fff5e0")
	room_light.light_energy = 1.75
	room_light.position = Vector3(0, 2.85, 0)
	lighting.add_child(room_light)
	_room_lights.append(room_light)
	_box(lighting, "MainLightFixture", Vector3(0.8, 0.08, 0.8), Vector3(0, 2.92, 0), _materials.light, false)
	var bed_light := OmniLight3D.new()
	bed_light.name = "BedLight"
	bed_light.light_color = Color("#fff2cf")
	bed_light.light_energy = 0.95
	bed_light.position = Vector3(-3.4, 2.25, -2.6)
	lighting.add_child(bed_light)
	_room_lights.append(bed_light)
	_box(lighting, "BedLightFixture", Vector3(0.45, 0.08, 0.45), Vector3(-3.4, 2.82, -2.6), _materials.light, false)
	var desk_lamp := OmniLight3D.new()
	desk_lamp.name = "DeskLamp"
	desk_lamp.light_color = Color("#ffeedd")
	desk_lamp.light_energy = 0.6
	desk_lamp.position = Vector3(-1.9, 1.2, -3.8)
	lighting.add_child(desk_lamp)
	_room_lights.append(desk_lamp)
	var switch_light := OmniLight3D.new()
	switch_light.name = "SwitchBoardLight"
	switch_light.light_color = Color("#fff7dd")
	switch_light.light_energy = 0.55
	switch_light.position = Vector3(-4.2, 1.75, 2.25)
	lighting.add_child(switch_light)
	_room_lights.append(switch_light)
	var guitar_light := OmniLight3D.new()
	guitar_light.name = "GuitarWallLight"
	guitar_light.light_color = Color("#fff0c8")
	guitar_light.light_energy = 0.85
	guitar_light.position = Vector3(3.8, 2.55, -2.65)
	lighting.add_child(guitar_light)
	_room_lights.append(guitar_light)
	_box(lighting, "GuitarWallLightFixture", Vector3(0.5, 0.08, 0.5), Vector3(3.8, 2.88, -2.65), _materials.light, false)
	var glow := OmniLight3D.new()
	glow.name = "MonitorGlow"
	glow.light_color = Color("#8888ff")
	glow.light_energy = 0.0
	glow.position = Vector3(0, 1.5, -4.35)
	lighting.add_child(glow)
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.12, 0.12, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.28, 0.27, 0.24)
	environment.ambient_light_energy = 0.35
	env.environment = environment
	lighting.add_child(env)
	var computer := get_node_or_null("Furniture/ComputerDesk")
	if computer:
		computer.set("monitor_glow_path", computer.get_path_to(glow))
	_sync_switch_states()


func _create_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var prompt := Label.new()
	prompt.name = "InteractPrompt"
	prompt.visible = false
	prompt.text = ""
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.anchor_left = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_top = 1.0
	prompt.anchor_bottom = 1.0
	prompt.offset_left = -260.0
	prompt.offset_right = 260.0
	prompt.offset_top = -110.0
	prompt.offset_bottom = -74.0
	ui.add_child(prompt)
	var message := Label.new()
	message.name = "RoomMessage"
	message.visible = false
	message.text = ""
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.anchor_left = 0.5
	message.anchor_right = 0.5
	message.anchor_top = 0.16
	message.anchor_bottom = 0.16
	message.offset_left = -360.0
	message.offset_right = 360.0
	message.offset_top = -28.0
	message.offset_bottom = 28.0
	message.add_theme_font_size_override("font_size", 28)
	ui.add_child(message)
	_message_label = message
	var fade := ColorRect.new()
	fade.name = "FadeOverlay"
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(fade)
	var crosshair := ColorRect.new()
	crosshair.name = "Crosshair"
	crosshair.color = Color(1, 1, 1, 0.8)
	crosshair.anchor_left = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -2.0
	crosshair.offset_right = 2.0
	crosshair.offset_top = -2.0
	crosshair.offset_bottom = 2.0
	ui.add_child(crosshair)


func _box(parent: Node, name: String, size: Vector3, pos: Vector3, mat: Material, collision: bool) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.set_surface_override_material(0, mat)
	parent.add_child(mesh_instance)
	if collision:
		_add_collision_child(mesh_instance, size, Vector3.ZERO)
	return mesh_instance


func _add_collision_child(parent: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "StaticBody3D"
	body.position = pos
	body.collision_layer = LAYER_WORLD
	body.collision_mask = LAYER_WORLD
	parent.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body


func _add_collision_owner(owner: Node3D, size: Vector3, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "StaticBody3D"
	body.position = pos
	body.collision_layer = LAYER_INTERACTABLE
	body.collision_mask = LAYER_WORLD
	body.set_meta("interactable_owner", owner)
	owner.add_child(body)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body


func _add_area(owner: Node3D, name: String, size: Vector3, pos: Vector3) -> Area3D:
	var area := Area3D.new()
	area.name = name
	area.position = pos
	area.collision_layer = LAYER_INTERACTABLE
	area.collision_mask = LAYER_WORLD
	area.set_meta("interactable_owner", owner)
	owner.add_child(area)
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	area.add_child(shape)
	return area
