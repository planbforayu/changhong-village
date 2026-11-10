extends Control

## 启动路由 + 网页版「继续游戏 / 重新开始」菜单。
## 微信版：直接走原有逻辑，不显示菜单。
## 浏览器版：
##   - 存档里有 stepId（即玩过至少一步）→ 显示菜单
##   - 否则直接进爱情篇

const CANVAS := Vector2(360, 640)
const FONT := preload("res://hongyuan/fonts/dialogue_font.tres")
const DeskArt := preload("res://hongyuan/ui/desk_art.gd")
const Checkpoint := preload("res://hongyuan/checkpoint.gd")

const INK  := Color("#281a1a")
const RED  := Color("#5e2929")
const PAPER := Color("#fff1d5")
const WHEAT := Color("#f4d495")
const GOLD  := Color("#d6a456")

# "menu" | "confirm" | "gone"
var _state := "gone"
var _bg: Texture2D
var _logo: Texture2D

# ---- 按钮布局常量 ----
const BTN_CONTINUE := Rect2(48, 490, 264, 52)
const BTN_RESTART  := Rect2(48, 556, 264, 42)
const DLG_PANEL    := Rect2(28, 230, 304, 155)
const BTN_CONFIRM  := Rect2(44, 330, 120, 44)
const BTN_CANCEL   := Rect2(196, 330, 120, 44)

func _ready() -> void:
	size = CANVAS
	mouse_filter = MOUSE_FILTER_STOP

	var saved := Checkpoint.read()
	var web_trial := OS.has_feature("web") and not OS.has_feature("hongyuan_wechat")

	if web_trial and _has_progress(saved):
		_bg   = load("res://hongyuan/assets/round1/common/welcome_bg.png")
		_logo = load("res://hongyuan/assets/round1/common/welcome.png")
		_state = "menu"
		queue_redraw()
		return

	# 非菜单路径：复用 #46 逻辑
	var destination := "res://hongyuan/player.tscn"
	if not web_trial and str(saved.get("worldRoute", "")) in ["wedding", "village"]:
		destination = "res://hongyuan/world_entry.tscn"
	if not ProjectSettings.get_setting("application/hongyuan/enabled", true):
		destination = "res://ayu_home/v4/phone_boot.tscn"
	get_tree().change_scene_to_file.call_deferred(destination)

## 判断存档里有没有实际游戏进度（玩过至少一步才有 stepId）
static func _has_progress(s: Dictionary) -> bool:
	return s.get("version") == 1 and s.has("stepId")

# ---- 绘制 ----

func _draw() -> void:
	if _state == "gone":
		return

	# 背景图铺满
	draw_rect(Rect2(Vector2.ZERO, CANVAS), INK)
	if _bg:
		DeskArt.cover(self, _bg, Rect2(Vector2.ZERO, CANVAS))
	if _logo:
		draw_texture_rect(_logo, Rect2(42, 166, 276, 386.4), false)

	# 半透明遮罩让按钮更易读
	draw_rect(Rect2(Vector2.ZERO, CANVAS), Color(0, 0, 0, 0.35))

	if _state == "menu":
		_pill(BTN_CONTINUE, "继续游戏", 20, RED, PAPER)
		_pill(BTN_RESTART,  "重新开始", 16, Color(WHEAT, 0.88), Color(INK, 0.82))

	elif _state == "confirm":
		# 确认弹窗
		draw_rect(DLG_PANEL, Color(PAPER, 0.96))
		draw_rect(DLG_PANEL, Color(INK, 0.9), false, 2.0)
		draw_multiline_string(FONT,
			Vector2(44, DLG_PANEL.position.y + 50),
			"确定要清除全部存档\n并重新开始吗？",
			HORIZONTAL_ALIGNMENT_CENTER, 272, 16, -1, INK)
		_pill(BTN_CONFIRM, "确认清档", 15, RED, PAPER)
		_pill(BTN_CANCEL,  "取消",     15, Color(WHEAT, 0.9), Color(INK, 0.9))

# ---- 输入 ----

func _input(event: InputEvent) -> void:
	if _state == "gone":
		return
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		pressed = event.pressed
	elif event is InputEventScreenTouch:
		pos = event.position
		pressed = event.pressed
	if not pressed:
		return
	accept_event()
	_handle_tap(pos)

func _handle_tap(pos: Vector2) -> void:
	if _state == "menu":
		if BTN_CONTINUE.grow(6).has_point(pos):
			_go("res://hongyuan/player.tscn")
		elif BTN_RESTART.grow(6).has_point(pos):
			_state = "confirm"
			queue_redraw()
	elif _state == "confirm":
		if BTN_CONFIRM.grow(6).has_point(pos):
			Checkpoint.clear()
			_go("res://hongyuan/player.tscn")
		elif BTN_CANCEL.grow(6).has_point(pos):
			_state = "menu"
			queue_redraw()

func _go(destination: String) -> void:
	_state = "gone"
	get_tree().change_scene_to_file.call_deferred(destination)

# ---- 工具 ----

func _pill(r: Rect2, text: String, font_size: int, fill: Color, fg: Color) -> void:
	draw_rect(r, fill)
	draw_rect(r, Color(INK, 0.9), false, 2.0)
	var asc  := FONT.get_ascent(font_size)
	var desc := FONT.get_descent(font_size)
	draw_string(FONT,
		Vector2(r.position.x, r.position.y + (r.size.y + asc - desc) * 0.5),
		text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, font_size, fg)
