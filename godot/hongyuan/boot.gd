extends Control

const Checkpoint := preload("res://hongyuan/checkpoint.gd")
const DeskArt := preload("res://hongyuan/ui/desk_art.gd")
const StoryCaption := preload("res://hongyuan/ui/story_caption.gd")
const FONT := preload("res://hongyuan/fonts/dialogue_font.tres")
const ASSET_ROOT := "res://hongyuan/assets/"

const CANVAS := Vector2(360, 640)
const INK := Color("#281a1a")
const RED := Color("#5e2929")
const PAPER := Color("#fff1d5")
const WHEAT := Color("#f4d495")
const GOLD := Color("#d6a456")

var saved: Dictionary = {}
var show_menu := false
var confirm_restart := false
var canvas := Control.new()
var tex_cache: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.custom_minimum_size = CANVAS
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.draw.connect(_draw_canvas)
	canvas.gui_input.connect(_on_canvas_input)
	add_child(canvas)
	resized.connect(_fit_canvas)

	if not ProjectSettings.get_setting("application/hongyuan/enabled", true):
		get_tree().change_scene_to_file.call_deferred("res://ayu_home/v4/phone_boot.tscn")
		return

	saved = Checkpoint.read()
	var web_trial := OS.has_feature("web") and not OS.has_feature("hongyuan_wechat")
	if web_trial and Checkpoint.has_progress(saved):
		show_menu = true
		_fit_canvas()
		canvas.queue_redraw()
		return
	_launch()


func _launch() -> void:
	get_tree().change_scene_to_file.call_deferred(_story_destination())


func _story_destination() -> String:
	var destination := "res://hongyuan/player.tscn"
	var web_trial := OS.has_feature("web") and not OS.has_feature("hongyuan_wechat")
	if not web_trial and str(saved.get("worldRoute", "")) in ["wedding", "village"]:
		destination = "res://hongyuan/world_entry.tscn"
	return destination


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#241b18"))


func _fit_canvas() -> void:
	var safe := Rect2(Vector2.ZERO, size)
	if OS.has_feature("web"):
		var viewport_js := """[
			innerWidth, innerHeight, ...['top', 'right', 'bottom', 'left'].map(
				edge => parseFloat(getComputedStyle(document.body).getPropertyValue('--hy-' + edge)) || 0
			)
		].join(',')"""
		if OS.has_feature("hongyuan_wechat"):
			viewport_js = """(() => {
				const info = wx.getSystemInfoSync();
				const w = info.windowWidth, h = info.windowHeight;
				const safe = info.safeArea || {top:0, right:w, bottom:h, left:0};
				return [w,h,safe.top,Math.max(0,w-safe.right),Math.max(0,h-safe.bottom),safe.left].join(',');
			})()"""
		var values := str(JavaScriptBridge.eval(viewport_js, true)).split(",")
		if values.size() == 6 and float(values[0]) > 0.0 and float(values[1]) > 0.0:
			var scale_to_view := size / Vector2(float(values[0]), float(values[1]))
			safe.position = Vector2(float(values[5]), float(values[2])) * scale_to_view
			safe.size -= safe.position + Vector2(float(values[3]), float(values[4])) * scale_to_view
	var fit := minf(safe.size.x / CANVAS.x, safe.size.y / CANVAS.y)
	canvas.scale = Vector2.ONE * fit
	canvas.position = safe.position + (safe.size - CANVAS * fit) * 0.5


func _draw_canvas() -> void:
	if not show_menu:
		return
	var view_rect := Rect2(Vector2.ZERO, CANVAS)
	var welcome_bg := _texture("round1/common/welcome_bg.png")
	if welcome_bg:
		DeskArt.cover(canvas, welcome_bg, view_rect)
	var welcome := _texture("round1/common/welcome.png")
	if welcome:
		canvas.draw_texture_rect(welcome, Rect2(42, 166, 276, 386.4), false)
	canvas.draw_rect(view_rect, Color(0, 0, 0, 0.35))

	if confirm_restart:
		var warn := Rect2(24, 168, 312, 108)
		canvas.draw_rect(warn, Color(INK, 0.94))
		canvas.draw_rect(warn, Color(GOLD, 0.6), false, 2.0)
		canvas.draw_multiline_string(
			FONT,
			Vector2(40, warn.position.y + 34),
			StoryCaption.wrap_text("确定要重新开始吗？当前进度将被清除。", 280, 17),
			HORIZONTAL_ALIGNMENT_LEFT,
			280,
			17,
			-1,
			WHEAT
		)
		_pill(_primary_rect(), "确定重新开始", 19, RED, PAPER)
		_pill(_secondary_rect(), "取消", 19, Color(INK, 0.85), PAPER)
	else:
		_pill(_primary_rect(), "继续游戏", 19, RED, PAPER)
		_pill(_secondary_rect(), "重新开始", 19, Color(INK, 0.85), PAPER)


func _primary_rect() -> Rect2:
	return Rect2(48, 532, 264, 44)


func _secondary_rect() -> Rect2:
	return Rect2(48, 532 + 52, 264, 44)


func _on_canvas_input(event: InputEvent) -> void:
	if not show_menu:
		return
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		pressed = event.pressed
		pos = event.position
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pressed = event.pressed
		pos = event.position
	else:
		return
	if not pressed:
		return
	if confirm_restart:
		if _primary_rect().grow(6).has_point(pos):
			Checkpoint.clear_save()
			saved = {}
			confirm_restart = false
			get_tree().change_scene_to_file.call_deferred("res://hongyuan/player.tscn")
		elif _secondary_rect().grow(6).has_point(pos):
			confirm_restart = false
			canvas.queue_redraw()
		return
	if _primary_rect().grow(6).has_point(pos):
		_launch()
	elif _secondary_rect().grow(6).has_point(pos):
		confirm_restart = true
		canvas.queue_redraw()


func _pill(r: Rect2, text: String, font_size: int, fill: Color, fg: Color) -> void:
	canvas.draw_rect(r, fill)
	canvas.draw_rect(r, Color(GOLD, 0.6), false, 2.0)
	var asc := FONT.get_ascent(font_size)
	var desc := FONT.get_descent(font_size)
	canvas.draw_string(
		FONT,
		Vector2(r.position.x, r.position.y + (r.size.y + asc - desc) * 0.5),
		text,
		HORIZONTAL_ALIGNMENT_CENTER,
		r.size.x,
		font_size,
		fg
	)


func _texture(name: String) -> Texture2D:
	if name.is_empty():
		return null
	if not tex_cache.has(name):
		var path := ASSET_ROOT + name
		if not ResourceLoader.exists(path) and not name.begins_with("w2/"):
			path = ASSET_ROOT + "w2/" + name
		tex_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return tex_cache[name]
