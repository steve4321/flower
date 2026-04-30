extends Control
## 花圃网格管理：创建/管理所有格子，处理交互

const PLOT_SCENE := preload("res://scenes/ui/garden_plot.tscn")

@onready var grid_container: GridContainer = $Background/Margin/VBox/GridContainer
@onready var seed_menu: Control = $SeedMenu
@onready var flower_action_menu: Control = $FlowerActionMenu
@onready var encyclopedia: Control = $Encyclopedia
@onready var info_label: Label = $Background/Margin/VBox/InfoBar/InfoLabel
@onready var encyclopedia_btn: Button = $Background/Margin/VBox/InfoBar/EncyclopediaButton
@onready var desktop_btn: Button = $Background/Margin/VBox/InfoBar/DesktopButton
@onready var breeding_room_btn: Button = $Background/Margin/VBox/InfoBar/BreedingRoomButton

var plot_nodes: Array[PanelContainer] = []
var _selected_plot: int = -1


func _ready() -> void:
	_load_save()
	_connect_signals()
	_build_grid()


func _load_save() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.new_game()


func _build_grid() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	plot_nodes.clear()

	grid_container.columns = 2

	for i in range(GameState.garden_size):
		var plot: PanelContainer = PLOT_SCENE.instantiate()
		grid_container.add_child(plot)
		plot.setup(i)
		plot.plot_clicked.connect(_on_plot_clicked)
		plot_nodes.append(plot)

	_refresh_all_plots()
	_update_info()


func _connect_signals() -> void:
	EventBus.plant_watered.connect(_on_plant_watered)
	EventBus.plant_planted.connect(_on_plant_planted)
	EventBus.plant_removed.connect(_on_plant_removed)
	EventBus.stage_advanced.connect(_on_stage_advanced)
	EventBus.flower_discovered.connect(_on_flower_discovered)
	EventBus.garden_expanded.connect(_on_garden_expanded)
	EventBus.game_loaded.connect(_on_game_loaded)
	EventBus.flower_stored.connect(_on_flower_stored)

	seed_menu.seed_selected.connect(_on_seed_selected)
	seed_menu.cancelled.connect(_on_seed_menu_cancelled)

	flower_action_menu.send_to_desktop.connect(_on_send_to_desktop)
	flower_action_menu.store_in_storage.connect(_on_store_in_storage)
	flower_action_menu.remove_plant.connect(_on_action_remove_plant)
	flower_action_menu.cancelled.connect(_on_action_menu_cancelled)

	encyclopedia.closed.connect(_on_encyclopedia_closed)

	encyclopedia_btn.pressed.connect(_on_encyclopedia_pressed)
	desktop_btn.pressed.connect(_on_desktop_btn_pressed)
	breeding_room_btn.pressed.connect(_on_breeding_room_pressed)


func _refresh_all_plots() -> void:
	for i in range(plot_nodes.size()):
		if i < GameState.garden_plots.size():
			plot_nodes[i].set_plant(GameState.garden_plots[i])
		else:
			plot_nodes[i].clear_plant()


func _refresh_plot(index: int) -> void:
	if index >= 0 and index < plot_nodes.size() and index < GameState.garden_plots.size():
		plot_nodes[index].set_plant(GameState.garden_plots[index])


func _update_info() -> void:
	var collected := GameState.encyclopedia.size()
	var total := PlantData.PLANT_DATABASE.size()
	var storage_count := GameState.flower_storage.size()
	info_label.text = "已收集: %d/%d | 花圃: %d格 | 仓库: %d朵 | 种子: %d种" % [collected, total, GameState.garden_size, storage_count, GameState.seed_inventory.size()]


## === 交互处理 ===

func _on_plot_clicked(index: int) -> void:
	var plant: Plant = GameState.get_plant(index)

	if plant == null:
		_selected_plot = index
		seed_menu.popup_seed_menu()
	elif plant.stage == Plant.Stage.FLOWERING:
		flower_action_menu.popup(index, plant.display_name)
	else:
		GameState.water_plant(index)
		_update_info()


func _input(event: InputEvent) -> void:
	var any_menu_open := (seed_menu != null and seed_menu.visible) \
		or (flower_action_menu != null and flower_action_menu.visible) \
		or (encyclopedia != null and encyclopedia.visible)
	if any_menu_open:
		return

	# 右键移除植物
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var clicked_plot := _get_plot_at_position(event.global_position)
		if clicked_plot >= 0:
			var plant: Plant = GameState.get_plant(clicked_plot)
			if plant != null:
				GameState.remove_plant(clicked_plot)
				_refresh_plot(clicked_plot)
				_update_info()
		get_viewport().set_input_as_handled()

	# ESC关闭（无操作，仅拦截）
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()


func _get_plot_at_position(global_pos: Vector2) -> int:
	for i in range(plot_nodes.size()):
		var rect := plot_nodes[i].get_global_rect()
		if rect.has_point(global_pos):
			return i
	return -1


## === 场景切换 ===

func _on_desktop_btn_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/desktop.tscn")


func _on_breeding_room_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/breeding_room.tscn")


## === 操作菜单回调 ===

func _on_send_to_desktop(plot_index: int) -> void:
	var plant: Plant = GameState.get_plant(plot_index)
	if plant == null:
		return
	var slot_index := -1
	for i in range(GameState.desktop_slots.size()):
		if GameState.desktop_slots[i] == null:
			slot_index = i
			break
	if slot_index >= 0:
		GameState.set_desktop_slot(slot_index, plot_index)
		info_label.text = "%s 已摆到桌面 ✅" % plant.display_name
	else:
		GameState.set_desktop_slot(0, plot_index)
		info_label.text = "桌面已满，%s 替换了第1位" % plant.display_name


func _on_store_in_storage(plot_index: int) -> void:
	var plant: Plant = GameState.get_plant(plot_index)
	if plant == null:
		return
	var plant_name: String = plant.display_name
	GameState.store_flower_from_garden(plot_index)
	_refresh_plot(plot_index)
	info_label.text = "📦 %s 已收入仓库" % plant_name
	_update_info()


func _on_action_remove_plant(plot_index: int) -> void:
	GameState.remove_plant(plot_index)
	_refresh_plot(plot_index)
	_update_info()


func _on_action_menu_cancelled() -> void:
	pass


## === 信号回调 ===

func _on_seed_selected(plant_type: String) -> void:
	if _selected_plot >= 0:
		GameState.plant_seed(_selected_plot, plant_type)
		_update_info()
		_selected_plot = -1


func _on_seed_menu_cancelled() -> void:
	_selected_plot = -1


func _on_plant_watered(plot_index: int) -> void:
	_refresh_plot(plot_index)


func _on_plant_planted(plot_index: int, _plant_type: String) -> void:
	_refresh_plot(plot_index)


func _on_plant_removed(plot_index: int) -> void:
	_refresh_plot(plot_index)


func _on_stage_advanced(plot_index: int, _new_stage: int) -> void:
	_refresh_plot(plot_index)
	_update_info()


func _on_flower_discovered(plant_type: String) -> void:
	var data: Dictionary = PlantData.get_data(plant_type)
	var plant_name: String = data.get("name", plant_type)
	info_label.text = "🎉 新发现：%s！已加入种子库和图鉴" % plant_name
	_update_info()


func _on_flower_stored(_plot_index: int) -> void:
	_refresh_all_plots()
	_update_info()


func _on_garden_expanded(new_size: int) -> void:
	_build_grid()


func _on_game_loaded() -> void:
	_build_grid()


func _on_encyclopedia_pressed() -> void:
	encyclopedia.popup()


func _on_encyclopedia_closed() -> void:
	_update_info()
