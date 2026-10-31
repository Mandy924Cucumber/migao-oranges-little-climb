extends Node2D

var camera_y := 0.0
var chapter := 0
var clock := 0.0
var font: Font
var grain: Array[Vector2] = []
const WALLS := [Color("f3efdf"), Color("eaf0e5"), Color("f4e8dc"), Color("ede7e7"), Color("e0e8e9"), Color("f4ecd8")]
var wall := Color("f3efdf")

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2468
	for i in range(1400):
		grain.append(Vector2(rng.randf_range(0, 1440), rng.randf_range(0, 900)))

func _process(delta: float) -> void:
	clock += delta
	wall = wall.lerp(WALLS[clampi(chapter, 0, 5)], delta * 1.7)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1440, 900), wall)
	# Paper, wall trim, and soft architectural details stay behind the playable furniture.
	for i in range(10):
		var x := 30 + i * 160
		draw_line(Vector2(x, 0), Vector2(x, 900), Color(0.57, 0.54, 0.42, 0.045), 1)
	var scroll := fposmod(-camera_y * 0.24, 1040.0)
	for row in range(-1, 2):
		var y := 170 + row * 1040 + scroll
		_window(Vector2(90, y), Vector2(280, 390), chapter >= 4)
		_window(Vector2(1085, y - 115), Vector2(250, 400), chapter >= 4)
		_frame(Vector2(548, y + 105), Vector2(155, 175), 0)
		_frame(Vector2(754, y + 35), Vector2(103, 126), 1)
		_wall_lamp(Vector2(968, y + 115))
		# A picture ledge, deliberately faint and behind the play plane.
		Paint.box(self, Rect2(498, y + 310, 376, 10), Color(0.63, 0.56, 0.43, 0.13), 3)
		_plant(Vector2(530, y + 310), 0.65, 0.28)
		Paint.box(self, Rect2(809, y + 264, 32, 46), Color(0.72, 0.57, 0.40, 0.18), 5)
		Paint.box(self, Rect2(848, y + 279, 19, 31), Color(0.54, 0.65, 0.55, 0.18), 3)
	# Warm dust drifts slowly in the sun.
	for i in range(24):
		var x := fmod(i * 127.37 + sin(clock * 0.17 + i) * 13, 1440)
		var y := fposmod(i * 91.73 - clock * (3 + i % 3), 900)
		draw_circle(Vector2(x, y), 1.6, Color(1.0, 0.99, 0.88, 0.65))
	for point in grain:
		draw_circle(point, 0.55, Color(0.43, 0.38, 0.27, 0.055))
	var gy := 780 - camera_y
	if gy < 1000:
		draw_rect(Rect2(0, gy + 8, 1440, 1000), Color("d4b994"))
		draw_rect(Rect2(0, gy, 1440, 12), Color("ad9573"))
		draw_rect(Rect2(0, gy - 12, 1440, 13), Color("e4d2ac"))
		draw_line(Vector2(0, gy - 12), Vector2(1440, gy - 12), Color("c8b690"), 2)
		for y in range(4):
			draw_line(Vector2(0, gy + 24 + y * 33), Vector2(1440, gy + 24 + y * 33), Color(0.54, 0.40, 0.27, 0.18), 2)
			for x in range(6):
				var xx := x * 310 + (145 if y % 2 else 0)
				draw_line(Vector2(xx, gy + 25 + y * 33), Vector2(xx, gy + 55 + y * 33), Color(0.54, 0.40, 0.27, 0.13), 2)
		_plant(Vector2(73, gy - 12), 1.32, 0.92)
		_plant(Vector2(1358, gy - 12), 1.10, 0.9)
		Paint.ellipse(self, Vector2(195, gy + 30), Vector2(102, 13), Color(0.73, 0.43, 0.27, 0.12))
		if font:
			Paint.label(self, font, "旅 程 的 起 点", Vector2(139, gy + 54), 14, Color("8f795c"))

func _window(at: Vector2, size: Vector2, night: bool) -> void:
	var border := Color(0.60, 0.57, 0.46, 0.22)
	Paint.box(self, Rect2(at - Vector2(10, 10), size + Vector2(20, 20)), Color(0.91, 0.88, 0.77, 0.55), 140, border, 2)
	Paint.box(self, Rect2(at, size), Color("d3e0d9") if not night else Color("b8cacc"), 130)
	# Cover the lower round corners for an arched, straight-on window.
	draw_rect(Rect2(at + Vector2(0, size.y * 0.45), Vector2(size.x, size.y * 0.55)), Color("d3e0d9") if not night else Color("b8cacc"))
	draw_circle(at + Vector2(size.x * 0.68, size.y * 0.26), 34, Color("f6e9ba") if not night else Color("e8eddb"))
	Paint.ellipse(self, at + Vector2(size.x * 0.28, size.y * 0.64), Vector2(size.x * 0.28, 16), Color(0.96, 0.98, 0.90, 0.45))
	Paint.ellipse(self, at + Vector2(size.x * 0.67, size.y * 0.78), Vector2(size.x * 0.3, 15), Color(0.96, 0.98, 0.90, 0.35))
	for x in [size.x * 0.5]:
		draw_line(at + Vector2(x, 4), at + Vector2(x, size.y), Color("e8e3ce"), 10)
	draw_line(at + Vector2(0, size.y * 0.47), at + Vector2(size.x, size.y * 0.47), Color("e8e3ce"), 10)
	Paint.box(self, Rect2(at + Vector2(-17, size.y), Vector2(size.x + 34, 15)), Color("ddd5bb"), 3, border, 1)
	# Gauze curtain, low contrast to keep the jump silhouettes readable.
	draw_colored_polygon(PackedVector2Array([at + Vector2(-19, 22), at + Vector2(37, 22), at + Vector2(19, size.y + 20), at + Vector2(-27, size.y + 22)]), Color(0.98, 0.97, 0.89, 0.83))
	draw_colored_polygon(PackedVector2Array([at + Vector2(size.x - 36, 22), at + Vector2(size.x + 19, 22), at + Vector2(size.x + 28, size.y + 22), at + Vector2(size.x - 14, size.y + 20)]), Color(0.98, 0.97, 0.89, 0.83))
	for x in [-12, 5, size.x + 2, size.x + 16]:
		draw_line(at + Vector2(x, 30), at + Vector2(x - 6, size.y + 10), Color(0.78, 0.74, 0.62, 0.16), 1.5, true)

func _frame(at: Vector2, size: Vector2, type: int) -> void:
	Paint.box(self, Rect2(at, size), Color(0.66, 0.55, 0.41, 0.16), 3)
	Paint.box(self, Rect2(at + Vector2(8, 8), size - Vector2(16, 16)), Color(0.98, 0.96, 0.87, 0.78), 1)
	var center := at + size * 0.5
	if type == 0:
		draw_circle(center - Vector2(0, 20), 31, Color(0.79, 0.64, 0.43, 0.14))
		draw_colored_polygon(PackedVector2Array([center + Vector2(-55, 46), center + Vector2(4, -9), center + Vector2(56, 46)]), Color(0.51, 0.62, 0.47, 0.18))
	else:
		draw_line(center + Vector2(0, 40), center - Vector2(0, 35), Color(0.46, 0.59, 0.47, 0.27), 2)
		for i in range(4):
			Paint.ellipse(self, center + Vector2(12 if i % 2 else -12, 18 - i * 13), Vector2(15, 7), Color(0.46, 0.59, 0.47, 0.2))

func _wall_lamp(at: Vector2) -> void:
	for i in range(5):
		draw_circle(at, 40 + i * 18, Color(1, 0.89, 0.55, 0.015))
	draw_line(at, at + Vector2(0, 57), Color(0.62, 0.54, 0.37, 0.25), 5)
	Paint.ellipse(self, at + Vector2(0, 60), Vector2(13, 6), Color(0.62, 0.54, 0.37, 0.20))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-15, -15), at + Vector2(15, -15), at + Vector2(28, 20), at + Vector2(-28, 20)]), Color(0.85, 0.72, 0.45, 0.30))

func _plant(at: Vector2, s: float, alpha: float) -> void:
	draw_set_transform(at, 0, Vector2.ONE * s)
	var stem := Color(0.38, 0.49, 0.36, alpha)
	for i in range(5):
		var tip := Vector2((i - 2) * 18, -65 - (2 - absi(i - 2)) * 20)
		draw_line(Vector2(0, -17), tip, stem, 2, true)
		Paint.ellipse(self, tip + Vector2(-7, 5), Vector2(13, 7), Color(0.57, 0.66, 0.46, alpha))
		Paint.ellipse(self, tip + Vector2(7, 18), Vector2(13, 7), Color(0.46, 0.59, 0.43, alpha))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, -34), Vector2(24, -34), Vector2(18, 0), Vector2(-18, 0)]), Color(0.74, 0.49, 0.35, alpha))
	Paint.box(self, Rect2(-27, -39, 54, 10), Color(0.81, 0.57, 0.40, alpha), 3)
	draw_set_transform(Vector2.ZERO)
