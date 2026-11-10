extends SceneTree

const Checkpoint := preload("res://hongyuan/checkpoint.gd")
var failures := 0

func _initialize() -> void:
	root.size = Vector2i(360, 640)
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1

func run() -> void:
	check(not Checkpoint.has_progress({}), "empty checkpoint is not progress")
	check(not Checkpoint.has_progress({"version": 1}), "version without step is not progress")
	check(Checkpoint.has_progress({"version": 1, "stepId": "prologue/desk"}), "stepId marks progress")

	change_scene_to_file("res://hongyuan/boot.tscn")
	for i in range(6):
		await process_frame
	var boot := current_scene
	check(boot != null and boot.has_method("_launch"), "boot scene instantiates")
	if boot:
		check(boot.show_menu == false, "desktop boot skips menu without save")
		check(boot.canvas != null, "boot keeps drawable canvas child")

	print("BOOT_MENU_FAILURES ", failures)
	quit(failures)
