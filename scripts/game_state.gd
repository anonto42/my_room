extends Node

var player_is_sitting: bool = false
var player_is_sleeping: bool = false

var fan_is_on: bool = false
var ac_is_on: bool = false
var pc_is_on: bool = false

var room_light_on: bool = true
var current_time_of_day: float = 8.0

var current_zone: StringName = &"apartment"
var current_chapter: StringName = &"chapter_01_city_wakes"
var city_reputation: int = 0
var visited_city_sites: Dictionary = {}
var city_story_flags: Dictionary = {}
var active_objectives: Array[String] = [
	"Open the apartment gate",
	"Find the city command points",
	"Learn what the city needs before the final assets arrive"
]

signal fan_toggled(is_on: bool)
signal ac_toggled(is_on: bool)
signal pc_toggled(is_on: bool)
signal room_light_toggled(is_on: bool)
signal player_sat_at_pc
signal player_left_pc
signal player_slept
signal zone_changed(zone_id: StringName)
signal city_site_visited(site_id: StringName, story_flag: StringName)
signal objective_updated(objective: String)
