extends Control
## 插花选择：列出花圃里所有开花的植物，选一朵插到桌面花瓶

signal flower_selected(plot_index: int)
signal cancelled()

@onready var list_vbox: VBoxContainer = $Panel/Margin/VBox/Scroll/List
@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseButton


func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)


func popup() -> void:
	_build_list()
	show()


func _build_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()

	var has_flowers := false
	for i in range(GameState.garden_plots.size()):
		var plant: Plant = GameState.garden_plots[i]
		if plant == null:
			continue
		if plant.stage != Plant.Stage.FLOWERING:
			continue
		has_flowers = true

		var btn := Button.new()
		btn.text = "🌸 %s  [%s]" % [plant.display_name, plant.breeding_group]
		btn.custom_minimum_size = Vector2(0, 36)
		var idx := i
		btn.pressed.connect(_on_flower_button_pressed.bind(idx))
		list_vbox.add_child(btn)

	if not has_flowers:
		var label := Label.new()
		label.text = "花圃里还没有开花的花，先去浇水吧"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list_vbox.add_child(label)


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
