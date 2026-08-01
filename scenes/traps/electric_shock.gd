extends Area2D

@onready var blue_light: PointLight2D = $BlueLight
@export var idle_light_energy: float = 0.1
@onready var zap: AudioStreamPlayer2D = $Zap
@onready var electric_effect: AnimatedSprite2D = $ElectricEffect
@onready var particles: GPUParticles2D = $GPUParticles2D

@export var minimum_delay: float = 0.3
@export var maximum_delay: float = 1.5
@export var spark_frame: int = 6
@export var minimum_pitch: float = 0.9
@export var maximum_pitch: float = 1.1

const LIGHT_STRENGTH: Array[float] = [0.1,0.25,0.45,0.7,0.9,1.2,1.4,1.1,0.8,0.55,0.3,0.15,0.0]


func _ready() -> void:
	blue_light.visible = true
	blue_light.energy = idle_light_energy
	play_random()


func play_random() -> void:
	while is_inside_tree():
		blue_light.visible = true
		zap.pitch_scale = randf_range(minimum_pitch, maximum_pitch)
		zap.play()
		electric_effect.play("electrifying")
		await electric_effect.animation_finished
		blue_light.energy = idle_light_energy
		var random_delay := randf_range(minimum_delay, maximum_delay)
		await get_tree().create_timer(random_delay).timeout


func _on_electric_effect_frame_changed() -> void:
	var current_frame := electric_effect.frame
	if current_frame == spark_frame:
		particles.restart()
	if current_frame < LIGHT_STRENGTH.size():
		blue_light.energy = LIGHT_STRENGTH[current_frame]
	else:
		blue_light.energy = 0.0
