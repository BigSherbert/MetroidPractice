extends Area2D

var direction : Vector2
@export var speed : = 100
@export var offset : = 16

func _ready() -> void:
	
	var tweenbscale = get_tree().create_tween()
	tweenbscale.tween_property($Sprite2D, "scale",Vector2.ONE,.25).from(Vector2.ZERO)

#Instead of trying to explicitly state properties elsewhere, we just send them in a simple function!
#This is helpful because we might want specific adjustments for scenes/characters
func setup(pos: Vector2, dir : Vector2 ) :
	#Here we want the starting position of the bullet to be the character position adding the direction and moving
	#it away from center by 16
	global_position = pos + dir * offset
	direction = dir

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	

#When the laser hits something
func _on_body_entered(body: Node2D) -> void:
	#Check if what we hit will react to getting shot and then activate that function shot_at
	if body.has_method("shot_at"):
		body.shot_at()
	#Delete the laser after it collides with something.
	queue_free()
