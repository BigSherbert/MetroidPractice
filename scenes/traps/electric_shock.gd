extends Area2D

func _ready():
	play_random()

func play_random():
	$ElectricEffect.play("electrifying")
	await $ElectricEffect.animation_finished
	await get_tree().create_timer(randf_range(0, 4.0)).timeout
	play_random()
