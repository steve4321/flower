extends Control
## 开花植物操作菜单：摆到桌面 / 移除 / 取消

signal send_to_desktop(plot_index: int)
signal remove_plant(plot_index: int)
signal cancelled()

@onready var desktop_btn: Button = $Panel/Margin/VBox/DesktopButton
@onready var remove_btn: Button = $Panel/Margin/VBox/RemoveButton
@onready var cancel_btn: Button = $Panel/Margin/VBox/CancelButton

var _plot_index: int = -1


func _ready() -> void:
    desktop_btn.pressed.connect(func(): send_to_desktop.emit(_plot_index); hide())
    remove_btn.pressed.connect(func(): remove_plant.emit(_plot_index); hide())
    cancel_btn.pressed.connect(func(): cancelled.emit(); hide())


func popup(plot_index: int, plant_name: String) -> void:
    _plot_index = plot_index
    desktop_btn.text = "🖥 摆到桌面 — %s" % plant_name
    remove_btn.text = "🗑 移除"
    show()


func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event is InputEventMouseButton and event.pressed:
        # 点击菜单外部关闭
        var panel_rect: Rect2 = $Panel.get_global_rect()
        if not panel_rect.has_point(event.global_position):
            cancelled.emit()
            hide()
