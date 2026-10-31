extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const PlatformScript = preload("res://scripts/platform.gd")
const BackdropScript = preload("res://scripts/backdrop.gd")
const HudScript = preload("res://scripts/hud.gd")
const SoundScript = preload("res://scripts/sound.gd")
const CHAPTERS := ["日光客厅", "绿意书房", "午后茶室", "暮色阁楼", "月光长廊", "云端花园"]
const ITEM_ORDER := ["stool", "books", "lamp", "bed", "radio", "teacup", "suitcase", "cushion", "drawer", "clock", "bench", "toaster", "basket", "skateboard", "piano", "books", "bed", "lamp", "radio", "stool", "clock", "cushion", "teacup", "drawer"]
const PATH_X := [355.0, 575.0, 795.0, 1015.0, 1210.0, 1015.0, 795.0, 575.0, 355.0, 180.0]
const SAVE_PATH := "user://journey.json"
var save_path := SAVE_PATH
var font: Font
var world: Node2D
var backdrop: Node2D
var player: OrangePlayer
var hud: Control
var sound: Node
var platforms: Array[ClimbPlatform] = []
var checkpoint_platforms: Dictionary = {}
var visited: Dictionary = {}
var art_cache: Dictionary = {}
var mode := "title"
var camera_y := 0.0
var camera_target := 0.0
var chapter := 0
var checkpoint_index := 0
var checkpoint_position := Vector2(180, 777)
var highest_landed_y := 780.0
var max_height := 0.0
var elapsed := 0.0
var has_left_start := false
var has_save := false
var sound_enabled := true
var toast := ""
var toast_time := 0.0
var fade := 0.0
var effects: Array[Dictionary] = []
var floats: Array[Dictionary] = []
var testing := false
var steps := 0
var next_y := 780.0
var checkpoint_count := 0
var capture_path := ""
var capture_mode := ""
var save_data: Dictionary = {}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_setup_inputs()
	var base_font: Font = load("res://assets/fonts/NotoSansSC.ttf")
	var readable_font := FontVariation.new()
	readable_font.base_font = base_font
	readable_font.variation_opentype = {2003265652: 450.0}
	font = readable_font
	for type in ClimbPlatform.SPECS:
		if type not in ["checkpoint", "finish"]:
			art_cache[type] = load("res://assets/objects/%s.svg" % type)
	backdrop = BackdropScript.new()
	backdrop.font = font
	add_child(backdrop)
	world = Node2D.new()
	add_child(world)
	_build_level()
	player = PlayerScript.new()
	player.position = Vector2(180, 777)
	world.add_child(player)
	player.landed.connect(_on_landed)
	player.jumped.connect(_on_jumped)
	sound = SoundScript.new()
	add_child(sound)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hud = HudScript.new()
	hud.game = self
	hud.font = font
	var bold := FontVariation.new()
	bold.base_font = base_font
	bold.variation_opentype = {2003265652: 620.0}
	hud.title_font = bold
	_read_save()
	layer.add_child(hud)
	world.hide()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			capture_path = arg.trim_prefix("--capture=")
		if arg.begins_with("--preview="):
			capture_mode = arg.trim_prefix("--preview=")
	if not capture_path.is_empty():
		testing = true
		_capture_preview.call_deferred()

func _setup_inputs() -> void:
	var mappings := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE], "pause_game": [KEY_ESCAPE], "retry_checkpoint": [KEY_R],
		"mute": [KEY_M], "fullscreen": [KEY_F11]
	}
	for action in mappings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in mappings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)

func _build_level() -> void:
	var ground := StaticBody2D.new()
	ground.name = "StartFloor"
	ground.add_to_group("ground")
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(1440, 80)
	collider.shape = shape
	collider.position = Vector2(720, 820)
	ground.add_child(collider)
	world.add_child(ground)
	for number in range(1, 145):
		var zone := (number - 1) / 24
		var type: String = ITEM_ORDER[(number - 1 + zone * 5) % ITEM_ORDER.size()]
		_add_platform(type, number, 106.0 + (number % 4) * 7 + zone * 3)
		if number % 24 == 0 and number < 144:
			var platform := _add_platform("checkpoint", number, 112)
			checkpoint_platforms[number] = platform
	_add_platform("finish", 144, 120)

func _add_platform(type: String, number: int, rise: float) -> ClimbPlatform:
	next_y -= rise
	var platform := PlatformScript.new()
	platform.configure(type, number)
	platform.font = font
	platform.position = Vector2(PATH_X[steps % PATH_X.size()], next_y)
	world.add_child(platform)
	platforms.append(platform)
	steps += 1
	return platform

func start_run(continue_saved: bool = false) -> void:
	visited.clear()
	checkpoint_index = 0
	checkpoint_position = Vector2(180, 777)
	highest_landed_y = 780
	elapsed = 0
	max_height = 0
	has_left_start = false
	chapter = 0
	effects.clear()
	floats.clear()
	for platform in platforms:
		platform.visited = false
		platform.active_checkpoint = false
		platform.queue_redraw()
	if continue_saved and has_save:
		checkpoint_index = int(save_data.get("checkpoint", 0))
		if checkpoint_platforms.has(checkpoint_index):
			var cp: ClimbPlatform = checkpoint_platforms[checkpoint_index]
			checkpoint_position = cp.position + Vector2(-25, -2)
			cp.active_checkpoint = true
			highest_landed_y = cp.position.y
			for item in save_data.get("visited", []):
				var id := int(item)
				if id >= 1 and id <= 144:
					visited[id] = true
			elapsed = maxf(0.0, float(save_data.get("elapsed", 0)))
			max_height = maxf(0.0, float(save_data.get("height", 0)))
			has_left_start = true
			chapter = clampi(checkpoint_index / 24, 0, 5)
			for platform in platforms:
				platform.visited = visited.has(platform.index) and platform.kind not in ["checkpoint", "finish"]
	else:
		if not testing and FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)
		has_save = false
	player.reset_at(checkpoint_position)
	player.active = true
	camera_y = minf(0.0, checkpoint_position.y - 580.0)
	world.position.y = -camera_y
	backdrop.camera_y = camera_y
	mode = "play"
	world.show()
	hud.show_mode("play")
	_show_toast("空格跳跃，空中再按一次可以跳得更高。" if not continue_saved else "欢迎回来。旅行从这里继续。", 5.0)

func _process(delta: float) -> void:
	toast_time = maxf(0.0, toast_time - delta)
	fade = move_toward(fade, 0.0, delta * 2.1)
	if mode == "play":
		elapsed += delta
		max_height = maxf(max_height, 780.0 - player.position.y)
		if player.position.y < 700:
			has_left_start = true
		camera_target = minf(0.0, player.position.y - 580)
		camera_y = lerpf(camera_y, camera_target, 1 - exp(-delta * 6.5))
		if checkpoint_index > 0 and player.position.y > highest_landed_y + 590 and player.position.y < 778:
			respawn()
		elif player.position.y > 900:
			game_over()
	world.position.y = -camera_y
	backdrop.camera_y = camera_y
	backdrop.chapter = chapter
	if mode == "play":
		for i in range(effects.size() - 1, -1, -1):
			var effect: Dictionary = effects[i]
			effect.life -= delta
			effect.pos += effect.vel * delta
			effect.vel.y += 95 * delta
			if effect.life <= 0:
				effects.remove_at(i)
		for i in range(floats.size() - 1, -1, -1):
			floats[i].life -= delta
			floats[i].pos.y -= 30 * delta
			if floats[i].life <= 0:
				floats.remove_at(i)
	queue_redraw()

func _draw() -> void:
	if mode == "title":
		return
	for effect in effects:
		var color: Color = effect.color
		color.a *= clampf(effect.life / effect.duration, 0, 1)
		var at: Vector2 = effect.pos - Vector2(0, camera_y)
		if effect.get("ring", false):
			draw_arc(at, effect.size + (1 - effect.life / effect.duration) * 30, 0, TAU, 40, color, 2, true)
		else:
			draw_circle(at, effect.size, color)
	for label in floats:
		Paint.label(self, font, label.text, label.pos - Vector2(0, camera_y), 20, Color(0.39, 0.54, 0.34, minf(label.life, 1)))
	# A soft oval shadow anchors Orange on a surface without changing the front view.
	if player.is_on_floor():
		Paint.ellipse(self, player.position - Vector2(0, camera_y) + Vector2(0, 2), Vector2(26, 4), Color(0.34, 0.28, 0.19, 0.16))

func _on_landed(body: Node) -> void:
	if mode != "play":
		return
	if body.is_in_group("ground"):
		if has_left_start and player.invincible <= 0:
			game_over()
		return
	if not body is ClimbPlatform:
		return
	var platform := body as ClimbPlatform
	highest_landed_y = minf(highest_landed_y, platform.position.y)
	_burst(player.position, 8, Color("e9d7b4"), 70)
	if platform.kind == "finish":
		win()
		return
	if platform.kind == "checkpoint":
		if platform.index > checkpoint_index:
			checkpoint_index = platform.index
			checkpoint_position = platform.position + Vector2(-25, -2)
			platform.active_checkpoint = true
			checkpoint_count += 1
			chapter = clampi(checkpoint_index / 24, 0, 5)
			_save_checkpoint()
			_show_toast("检查站已保存  ·  下一站：%s" % CHAPTERS[chapter], 4.2)
			_burst(player.position - Vector2(0, 38), 28, Color("a7b98c"), 170)
			sound.play_sound("checkpoint")
		return
	if not visited.has(platform.index):
		visited[platform.index] = true
		platform.visited = true
		floats.append({"text": "+1", "pos": player.position + Vector2(22, -55), "life": 1.1})
	if platform.kind == "bed":
		platform.spring = 1
		player.bounce()
		_burst(player.position, 12, Color("b8c4a1"), 110)
		sound.play_sound("spring")
		if platform.index <= 4:
			_show_toast("软软的床会把你弹高，空中还能再跳一次。", 3.5)
	else:
		if platform.kind == "cushion":
			platform.spring = 0.7
		sound.play_sound("land")
	platform.queue_redraw()

func _on_jumped(double: bool) -> void:
	_burst(player.position, 7 if double else 4, Color("e5ba77") if double else Color("e8dcc4"), 80)
	if double:
		effects.append({"pos": player.position + Vector2(0, -15), "vel": Vector2(0, 15), "life": 0.4, "duration": 0.4, "size": 14.0, "color": Color("d9b779"), "ring": true})
	sound.play_sound("double" if double else "jump")

func _burst(at: Vector2, count: int, color: Color, force: float) -> void:
	for i in range(count):
		var duration := randf_range(0.3, 0.75)
		effects.append({"pos": at, "vel": Vector2(randf_range(-force, force), randf_range(-force, -10)), "life": duration, "duration": duration, "size": randf_range(1.5, 4), "color": color})

func respawn() -> void:
	if mode != "play" or checkpoint_index <= 0:
		return
	player.reset_at(checkpoint_position)
	highest_landed_y = checkpoint_position.y + 2
	camera_y = minf(0, checkpoint_position.y - 580)
	fade = 0.7
	_show_toast("回到检查站。慢慢来，你已经走了很远。", 3.0)
	sound.play_sound("fall")

func game_over() -> void:
	mode = "over"
	player.active = false
	player.velocity = Vector2.ZERO
	hud.show_mode("over")
	sound.play_sound("fall")

func win() -> void:
	mode = "win"
	player.active = false
	player.velocity = Vector2.ZERO
	hud.show_mode("win")
	_burst(player.position - Vector2(0, 45), 50, Color("d7b16a"), 220)
	sound.play_sound("win")
	if not testing and FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	has_save = false

func set_paused(value: bool) -> void:
	if mode not in ["play", "pause"]:
		return
	mode = "pause" if value else "play"
	player.active = not value
	hud.show_mode(mode)

func go_to_title() -> void:
	if checkpoint_index > 0:
		_save_checkpoint()
	mode = "title"
	player.active = false
	world.hide()
	camera_y = 0
	chapter = 0
	hud.show_mode("title")

func toggle_sound() -> void:
	sound_enabled = not sound_enabled
	sound.set_enabled(sound_enabled)
	hud.buttons.sound.text = "♪" if sound_enabled else "×"

func _show_toast(message: String, duration: float) -> void:
	toast = message
	toast_time = duration

func time_text() -> String:
	return "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		set_paused(mode == "play")
	elif event.is_action_pressed("mute"):
		toggle_sound()
	elif event.is_action_pressed("retry_checkpoint") and mode == "play":
		respawn()
	elif event.is_action_pressed("fullscreen"):
		var window := get_window()
		window.mode = Window.MODE_WINDOWED if window.mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ENTER:
			if mode == "title":
				start_run(has_save)
			elif mode in ["win", "over"]:
				start_run(false)

func _save_checkpoint() -> void:
	if checkpoint_index <= 0:
		return
	save_data = {"version": 1, "checkpoint": checkpoint_index, "visited": visited.keys(), "elapsed": elapsed, "height": max_height}
	has_save = true
	if testing:
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))

func _read_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return
	var parsed: Variant = parser.data
	if parsed is Dictionary and parsed.get("version", 0) == 1 and checkpoint_platforms.has(int(parsed.get("checkpoint", 0))) and parsed.get("visited", null) is Array:
		save_data = parsed
		has_save = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if checkpoint_index > 0 and mode != "win":
			_save_checkpoint()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "play":
		set_paused(true)

func _capture_preview() -> void:
	if capture_mode in ["game", "checkpoint", "night", "pause", "over", "win"]:
		start_run(false)
		if capture_mode in ["checkpoint", "night"]:
			var id := 24 if capture_mode == "checkpoint" else 96
			var cp: ClimbPlatform = checkpoint_platforms[id]
			checkpoint_index = id
			chapter = id / 24
			cp.active_checkpoint = true
			player.reset_at(cp.position + Vector2(-30, -1))
			camera_y = cp.position.y - 640
			for i in range(1, id + 1):
				visited[i] = true
		else:
			player.reset_at(platforms[1].position + Vector2(-12, -1))
			visited[1] = true
			visited[2] = true
			platforms[0].visited = true
			platforms[1].visited = true
		player.active = false
		mode = capture_mode if capture_mode in ["pause", "over", "win"] else "capture"
		if mode != "capture":
			hud.show_mode(mode)
		toast_time = 0
		max_height = 780 - player.position.y
		elapsed = 97
	for i in range(12):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_path)
	get_tree().quit()
