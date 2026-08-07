extends CharacterBody2D

const ENEMY_LASER_SCENE := preload("res://scenes/bullets/laser.tscn")
const DRONE_SCENE := preload("res://scenes/enemies/drone.tscn")
const SNIPER_DRONE_SCENE := preload("res://scenes/enemies/sniper_drone.tscn")
const EXPLOSION_TEXTURE := preload("res://graphics/fire/explosion.png")
const EXPLOSION_SOUND := preload("res://audio/explosion.wav")

@export var max_health := 36
@export var activation_range := 300.0
@export var move_speed := 55.0
@export var move_radius := 140.0
@export var move_change_time := 2.0
@export var laser_damage := 3
@export var laser_length := 260.0
@export var laser_charge_time := 0.9
@export var laser_lock_delay := 0.8
@export var aoe_damage := 3
@export var aoe_radius := 82.0
@export var aoe_charge_time := 1.15
@export var frenzy_volleys := 10
@export var frenzy_delay := 0.13
@export var drones_per_summon := 3
@export var summoned_drone_health := 1
@export var max_summoned_drones := 3

var health: int
var starting_position: Vector2
var move_target: Vector2
var move_timer := 0.0
var player: CharacterBody2D
var active := false
var attacking := false
var exploding := false
var phase_two := false
var spawned_drones: Array[Node] = []

func _ready() -> void:
	health = max_health
	starting_position = global_position
	choose_move_target()
	$AnimatedSprite2D.material = $AnimatedSprite2D.material.duplicate()
	$BossHUD.visible = false
	$BossHUD/BossBar.max_value = max_health
	$BossHUD/BossBar.value = health
	$LaserPivot/WarningLine.visible = false
	$LaserPivot/LaserBeam.visible = false
	$LaserPivot/DamageArea/DamageCollision.disabled = true
	$LaserOrigin.visible = false
	$AOE/DamageCollision.disabled = true
	$AOE/WarningRing.visible = false
	build_aoe_ring()
	update_laser_length()
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

func choose_move_target() -> void:
	var side := -1.0 if global_position.x > starting_position.x else 1.0
	move_target = starting_position + Vector2(randf_range(60.0, move_radius) * side, randf_range(-60.0, 60.0))

func _physics_process(delta: float) -> void:
	if exploding:
		return
	if attacking:
		velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
		move_and_slide()
		return
	move_timer -= delta
	if move_timer <= 0.0:
		choose_move_target()
		move_timer = move_change_time
	var direction := global_position.direction_to(move_target)
	velocity = direction * move_speed
	if global_position.distance_to(move_target) < 10.0:
		velocity = Vector2.ZERO
	move_and_slide()
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if player:
		$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
		$LaserOrigin.scale.x = 1 if player.global_position.x > global_position.x else -1
		if not active and global_position.distance_to(player.global_position) <= activation_range:
			start_fight()

func start_fight() -> void:
	if active or exploding:
		return
	active = true
	$BossHUD.visible = true
	var intro := create_tween()
	intro.tween_property(self, "modulate", Color(1.5, 0.7, 0.7, 1.0), 0.12)
	intro.tween_property(self, "modulate", Color.WHITE, 0.25)
	await get_tree().create_timer(0.8).timeout
	attack_loop()

func attack_loop() -> void:
	if attacking or exploding:
		return
	while active and not exploding and health > 0:
		attacking = true
		await laser_attack()
		attacking = false
		if exploding:
			break
		await get_tree().create_timer(0.45 if phase_two else 0.7).timeout
		attacking = true
		await charge_aoe_attack()
		attacking = false
		if exploding:
			break
		await get_tree().create_timer(0.45 if phase_two else 0.7).timeout
		attacking = true
		await bullet_frenzy()
		attacking = false
		if exploding:
			break
		await get_tree().create_timer(0.5).timeout
		attacking = true
		await summon_drones()
		attacking = false
		if exploding:
			break
		await get_tree().create_timer(0.8 if phase_two else 1.1).timeout

func laser_attack() -> void:
	if player == null or exploding:
		return
	$ChargeSound.play()
	$LaserPivot/WarningLine.visible = true
	$LaserOrigin.visible = true
	$LaserOrigin.modulate.a = 0.15
	var charge := 0.0
	var charge_length := laser_charge_time * (0.75 if phase_two else 1.0)
	while charge < charge_length:
		if player == null or exploding:
			stop_laser()
			return
		$LaserPivot.global_rotation = (player.global_position - $LaserPivot.global_position).angle()
		var pulse := remap(sin(charge * 20.0), -1.0, 1.0, 0.2, 1.0)
		$LaserOrigin.modulate.a = pulse
		charge += get_physics_process_delta_time()
		await get_tree().physics_frame
	$LaserOrigin.modulate.a = 1.0
	await get_tree().create_timer(laser_lock_delay).timeout
	if exploding:
		stop_laser()
		return
	$LaserPivot/WarningLine.visible = false
	$LaserPivot/LaserBeam.visible = true
	$LaserPivot/DamageArea/DamageCollision.set_deferred("disabled", false)
	$LaserSound.play()
	await get_tree().physics_frame
	damage_player_in_beam()
	await get_tree().create_timer(0.32).timeout
	stop_laser()

func spawn_aoe_explosion() -> void:
	var explosion := Sprite2D.new()
	explosion.texture = EXPLOSION_TEXTURE
	explosion.hframes = 8
	var angle := randf_range(0.0, TAU)
	var distance := sqrt(randf()) * aoe_radius
	explosion.position = Vector2(cos(angle), sin(angle)) * distance
	explosion.scale = Vector2(1.5, 1.5)
	$AOE.add_child(explosion)
	var sound := AudioStreamPlayer2D.new()
	sound.stream = EXPLOSION_SOUND
	sound.pitch_scale = randf_range(0.9, 1.1)
	sound.volume_db = -6.0
	explosion.add_child(sound)
	sound.play()
	for frame in 8:
		explosion.frame = frame
		await get_tree().create_timer(0.06).timeout
	explosion.queue_free()

func charge_aoe_attack() -> void:
	if exploding:
		return
	$AOE/WarningRing.visible = true
	$AOE/WarningRing.modulate.a = 0.2
	$ChargeSound.play()
	var duration := aoe_charge_time * (0.8 if phase_two else 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property($AOE/WarningRing, "modulate:a", 1.0, duration)
	tween.parallel().tween_property($AOE/WarningRing, "width", 5.0, duration)
	var elapsed := 0.0
	while elapsed < duration:
		if exploding:
			return
		spawn_aoe_explosion()
		await get_tree().create_timer(0.15).timeout
		elapsed += 0.15
	if exploding:
		return
	for i in 10:
		spawn_aoe_explosion()
	$ExplosionSound.play()
	if player and player.has_method("shake"):
		player.shake(8.0)
	if player:
		var distance_to_player: float = global_position.distance_to(player.global_position)
		var actual_aoe_radius: float = aoe_radius * abs(global_scale.x)
		if distance_to_player <= actual_aoe_radius:
			player.take_damage(aoe_damage)
	await get_tree().create_timer(0.12).timeout
	$AOE/WarningRing.visible = false
	$AOE/WarningRing.width = 2.0

func bullet_frenzy() -> void:
	if player == null or exploding:
		return
	var volleys := frenzy_volleys + (4 if phase_two else 0)
	for i in volleys:
		if player == null or exploding:
			return
		var base_dir := (player.global_position - global_position).normalized()
		spawn_enemy_laser(base_dir.rotated(deg_to_rad(-12.0)))
		spawn_enemy_laser(base_dir)
		spawn_enemy_laser(base_dir.rotated(deg_to_rad(12.0)))
		$LaserOrigin.visible = true
		$LaserOrigin.modulate.a = 1.0
		var flash := create_tween()
		flash.tween_property($LaserOrigin, "modulate:a", 0.0, 0.09)
		await get_tree().create_timer(frenzy_delay * (0.75 if phase_two else 1.0)).timeout
	$LaserOrigin.visible = false

func spawn_enemy_laser(dir: Vector2) -> void:
	var laser := ENEMY_LASER_SCENE.instantiate() as Area2D
	laser.setup(global_position, dir)
	var laser_container := get_tree().current_scene.get_node_or_null("Lasers")
	if laser_container:
		laser_container.add_child(laser)
	else:
		get_tree().current_scene.add_child(laser)

func summon_drones() -> void:
	clean_spawned_drones()
	if spawned_drones.size() >= max_summoned_drones:
		return
	var points := $SpawnPoints.get_children()
	var amount_needed: int = max_summoned_drones - spawned_drones.size()
	var desired_summon: int = drones_per_summon + (1 if phase_two else 0)
	var count: int = min(desired_summon, min(amount_needed, points.size()))
	for i in count:
		var scene := SNIPER_DRONE_SCENE if i % 2 == 0 else DRONE_SCENE
		var drone := scene.instantiate()
		drone.set("health", summoned_drone_health)
		get_tree().current_scene.add_child(drone)
		drone.global_position = points[i].global_position
		drone.set("player", player)
		drone.set("frenzy_time_left", 999.0)
		drone.set("starting_position", drone.global_position)
		if drone.has_signal("droneshoot"):
			drone.connect("droneshoot", _on_spawned_drone_shoot)
		spawned_drones.append(drone)
		var pop := drone.create_tween()
		pop.tween_property(drone, "scale", Vector2.ONE, 0.2).from(Vector2.ZERO)
		await get_tree().create_timer(0.12).timeout

func _on_spawned_drone_shoot(pos: Vector2, dir: Vector2) -> void:
	var laser := ENEMY_LASER_SCENE.instantiate() as Area2D
	laser.setup(pos, dir)
	var laser_container := get_tree().current_scene.get_node_or_null("Lasers")
	if laser_container:
		laser_container.add_child(laser)
	else:
		get_tree().current_scene.add_child(laser)

func shot_at() -> void:
	if exploding:
		return
	if not active:
		start_fight()
	health = max(health - 1, 0)
	$BossHUD/BossBar.value = health
	$ShotAtSound.play()
	var hit := create_tween()
	hit.tween_property($AnimatedSprite2D.material, "shader_parameter/HitShaderMix", 0.0, 0.04)
	hit.tween_property($AnimatedSprite2D.material, "shader_parameter/HitShaderMix", 1.0, 0.08)
	if not phase_two and health <= max_health * 0.5:
		enter_phase_two()
	if health <= 0:
		drone_explode()

func enter_phase_two() -> void:
	phase_two = true
	var phase_tween := create_tween()
	phase_tween.tween_property(self, "modulate", Color(1.4, 0.35, 0.35, 1.0), 0.15)
	phase_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	if player and player.has_method("shake"):
		player.shake(10.0)

func damage_player_in_beam() -> void:
	for body in $LaserPivot/DamageArea.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(laser_damage)

func stop_laser() -> void:
	$LaserPivot/WarningLine.visible = false
	$LaserPivot/LaserBeam.visible = false
	$LaserPivot/DamageArea/DamageCollision.set_deferred("disabled", true)
	$LaserOrigin.visible = false

func update_laser_length() -> void:
	$LaserPivot/WarningLine.points = PackedVector2Array([Vector2.ZERO, Vector2(laser_length, 0.0)])
	$LaserPivot/LaserBeam.points = PackedVector2Array([Vector2.ZERO, Vector2(laser_length, 0.0)])
	var beam_shape := $LaserPivot/DamageArea/DamageCollision.shape as RectangleShape2D
	beam_shape.size = Vector2(laser_length, 8.0)
	$LaserPivot/DamageArea/DamageCollision.position.x = laser_length / 2.0

func build_aoe_ring() -> void:
	var points := PackedVector2Array()
	for i in 49:
		var angle := TAU * float(i) / 48.0
		points.append(Vector2(cos(angle), sin(angle)) * aoe_radius)
	$AOE/WarningRing.points = points
	var aoe_shape := $AOE/DamageCollision.shape as CircleShape2D
	aoe_shape.radius = aoe_radius

func clean_spawned_drones() -> void:
	var alive: Array[Node] = []
	for drone in spawned_drones:
		if is_instance_valid(drone):
			alive.append(drone)
	spawned_drones = alive

func drone_explode() -> void:
	if exploding:
		return
	exploding = true
	active = false
	attacking = false
	stop_laser()
	$AOE/WarningRing.visible = false
	$AOE/DamageCollision.set_deferred("disabled", true)
	$DroneCollisionArea.set_deferred("disabled", true)
	$SelfDestructArea/SelfDestructCollision.set_deferred("disabled", true)
	$BossHUD.visible = false
	$AnimatedSprite2D.visible = false
	$ExplosionAnimation.play("explode")
	$ExplosionSound.play()
	if player and player.has_method("shake"):
		player.shake(14.0)

func _on_explosion_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"explode":
		queue_free()


func _on_self_destruct_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not exploding:
		body.take_damage(2)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if $LaserPivot/LaserBeam.visible and body.has_method("take_damage"):
		body.take_damage(laser_damage)
