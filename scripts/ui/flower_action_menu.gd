extends Control
## 开花植物操作菜单：摆到桌面 / 收入仓库 / 培育 / 移除 / 取消

signal send_to_desktop(plot_index: int)
signal store_in_storage(plot_index: int)
signal start_breeding(plot_index: int)
signal remove_plant(plot_index: int)
signal cancelled()

@onready var desktop_btn: Button = $Panel/Margin/VBox/DesktopButton
@onready var storage_btn: Button = $Panel/Margin/VBox/StorageButton
@onready var breed_btn: Button = $Panel/Margin/VBox/BreedButton
@onready var remove_btn: Button = $Panel/Margin/VBox/RemoveButton
@onready var cancel_btn: Button = $Panel/Margin/VBox/CancelButton

var _plot_index: int = -1


func _ready() -> void:
	desktop_btn.pressed.connect(_on_desktop_pressed)
	storage_btn.pressed.connect(_on_storage_pressed)
	breed_btn.pressed.connect(_on_breed_pressed)
	remove_btn.pressed.connect(_on_remove_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)


func popup(plot_index: int, plant_name: String) -> void:
	_plot_index = plot_index
	desktop_btn.text = "🖥 摆到桌面 — %s" % plant_name
	storage_btn.text = "📦 收入仓库 — %s" % plant_name
	breed_btn.text = "🌱 培育 — %s" % plant_name
	remove_btn.text = "🗑 移除"
	show()


func _on_desktop_pressed() -> void:
	send_to_desktop.emit(_plot_index)
	hide()


func _on_storage_pressed() -> void:
	store_in_storage.emit(_plot_index)
	hide()


func _on_breed_pressed() -> void:
	start_breeding.emit(_plot_index)
	hide()


func _on_remove_pressed() -> void:
	remove_plant.emit(_plot_index)
	hide()


func _on_cancel_pressed() -> void:
	cancelled.emit()
	hide()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var panel_rect: Rect2 = $Panel.get_global_rect()
		if not panel_rect.has_point(event.global_position):
			cancelled.emit()
			hide()
			get_viewport().set_input_as_handled()
