extends Control
## 换场景的转场。STYLE="fade"：柔和渐隐（默认）；"diamond"：像素菱形斜扫。
const STYLE := "fade"
const CELL := 30.0
const SPREAD := 0.9
const COLOR := Color("#281a1a")
const EDGE := Color("#f4d495")

## 0 = 画面完全露出，1 = 完全盖住。
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()
## false：正在盖上；true：正在退开（退开时先盖上的地方先露出来）。
var leaving := false

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## 每个格子的菱形大小，0～1。
static func cell_amount(amount: float, leaving_now: bool, offset: float) -> float:
	if leaving_now:
		return 1.0 - clampf((1.0 - amount) * (1.0 + SPREAD) - offset * SPREAD, 0.0, 1.0)
	return clampf(amount * (1.0 + SPREAD) - offset * SPREAD, 0.0, 1.0)

static func paint(ci: CanvasItem, rect: Rect2, amount: float, leaving_now: bool, color := COLOR) -> void:
	if amount <= 0.0:
		return
	if amount >= 1.0:
		ci.draw_rect(rect, color)
		return
	if STYLE == "fade":
		ci.draw_rect(rect, Color(color, color.a * amount))
		return
	var cols := int(ceil(rect.size.x / CELL)) + 1
	var rows := int(ceil(rect.size.y / CELL)) + 1
	var edge := Color(EDGE, 0.55 * color.a)
	for row in range(rows):
		for col in range(cols):
			var center := rect.position + Vector2(col * CELL, row * CELL)
			# 从左下角开始扫向右上角。
			var offset := (float(col) / cols + 1.0 - float(row) / rows) * 0.5
			var k := cell_amount(amount, leaving_now, offset)
			if k < 0.04:
				continue
			var r := CELL * k
			var diamond := PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)])
			ci.draw_colored_polygon(diamond, color)
			if k < 0.98:
				diamond.append(diamond[0])
				ci.draw_polyline(diamond, edge, 1.0)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	paint(self, rect, progress, leaving)

## 盖上。
func cover(seconds := 0.38) -> void:
	leaving = false
	var tween := create_tween()
	tween.tween_property(self, "progress", 1.0, seconds).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

## 退开。
func reveal(seconds := 0.5) -> void:
	leaving = true
	var tween := create_tween()
	tween.tween_property(self, "progress", 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	leaving = false
