extends Control
## 桌面展示：单花瓶 + idle动画 + 插花选择

const IDLE_SCRIPT: GDScript = preload("res://scripts/desktop/idle_animator.gd")
const ARRANGE_SCENE: PackedScene = preload("res://scenes/ui/flower_arrange.tscn")

@onready var vase_area: PanelContainer = $VBox/Center/VaseArea
@onready var flower_icon: Label = $VBox/Center/VaseArea/VBox/FlowerIcon
@onready var flower_name: Label = $VBox/Center/VaseArea/VBox/FlowerName
@onready var empty_hint: Label = $VBox/Center/VaseArea/VBox/EmptyHint
@onready var garden_btn: Button = $VBox/Bar/GardenButton
@onready var breeding_room_btn: Button = $VBox/Bar/BreedingRoomButton

var idle_animator: Node = null
var arrange_popup: Control = null


func _ready() -> void:
	_load_save()
	_connect_signals()
	_setup_vase()

	# 创建插花选择弹窗
	arrange_popup = ARRANGE_SCENE.instantiate()
	add_child(arrange_popup)
	arrange_popup.flower_selected.connect(_on_flower_selected)
	arrange_popup.cancelled.connect(_on_arrange_cancelled)


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


func _setup_vase() -> void:
	# 创建 idle 动画器
	idle_animator = Node.new()
	idle_animator.set_script(IDLE_SCRIPT)
	idle_animator.set_process(false)
	vase_area.add_child(idle_animator)
	_refresh_vase()


func _refresh_vase() -> void:
	var plant: Plant = GameState.get_vase_plant()

	if plant != null:
		flower_icon.visible = true
		flower_name.visible = true
		empty_hint.visible = false
		flower_icon.text = "🌸"
		flower_icon.modulate = plant.get_display_color()
		flower_name.text = plant.display_name

		idle_animator.setup(vase_area, plant.plant_type)
		idle_animator.set_process(true)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.12)
		style.set_corner_radius_all(12)
		style.set_border_width_all(1)
		style.border_color = Color(1, 1, 1, 0.2)
		vase_area.add_theme_stylebox_override("panel", style)
	else:
		flower_icon.visible = false
		flower_name.visible = false
		empty_hint.visible = true

		idle_animator.stop()
		idle_animator.set_process(false)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.06)
		style.set_corner_radius_all(12)
		vase_area.add_theme_stylebox_override("panel", style)


func _on_vase_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		arrange_popup.popup()


func _on_flower_selected(plot_index: int) -> void:
	GameState.arrange_flower(plot_index)


func _on_arrange_cancelled() -> void:
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
