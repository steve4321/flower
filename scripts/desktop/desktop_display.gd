extends Control
## 桌面展示主场景：3个花位 + idle动画 + 场景切换

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/desktop_slot.tscn")
const IDLE_SCRIPT: GDScript = preload("res://scripts/desktop/idle_animator.gd")
const FLOWER_PICKER_SCENE: PackedScene = preload("res://scenes/ui/flower_picker.tscn")

@onready var slot_container: HBoxContainer = $VBox/Bar/SlotContainer
@onready var garden_btn: Button = $VBox/Bar/GardenButton
@onready var breeding_room_btn: Button = $VBox/Bar/BreedingRoomButton

var slot_nodes: Array[PanelContainer] = []
var idle_nodes: Array[Node] = []
var flower_picker: Control = null
var _picking_slot: int = -1


func _ready() -> void:
	_load_save()
	_connect_signals()
	_build_slots()

	# 创建花选择器
	flower_picker = FLOWER_PICKER_SCENE.instantiate()
	add_child(flower_picker)
	flower_picker.flower_selected.connect(_on_flower_selected_for_desktop)
	flower_picker.cancelled.connect(_on_picker_cancelled)


func _load_save() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.new_game()


func _connect_signals() -> void:
	garden_btn.pressed.connect(_on_garden_btn_pressed)
	breeding_room_btn.pressed.connect(_on_breeding_room_btn_pressed)
	EventBus.desktop_changed.connect(_on_desktop_changed)
	EventBus.game_loaded.connect(_on_game_loaded)


func _build_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	slot_nodes.clear()
	idle_nodes.clear()

	for i in range(GameState.desktop_slots.size()):
		var slot: PanelContainer = SLOT_SCENE.instantiate()
		slot_container.add_child(slot)
		slot.setup(i)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot_nodes.append(slot)

		var animator := Node.new()
		animator.set_script(IDLE_SCRIPT)
		animator.set_process(false)
		slot.add_child(animator)
		idle_nodes.append(animator)

	_refresh_slots()


func _refresh_slots() -> void:
	var desktop_plants: Array = GameState.get_desktop_plants()
	for i in range(slot_nodes.size()):
		var plant: Plant = null
		if i < desktop_plants.size():
			plant = desktop_plants[i]
		if plant != null:
			slot_nodes[i].set_plant(plant)
			idle_nodes[i].setup(slot_nodes[i], plant.plant_type)
			idle_nodes[i].set_process(true)
		else:
			slot_nodes[i].clear_plant()
			idle_nodes[i].stop()
			idle_nodes[i].set_process(false)


func _on_garden_btn_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/garden.tscn")


func _on_breeding_room_btn_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/breeding_room.tscn")


func _on_slot_clicked(slot_index: int) -> void:
	# 点击桌面槽位 → 弹出仓库选花
	_picking_slot = slot_index
	flower_picker.popup([])


func _on_flower_selected_for_desktop(storage_index: int) -> void:
	if _picking_slot >= 0:
		GameState.set_desktop_from_storage(_picking_slot, storage_index)
	_picking_slot = -1


func _on_picker_cancelled() -> void:
	_picking_slot = -1


## === 信号回调 ===

func _on_desktop_changed() -> void:
	_refresh_slots()


func _on_game_loaded() -> void:
	_refresh_slots()
