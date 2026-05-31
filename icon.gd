extends Sprite3D

# Var's
var coins = 5
var player_name = "robot"
var hp = 200

const SPEED = 2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	print(delta)
	rotate_y(deg_to_rad(SPEED))
	pass
