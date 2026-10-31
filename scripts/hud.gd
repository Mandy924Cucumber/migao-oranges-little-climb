extends Control

var game: Node
var font: Font
var title_font: Font
var mode := "title"
var hovered := ""
var buttons: Dictionary = {}
var clock := 0.0
const INK := Color("48594c")
const MUTED := Color("92917d")
const CREAM := Color("faf6e9")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	make_button("start", "开始旅行  →", Rect2(125, 530, 240, 64), _start)
	make_button("continue", "继续上次的旅行", Rect2(125, 607, 240, 49), _continue, false)
	make_button("resume", "继续向上  →", Rect2(570, 478, 300, 58), _resume)
	make_button("restart", "重新开始", Rect2(570, 552, 142, 48), _restart, false)
	make_button("menu", "返回首页", Rect2(728, 552, 142, 48), _menu, false)
	make_button("retry", "再试一次  →", Rect2(570, 489, 300, 59), _restart)
	make_button("finish_restart", "再旅行一次  →", Rect2(570, 520, 300, 60), _restart)
	make_button("pause", "Ⅱ", Rect2(1360, 28, 44, 44), _pause, false)
	make_button("sound", "♪", Rect2(1304, 28, 44, 44), _sound, false)
	show_mode("title")

func make_button(id: String, caption: String, rect: Rect2, action: Callable, primary := true) -> void:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 18 if rect.size.x > 100 else 23)
	button.add_theme_color_override("font_color", CREAM if primary else INK)
	button.add_theme_color_override("font_hover_color", CREAM if primary else INK)
	button.add_theme_color_override("font_pressed_color", CREAM if primary else INK)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("677e63") if primary else Color("f5f0e1")
		if state == "hover":
			style.bg_color = Color("78906e") if primary else Color("ebe5d3")
		if state == "pressed":
			style.bg_color = Color("4e684d") if primary else Color("dcd7c3")
		style.set_corner_radius_all(12)
		style.border_color = Color("5b7358") if primary else Color("dcd8c4")
		style.set_border_width_all(1)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = Color("d8ab63")
			style.set_border_width_all(3)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	add_child(button)
	buttons[id] = button

func show_mode(next: String) -> void:
	mode = next
	for button in buttons.values():
		button.hide()
	match mode:
		"title":
			buttons.start.show()
			if game.has_save:
				buttons.continue.show()
		"play":
			buttons.pause.show()
			buttons.sound.show()
		"pause":
			buttons.resume.show()
			buttons.restart.show()
			buttons.menu.show()
		"over": buttons.retry.show()
		"win": buttons.finish_restart.show()
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	if not game:
		return
	if mode == "title":
		_draw_title()
		return
	_draw_game_hud()
	if mode == "pause" or mode == "over" or mode == "win":
		draw_rect(Rect2(0, 0, 1440, 900), Color(0.21, 0.27, 0.22, 0.29))
		Paint.box(self, Rect2(500, 236, 440, 412), CREAM, 24, Color("d3cbb4"), 1)
		center_text("TAKE A LITTLE BREATH" if mode == "pause" else ("EVERY STEP COUNTS" if mode == "over" else "HELLO, LITTLE SKY"), 289, 12, MUTED)
		center_text("在这里歇一会儿" if mode == "pause" else ("再向上一次吧" if mode == "over" else "你把日常，跳成了远方"), 348, 29, INK)
		if mode == "pause":
			center_text("小橘子会在这里等你。", 393, 17, MUTED)
			center_text("已点亮 %d 件物品 · %s" % [game.visited.size(), game.time_text()], 434, 16, INK)
		elif mode == "over":
			center_text("落回了最底层，旅行暂时结束。", 393, 17, MUTED)
			center_text("这次点亮了 %d 件物品" % game.visited.size(), 436, 18, INK)
			center_text("试着在空中再按一次空格。", 588, 14, MUTED)
		else:
			center_text("云端花园到了。谢谢你没有停下脚步。", 394, 16, MUTED)
			center_text("收集 %d / 144     ·     用时 %s" % [game.visited.size(), game.time_text()], 446, 18, INK)
			center_text("最高到达 %d m" % int(game.max_height / 50.0), 477, 15, MUTED)
	if game.fade > 0:
		draw_rect(Rect2(0, 0, 1440, 900), Color(0.98, 0.96, 0.88, game.fade))

func _draw_game_hud() -> void:
	Paint.box(self, Rect2(24, 15, 278, 111), Color(0.98, 0.97, 0.92, 0.94), 14)
	Paint.box(self, Rect2(1073, 839, 331, 38), Color(0.98, 0.97, 0.92, 0.92), 9)
	Paint.label(self, font, "ORANGE’S LITTLE CLIMB", Vector2(39, 37), 11, Color("8c947e"))
	Paint.label(self, font, "橘子的向上旅行", Vector2(37, 72), 25, INK)
	Paint.label(self, font, "%02d  /  %s" % [game.chapter + 1, game.CHAPTERS[game.chapter]], Vector2(39, 107), 14, MUTED)
	Paint.box(self, Rect2(1082, 24, 204, 96), Color(0.99, 0.98, 0.94, 0.93), 15, Color("dedcc8"), 1)
	Paint.label(self, font, "物 品 图 鉴", Vector2(1101, 50), 12, MUTED)
	Paint.label(self, font, "%03d" % game.visited.size(), Vector2(1100, 94), 36, INK)
	Paint.label(self, font, "/ 144", Vector2(1187, 92), 16, MUTED)
	Paint.label(self, font, "↗ %d m" % int(game.max_height / 50), Vector2(1100, 148), 17, INK)
	Paint.label(self, font, game.time_text(), Vector2(1202, 148), 15, MUTED)
	# Quiet chapter rail at the edge, one point per checkpoint.
	draw_line(Vector2(1391, 274), Vector2(1391, 604), Color("d7d6c2"), 2)
	for i in range(6):
		var y := 604 - i * 66
		draw_circle(Vector2(1391, y), 5 if i != game.chapter else 8, Color("8eaa86") if i <= game.chapter else Color("d1d2bd"))
		if i == game.chapter:
			draw_arc(Vector2(1391, y), 13, 0, TAU, 32, Color("b3bf9c"), 1.2, true)
	Paint.box(self, Rect2(35, 839, 511, 38), Color(0.98, 0.97, 0.92, 0.93), 9)
	keycap("A", Vector2(47, 845), 24)
	keycap("D", Vector2(76, 845), 24)
	Paint.label(self, font, "移动", Vector2(111, 864), 13, MUTED)
	keycap("SPACE", Vector2(166, 845), 65)
	Paint.label(self, font, "跳跃 · 可连按两次", Vector2(243, 864), 13, MUTED)
	keycap("ESC", Vector2(411, 845), 42)
	Paint.label(self, font, "暂停", Vector2(465, 864), 13, MUTED)
	if game.checkpoint_index > 0:
		Paint.label(self, font, "●  已保存至检查站 %02d" % (game.checkpoint_index / 24), Vector2(1114, 863), 13, Color("7e9374"))
	else:
		Paint.label(self, font, "下一个检查站  ·  第 24 件物品后", Vector2(1090, 863), 12, MUTED)
	if game.toast_time > 0:
		var text_width := font.get_string_size(game.toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		var x := (1440.0 - text_width) * 0.5
		Paint.box(self, Rect2(x - 25, 110, text_width + 50, 44), Color(0.98, 0.96, 0.87, minf(1, game.toast_time)), 22, Color("d8d1b7"), 1)
		Paint.label(self, font, game.toast, Vector2(x, 139), 18, INK)

func _draw_title() -> void:
	# A restrained book-cover composition. The right half is a playable-world vignette.
	draw_rect(Rect2(0, 0, 610, 900), Color(0.96, 0.95, 0.90, 0.89))
	Paint.label(self, font, "一  橘 子 的 小 小 冒 险", Vector2(127, 181), 14, Color("8a967c"))
	Paint.label(self, title_font, "橘子的", Vector2(120, 293), 72, INK)
	Paint.label(self, title_font, "向上旅行", Vector2(120, 387), 72, INK)
	Paint.label(self, font, "ORANGE’S LITTLE CLIMB", Vector2(128, 425), 13, Color("9a967e"))
	draw_line(Vector2(128, 449), Vector2(181, 449), Color("c6ac76"), 2, true)
	Paint.label(self, font, "踩着日常的小物，去看看更高处的风景。", Vector2(127, 488), 18, Color("7b826d"))
	if not game.has_save:
		Paint.label(self, font, "A / D  移动       空格  跳跃 / 二段跳", Vector2(128, 628), 14, MUTED)
	Paint.label(self, font, "144 件小物     /     6 段风景     /     一直向上", Vector2(128, 727), 14, Color("8b8d76"))
	Paint.label(self, font, "不必着急，每一小步都算数。", Vector2(128, 756), 14, Color("a4a18b"))
	# The tiny orange, drawn directly from the user's oval silhouette.
	var bob := sin(clock * 2.3) * 5
	Paint.ellipse(self, Vector2(1013, 404), Vector2(109, 12), Color(0.38, 0.33, 0.21, 0.12))
	draw_set_transform(Vector2(1010, 389 + bob), 0, Vector2(2.65, 2.65))
	Paint.ellipse(self, Vector2(-16, -4), Vector2(12, 5), Color("f77814"))
	Paint.ellipse(self, Vector2(16, -4), Vector2(12, 5), Color("f77814"))
	Paint.box(self, Rect2(-21, -15, 10, 11), Color("ff7d16"), 2)
	Paint.box(self, Rect2(11, -15, 10, 11), Color("ff7d16"), 2)
	Paint.ellipse(self, Vector2(0, -27), Vector2(43, 20), Color("ff7d16"))
	Paint.ellipse(self, Vector2(-10, -39), Vector2(20, 3), Color(1.0, 0.70, 0.32, 0.32))
	for x in [-10, 10]:
		Paint.ellipse(self, Vector2(x, -30), Vector2(2.4, 0.65 if fmod(clock, 4.3) > 4.17 else 4.5), Color("20241b"))
	draw_set_transform(Vector2.ZERO)
	_draw_object("books", Vector2(1012, 418), 1.65)
	_draw_object("stool", Vector2(754, 657), 1.25)
	_draw_object("teacup", Vector2(1258, 260), 1.12)
	_draw_object("lamp", Vector2(1231, 607), 1.08)
	_draw_object("cushion", Vector2(1103, 738), 1.0)
	Paint.label(self, font, "你好，小橘子。", Vector2(948, 222), 17, Color("87947a"))
	Paint.label(self, font, "从一小步开始", Vector2(704, 810), 13, Color("9c967e"))
	# Small dotted trajectories convey the upward journey without perspective.
	for i in range(12):
		var t := i / 11.0
		var p := Vector2(816, 612).lerp(Vector2(916, 480), t)
		p.x -= sin(t * PI) * 28
		draw_circle(p, 2, Color("c6bd9c"))
	for i in range(11):
		var t := i / 10.0
		var p := Vector2(1124, 412).lerp(Vector2(1230, 293), t)
		p.x -= sin(t * PI) * 20
		draw_circle(p, 2, Color("c6bd9c"))
	for p in [Vector2(827, 259), Vector2(1159, 172), Vector2(1288, 487)]:
		draw_line(p - Vector2(6, 0), p + Vector2(6, 0), Color("c9b478"), 2, true)
		draw_line(p - Vector2(0, 6), p + Vector2(0, 6), Color("c9b478"), 2, true)
	Paint.label(self, font, "一个平凡房间里的，不平凡旅程", Vector2(908, 855), 12, Color("9c967f"))

func _draw_object(type: String, at: Vector2, scale_factor: float) -> void:
	var texture: Texture2D = game.art_cache[type]
	var w := texture.get_width() * scale_factor
	var h := texture.get_height() * scale_factor
	draw_texture_rect(texture, Rect2(at.x - w / 2, at.y, w, h), false)

func center_text(text: String, y: float, size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	Paint.label(self, font, text, Vector2((1440 - width) / 2, y), size, color)

func keycap(text: String, at: Vector2, width: float) -> void:
	Paint.box(self, Rect2(at, Vector2(width, 25)), Color("edead9"), 5, Color("d7d5c0"), 1)
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	Paint.label(self, font, text, at + Vector2((width - tw) / 2, 17), 11, Color("747e69"))

func _start() -> void: game.start_run(false)
func _continue() -> void: game.start_run(true)
func _restart() -> void: game.start_run(false)
func _resume() -> void: game.set_paused(false)
func _menu() -> void: game.go_to_title()
func _pause() -> void: game.set_paused(true)
func _sound() -> void:
	game.toggle_sound()
	buttons.sound.text = "♪" if game.sound_enabled else "×"
