extends SceneTree
## 样板户走查：开真窗口按 plan.json 一步步走（stand / click 真点击 / keys 方向键 / go / shot），在游戏内 13:00 夏晴截图。
## 用法：godot --path godot --resolution 540x960 -s res://ayu_home/v4/tests/claude_yard_probe.gd -- --out=<含 plan.json 的目录> --size=540x960
var h
var out:=""
var W:=Vector2i(1280,800)
func _initialize() -> void:call_deferred("run")
func shot(tag:String) -> void:
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+tag+".png");print("SHOT ",tag," area=",h.area," pos=",h.player.position)
func settle(n:=40) -> void:
	for i in n:await process_frame
	h.transition=false;h.fade.color.a=0
func walk_until(cond:Callable,limit:=900) -> bool:
	for i in limit:
		await process_frame
		if cond.call():return true
	return false
func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):out=a.substr(6)
		if a.begins_with("--size="):var p=a.substr(7).split("x");W=Vector2i(int(p[0]),int(p[1]))
	if not out.ends_with("/"):out+="/"
	DirAccess.make_dir_recursive_absolute(out)
	root.size=W;root.content_scale_size=W
	var boot=load("res://ayu_home/v4/phone_boot.tscn").instantiate();root.add_child(boot)
	for i in 10:await process_frame
	boot.start()
	for i in 1500:
		await process_frame
		h=find_home(root)
		if h!=null and h.bootstrapped:break
	if h==null:print("NO_HOME");quit(1);return
	print("READY area=",h.area)
	h.sound_on=false;h.close_modal();h.set_test_clock(13.0,7,"clear")
	var plan:Array=JSON.parse_string(FileAccess.get_file_as_string(out+"plan.json"))
	for step in plan:
		match str(step.do):
			"stand":
				h.enter_room(str(step.room),false,str(step.get("from","")));await settle(5)
				h.player.position=h.world.nearest(Vector2(step.at[0],step.at[1]));h.player.face=str(step.get("face","up"));h.camera=h.room_camera_target();await settle(30)
			"go":
				h.go(str(step.id));var start:=str(h.area)
				var ok=await walk_until(func():return h.area!=start and not h.transition,int(step.get("limit",1200)))
				await settle(30);print("GO ",step.id," ok=",ok," area=",h.area," pos=",h.player.position," note=",h.note)
			"tap":
				var p:=Vector2(step.at[0],step.at[1]);h.player.route=h.world.path(h.player.position,p);h.final_leg=true
				await walk_until(func():return h.player.route.is_empty(),1200);await settle(20)
				print("TAP area=",h.area," pos=",h.player.position)
			"click":
				var wp:=Vector2(step.at[0],step.at[1]);var sp:Vector2=h.world.get_global_transform_with_canvas()*wp
				for pressed in [true,false]:
					var e:=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.position=sp;e.global_position=sp;Input.parse_input_event(e)
					await process_frame
				var start:=str(h.area)
				await walk_until(func():return (h.player.route.is_empty() and h.pending.is_empty() and not h.transition) or h.area!=start,int(step.get("limit",1500)))
				await settle(30);print("CLICK ",step.at," screen=",sp," area=",h.area," pos=",h.player.position," note=",h.note)
			"keys":
				var dir:=Vector2(step.dir[0],step.dir[1]);var start:=str(h.area)
				for i in int(step.frames):
					var ev:=InputEventKey.new();ev.keycode=KEY_UP if dir.y<0 else (KEY_DOWN if dir.y>0 else (KEY_LEFT if dir.x<0 else KEY_RIGHT));ev.physical_keycode=ev.keycode;ev.pressed=true;Input.parse_input_event(ev)
					await process_frame
					if h.area!=start:break
				var up:=InputEventKey.new();up.keycode=KEY_UP if dir.y<0 else (KEY_DOWN if dir.y>0 else (KEY_LEFT if dir.x<0 else KEY_RIGHT));up.physical_keycode=up.keycode;up.pressed=false;Input.parse_input_event(up)
				await settle(30);print("KEYS ",step.dir," area=",h.area," pos=",h.player.position)
			"shot":await shot(str(step.name))
			"clock":h.set_test_clock(float(step.h),int(step.get("m",7)),"clear")
	print("DONE");quit()
func find_home(n:Node):
	if n.get_script()!=null and n.get_script().resource_path=="res://ayu_home/v4/home.gd":return n
	for c in n.get_children():
		var r=find_home(c)
		if r!=null:return r
	return null
