extends SceneTree
class Harness extends "res://hongyuan/player.gd":
	func _save() -> void: pass
var p
var failures := 0
var out := "user://coast-memory"
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: failures += 1
func tick(sec: float) -> void:
	for i in range(roundi(sec / 0.05)): p.runner._process(0.05)
	await process_frame
func tap() -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = p.stage.get_global_transform() * Vector2(180, 616)
		e.pressed = pressed
		root.push_input(e, true)
func shot(name: String) -> Image:
	p.runner.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	check(img.get_size() == Vector2i(360, 640), "360x640 " + name)
	img.save_png(out.path_join(name + ".png"))
	return img
func run() -> void:
	root.size = Vector2i(360, 640)
	root.content_scale_size = Vector2i(360, 640)
	await process_frame
	p = Harness.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(p)
	await process_frame
	p.set_process(false)
	p.shot = {}  # 跳过换场淡出，测试里同步进场
	p._enter_step(p.step_indices["hainan/wanning"])
	var r = p.runner
	r.set_process(false)
	var index := -1
	var has_click_game := false
	for i in range(r.beats.size()):
		if r.beats[i].get("narrate", "") == "A5-2": index = i
		if r.beats[i].get("game", "") == "fireworks": has_click_game = int(r.beats[i].get("count", 5)) <= 3
	check(index >= 0 and has_click_game, "Seaside memory keeps the continuous show and adds a short tap-to-launch moment")
	r.begin(index)
	r.reveal = r.say_text.length()
	check(r.bg.ends_with("bg_wenchang_memory_r2.png") and r.texture(r.bg) != null and r.bg_fit and r.atmosphere == "coast", "New crowd beach is imported and actually selected by the chapter")
	check(r.person_height_at(r.feet.y) > 105 and r.person_height_at(r.feet.y) < 116, "Couple scale matches the foreground spectators")
	await tick(2.2)
	var first := await shot("01-crowd-beach-memory")
	await tick(2.0)
	var second := await shot("02-continuous-fireworks")
	check(first.get_region(Rect2i(0, 110, 360, 230)).get_data() != second.get_region(Rect2i(0, 110, 360, 230)).get_data(), "Fireworks animate visibly without any tap input")
	check(r.mode == "say" and r.bi == index, "Watching does not skip the original narration")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(r.snapshot()))
	var other = r.get_script().new()
	other.setup(r.spec, p.copy, {})
	root.add_child(other)
	other.set_process(false)
	other.begin(saved.beat)
	other.restore(saved)
	check(is_equal_approx(other.atmosphere_elapsed, r.atmosphere_elapsed) and other.bg == r.bg, "Reload resumes the same visual show time and new beach")
	other.free()
	tap()
	check(r.say_who == "toretto" and r.beats[r.bi].say == "A5-3a", "First original seaside dialogue is intact")
	r.reveal = r.say_text.length()
	await tick(2.4)
	await shot("03-couple-under-fireworks")
	tap()
	check(r.say_who == "ayu" and r.beats[r.bi].say == "A5-3b", "Ayu's original answer is intact")
	r.reveal = r.say_text.length()
	await tick(0.3)
	tap()
	check(r.mode == "game" and r.atmosphere == "coast", "Player launches the fireworks while the seaside show keeps playing")
	await tick(3.0)
	check(r.mode == "game", "Fireworks wait for the player instead of advancing on a timer")
	for at in [Vector2(90, 150), Vector2(260, 120), Vector2(180, 220)]:
		r.game.input("down", at)
		await tick(0.3)
	await tick(6.0)
	check(r.mode == "material" and r.material_id == "wax" and r.atmosphere == "", "Three launches end in the wax seal")
	print("FAILURES ", failures)
	p.queue_free()
	await process_frame
	quit(failures)
