extends RefCounted
## 隔着电话唱歌：part=sing 时 Toretto 唱，音符从他那边飘向阿鱼，点住音符就是在认真听；
## 认出那句「多远都要在一起」后结束。part=crash 时电脑被唱死机，画面卡住、弹出无响应，两人笑成一团。
var r
var part := "sing"
var phase := "play"
var t := 0.0
var notes: Array = []     # {p, v, age, caught, wob}
var spawn := 0.0
var caught := 0
var need := 5
var shown: Array = []     # [文字, 位置, 剩余时间]
const FROM := Vector2(212, 470)
const TO := Vector2(170, 150)
const BITS := ["♪ 啦～", "♫ 啦啦～", "（调跑到天边了）", "♪ 嗯～嗯～", "（努力跟上节奏）"]
const LYRIC := "多远都要在一起"

func start(runner, beat: Dictionary) -> void:
	r = runner
	part = str(beat.get("part", "sing"))
	need = int(beat.get("count", 5))
	if part == "sing":
		r.hint = "点一下飘过来的音符，认真听他在唱什么"
	else:
		r.hint = ""
		r.play("pop")

func process(dt: float) -> bool:
	t += dt
	for s: Array in shown:
		s[2] = float(s[2]) - dt
	shown = shown.filter(func(s: Array) -> bool: return float(s[2]) > 0)
	if part == "crash":
		return t > 3.0
	if part == "laugh":
		return t > 2.6
	for n: Dictionary in notes:
		n.age += dt
		if n.caught:
			continue
		n.p += n.v * dt
		n.p.x += sin(n.age * 5.0 + n.wob) * 0.9
	notes = notes.filter(func(n: Dictionary) -> bool: return n.age < 6.0 and (not n.caught or n.age < 0.6 + n.get("caught_at", 0.0)) and n.p.y > 30)
	match phase:
		"play":
			spawn -= dt
			if spawn <= 0:
				spawn = 0.9
				var dir: Vector2 = (TO - FROM).normalized().rotated(randf_range(-0.35, 0.35))
				notes.append({"p": FROM + Vector2(randf_range(-14, 14), 0), "v": dir * randf_range(48, 62), "age": 0.0, "caught": false, "wob": randf() * TAU})
			if caught >= need:
				phase = "lyric"
				t = 0.0
				r.hint = ""
				notes.clear()
		"lyric":
			if t > 3.2:
				phase = "done"
				return true
	return false

func input(kind: String, pos: Vector2) -> void:
	if part != "sing" or phase != "play" or kind != "down":
		return
	for n: Dictionary in notes:
		if not n.caught and pos.distance_to(n.p) < 34:
			n.caught = true
			n.caught_at = n.age
			shown.append([BITS[caught % BITS.size()], n.p + Vector2(0, -18), 1.4])
			caught += 1
			r.play("pop")
			return

func draw(ci) -> void:
	if part == "crash":
		_draw_crash(ci)
		return
	if part == "laugh":
		_draw_laugh(ci)
		return
	# 音符：五线谱一样的小尾巴，被点到时亮一下变大
	for n: Dictionary in notes:
		var a: float = clampf(1.0 - n.age / 6.0, 0.25, 1.0)
		var size := 30 if not n.caught else 30 + int((n.age - n.get("caught_at", 0.0)) * 40)
		var col := Color("#ffe3a3", a) if not n.caught else Color("#ffb3cf", a)
		ci.draw_circle(n.p, 18.0, Color(0, 0, 0, 0.18 * a))
		ci.text_at(n.p + Vector2(-20, 11), "♪" if int(n.wob * 10) % 2 == 0 else "♫", size, col, 40)
	for s: Array in shown:
		var k: float = clampf(float(s[2]) / 1.4, 0, 1)
		var at: Vector2 = s[1] + Vector2(0, -(1.0 - k) * 24)
		ci.draw_style_box(_box(Color("#fff7ea", 0.9 * k), 9), Rect2(at - Vector2(66, 18), Vector2(132, 26)))
		ci.text_at(at + Vector2(-66, 1), str(s[0]), 14, Color(ci.INK, k), 132)
	if phase == "play":
		ci.text_at(Vector2(0, 618), "听懂了 %d / %d 句" % [mini(caught, need), need], 14, ci.PAPER, 360)
	elif phase == "lyric":
		var k := clampf(t / 0.8, 0, 1)
		var box := Rect2(40, 268, 280, 64)
		ci.draw_style_box(_box(Color("#fff3f6", 0.95 * k), 14), box)
		ci.text_at(Vector2(40, 296), "原来他唱的是", 14, Color(ci.WOOD, k), 280)
		ci.text_at(Vector2(40, 322), "「" + LYRIC + "」", 22, Color("#c2456b", k), 280)

func _draw_crash(ci) -> void:
	# 0–1.4 秒：画面撕裂、卡住；1.4–3 秒：无响应对话框；之后：两人哈哈大笑
	if t < 1.4:
		for i in range(14):
			var y := fmod(i * 47.0 + t * 260.0, 640.0)
			var h := 6.0 + fmod(i * 13.0, 18.0)
			ci.draw_rect(Rect2(0, y, 360, h), Color(1, 1, 1, 0.08) if i % 2 == 0 else Color(0.2, 0.9, 1.0, 0.10))
			ci.draw_rect(Rect2(fmod(i * 61.0, 300.0), y, 60, h * 0.5), Color(1, 0.2, 0.5, 0.18))
		ci.text_at(Vector2(0, 330), "多 远 都 要 在 一 起 ——", 20, Color("#ffd6e2", 0.9), 360)
	else:
		ci.draw_rect(Rect2(0, 0, 360, 640), Color(0, 0, 0, 0.35))
		var box := Rect2(46, 250, 268, 120)
		ci.draw_style_box(_box(Color("#eef0f4"), 8), box)
		ci.draw_rect(Rect2(box.position, Vector2(box.size.x, 26)), Color("#5a6b8c"))
		ci.text_at(box.position + Vector2(10, 18), "音乐播放器", 13, Color.WHITE, 200, HORIZONTAL_ALIGNMENT_LEFT)
		ci.text_at(box.position + Vector2(0, 62), "程序未响应", 18, Color("#2a2f3a"), box.size.x)
		ci.text_at(box.position + Vector2(0, 92), "（电脑被唱死机了）", 14, Color("#6b7385"), box.size.x)


func _draw_laugh(ci) -> void:
	var k := clampf(t / 0.3, 0, 1)
	for i in range(9):
		var at := Vector2(30 + fmod(i * 83.0, 250.0), 90 + fmod(i * 131.0, 420.0) - t * 26.0)
		var s := 18 + (i % 3) * 6
		ci.text_at(at, "哈哈" if i % 2 == 0 else "哈哈哈", s, Color("#fff1d5", k * (0.65 + 0.35 * sin(t * 9 + i))), 120)

static func _box(fill: Color, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.set_corner_radius_all(radius)
	b.anti_aliasing = true
	return b
