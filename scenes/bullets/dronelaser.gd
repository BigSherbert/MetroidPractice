extends Area2D

var direction : Vector2
@export var speed : = 100
@export var offset : = 16

func _ready() -> void:
	
	var tweenbscale = get_tree().create_tween()
	tweenbscale.tween_property($Sprite2D, "scale",Vector2.ONE,.25).from(Vector2.ZERO)

#Instead of trying to explicitly state properties elsewhere, we just send them in a simple function!
#This is helpful because we might want specific adjustments for scenes/characters
#Like a bullet that spawns not in the center of the character but at their gun.
func setup(pos: Vector2, dir : Vector2 ) :
	#Here we want the starting position of the bullet to be the character position adding the direction and moving
	#it away from center by 16
	position = pos + dir * offset
	direction = dir

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	

#When the bullet hits something
func _on_body_entered(body: Node2D) -> void:
	#We want to determine if the body being hit is affected by the bullet. To do this we inserted a function ShotAt into the script of vulnerable entities.
	if "ShotAt" in body :
		body.ShotAt()
	#Delete the bullet after it collides with something.
	queue_free()
