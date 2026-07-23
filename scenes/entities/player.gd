extends CharacterBody2D

#Character Physics
#Gravity is stored in Physics Setting of Godot, we will call it later.
var speed = 100
var jump_velocity = -450

func _physics_process(delta: float) -> void:
	
	#Lets handle gravity first
	if !is_on_floor():
		velocity.y += ProjectSettings.get
