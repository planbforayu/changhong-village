extends SceneTree
## 终章写名字：键盘拉不起来时可以跳过，用默认名字继续写信。
class Harness extends "res://hongyuan/player.gd":
	func _save() -> void: pass
var p
var failures := 0
var out := "user://name-skip"
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
	p._enter_step(p.step_indices["finale/finale"])
	var r = p.runner
	r.set_process(false)
	var index := -1
	for i in range(r.beats.size()):
		if r.beats[i].get("game", "") == "finale": index = i
	check(index >= 0, "Finale has the letter game")
	r.begin(index)
	await tick(0.5)
	var g = r.game
	for i in range(3):
		g.t = 1.0
		g.input("tap", Vector2(180, 300))
	await tick(0.3)
	check(g.phase == "name", "Reaches the name step")
	await shot("01-name-with-skip")
	g.input("tap", g.SKIP_NAME.get_center())
	await tick(0.3)
	check(g.phase == "write" and g.name == g.SKIP_NAME_AS and g.edit == null, "Skip writes the letter as a default guest name")
	await tick(4.0)
	await shot("02-letter-after-skip")
	print("FAILURES ", failures)
	p.queue_free()
	await process_frame
	quit(failures)
