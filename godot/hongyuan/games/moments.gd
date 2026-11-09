extends RefCounted
## 去看阿鱼那晚发的朋友圈：手机里一条长动态，手指上下滑着读；读到最后点一下爱心就合上。
const StoryCaption := preload("res://hongyuan/ui/story_caption.gd")
var r
var phase := "read"
var t := 0.0
var scroll := 0.0
var dragging := false
var last_y := 0.0
var liked := false
var lines: PackedStringArray = []
const FS := 15
const LH := 23.0
const VIEW := Rect2(34, 150, 292, 380)   # 正文可见区域
const LIKE := Rect2(232, 546, 84, 34)

func start(runner, beat: Dictionary) -> void:
	r = runner
	var body := str(r.copy.get(str(beat.get("text", "")), ""))
	lines = StoryCaption.wrap_text(body, VIEW.size.x, FS).split("\n")
	r.hint = "上下滑动，读完她那晚写下的话"

func _max_scroll() -> float:
	return maxf(0.0, lines.size() * LH - VIEW.size.y + 12)

func process(dt: float) -> bool:
	t += dt
	if phase == "liked" and t > 1.4:
		phase = "done"
		return true
	return false

func input(kind: String, pos: Vector2) -> void:
	if phase != "read":
		return
	if kind == "down":
		if scroll >= _max_scroll() - 4 and LIKE.grow(10).has_point(pos):
			liked = true
			phase = "liked"
			t = 0.0
			r.hint = ""
			r.play("pop")
			return
		dragging = VIEW.grow(20).has_point(pos)
		last_y = pos.y
	elif kind == "move" and dragging:
		scroll = clampf(scroll - (pos.y - last_y), 0, _max_scroll())
		last_y = pos.y
	elif kind == "up":
		dragging = false
		if scroll >= _max_scroll() - 4:
			r.hint = "读完了，点个爱心"

func draw(ci) -> void:
	ci.draw_rect(Rect2(0, 0, 360, 640), Color(0, 0, 0, 0.45))
	# 手机外框和屏幕
	ci.draw_style_box(_box(Color("#1c1a1f"), 30), Rect2(14, 60, 332, 548))
	ci.draw_style_box(_box(Color("#fbf8f3"), 22), Rect2(22, 72, 316, 524))
	# 头像、名字、时间
	ci.draw_circle(Vector2(54, 110), 18, Color("#f2c9d4"))
	ci.sprite("w2/common/ayu_cheer.png|ayu_idle.png", Vector2(54, 124), false, 0.18)
	ci.text_at(Vector2(80, 106), "阿鱼", 16, Color("#4a5d8a"), 120, HORIZONTAL_ALIGNMENT_LEFT)
	ci.text_at(Vector2(80, 128), "异地的最后一段日子 · 深夜", 12, Color("#9a9198"), 220, HORIZONTAL_ALIGNMENT_LEFT)
	ci.draw_line(Vector2(34, 142), Vector2(326, 142), Color("#ece4dc"), 1)
	# 正文：只画落在可见区域里的行
	for i in range(lines.size()):
		var y := VIEW.position.y + 16 + i * LH - scroll
		if y < VIEW.position.y + 8 or y > VIEW.end.y:
			continue
		ci.text_at(Vector2(VIEW.position.x, y), lines[i], FS, Color("#2c2a2e"), VIEW.size.x, HORIZONTAL_ALIGNMENT_LEFT)
	# 上下渐隐，提示还有内容
	if scroll > 2:
		ci.draw_rect(Rect2(VIEW.position.x, VIEW.position.y, VIEW.size.x, 10), Color("#fbf8f3", 0.85))
	if scroll < _max_scroll() - 2:
		ci.draw_rect(Rect2(VIEW.position.x, VIEW.end.y - 10, VIEW.size.x, 12), Color("#fbf8f3", 0.85))
		ci.text_at(Vector2(0, VIEW.end.y + 20), "︾ 往上滑", 12, Color("#b0a6a0"), 360)
	# 滚动条
	if _max_scroll() > 0:
		var bar_h := VIEW.size.y * VIEW.size.y / (VIEW.size.y + _max_scroll())
		var y0 := VIEW.position.y + (VIEW.size.y - bar_h) * scroll / _max_scroll()
		ci.draw_style_box(_box(Color("#d8cfc6"), 2), Rect2(328, y0, 4, bar_h))
	# 读完才出现的爱心
	if scroll >= _max_scroll() - 4:
		var pulse := 1.0 + (0.08 * sin(t * 6.0) if not liked else 0.0)
		ci.draw_style_box(_box(Color("#fde6ec") if not liked else Color("#f07a9a"), 17), Rect2(LIKE.position, LIKE.size * Vector2(1, 1)))
		ci.text_at(LIKE.position + Vector2(0, 24), "♥ 赞" if not liked else "♥ 已赞", int(16 * pulse), Color("#d0507a") if not liked else Color.WHITE, LIKE.size.x)

static func _box(fill: Color, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.anti_aliasing = true
	return b
