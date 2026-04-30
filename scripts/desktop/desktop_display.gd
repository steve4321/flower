extends Control
## 桌面展示主场景

func _ready() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.new_game()
	_init_desktop_display()


func _init_desktop_display() -> void:
	# TODO: P2 实现 — 加载桌面展示位、idle动画
	pass
