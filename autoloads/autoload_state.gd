extends Node

const MAX_LIVES := 3

const SPOOK_MUSIC := preload("res://audio/Music/Spook.mp3")
var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "GlobalMusic"
	music_player.stream = SPOOK_MUSIC
	music_player.volume_db = -6.0
	add_child(music_player)
	if music_player.stream is AudioStreamMP3:
		music_player.stream.loop = true
	music_player.play()


var lives := MAX_LIVES

var has_checkpoint := false
var checkpoint_position := Vector2.ZERO

#Loading the Initial Camera Specs for Game Start
#Top floor:     -950
#Second floor:  -540
#Third floor:   -156
#Boss floor:     250
var checkpoint_camera_y := -950.0
var checkpoint_camera_limit_left := -32
var checkpoint_camera_limit_right := 4720
var checkpoint_camera_limit_bottom := 10000000
var checkpoint_camera_zoom := Vector2(2.5,2.5)
var checkpoint_camera_offset := Vector2(0.0,-105.0)


func set_checkpoint(new_position: Vector2,new_camera_y: float,new_limit_left: int,new_limit_right: int,new_limit_bottom: int = 10000000,new_camera_zoom: Vector2 = Vector2(2.5,2.5),new_camera_offset: Vector2 = Vector2(0.0,-105.0)) -> void:
	checkpoint_position = new_position
	checkpoint_camera_y = new_camera_y
	checkpoint_camera_limit_left = new_limit_left
	checkpoint_camera_limit_right = new_limit_right
	checkpoint_camera_limit_bottom = new_limit_bottom
	checkpoint_camera_zoom = new_camera_zoom
	checkpoint_camera_offset = new_camera_offset
	has_checkpoint = true

	print("Checkpoint saved at: ", checkpoint_position)


func lose_life() -> bool:
	lives -= 1
	print("Lives remaining: ", lives)
	return lives > 0


func reset_run() -> void:
	lives = MAX_LIVES
	has_checkpoint = false
	checkpoint_position = Vector2.ZERO
