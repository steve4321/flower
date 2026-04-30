extends Control
## 花仓库选择器：从仓库中选一朵花

signal flower_selected(storage_index: int)
signal cancelled()

@onready var list_vbox: VBoxContainer = $Panel/Margin/VBox/Scroll/List
@onready var title_label: Label = $Panel/Margin/VBox/Header/Title
@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseButton

var _disabled_indices: Array[int] = []
var _buttons: Array[Button] = []


func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)


## disabled_indices: 不允许选中的仓库索引（已放入另一个槽位的）
func popup(disabled_indices: Array[int] = []) -> void:
	_disabled_indices = disabled_indices
	_build_list()
	show()


func _build_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()
	_buttons.clear()

	if GameState.flower_storage.is_empty():
		var label := Label.new()
		label.text = "仓库是空的，先把花圃里的花收入仓库吧"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list_vbox.add_child(label)
		return

	for i in range(GameState.flower_storage.size()):
		var plant: Plant = GameState.flower_storage[i]
		var btn := Button.new()
		var display_color: Color = plant.get_display_color()
		var color_hex: String = display_color.to_html(false)
		btn.text = "🌸 %s  [%s]" % [plant.display_name, plant.breeding_group]
		btn.custom_minimum_size = Vector2(0, 36)

		if i in _disabled_indices:
			btn.disabled = true
			btn.text += " (已选)"

		var idx := i
		btn.pressed.connect(_on_flower_button_pressed.bind(idx))
		list_vbox.add_child(btn)
		_buttons.append(btn)


func _on_flower_button_pressed(index: int) -> void:
	flower_selected.emit(index)
	hide()


func _on_close_pressed() -> void:
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
