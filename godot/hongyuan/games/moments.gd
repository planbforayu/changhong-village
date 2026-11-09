extends RefCounted
## 去看阿鱼那晚发的朋友圈：整屏就是一条朋友圈的「详情」页。
## 上下滑着读完长文和四张图，点右下角「··」弹出「赞」，点赞后 Toretto 的头像加进点赞栏，再留一句评论。
const StoryCaption := preload("res://hongyuan/ui/story_caption.gd")
var r
var phase := "read"          # read → liked → done
var t := 0.0
var liked_t := 0.0
var scroll := 0.0
var dragging := false
var last_y := 0.0
var menu := false
var menu_t := 0.0
var lines: PackedStringArray = []
var toast := ""

const FS := 15
const LH := 24.0
const NAV_H := 52.0
const TEXT_X := 62.0
const TEXT_W := 284.0
const BLUE := Color("#576b95")
const GRAY := Color("#b2b2b2")
const INK := Color("#191919")
const PANEL := Color("#f7f7f7")
const PHOTO := 92.0
## 四张图都取自游戏里画好的场景（不是真实照片）：牵手、她打电话、他打电话、并肩散步
const PHOTOS := [
	["w2/call/ayu_toretto_holdhands.png", Rect2(0, 820, 841, 841)],
	["round1/people/call_split.png", Rect2(110, 40, 740, 740)],
	["round1/people/call_split.png", Rect2(80, 900, 760, 760)],
	["round1/people/daily_walk.png", Rect2(0, 860, 841, 841)],
]
## 点赞栏里先有的朋友（游戏角色和泛化的朋友），点赞后 Toretto 排到最前
const FRIENDS := [
	["axiao_avatar.png", "", Color.WHITE],
	["", "猫", Color("#e9c9a8")],
	["", "海", Color("#8fb8d8")],
	["", "星", Color("#3c4f86")],
	["", "花", Color("#f2b8c6")],
	["", "糖", Color("#c8e0b4")],
	["", "鹿", Color("#c9a27e")],
	["", "云", Color("#d8dde6")],
	["", "橘", Color("#f4b26b")],
]

# 版面（内容坐标，未减滚动）
var y_body := 0.0
var y_photos := 0.0
var y_meta := 0.0
var y_panel := 0.0
var bottom := 0.0

func start(runner, beat: Dictionary) -> void:
	r = runner
	var body := str(r.copy.get(str(beat.get("text", "")), ""))
	lines = StoryCaption.wrap_text(body, TEXT_W, FS).split("\n")
	r.hint = ""
	toast = "上下滑动，读完她那晚写下的话"
	_layout()

func _layout() -> void:
	y_body = NAV_H + 44.0
	y_photos = y_body + lines.size() * LH + 10.0
	y_meta = y_photos + PHOTO * 2 + 4 + 22.0
	y_panel = y_meta + 18.0
	bottom = y_panel + _panel_h() + 40.0

func _like_rows() -> int:
	var n := FRIENDS.size() + (1 if phase != "read" else 0)
	return int(ceil(n / 8.0))

func _comments() -> Array:
	var c := [["阿鱼。", "谢谢大家～点赞即祝福哈哈哈哈"], ["阿晓", "所以电脑最后修好了吗"]]
	if phase != "read":
		c.append(["Toretto", "下次换台电脑，再唱给你听。"])
	return c

func _panel_h() -> float:
	return 12.0 + _like_rows() * 34.0 + 8.0 + _comments().size() * 24.0 + 8.0

func _max_scroll() -> float:
	return maxf(0.0, bottom - 640.0)

func _dots_rect() -> Rect2:
	return Rect2(312, y_meta - 15 - scroll, 34, 22)

func _like_btn() -> Rect2:
	var d := _dots_rect()
	return Rect2(d.position.x - 152, d.position.y - 8, 74, 38)

func process(dt: float) -> bool:
	t += dt
	if menu:
		menu_t += dt
	if phase == "read" and scroll >= _max_scroll() - 30 and toast.begins_with("上下"):
		toast = "读完了，点右下角的「··」给她点个赞"
	if phase == "liked":
		liked_t += dt
		# 点赞后把新长出来的点赞栏和评论滑进来
		scroll = move_toward(scroll, _max_scroll(), 240.0 * dt)
		if liked_t > 2.6:
			phase = "done"
			return true
	return false

func input(kind: String, pos: Vector2) -> void:
	if phase != "read":
		return
	match kind:
		"down":
			dragging = pos.y > NAV_H
			last_y = pos.y
		"move":
			if dragging:
				scroll = clampf(scroll - (pos.y - last_y), 0, _max_scroll())
				last_y = pos.y
		"up":
			dragging = false
		"tap":
			if menu and _like_btn().grow(6).has_point(pos):
				_like()
			elif _dots_rect().grow(10).has_point(pos):
				menu = not menu
				menu_t = 0.0
				r.play("pop")
			else:
				menu = false

func _like() -> void:
	menu = false
	phase = "liked"
	liked_t = 0.0
	toast = ""
	r.play("pop")
	_layout()

## 测试和走查脚本用：直接滑到底并点赞
func auto_like() -> void:
	scroll = _max_scroll()
	_like()

func draw(ci) -> void:
	var s := scroll
	ci.draw_rect(Rect2(0, 0, 360, 640), Color.WHITE)
	# 头像、名字
	var top := NAV_H + 14 - s
	_avatar(ci, "ayu_avatar.png", "", Color.WHITE, Rect2(12, top, 42, 42))
	ci.text_at(Vector2(TEXT_X, top + 17), "阿鱼。", 16, BLUE, 200, HORIZONTAL_ALIGNMENT_LEFT)
	# 正文
	for i in range(lines.size()):
		var y := y_body + i * LH - s + 4
		if y < NAV_H or y > 660:
			continue
		ci.text_at(Vector2(TEXT_X, y), lines[i], FS, INK, TEXT_W, HORIZONTAL_ALIGNMENT_LEFT)
	# 2×2 配图
	for k in range(PHOTOS.size()):
		var rect := Rect2(TEXT_X + (k % 2) * (PHOTO + 4), y_photos - s + int(k / 2) * (PHOTO + 4), PHOTO, PHOTO)
		if rect.end.y < NAV_H or rect.position.y > 640:
			continue
		var tex: Texture2D = ci.texture(str(PHOTOS[k][0]))
		if tex:
			ci.draw_texture_rect_region(tex, rect, PHOTOS[k][1])
		else:
			ci.draw_rect(rect, Color("#e8e2da"))
	# 时间行和「··」
	var my := y_meta - s
	ci.text_at(Vector2(TEXT_X, my), "深夜 · 异地的最后一段日子", 12, GRAY, 240, HORIZONTAL_ALIGNMENT_LEFT)
	var d := _dots_rect()
	if phase == "read" and not menu and scroll >= _max_scroll() - 30:
		var a := 0.35 + 0.35 * sin(t * 5.0)
		ci.draw_style_box(_box(Color(0, 0, 0, 0), 6, Color(BLUE, a), 2), d.grow(4))
	ci.draw_style_box(_box(PANEL, 4), d)
	ci.draw_circle(d.get_center() + Vector2(-5, 0), 2.4, BLUE)
	ci.draw_circle(d.get_center() + Vector2(5, 0), 2.4, BLUE)
	# 点赞和评论栏
	_draw_panel(ci, y_panel - s)
	# 弹出的「赞 | 评论」
	if menu:
		var k := clampf(menu_t / 0.12, 0, 1)
		var box := Rect2(d.position.x - 156 + 156 * (1 - k), d.position.y - 8, 150 * k, 38)
		ci.draw_style_box(_box(Color("#4c4c4c"), 6), box)
		if k >= 1:
			ci.text_at(Vector2(box.position.x, box.position.y + 25), "♡ 赞", 14, Color.WHITE, 76)
			ci.draw_line(Vector2(box.position.x + 76, box.position.y + 10), Vector2(box.position.x + 76, box.end.y - 10), Color(1, 1, 1, 0.25), 1)
			ci.text_at(Vector2(box.position.x + 76, box.position.y + 25), "评论", 14, Color.WHITE, 74)
	# 顶栏（盖在滚动内容上面）
	ci.draw_rect(Rect2(0, 0, 360, NAV_H), Color("#ededed"))
	ci.draw_line(Vector2(0, NAV_H), Vector2(360, NAV_H), Color("#dcdcdc"), 1)
	ci.draw_polyline(PackedVector2Array([Vector2(26, 22), Vector2(18, 31), Vector2(26, 40)]), INK, 2.0)
	ci.text_at(Vector2(0, 38), "详情", 17, INK, 360)
	# 滚动条
	if _max_scroll() > 0:
		var view := 640.0 - NAV_H
		var bar_h := view * view / (view + _max_scroll())
		ci.draw_style_box(_box(Color(0, 0, 0, 0.18), 2), Rect2(354, NAV_H + (view - bar_h) * scroll / _max_scroll(), 3, bar_h))
	# 底部提示
	if toast != "":
		var w := minf(320.0, 30.0 + 14.0 * toast.length())
		var tr := Rect2((360 - w) * 0.5, 588, w, 32)
		ci.draw_style_box(_box(Color(0, 0, 0, 0.62), 16), tr)
		ci.text_at(Vector2(tr.position.x, tr.position.y + 21), toast, 14, Color.WHITE, w)

func _draw_panel(ci, y: float) -> void:
	var rect := Rect2(TEXT_X, y, 346 - TEXT_X, _panel_h())
	ci.draw_colored_polygon(PackedVector2Array([Vector2(TEXT_X + 14, y - 6), Vector2(TEXT_X + 8, y), Vector2(TEXT_X + 20, y)]), PANEL)
	ci.draw_style_box(_box(PANEL, 4), rect)
	# 爱心 + 头像
	_heart(ci, Vector2(TEXT_X + 14, y + 26), 7.0, BLUE)
	var people: Array = FRIENDS.duplicate()
	if phase != "read":
		people.push_front(["toretto_avatar.png", "", Color.WHITE])
	for i in range(people.size()):
		var at := Vector2(TEXT_X + 30 + (i % 8) * 31, y + 12 + int(i / 8) * 34)
		var size := 28.0
		if phase != "read" and i == 0:
			var k := clampf(liked_t / 0.35, 0, 1)
			size = 28.0 * (1.0 + 0.35 * sin(k * PI)) * k
		var p: Array = people[i]
		_avatar(ci, str(p[0]), str(p[1]), p[2], Rect2(at + Vector2(14 - size * 0.5, 14 - size * 0.5), Vector2(size, size)))
	# 评论
	var cy := y + 12 + _like_rows() * 34.0 + 4
	ci.draw_line(Vector2(TEXT_X + 6, cy), Vector2(rect.end.x - 6, cy), Color("#e6e6e6"), 1)
	for c: Array in _comments():
		cy += 24
		var name := str(c[0]) + "："
		var nw := 0.0
		for ch in name:
			nw += 7.5 if ch.unicode_at(0) < 128 else 13.0
		ci.text_at(Vector2(TEXT_X + 10, cy - 6), name, 13, BLUE, nw + 4, HORIZONTAL_ALIGNMENT_LEFT)
		ci.text_at(Vector2(TEXT_X + 10 + nw, cy - 6), str(c[1]), 13, INK, rect.size.x - nw - 14, HORIZONTAL_ALIGNMENT_LEFT)

func _avatar(ci, tex_name: String, letter: String, fill: Color, rect: Rect2) -> void:
	if rect.size.x <= 1:
		return
	var tex: Texture2D = ci.texture(tex_name) if tex_name != "" else null
	if tex:
		ci.draw_rect(rect, Color("#f0ebe4"))
		ci.draw_texture_rect(tex, rect, false)
	else:
		ci.draw_style_box(_box(fill, 3), rect)
		ci.text_at(Vector2(rect.position.x, rect.position.y + rect.size.y * 0.7), letter, int(rect.size.y * 0.5), Color(1, 1, 1, 0.92), rect.size.x)

static func _heart(ci, c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(25):
		var a := TAU * i / 24.0
		var x := 16.0 * pow(sin(a), 3)
		var y := -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
		pts.append(c + Vector2(x, y) * s / 16.0)
	ci.draw_polyline(pts, col, 1.6, true)

static func _box(fill: Color, radius: int, border := Color(0, 0, 0, 0), bw := 0) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.anti_aliasing = true
	if bw > 0:
		b.border_color = border
		b.set_border_width_all(bw)
	return b
