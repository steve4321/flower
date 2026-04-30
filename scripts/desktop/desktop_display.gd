extends Control
## 桌面展示：花瓶（可插多朵花） + idle动画 + 插花选择

const IDLE_SCRIPT: GDScript = preload("res://scripts/desktop/idle_animator.gd")
const ARRANGE_SCENE: PackedScene = preload("res://scenes/ui/flower_arrange.tscn")

@onready var vase_area: PanelContainer = $VBox/Center/VaseArea
@onready var flower_container: HFlowContainer = $VBox/Center/VaseArea/VBox/FlowerContainer
@onready var empty_hint: Label = $VBox/Center/VaseArea/VBox/EmptyHint
@onready var garden_btn: Button = $VBox/Bar/GardenButton
@onready var breeding_room_btn: Button = $VBox/Bar/BreedingRoomButton

var arrange_popup: Control = null
var _flower_widgets: Array = []  # [{ "icon": Label, "name": Label, "animator": Node }]


func _ready() -> void:
	_load_save()
	_connect_signals()
	_refresh_vase()

	# 创建插花选择弹窗
	arrange_popup = ARRANGE_SCENE.instantiate()
	add_child(arrange_popup)
	arrange_popup.flower_added.connect(_on_flower_added)
	arrange_popup.done.connect(_on_arrange_done)


func _load_save() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.new_game()


func _connect_signals() -> void:
	garden_btn.pressed.connect(_on_garden_btn_pressed)
	breeding_room_btn.pressed.connect(_on_breeding_room_btn_pressed)
	vase_area.gui_input.connect(_on_vase_input)
	EventBus.desktop_changed.connect(_on_desktop_changed)
	EventBus.game_loaded.connect(_on_game_loaded)


func _refresh_vase() -> void:
	# 清除旧的
	for w in _flower_widgets:
		if w.icon != null and is_instance_valid(w.icon):
			w.icon.get_parent().queue_free()
		if w.animator != null and is_instance_valid(w.animator):
			if w.animator.is_processing():
				w.animator.stop()
	_flower_widgets.clear()

	var plants: Array = GameState.get_vase_plants()

	if plants.is_empty():
		empty_hint.visible = true
		flower_container.visible = false

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.06)
		style.set_corner_radius_all(12)
		vase_area.add_theme_stylebox_override("panel", style)
		return

	empty_hint.visible = false
	flower_container.visible = true

	for plant in plants:
		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon := Label.new()
		icon.text = "🌸"
		icon.modulate = plant.get_display_color()
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 40)
		vbox.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = plant.display_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 10)
		vbox.add_child(name_lbl)

		flower_container.add_child(vbox)

		# idle 动画器
		var animator := Node.new()
		animator.set_script(IDLE_SCRIPT)
		animator.set_process(false)
		vbox.add_child(animator)
		animator.setup(vbox, plant.plant_type)
		animator.set_process(true)

		_flower_widgets.append({ "icon": icon, "name": name_lbl, "animator": animator })

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.10)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(1, 1, 1, 0.15)
	vase_area.add_theme_stylebox_override("panel", style)


func _on_vase_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		arrange_popup.popup()


func _on_flower_added(plot_index: int) -> void:
	GameState.arrange_flower(plot_index)


func _on_arrange_done() -> void:
	# popup 已自己 hide，这里只需刷新显示
	pass


func _on_garden_btn_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/garden.tscn")


func _on_breeding_room_btn_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/breeding_room.tscn")


func _on_desktop_changed() -> void:
	_refresh_vase()


func _on_game_loaded() -> void:
	_refresh_vase()
