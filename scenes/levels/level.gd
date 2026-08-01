extends Node2D

const BULLET_SCENE = preload("res://scenes/bullets/bullet.tscn")
const LASER_SCENE = preload("res://scenes/bullets/laser.tscn")

func _ready() -> void:
	#print(get_tree().get_nodes_in_group("Drones"))
	pass

func _on_player_shoot(pos: Vector2, dir: Vector2) -> void:
	#print("PEW",pos,dir)
	var bullet = BULLET_SCENE.instantiate() as Area2D
	#bullet.position = pos
	#bullet.direction = dir
	bullet.setup(pos,dir)
	
	#This works but addsa bullets to level
	#get_tree().current_scene.add_child(bullet)
	#Contains bullets in Bullets Node
	$Bullets.add_child(bullet)
	


func _on_sniper_drone_droneshoot(pos: Vector2, dir: Vector2) -> void:
	print(pos,dir)
	var laser = LASER_SCENE.instantiate() as Area2D
	laser.setup(pos,dir)
	$Lasers.add_child(laser)
