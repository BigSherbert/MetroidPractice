extends Area2D

var direction : Vector2
@export var speed : = 250
@export var offset : = 16

func _ready() -> void:
	#$firesprite.scale = Vector2.ZERO
	var tweenbscale = get_tree().create_tween()
	tweenbscale.tween_property($firesprite, "scale",Vector2.ONE,.25).from(Vector2.ZERO)
	$PewPew.play()
	#Delete if bullet somehow lasts longer than 60 seconds.
	get_tree().create_timer(60.0).timeout.connect(queue_free)

#Instead of trying to explicitly state properties elsewhere, we just send them in a simple function!
#This is helpful because we might want specific adjustments for scenes/characters
#Like a bullet that spawns not in the center of the character but at their gun.
func setup(pos: Vector2, dir : Vector2 ) :
	#Here we want the starting position of the bullet to be the character position adding the direction and moving
	#it away from center by 16
	global_position = pos + dir * offset
	direction = dir.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	

#When the bullet hits something
func _on_body_entered(body: Node2D) -> void:
	#We want to determine if the body being hit is affected by the bullet. To do this we inserted a function shot_at into the script of vulnerable entities.
	if body.has_method("shot_at") :
		body.shot_at()
	#Delete the bullet after it collides with something.
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
