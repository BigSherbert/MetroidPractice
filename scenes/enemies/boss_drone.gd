extends CharacterBody2D

const ENEMY_LASER_SCENE := preload("res://scenes/bullets/laser.tscn")
const DRONE_SCENE := preload("res://scenes/enemies/drone.tscn")
const SNIPER_DRONE_SCENE := preload("res://scenes/enemies/sniper_drone.tscn")
const EXPLOSION_TEXTURE := preload("res://graphics/fire/explosion.png")

@export var max_health := 36
@export var activation_range := 300.0
@export var laser_damage := 3
@export var laser_length := 260.0
@export var laser_charge_time := 0.9
@export var laser_lock_delay := 0.6
@export var aoe_damage := 3
@export var aoe_radius := 82.0
@export var aoe_charge_time := 1.15
@export var frenzy_volleys := 10
@export var frenzy_delay := 0.13
@export var drones_per_summon := 3
@export var summoned_drone_health :=1

var health: int
var player: CharacterBody2D
var active := false
var attacking := false
var exploding := false
var phase_two := false
var spawned_drones: Array[Node] = []

func _ready() -> void:
	health = max_health
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

func _physics_process(_delta: float) -> void:
	if exploding:
		return
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	if player:
		$AnimatedSprite2D.flip_h = player.global_position.x > global_position.x
		if player.global_position.x > global_position.x :
			$LaserOrigin.scale.x = 1
		else :
			$LaserOrigin.scale.x = -1
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
	await get_tree().create_timer(laser_lock_delay).timeout
	attack_loop()

func attack_loop() -> void:
	if attacking or exploding:
		return
	attacking = true
	while active and not exploding and health > 0:
		await laser_attack()
		if exploding: break
		await get_tree().create_timer(0.45 if phase_two else 0.7).timeout
		await charge_aoe_attack()
		if exploding: break
		await get_tree().create_timer(0.45 if phase_two else 0.7).timeout
		await bullet_frenzy()
		if exploding: break
		await get_tree().create_timer(0.5).timeout
		await summon_drones()
		if exploding: break
		await get_tree().create_timer(0.8 if phase_two else 1.1).timeout
	attacking = false

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
		var pulse := remap(sin(charge * 20.0),-1.0,1.0,0.2,1.0)
		$LaserOrigin.modulate.a = pulse
		charge += get_physics_process_delta_time()
		await get_tree().physics_frame
	$LaserOrigin.modulate.a = 1.0
	await get_tree().create_timer(0.6).timeout
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
	explosion.position = Vector2(cos(angle),sin(angle)) * distance
	explosion.scale = Vector2(1.5, 1.5)
	$AOE.add_child(explosion)
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
	tween.tween_property($AOE/WarningRing,"modulate:a",1.0,duration)
	tween.parallel().tween_property($AOE/WarningRing,"width",5.0,duration)
	var elapsed := 0.0
	while elapsed < duration:
		if exploding:
			return
		spawn_aoe_explosion()
		await get_tree().create_timer(0.15).timeout
		elapsed += 0.15
	if exploding:
		return
	# Big burst of explosions when it actually detonates.
	for i in 10:
		spawn_aoe_explosion()
	$AOE/DamageCollision.set_deferred("disabled", false)
	$ExplosionSound.play()
	if player and player.has_method("shake"):
		player.shake(8.0)
	await get_tree().physics_frame
	for body in $AOE.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(aoe_damage)
	await get_tree().create_timer(0.12).timeout
	$AOE/DamageCollision.set_deferred("disabled", true)
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
		#A small 3-shot fan is readable, but becomes nasty when repeated quickly.
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
	var points := $SpawnPoints.get_children()
	var count: int = min(drones_per_summon + (1 if phase_two else 0), points.size())
	for i in count:
		var scene := SNIPER_DRONE_SCENE if i % 2 == 0 else DRONE_SCENE
		var drone := scene.instantiate()
		drone.set("health", summoned_drone_health)
		get_tree().current_scene.add_child(drone)
		drone.global_position = points[i].global_position
		#Existing drones already use these variables for frenzy mode.
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

#Kept for LaserDrone scene connections remain valid
func _on_detection_area_body_entered(body: CharacterBody2D) -> void:
	if body.is_in_group("Player"):
		player = body

func _on_detection_area_body_exited(_body: CharacterBody2D) -> void:
	pass

func _on_self_destruct_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not exploding:
		body.take_damage(2)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if $LaserPivot/LaserBeam.visible and body.has_method("take_damage"):
		body.take_damage(laser_damage)
