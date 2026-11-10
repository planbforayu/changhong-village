extends RefCounted
## 终章：请柬正文 → 写自己的名字（2～12 字）→ 选形象（婚宴的 8 个宾客）→ 装封 → 按住 1 秒盖火漆。

const LOOKS := ["01", "02", "03", "04", "05", "06", "07", "08"]

var r
var phase := "read"
var read_index := 0
var typed := 0.0
var dragging := false
var from := Vector2.ZERO
var open_progress := 0.0
var t := 0.0
var edit: LineEdit
var error := false
const SEND_TIME := 3.3   # 寄信过场：书桌窗口飞出 → 飞过江岸 → 落到收件人桌上
const LETTER := "w2/finale/invite_card.png|w2/finale/letter_closeup.png"
## GPT 重画的邀请函到位后，字写在中间留白处（顶部是插画）
const NEW_CARD := "w2/finale/invite_card.png"
const NEW_CARD_SMALL := "w2/finale/invite_card_small.png"
var error_key := "A7-E1"
const RESERVED_NAMES := ["阿鱼", "toretto", "新郎", "新娘", "主角"]
var look := -1
const SEAL_BAR := Rect2(65, 475, 230, 44)
var hold := 0.0
var holding := false
var name := ""
var tex_cache := {}
var keyboard_callback: JavaScriptObject
var keyboard_open := false


func start(runner, _beat: Dictionary) -> void:
	r = runner


func process(dt: float) -> bool:
	t += dt
	match phase:
		"write":
			typed = minf(float(_letter().length()), typed + dt * 14.0)
			if typed >= _letter().length():
				_set_phase("written")
		"fold":
			if t >= 1.3: _set_phase("seal")
		"seal":
			if holding:
				hold = minf(1.0, hold + dt)
				if hold >= 1.0:
					_set_phase("stamped")
					r.play("pop")
		"stamped":
			if t >= 1.2: _set_phase("ready_send")
		"send":
			if t >= SEND_TIME: _set_phase("receive")
		"opening":
			if t >= 0.8: _set_phase("read_received")
	return phase == "done"

func _set_phase(value: String) -> void:
	phase = value
	t = 0.0
	holding = false
	dragging = false
	r.play("blip")

func _letter() -> String:
	return "亲爱的我的朋友" + name + "：\n" + r.t_("A7-1a") + "\n" + r.t_("A7-1c") + "\n" + r.t_("A7-1e")

func _ok_rect(phase_name := "") -> Rect2:
	if phase_name == "look":
		return Rect2(100, 606, 160, 34)
	return Rect2(100, 560, 160, 48)

const LOOK_PANEL_Y := 50.0
const LOOK_CELL_W := 180.0
const LOOK_CELL_H := 138.0

func _look_rect(i: int) -> Rect2:
	return Rect2((i % 2) * LOOK_CELL_W, LOOK_PANEL_Y + (i / 2) * LOOK_CELL_H, LOOK_CELL_W, LOOK_CELL_H)

func _envelope() -> Rect2:
	# recipient_gate 底图火漆约在 y≈299（360×640 视口），与 overlay 信封对齐
	return Rect2(50, 218, 260, 165)

func input(kind: String, pos: Vector2) -> void:
	match phase:
		"read":
			if kind == "tap" and t > 0.6:
				if read_index < 2:
					read_index += 1
					t = 0.0
				else:
					_set_phase("name")
					_make_edit()
		"name":
			if kind == "tap" and _ok_rect().grow(8).has_point(pos): _submit_name()
			elif kind == "tap" and SKIP_NAME.grow(6).has_point(pos): _skip_name()
		"written":
			if kind == "tap" and _ok_rect().has_point(pos): _set_phase("fold")
		"seal":
			# 按封口，或者按底部的「按住火漆」条，都算按住
			if kind == "down" and (pos.distance_to(_envelope().get_center()) <= 60 or SEAL_BAR.grow(8).has_point(pos)):
				holding = true
			elif kind == "up":
				holding = false
				hold = 0.0
			elif kind == "move" and pos.distance_to(_envelope().get_center()) > 76 and not SEAL_BAR.grow(30).has_point(pos):
				holding = false
				hold = 0.0
		"ready_send":
			if kind == "tap" and _ok_rect().has_point(pos): _set_phase("send")
		"receive":
			# 要亲手撕开（只点不算）。电脑上用鼠标也好拆：信封附近按下往右拖都算，拖过六成松手也拆开
			if kind == "down" and _envelope().grow(60).has_point(pos):
				dragging = true
				from = pos
			elif kind == "move" and dragging:
				open_progress = clampf((pos.x - from.x) / 120.0, 0, 1)
				if open_progress >= 1.0: _set_phase("opening")
			elif kind == "up":
				dragging = false
				if open_progress >= 0.6: _set_phase("opening")
				open_progress = 0.0
		"read_received":
			if kind == "tap" and t > 0.5: _set_phase("look")
		"look":
			if kind == "tap":
				for i in range(LOOKS.size()):
					if _look_rect(i).has_point(pos):
						look = i
						r.play("blip")
				if look >= 0 and _ok_rect("look").has_point(pos): _set_phase("welcome")
		"welcome":
			if kind == "tap" and t > 0.6:
				r.result = {"name": name, "look": LOOKS[look]}
				_set_phase("done")

func restore_checkpoint() -> void:
	# Old sealed saves predate sending/opening: continue with the physical letter.
	if phase == "stamped" and hold >= 1.0:
		t = minf(t, 1.2)
	holding = false
	dragging = false
	open_progress = 0.0
	# 进后台时手指还按着：回来要重新按满一秒
	if phase == "seal": hold = 0.0


func _make_edit() -> void:
	edit = LineEdit.new()
	edit.placeholder_text = "例如：小林"
	edit.max_length = 12
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.position = Vector2(48, 475)
	edit.size = Vector2(264, 40)
	edit.add_theme_font_override("font", r.FONT)
	edit.add_theme_font_size_override("font_size", 18)
	edit.add_theme_color_override("font_color", r.INK)
	edit.add_theme_color_override("font_placeholder_color", Color(r.WOOD, 0.55))
	var box := StyleBoxFlat.new()
	box.bg_color = r.PAPER
	box.border_color = r.WOOD
	box.set_border_width_all(2)
	edit.add_theme_stylebox_override("normal", box)
	edit.add_theme_stylebox_override("focus", box)
	edit.text_submitted.connect(func(_s: String) -> void: _submit_name())
	edit.text_changed.connect(func(_s: String) -> void: error = false)
	r.add_child(edit)
	if OS.has_feature("web") and OS.has_feature("hongyuan_wechat"):
		edit.virtual_keyboard_enabled = false
		edit.gui_input.connect(_wechat_name_input)
	elif OS.has_feature("web") and DisplayServer.is_touchscreen_available():
		# 手机浏览器：键盘必须在手指点下的同一时刻由浏览器自己弹出，Godot 的输入框
		# 晚一帧才处理触摸，安卓会被拦掉。改用浏览器自带的输入对话框，一定弹得出来。
		edit.virtual_keyboard_enabled = false
		edit.placeholder_text = "点这里输入名字"
		edit.gui_input.connect(_web_name_input)
	else:
		edit.grab_focus()


var _last_name_tap := -10000

func _web_name_input(event: InputEvent) -> void:
	# 触摸松开和模拟出来的鼠标松开都收，同一下点按只弹一次框
	var released: bool = event is InputEventScreenTouch and not event.pressed and not event.canceled
	if event is InputEventMouseButton:
		released = event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if not released or keyboard_open or phase != "name" or not is_instance_valid(edit):
		return
	if Time.get_ticks_msec() - _last_name_tap < 500:
		return
	_last_name_tap = Time.get_ticks_msec()
	keyboard_open = true
	var answer = JavaScriptBridge.eval("window.prompt(%s, %s)" % [JSON.stringify("请输入你的名字（2–12 个字）"), JSON.stringify(edit.text)], true)
	keyboard_open = false
	if answer == null or not is_instance_valid(edit):
		return
	edit.text = str(answer).strip_edges().substr(0, edit.max_length)
	error = false


func _wechat_name_input(event: InputEvent) -> void:
	var released: bool = event is InputEventScreenTouch and not event.pressed and not event.canceled
	if event is InputEventMouseButton:
		released = event.button_index == MOUSE_BUTTON_LEFT and not event.pressed
	if not released or keyboard_open or phase != "name":
		return
	var bridge := JavaScriptBridge.get_interface("hongyuanContent")
	if bridge == null:
		edit.placeholder_text = "输入框没连上，请退出小游戏再进"
		return
	keyboard_open = true
	keyboard_callback = JavaScriptBridge.create_callback(func(args: Array) -> void:
		keyboard_open = false
		if phase == "name" and is_instance_valid(edit) and not args.is_empty():
			edit.text = str(args[0])
	)
	bridge.editGuestName(edit.text, edit.max_length, keyboard_callback)


## 手机键盘偶尔拉不起来：允许先跳过，用「来做客的你」当名字，照样能写信、入席
const SKIP_NAME := Rect2(56, 612, 226, 24)
const SKIP_NAME_AS := "来做客的你"
func _skip_name() -> void:
	if is_instance_valid(edit):
		edit.queue_free()
	edit = null
	name = SKIP_NAME_AS
	error = false
	keyboard_open = false
	phase = "write"
	typed = 0.0
	t = 0.0
	r.play("pop")


func _submit_name() -> void:
	var s := edit.text.strip_edges()
	if s.length() < 2 or s.length() > 12:
		error = true
		error_key = "A7-E1"
		r.play("blip")
		return
	# 主角的名字留给主角：婚礼现场服务端也会拒，这里先拦下，免得进场后没有退路
	if s.to_lower().replace(" ", "") in RESERVED_NAMES:
		error = true
		error_key = "A7-E2"
		r.play("blip")
		return
	name = s
	error = false
	edit.queue_free()
	edit = null
	phase = "write"
	typed = 0.0
	t = 0.0
	r.play("pop")


func _guest(i: int) -> Texture2D:
	var id: String = LOOKS[i]
	if not tex_cache.has(id):
		var path := "res://hongyuan/assets/w2/finale/chr_LM-GUEST-07.png" if id == "07" else "res://assets/characters/lm/chr_LM-GUEST-%s.png" % id
		tex_cache[id] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[id]


func draw(ci) -> void:
	var desk = preload("res://hongyuan/ui/desk_art.gd")
	if phase == "welcome":
		# 新欢迎图把两人画在门里，整张铺满，不再叠旧人物
		desk.cover(ci, ci.texture("round1/common/welcome_entrance_r2.png"), r.view_rect)
	elif phase == "send":
		_send_frames(ci)
		return
	elif phase in ["receive", "opening", "read_received"]:
		desk.cover(ci, ci.texture("w2/finale/recipient_gate.png"), r.view_rect)
	elif phase in ["write", "written"]:
		desk.cover(ci, ci.texture(LETTER), r.view_rect)
	else:
		desk.draw(ci, r.materials, r.view_rect, "", t, false, phase in ["write", "written"])
	match phase:
		"read":
			var copy_id: String = ["R1-I02-REUNION", "R1-I02-YOU", "A7-2b"][read_index]
			ci.StoryCaption.draw_caption(ci, ci.t_(copy_id), "ayu", -1, false, desk.head(r.view_rect))
			ci.pill(_ok_rect(), "写下名字" if read_index == 2 else "轻点继续", 18, ci.RED, ci.PAPER)
		"name":
			ci.draw_rect(Rect2(30,432,300,112),Color(ci.PAPER,0.96))
			ci.text_at(Vector2(42,458),ci.t_("A7-I1"),16,ci.INK,276)
			ci.text_at(Vector2(42,533),ci.t_(error_key) if error else ci.t_("A7-I2"),13,ci.WOOD,276)
			ci.pill(_ok_rect(), ci.t_("G-19"), 18, ci.RED, ci.PAPER)
			ci.pill(SKIP_NAME, "键盘没弹出来？点这里先跳过", 13, Color(ci.INK, 0.72), ci.PAPER)
		"write", "written":
			_paper(ci, int(typed))
			if phase == "written":
				ci.pill(_ok_rect(), "装进信封", 18, ci.RED, ci.PAPER)
		"fold":
			_envelope_art(ci, false)
			var k := smoothstep(0, 1, clampf(t / 1.3, 0, 1))
			var page := Rect2(Vector2(70, 130).lerp(Vector2(75, 280), k), Vector2(210, 260).lerp(Vector2(210, 95), k))
			var small: Texture2D = ci.texture(NEW_CARD_SMALL)
			if small: ci.draw_texture_rect(small, page, false)
			else: desk.paper_art(ci, page)
			ci.draw_set_transform(page.position,0,page.size/Vector2(210,260))
			var row := 0
			var top := 112 if small else 30
			for line in _letter_lines(ci,_letter(),11 if small else 13,174):
				ci.draw_string(ci.FONT,Vector2(18,top+row*(15 if small else 18)),line,HORIZONTAL_ALIGNMENT_LEFT,174,11 if small else 13,ci.INK)
				row += 1
			ci.draw_set_transform(Vector2.ZERO)
		"seal", "stamped", "ready_send", "send", "receive", "opening":
			if phase == "send":
				ci.draw_set_transform(Vector2(0, -700 * smoothstep(0, 1, clampf(t / 1.8, 0, 1))))
			_envelope_art(ci, phase != "seal" or hold > 0.0)
			ci.draw_set_transform(Vector2.ZERO)
			var c := _envelope().get_center()
			if phase == "seal":
				var pulse := 0.5 + 0.5 * sin(t * 5.0)
				ci.draw_arc(c, 44 + 4 * pulse, 0, TAU, 40, Color(1, 0.88, 0.5, 0.4 + 0.4 * pulse), 2)
				ci.draw_arc(c, 38, -PI / 2, -PI / 2 + TAU * maxf(0.02, hold), 40, ci.GOLD, 4)
				ci.pill(SEAL_BAR, "按住火漆一秒", 18, ci.RED, ci.PAPER)
				if hold > 0: ci.draw_rect(Rect2(SEAL_BAR.position + Vector2(8, SEAL_BAR.size.y - 6), Vector2((SEAL_BAR.size.x - 16) * hold, 3)), ci.GOLD)
			elif phase == "ready_send":
				ci.pill(_ok_rect(), "寄出邀请函", 18, ci.RED, ci.PAPER)
			elif phase == "receive":
				ci.StoryCaption.draw_caption(ci, "你收到了一封邀请函", "narrator")
				ci.draw_line(Vector2(76, 238), Vector2(76 + 208 * open_progress, 238), ci.GOLD, 4)
				ci.pill(Rect2(48, 475, 264, 44), "按住信封，向右拖动拆开", 16, ci.RED, ci.PAPER)
			elif phase == "opening":
				var k := clampf(t / 0.8, 0, 1)
				var open_art: Texture2D = ci.texture("round1/finale/mail_02_open.png" if k < 0.5 else "round1/finale/mail_03_pull.png")
				if open_art: ci.draw_texture_rect_region(open_art, Rect2(50, 182, 260, 298), Rect2(27, 5, 306, 351))
		"read_received":
			_paper(ci, _letter().length())
			ci.pill(_ok_rect(), "收下这份邀请", 18, ci.RED, ci.PAPER)
		"look":
			ci.text_at(Vector2(30, 22), ci.t_("G-CHOOSE-LOOK"), 18, ci.PAPER, 300)
			var panel: Texture2D = ci.texture("round1/people/choose_look_panel.png")
			if panel:
				# Panel 720×1100 → 360×550 at 0.5×
				ci.draw_texture_rect(panel, Rect2(0, LOOK_PANEL_Y, 360, 550), false)
				var hi: Texture2D = ci.texture("round1/people/choose_look_highlight.png")
				if hi and look >= 0:
					var rr := _look_rect(look)
					ci.draw_texture_rect(hi, Rect2(rr.position + Vector2(2, 2), rr.size - Vector2(4, 4)), false)
			else:
				for i in range(LOOKS.size()):
					var rr := _look_rect(i)
					ci.draw_rect(rr, ci.PAPER if i != look else Color("#ffe6a8"))
					ci.draw_rect(rr, ci.GOLD if i == look else ci.WOOD, false, 3 if i == look else 2)
					var guest := _guest(i)
					if guest: ci.draw_texture_rect_region(guest, Rect2(rr.position + Vector2(1, 0), Vector2(64, 84)), Rect2(0, 0, 64, 84))
			if look >= 0: ci.pill(_ok_rect("look"), ci.t_("G-19"), 16, ci.RED, ci.PAPER)
		"welcome":
			ci.StoryCaption.draw_caption(ci, ci.t_("A7-2c"), "ayu", -1, true, Vector2(166, 318))
			ci.pill(_ok_rect(), "去赴约", 18, ci.RED, ci.PAPER)

func _letter_lines(ci, text: String, font_size := 20, width := 205.0) -> Array[String]:
	var result: Array[String] = []
	for paragraph in text.split("\n"):
		var line := ""
		for character in paragraph:
			# 句号逗号等不单独占行首（悬挂在上一行末尾）
			if character not in "，。！？、；：）」』…" and ci.FONT.get_string_size(line + character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width:
				result.append(line)
				line = ""
			line += character
		result.append(line)
	return result

func _paper(ci, length: int) -> void:
	var desk = preload("res://hongyuan/ui/desk_art.gd")
	# 正面信纸特写占满屏幕，字一行一行写上去，手机上也看得清
	if phase == "read_received":
		desk.cover(ci, ci.texture(LETTER), r.view_rect)
	var fancy: bool = ci.texture(NEW_CARD) != null
	var fs := 15 if fancy else 18
	var width := 220.0 if fancy else 248.0
	var origin := Vector2(72, 304) if fancy else Vector2(56, 120)
	var step := 23.0 if fancy else 30.0
	var row := 0
	for line in _letter_lines(ci, _letter().substr(0,length),fs,width):
		ci.draw_string(ci.FONT,origin + Vector2(0, row*step),line,HORIZONTAL_ALIGNMENT_LEFT,width,fs,ci.INK)
		row += 1

func _envelope_art(ci, sealed: bool) -> void:
	var rect := _envelope()
	var art: Texture2D = ci.texture("round1/finale/mail_01_closed.png")
	if art:
		ci.draw_texture_rect_region(art, rect, Rect2(27, 137, 306, 219))
	ci.text_at(rect.position + Vector2(15, 142), name, 18, ci.INK, 230)
	if sealed:
		var file := "round1/finale/wax_03_seal.png"
		if phase == "seal": file = "round1/finale/wax_01_melt.png" if hold < 0.45 else "round1/finale/wax_02_press.png"
		var wax: Texture2D = ci.texture(file)
		if wax:
			ci.draw_texture_rect(wax, Rect2(rect.get_center() - Vector2(26,26), Vector2(52,52)), false)
		if phase == "seal" and hold >= 0.45:
			var stamp: Texture2D = ci.texture("round1/desk_r3/object_stamp.png")
			var lift := 9.0 * (1.0 - clampf((hold - 0.45) / 0.3, 0, 1))
			if stamp: ci.draw_texture_rect(stamp, Rect2(rect.get_center() - Vector2(25, 48 + lift), Vector2(50,50)), false)


## 寄信过场：三张图依次交叉淡入，最后一帧落到收件人桌上
func _send_frames(ci) -> void:
	var span := SEND_TIME / 3.0
	var i := mini(2, int(t / span))
	_cover_alpha(ci, "w2/finale/send_transition_%d.png" % (i + 1), 1.0)
	var k := clampf((t - i * span) / 0.4, 0, 1)
	if i > 0 and k < 1.0:
		_cover_alpha(ci, "w2/finale/send_transition_%d.png" % i, 1.0 - k)

func _cover_alpha(ci, file: String, alpha: float) -> void:
	var tex: Texture2D = ci.texture(file)
	if not tex: return
	var area: Rect2 = r.view_rect
	var scale := maxf(area.size.x / tex.get_width(), area.size.y / tex.get_height())
	var size := tex.get_size() * scale
	var rect := Rect2(area.get_center() - size * 0.5, size)
	ci.draw_texture_rect_region(tex, area, Rect2((area.position - rect.position) / scale, area.size / scale), Color(1, 1, 1, alpha))
