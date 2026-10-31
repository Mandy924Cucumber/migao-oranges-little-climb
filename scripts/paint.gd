class_name Paint
extends RefCounted

static func box(canvas: CanvasItem, rect: Rect2, fill: Color, radius: float = 8.0, border: Color = Color.TRANSPARENT, width: float = 1.0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(int(radius))
	style.border_color = border
	style.set_border_width_all(int(width) if border.a > 0 else 0)
	canvas.draw_style_box(style, rect)

static func ellipse(canvas: CanvasItem, at: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(48):
		var angle := TAU * i / 48.0
		points.append(at + Vector2(cos(angle), sin(angle)) * radius)
	canvas.draw_colored_polygon(points, color)

static func label(canvas: CanvasItem, font: Font, text: String, at: Vector2, size: int, color: Color) -> void:
	canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
