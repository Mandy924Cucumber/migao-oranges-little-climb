class_name ClimbPlatform
extends StaticBody2D

const SPECS := {
	"stool": [118, 90, "小木凳"], "books": [142, 76, "叠叠书"],
	"lamp": [82, 135, "小台灯"], "bed": [208, 103, "弹力床"],
	"radio": [136, 93, "旧收音机"], "teacup": [78, 84, "陶瓷杯"],
	"suitcase": [144, 104, "旅行箱"], "cushion": [152, 63, "软坐垫"],
	"drawer": [134, 127, "床头柜"], "clock": [88, 96, "小闹钟"],
	"bench": [174, 98, "长木凳"], "toaster": [112, 91, "烤面包机"],
	"basket": [139, 88, "藤编篮"], "skateboard": [154, 42, "滑板"],
	"piano": [178, 138, "小钢琴"], "checkpoint": [270, 92, "砖块检查站"],
	"finish": [330, 100, "云端花园"]
}
var kind := "stool"
var index := 0
var visited := false
var active_checkpoint := false
var width := 118.0
var art_height := 90.0
var spring := 0.0
var clock := 0.0
var font: Font
var texture: Texture2D
var item_name := ""

func configure(type: String, number: int) -> void:
	kind = type
	index = number
	width = float(SPECS[kind][0])
	art_height = float(SPECS[kind][1])
	item_name = SPECS[kind][2]

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("platforms")
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# Match the top silhouette, rather than the widest part of the illustration.
	var top_width := width - 4
	var top_offset := 0.0
	match kind:
		"lamp": top_width = 46.0
		"books":
			top_width = 126.0
			top_offset = -6.5
		"bed": top_width = 184.0
		"cushion": top_width = 124.0
		"radio", "suitcase": top_width = width - 24.0
		"clock": top_width = 58.0
		"toaster": top_width = 84.0
		"skateboard": top_width = 132.0
	shape.size = Vector2(top_width, 12)
	collider.shape = shape
	collider.position = Vector2(top_offset, 6)
	collider.one_way_collision = true
	collider.one_way_collision_margin = 8.0
	add_child(collider)
	if kind != "checkpoint" and kind != "finish":
		texture = load("res://assets/objects/%s.svg" % kind)

func _process(delta: float) -> void:
	clock += delta
	spring = move_toward(spring, 0.0, delta * 3.0)
	if absf(global_position.y - get_viewport_rect().size.y * 0.5) < 1200.0:
		queue_redraw()

func _draw() -> void:
	if kind == "checkpoint" or kind == "finish":
		_draw_bricks()
	else:
		Paint.ellipse(self, Vector2(3, art_height + 10), Vector2(width * 0.48, 5), Color(0.28, 0.24, 0.18, 0.075))
		var squash := 1.0 - spring * 0.14
		draw_texture_rect(texture, Rect2(-width / 2.0 - 12, -12 + spring * 8, width + 24, (art_height + 24) * squash), false)
		if kind == "bed":
			Paint.box(self, Rect2(width / 2.0 - 37, 68, 43, 21), Color("f3d799"), 5)
			Paint.label(self, font, "弹力", Vector2(width / 2.0 - 29, 83), 11, Color("856742"))
	if font:
		var txt := "%03d  %s" % [index, item_name]
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		Paint.label(self, font, txt, Vector2(-tw / 2.0, art_height + 32), 12, Color("938c78"))
		if visited:
			draw_circle(Vector2(-tw / 2.0 - 12, art_height + 27), 3, Color("8eaa8b"))

func _draw_bricks() -> void:
	var color := Color("c79778")
	if active_checkpoint:
		Paint.box(self, Rect2(-width / 2.0 - 7, -6, width + 14, 17), Color(0.96, 0.77, 0.43, 0.3), 6)
	Paint.box(self, Rect2(-width / 2.0, 0, width, 78), color, 3, Color("a57e62"), 2)
	for row in range(3):
		var y := 10.0 + row * 23.0
		draw_line(Vector2(-width / 2, y + 22), Vector2(width / 2, y + 22), Color("e9c5a3"), 3, true)
		for col in range(5):
			var x := -width / 2 + col * 67 + (32 if row % 2 == 1 else 0)
			if x > -width / 2 and x < width / 2:
				draw_line(Vector2(x, y), Vector2(x, y + 20), Color("e9c5a3"), 3, true)
	Paint.box(self, Rect2(-width / 2.0 - 5, 0, width + 10, 12), Color("e9c9a2"), 4, Color("b08b69"), 2)
	# The flag is decorative; the entire brick cap is a landing surface.
	var fx := width / 2.0 - 23
	draw_line(Vector2(fx, 0), Vector2(fx, -77), Color("8e8265"), 4, true)
	var flag_color := Color("dd9a66") if not active_checkpoint else Color("88a792")
	draw_colored_polygon(PackedVector2Array([Vector2(fx, -77), Vector2(fx + 42, -73), Vector2(fx + 35, -57), Vector2(fx + 42, -42), Vector2(fx, -46)]), flag_color)
	draw_circle(Vector2(fx, -80), 4, Color("d6b16c"))
	Paint.box(self, Rect2(-65, 29, 130, 31), Color("f5e9ce"), 5)
	Paint.label(self, font, "已保存" if active_checkpoint else ("到达云端" if kind == "finish" else "检查站 %02d" % (index / 24)), Vector2(-40, 50), 15, Color("7e725c"))
