extends Area2D

var direction : Vector2
@export var speed : = 500

#Instead of trying to explicitly state properties elsewhere, we just send them in a simple function!
#This is helpful because we might want specific adjustments for scenes/characters
#Like a bullet that spawns not in the center of the character but at their gun.
func setup(pos: Vector2, dir : Vector2 ) :
	#Here we want the starting position of the bullet to be the character position adding the direction and moving
	#it away from center by 16
	position = pos + dir * 16
	direction = dir

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
