@tool
extends Control

@export_range(0.0, 15.5, 0.1) var editor_preview_time: float = 2.0:
	set(value):
		editor_preview_time = value
		if Engine.is_editor_hint():
			elapsed = value
			if is_node_ready():
				_update_cutscene_state()

var elapsed: float = 0.0
var finished: bool = false
var stars: Array[Vector2] = [Vector2(62,55),Vector2(146,92),Vector2(244,43),Vector2(352,78),Vector2(470,48),Vector2(581,104),Vector2(702,61),Vector2(810,91),Vector2(930,44),Vector2(1050,88),Vector2(1182,58),Vector2(111,180),Vector2(285,153),Vector2(1030,166)]

var radar_alert_played := false
var landing_sound_played := false

func _ready() -> void:
	if Engine.is_editor_hint():
		elapsed = editor_preview_time
		$Fade.color.a = 0.0
		_update_cutscene_state()
		return
	$Fade.color.a = 1.0
	create_tween().tween_property($Fade,"color:a",0.0,0.5)
	_update_cutscene_state()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	elapsed += delta
	_update_cutscene_state()
	if elapsed >= 15.5 and not finished:
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_finish()

func _update_cutscene_state() -> void:
	_update_caption()
	$DrEllis.visible = elapsed < 9.2
	$Flower.visible = elapsed >= 9.2 and elapsed < 12.0
	queue_redraw()


func _update_caption() -> void:
	var text := ""
	if elapsed < 3.2:
		text = "DR. ELLIS HAS SEARCHED THE STARS FOR FLOWER..."
	elif elapsed < 6.0:
		text = "THE ULTIMATE SOURCE OF CHILL IN THE UNIVERSE."
	elif elapsed < 9.2:
		text = "...WAIT.  THAT SIGNAL!"
		if not radar_alert_played and not Engine.is_editor_hint():
			radar_alert_played = true
			_play_radar_alert()
	elif elapsed < 12.0:
		text = "FLOWER!"
	else:
		text = "DR. ELLIS SETS DOWN NEARBY.  THE SEARCH BEGINS."
		if not landing_sound_played and not Engine.is_editor_hint():
			landing_sound_played = true
			$ShipLanding.play()
	$Caption.text = text

func _finish() -> void:
	if Engine.is_editor_hint() or finished:
		return
	finished = true
	var tween := create_tween()
	tween.tween_property($Fade,"color:a",1.0,0.35)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/levels/level.tscn")

func _draw() -> void:
	draw_rect(Rect2(0,0,size.x,size.y),Color("07101f"))
	for s in stars:
		var blink: float = 1.0 if int(elapsed * 3.0 + s.x) % 5 else 0.35
		draw_rect(Rect2(s,Vector2(4,4)),Color(0.65,0.8,1.0,blink))
	if elapsed < 9.2:
		_draw_cockpit()
	elif elapsed < 12.0:
		_draw_radar()
	else:
		_draw_landing()

func _draw_cockpit() -> void:
	draw_rect(Rect2(70,115,1140,420),Color("111b31"))
	draw_rect(Rect2(90,135,1100,380),Color("202c46"),false,8)
	draw_rect(Rect2(650,180,400,250),Color("061a24"))
	draw_rect(Rect2(665,195,370,220),Color("0b3540"),false,6)
	var c := Vector2(850,305)
	for r in [45.0,85.0,125.0]:
		draw_arc(c,r,0,TAU,48,Color("24d6c8"),3,false)
	draw_line(c,c+Vector2.from_angle(elapsed*2.4)*125,Color("8bfff0"),5,false)
	if elapsed >= 6.0 and int(elapsed*5.0)%2==0:
		draw_circle(c+Vector2(72,-35),10,Color("ff7a00"))
		draw_circle(c+Vector2(72,-35),18,Color(1,0.45,0,0.25))

func _draw_radar() -> void:
	draw_rect(Rect2(120,90,1040,500),Color("081a22"))
	draw_rect(Rect2(145,115,990,450),Color("1b5260"),false,8)
	for x in range(180,1120,80):
		draw_line(Vector2(x,130),Vector2(x,550),Color(0.1,0.5,0.55,0.18),2,false)
	for y in range(150,550,80):
		draw_line(Vector2(160,y),Vector2(1120,y),Color(0.1,0.5,0.55,0.18),2,false)

func _draw_landing() -> void:
	draw_rect(Rect2(0,430,1280,290),Color("171b29"))
	for x in range(0,1280,64):
		draw_rect(Rect2(x, 430 + (x % 128) / 16.0, 32, 4), Color("31384d"))
	var t: float = clampf((elapsed - 12.0) / 2.4, 0.0, 1.0)
	var ship_pos: Vector2 = Vector2(640,160).lerp(Vector2(640,380),t)
	var tex: Texture2D = preload("res://graphics/random/SpaceShip/EllisType4.png")
	draw_texture_rect(tex,Rect2(ship_pos-Vector2(230,153),Vector2(460,306)),false)
	if t < 0.95:
		for x in [-120.0,120.0]:
			draw_rect(Rect2(ship_pos+Vector2(x,-5),Vector2(18,70+randf()*20)),Color(0.1,0.8,1.0,0.35))

func _play_radar_alert() -> void:
	for i in 5:
		$RadarAlert.play()
		await $RadarAlert.finished
