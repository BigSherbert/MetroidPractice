extends CanvasLayer

@onready var health_label: Label = $MarginContainer/PanelContainer/ContentAdjustment/VBoxContainer/HealthIndicator
@onready var health_bar: ProgressBar = $MarginContainer/PanelContainer/ContentAdjustment/VBoxContainer/HealthProgressBar

func setup_player(player) -> void:
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.health, player.max_health)


func _on_player_health_changed(current_health: int,maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "HEALTH  %d / %d" % [current_health,maximum_health]
