extends CanvasLayer

@export var heart_texture: Texture2D
@export var heart_size := Vector2(24, 24)

@onready var health_label: Label = $MarginContainer/PanelContainer/ContentAdjustment/VBoxContainer/HealthIndicator
@onready var health_bar: ProgressBar = $MarginContainer/PanelContainer/ContentAdjustment/VBoxContainer/HealthProgressBar
@onready var lives_container: HBoxContainer = $MarginContainer/PanelContainer/ContentAdjustment/VBoxContainer/HBoxContainer/LivesContainer

func setup_player(player) -> void:
	player.health_changed.connect(_on_player_health_changed)
	player.lives_changed.connect(_on_player_lives_changed)
	_on_player_health_changed(player.health, player.max_health)
	_on_player_lives_changed(AutoloadState.lives)



func _on_player_health_changed(current_health: int,maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "HEALTH  %d / %d" % [current_health,maximum_health]

func _on_player_lives_changed(current_lives: int) -> void:
	for child in lives_container.get_children():
		child.queue_free()
		
	for i in current_lives:
		var heart := TextureRect.new()
		heart.texture = heart_texture
		heart.custom_minimum_size = heart_size
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		lives_container.add_child(heart)
