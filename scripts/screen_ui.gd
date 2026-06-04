extends Control

@onready var clock_label: Label = $Taskbar/ClockLabel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_update_clock()


func _process(_delta: float) -> void:
	_update_clock()


func _update_clock() -> void:
	var time := Time.get_time_dict_from_system()
	clock_label.text = "%02d:%02d" % [time.hour, time.minute]
