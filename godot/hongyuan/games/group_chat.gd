extends "res://hongyuan/games/desk_chat.gd"
## 群聊：和窗前微信用同一套对话样式（desk_chat），底图是阿鱼手里的手机。
## 自己发的（阿鱼）靠右、绿色；别人靠左、白色；系统提示是居中的小灰条。
const Desk := preload("res://hongyuan/ui/desk_art.gd")
var backdrop := "round1/people/group_phone_1109_bg.png|round1/people/group_phone_1109.png|round1/people/group_shoulder.png"
var title_key := "A1-G0"
var title_suffix := " · 23"

func start(runner, beat: Dictionary) -> void:
	super.start(runner, beat)
	own_who = "ayu"
	backdrop = str(beat.get("backdrop", backdrop))
	title_key = str(beat.get("title", title_key))
	title_suffix = str(beat.get("titleSuffix", title_suffix))
	r.hint = ""

func _title(ci) -> String:
	return ci.t_(title_key) + title_suffix

func draw(ci) -> void:
	var bg: Texture2D = ci.texture(backdrop)
	if bg:
		Desk.cover(ci, bg, ci.view_rect)
	super.draw(ci)
