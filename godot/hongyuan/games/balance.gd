extends RefCounted
## Thirty calm seconds balancing daily demands. Full bars wait; there is no failure.
var r
var phase := "active"
var t := 0.0
var levels := [0.25,0.4,0.2]
var touches := 0
var glow := [0.0,0.0,0.0]
const LABELS := ["工作","家人","对方"]
func start(runner,_beat: Dictionary) -> void:
	r=runner;r.hint="哪件事快堆满了，就点一下照顾它"
func rect(i: int) -> Rect2: return Rect2(20+i*110,542,100,56)  # 三张并排压在最下沿，只挡到小腿，不再从腰盖到腿
func process(dt: float) -> bool:
	t += dt
	if phase == "active":
		for i in range(3):
			levels[i] = minf(1,levels[i]+dt*(0.033+i*0.004));glow[i]=maxf(0,glow[i]-dt)
		if t>=30 and touches>=3: phase="done";r.hint=""
	return phase == "done"
func input(kind: String,pos: Vector2) -> void:
	if kind!="tap" or phase!="active":return
	for i in range(3):
		if rect(i).has_point(pos):levels[i]=maxf(0,levels[i]-0.6);glow[i]=0.5;touches+=1;r.play("pop")
const ICON_COLOR := [Color("#5f7ea8"), Color("#c9824f"), Color("#d0607a")]

static func _box(fill: Color, border: Color, radius: int, bw: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(bw)
	b.set_corner_radius_all(radius)
	b.anti_aliasing = true
	return b

## 小图标：公文包、房子、爱心，用几笔画出来，跟像素风一致
func _icon(ci, i: int, c: Vector2, col: Color) -> void:
	match i:
		0:
			ci.draw_rect(Rect2(c + Vector2(-8, -4), Vector2(16, 11)), col)
			ci.draw_rect(Rect2(c + Vector2(-3, -7), Vector2(6, 3)), col, false, 1.5)
			ci.draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(1, 1, 1, 0.6), 1)
		1:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 0), c + Vector2(0, -8), c + Vector2(9, 0)]), col)
			ci.draw_rect(Rect2(c + Vector2(-6, 0), Vector2(12, 8)), col)
			ci.draw_rect(Rect2(c + Vector2(-2, 3), Vector2(4, 5)), Color(1, 1, 1, 0.7))
		2:
			ci.draw_circle(c + Vector2(-4, -2), 4.4, col)
			ci.draw_circle(c + Vector2(4, -2), 4.4, col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-8.2, -0.5), c + Vector2(8.2, -0.5), c + Vector2(0, 8)]), col)

func draw(ci) -> void:
	for i in range(3):
		var box:=rect(i)
		var lift: float = glow[i] * 4.0
		box.position.y -= lift
		# 投影 + 半透明纸面圆角卡片，细金边
		ci.draw_style_box(_box(Color(0, 0, 0, 0.28), Color(0, 0, 0, 0), 10, 0), Rect2(box.position + Vector2(0, 3), box.size))
		ci.draw_style_box(_box(Color("#fff7ea", 0.93), Color("#c9a15a") if levels[i] <= .8 else Color("#d9775a"), 10, 2), box)
		_icon(ci, i, box.position + Vector2(20, 18), ICON_COLOR[i])
		ci.text_at(box.position + Vector2(32, 25), LABELS[i], 16, ci.INK, 64, HORIZONTAL_ALIGNMENT_LEFT)
		var track := Rect2(box.position + Vector2(10, 38), Vector2(box.size.x - 20, 8))
		ci.draw_style_box(_box(Color("#e5d6bf"), Color(0, 0, 0, 0), 4, 0), track)
		var full: bool = levels[i] > .8
		if levels[i] > 0.02:
			ci.draw_style_box(_box(Color("#e07a5f") if full else Color("#7fb08e"), Color(0, 0, 0, 0), 4, 0), Rect2(track.position, Vector2(maxf(8, track.size.x * levels[i]), 8)))
		if full:
			var pulse := 0.5 + 0.5 * sin(t * 8.0)
			ci.draw_style_box(_box(Color(0, 0, 0, 0), Color("#e07a5f", 0.5 * pulse), 12, 2), box.grow(3))
		if glow[i]>0:ci.text_at(box.position+Vector2(10,-8),"慢慢来",14,ci.PAPER,80)
	ci.text_at(Vector2(24,620),"一起度过这段日子 · %d / 30 秒"%mini(30,int(t)),14,ci.PAPER,250)
