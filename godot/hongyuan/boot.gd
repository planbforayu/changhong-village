extends Node

func _ready() -> void:
	var destination := "res://hongyuan/player.tscn"
	var saved := preload("res://hongyuan/checkpoint.gd").read()
	# 网页试玩站打开总是进爱情篇：读档会停在终章二选一，从那里再去村子或婚礼。
	# 村子里没有回爱情篇的入口，直接续进村子会把玩家一直关在村里。
	var web_trial := OS.has_feature("web") and not OS.has_feature("hongyuan_wechat")
	if not web_trial and str(saved.get("worldRoute", "")) in ["wedding", "village"]:
		destination = "res://hongyuan/world_entry.tscn"
	if not ProjectSettings.get_setting("application/hongyuan/enabled", true):
		destination = "res://ayu_home/v4/phone_boot.tscn"
	get_tree().change_scene_to_file.call_deferred(destination)
