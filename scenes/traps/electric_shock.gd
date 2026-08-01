extends Area2D

func _ready() -> void:
	play_random()


func _process(_delta: float) -> void:
	if $ElectricEffect.is_playing():
		$BlueLight.energy = randf_range(0.4, 1.0)

func play_random() -> void:
	$BlueLight.visible = true
	$BlueLight.energy = 0.8
	$Zap.play()
	$ElectricEffect.play("electrifying")
	await $ElectricEffect.animation_finished
	$BlueLight.visible = false
	await get_tree().create_timer(randf_range(0.3, 1.5)).timeout
	play_random()
