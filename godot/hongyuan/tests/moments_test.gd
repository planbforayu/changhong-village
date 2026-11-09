extends SceneTree
## 朋友圈详情页：能滑到底、点「··」弹出赞、点赞后 Toretto 加入点赞栏并结束。
class Harness extends "res://hongyuan/player.gd":
	func _save() -> void: pass
var p
var failures := 0
var out := "user://moments"
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
func shot(name: String) -> void:
	p.runner.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
func run() -> void:
	root.size = Vector2i(360, 640)
	root.content_scale_size = Vector2i(360, 640)
	await process_frame
	p = Harness.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(p)
	await process_frame
	p.set_process(false)
	p.shot = {}
	p._enter_step(p.step_indices["call/night_call"])
	var r = p.runner
	r.set_process(false)
	var index := -1
	for i in range(r.beats.size()):
		if r.beats[i].get("game", "") == "moments": index = i
	check(index >= 0, "Call chapter has the Moments beat")
	r.begin(index)
	await tick(0.5)
	check(r.mode == "game", "Moments page is open")
	await shot("01-top")
	var g = r.game
	g.input("down", Vector2(180, 500))
	for k in range(30):
		g.input("move", Vector2(180, 500 - k * 10))
	g.input("up", Vector2(180, 210))
	await tick(0.3)
	await shot("02-middle")
	g.scroll = g._max_scroll()
	await tick(0.6)
	await shot("03-bottom")
	g.input("tap", g._dots_rect().get_center())
	await tick(0.3)
	check(g.menu, "Tapping ·· opens the like menu")
	await shot("04-menu")
	g.input("tap", g._like_btn().get_center())
	await tick(0.4)
	check(g.phase == "liked", "Tapping 赞 likes the post")
	await shot("05-liked")
	await tick(2.6)
	check(r.mode != "game" or r.bi != index, "Moments finishes after the like")
	print("FAILURES ", failures)
	p.queue_free()
	await process_frame
	quit(failures)
