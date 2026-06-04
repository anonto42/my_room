extends Node

var player_is_sitting: bool = false
var player_is_sleeping: bool = false

var fan_is_on: bool = false
var ac_is_on: bool = false
var pc_is_on: bool = false

var room_light_on: bool = true
var current_time_of_day: float = 8.0

signal fan_toggled(is_on: bool)
signal ac_toggled(is_on: bool)
signal pc_toggled(is_on: bool)
signal room_light_toggled(is_on: bool)
signal player_sat_at_pc
signal player_left_pc
signal player_slept
