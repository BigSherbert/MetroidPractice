extends Node2D

const BULLET_SCENE = preload("res://scenes/bullets/bullet.tscn")

func _on_player_shoot(pos: Vector2, dir: Vector2) -> void:
	print("PEW",pos,dir)
	var bullet = BULLET_SCENE.instantiate() as Area2D
	#bullet.position = pos
	#bullet.direction = dir
	bullet.setup(pos,dir)
	
	#This works but addsa bullets to level
	#get_tree().current_scene.add_child(bullet)
	#Contains bullets in Bullets Node
	$Bullets.add_child(bullet)
	
