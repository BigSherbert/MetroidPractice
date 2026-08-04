extends CanvasLayer

@export var heart_texture: Texture2D
@export var heart_size := Vector2(24, 24)

@onready var health_label: Label = $PersistantHUD/PanelContainer/ContentAdjustment/VBoxContainer/HealthIndicator
@onready var health_bar: ProgressBar = $PersistantHUD/PanelContainer/ContentAdjustment/VBoxContainer/HealthProgressBar
@onready var lives_container: HBoxContainer = $PersistantHUD/PanelContainer/ContentAdjustment/VBoxContainer/HBoxContainer/LivesContainer

@onready var notifications: MarginContainer = $Notifcations
@onready var notifications_label : Label = $Notifcations/PanelContainer/ContentAdjustment/NotificationsLabel

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

#Notification System
#Currently using text notifications but could change to animated sprites or in game object like a flag or something.
var checkpoint_message := "Checkpoint Reached"
var notification_tween: Tween

func show_checkpoint_message() -> void:

	if notification_tween and notification_tween.is_valid():
		notification_tween.kill()
		
	notifications_label.text = checkpoint_message
	notifications.modulate.a = 0.0
	notifications.position.y = 50.0
	notifications.visible = true
	
	notification_tween = create_tween()
	
	notification_tween.set_trans(Tween.TRANS_QUAD)
	notification_tween.set_ease(Tween.EASE_OUT)
	notification_tween.tween_property(notifications,"modulate:a",1.0,0.25)
	notification_tween.parallel().tween_property(notifications,"position:y",40.0,0.25)
	
	notification_tween.tween_interval(1.5)
	
	notification_tween.set_ease(Tween.EASE_IN)
	notification_tween.tween_property(notifications,"modulate:a",0.0,0.4)
	
	notification_tween.tween_callback(func(): notifications.visible = false)

func _on_sub_floor_2_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		show_checkpoint_message()


func _on_sub_floor_3_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		show_checkpoint_message()


func _on_boss_floor_entrance_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		show_checkpoint_message()


func _on_boss_fight_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		show_checkpoint_message()
