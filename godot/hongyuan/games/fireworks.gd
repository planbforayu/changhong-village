extends RefCounted
## 文昌烟花：点哪里，哪里就升起一簇大烟花（主花加两朵伴花，带火光拖尾）。
## 点够次数后满天齐放一轮，最后一朵最大的凝成火漆。

const COLORS := ["red", "gold", "blue"]
const TINT := {"red": Color("#ff6b7d"), "gold": Color("#ffd46b"), "blue": Color("#8fd0ff"), "pink": Color("#ff86c8")}
const RISE := 0.32          # 火光从岸边升到绽放点的时间
const LIFE := 2.4           # 一朵从绽放到散尽
var r
var t := 0.0
var bursts: Array = []      # {at, color, t, size, big, from}
var pending: Array = []     # [延迟秒, at, color, size]
var count := 0
var need := 5
var phase := "play"
var finale_t := 0.0
var color_offset := 0
var flash := 0.0

func start(runner, beat: Dictionary) -> void:
	r = runner
	need = int(beat.get("count", 5))
	color_offset = randi_range(0, 2)
	r.hint = "点一下夜空，在那里放一簇烟花"

func _burst(at: Vector2, color: String, size: float, big := false, shape := "ring") -> void:
	bursts.append({"at": at, "color": color, "t": 0.0, "size": size, "big": big, "shape": shape,
		"from": Vector2(at.x + randf_range(-18, 18), 400)})

## 火花的方向：圆形烟花沿圆周，心形烟花沿心形曲线（尖朝下）
static func _dir(shape: String, angle: float) -> Vector2:
	if shape == "heart":
		var s := sin(angle)
		return Vector2(16.0 * s * s * s, -(13.0 * cos(angle) - 5.0 * cos(2 * angle) - 2.0 * cos(3 * angle) - cos(4 * angle))) / 16.0
	return Vector2(cos(angle), sin(angle))

func _cluster(at: Vector2, k: int) -> void:
	var main: String = COLORS[(k + color_offset) % 3]
	# 第二下是一颗粉色的心
	if k % 2 == 1:
		_burst(at, "pink", randf_range(190, 215), false, "heart")
	else:
		_burst(at, main, randf_range(170, 200))
	r.play("pop")
	# 两朵伴花，稍晚一点在旁边开，颜色不同
	for j in range(2):
		var side := -1.0 if j == 0 else 1.0
		var off := Vector2(side * randf_range(55, 80), randf_range(-45, 35))
		pending.append([0.18 + j * 0.16, (at + off).clamp(Vector2(30, 40), Vector2(330, 330)), COLORS[(k + color_offset + 1 + j) % 3], randf_range(110, 140)])

func process(dt: float) -> bool:
	t += dt
	flash = maxf(0.0, flash - dt * 2.5)
	for b: Dictionary in bursts:
		b.t += dt
		if b.t >= RISE and b.t - dt < RISE:
			flash = maxf(flash, 0.5 if b.big else 0.25)
	bursts = bursts.filter(func(b: Dictionary) -> bool: return b.t < RISE + LIFE or (b.big and phase != "done"))
	for p: Array in pending:
		p[0] -= dt
	for p: Array in pending.filter(func(p: Array) -> bool: return p[0] <= 0):
		_burst(p[1], p[2], p[3], false, p[4] if p.size() > 4 else "ring")
		r.play("pop")
	pending = pending.filter(func(p: Array) -> bool: return p[0] > 0)
	match phase:
		"play":
			if count >= need and pending.is_empty():
				r.hint = ""
				phase = "finale"
				finale_t = 0.0
				# 满天齐放：三秒里十六朵，铺满整片夜空
				for i in range(16):
					var at := Vector2(40 + fmod(i * 97.0, 280.0), 60 + fmod(i * 61.0, 230.0))
					if i % 4 == 2:
						pending.append([0.2 + i * 0.17, at, "pink", randf_range(170, 210), "heart"])
					else:
						pending.append([0.2 + i * 0.17, at, COLORS[(i + color_offset) % 3], randf_range(140, 210)])
		"finale":
			finale_t += dt
			if finale_t > 3.4 and bursts.filter(func(b: Dictionary) -> bool: return b.big).is_empty():
				_burst(Vector2(180, 200), "pink", 280.0, true, "heart")
				r.play("pop")
			if finale_t > 5.4:
				phase = "wax"
				finale_t = 0.0
		"wax":
			finale_t += dt
			if finale_t > 2.4:
				phase = "done"
				return true
	return false

func input(kind: String, pos: Vector2) -> void:
	if phase == "play" and kind == "down" and pos.y >= 0 and pos.y < 440 and count < need:
		_cluster(Vector2(clampf(pos.x, 40, 320), clampf(pos.y, 50, 320)), count)
		count += 1

func draw(ci) -> void:
	for b: Dictionary in bursts:
		if b.big and phase == "wax":
			continue
		var color: Color = TINT[b.color]
		var at: Vector2 = b.at
		if b.t < RISE:
			var k := ease(b.t / RISE, 0.6)
			var head: Vector2 = b.from.lerp(at, k)
			var tail: Vector2 = b.from.lerp(at, maxf(0.0, k - 0.18))
			ci.draw_line(tail, head, Color(color, 0.85), 3.0)
			ci.draw_circle(head, 6.0, Color(color, 0.3))
			ci.draw_circle(head, 2.6, Color(1, 1, 0.9))
			continue
		var bloom: float = b.t - RISE
		var alpha: float = clampf((LIFE - bloom) / 0.9, 0, 1)
		var shape: String = b.get("shape", "ring")
		var core_tex: Texture2D = null
		if shape == "ring":
			var frame := mini(5, 1 + int(bloom / 0.3))
			core_tex = ci.texture("w2/hainan/firework_%s_%d.png" % [b.color, frame])
		if core_tex:
			var size: float = b.size * lerpf(0.55, 1.1, clampf(bloom / 1.4, 0, 1))
			ci.draw_texture_rect(core_tex, Rect2(at - Vector2.ONE * size * 0.5, Vector2.ONE * size), false, Color(1, 1, 1, alpha * 0.8))
		# 粗一点、亮一点的火花：每颗先画一圈柔光，再画实心亮点，往外炸开慢慢下坠
		var radius: float = b.size * 0.5 * (1.0 - exp(-bloom * 2.6))
		var rays := (64 if b.big else 40) + (20 if shape == "heart" else 0)
		var glow := Color(color, alpha * 0.28)
		var hot := Color(color.lerp(Color.WHITE, 0.55), alpha)
		var dot: float = 2.6 if b.big else 2.2
		for ray in range(rays):
			var angle: float = TAU * ray / rays + (0.0 if shape == "heart" else float(b.size))
			var lk: float = 1.0 if shape == "heart" else 0.85 + 0.15 * sin(ray * 2.43 + float(b.size))
			var dir := _dir(shape, angle)
			var fall := Vector2(0, bloom * bloom * (5.0 if shape == "heart" else 9.0))
			var p: Vector2 = at + dir * radius * lk + fall
			var trail: Vector2 = at + dir * radius * lk * 0.82 + fall * 0.8
			var tw: float = 0.75 + 0.25 * sin(t * 20 + ray)
			ci.draw_line(trail, p, Color(color, alpha * 0.55 * tw), dot)
			ci.draw_circle(p, dot * 2.2, Color(glow, glow.a * tw))
			ci.draw_circle(p, dot, Color(hot, hot.a * tw))
		# 内圈换一种颜色，层次更满
		var inner: Color = TINT[COLORS[(COLORS.find(b.color) + 1) % 3]] if b.color in COLORS else Color("#fff1a8")
		for ray in range(0 if shape == "heart" else rays / 2):
			var angle2: float = TAU * ray / (rays / 2) + 0.3
			var p2: Vector2 = at + _dir(shape, angle2) * radius * 0.55 + Vector2(0, bloom * bloom * 6)
			ci.draw_circle(p2, dot * 0.9, Color(inner.lerp(Color.WHITE, 0.35), alpha * 0.95))
		if bloom < 0.4:
			ci.draw_circle(at, b.size * 0.1 * (1.0 - bloom / 0.4), Color(1, 0.97, 0.85, 0.6 * (1.0 - bloom / 0.4)))
		# 海面倒影
		for j in range(8):
			var y := 386.0 + j * 4.5
			var x: float = at.x + sin(t * 1.8 + j * 1.7) * 8
			var w: float = (14 + j * 2.6) * alpha * (1.5 if b.big else 1.0)
			ci.draw_line(Vector2(x - w, y), Vector2(x + w, y), Color(color, alpha * 0.2), 2.0)
	if phase == "wax":
		var frame := mini(4, 1 + int(finale_t / 0.4))
		var wax: Texture2D = ci.texture("w2/hainan/firework_wax_%d.png" % frame)
		if wax:
			var sz: Vector2 = wax.get_size() * ci.S
			ci.draw_texture_rect(wax, Rect2(Vector2(180, 200) - sz * 0.5, sz), false)
	if flash > 0:
		ci.draw_rect(Rect2(0, 0, 360, 640), Color(1, 0.9, 0.75, flash * 0.12))
	if phase == "play" and count == 0:
		var a := 0.6 + 0.4 * sin(t * 5.0)
		var p0 := Vector2(180, 200)
		ci.draw_arc(p0, 14 + fmod(t * 20.0, 14.0), 0, TAU, 24, Color(ci.PAPER, a * 0.6), 2.0)
		ci.draw_circle(p0, 8, Color(ci.PAPER, a))
