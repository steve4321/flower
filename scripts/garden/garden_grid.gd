extends Control
## 花圃网格管理：创建/管理所有格子，处理交互

const PLOT_SCENE := preload("res://scenes/ui/garden_plot.tscn")

@onready var grid_container: GridContainer = $Background/Margin/VBox/GridContainer
@onready var seed_menu: Control = $SeedMenu
@onready var flower_action_menu: Control = $FlowerActionMenu
@onready var info_label: Label = $Background/Margin/VBox/InfoBar/InfoLabel
@onready var encyclopedia_btn: Button = $Background/Margin/VBox/InfoBar/EncyclopediaButton
@onready var desktop_btn: Button = $Background/Margin/VBox/InfoBar/DesktopButton

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
    # 清除旧格子
    for child in grid_container.get_children():
        child.queue_free()
    plot_nodes.clear()

    # 设置网格列数（2列布局）
    grid_container.columns = 2

    # 创建格子
    for i in range(GameState.garden_size):
        var plot: PanelContainer = PLOT_SCENE.instantiate()
        grid_container.add_child(plot)  # 先加入场景树，@onready变量才能初始化
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

    seed_menu.seed_selected.connect(_on_seed_selected)
    seed_menu.cancelled.connect(_on_seed_menu_cancelled)

    flower_action_menu.send_to_desktop.connect(_on_send_to_desktop)
    flower_action_menu.remove_plant.connect(_on_action_remove_plant)
    flower_action_menu.cancelled.connect(_on_action_menu_cancelled)

    encyclopedia_btn.pressed.connect(_on_encyclopedia_pressed)
    desktop_btn.pressed.connect(_on_desktop_btn_pressed)


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
    info_label.text = "已收集: %d/%d | 花圃: %d格 | 种子: %d种" % [collected, total, GameState.garden_size, GameState.seed_inventory.size()]


## === 交互处理 ===

func _on_plot_clicked(index: int) -> void:
    var plant: Plant = GameState.get_plant(index)

    if plant == null:
        # 空格 → 打开种子选择
        _selected_plot = index
        seed_menu.popup_seed_menu()
    elif plant.stage == Plant.Stage.FLOWERING:
        # 开花 → 打开操作菜单（摆到桌面/移除）
        flower_action_menu.popup(index, plant.display_name)
    else:
        # 有植物但未开花 → 浇水（信号回调自动刷新显示）
        GameState.water_plant(index)
        _update_info()


func _input(event: InputEvent) -> void:
    # 任何弹窗打开时忽略右键操作
    if seed_menu.visible or flower_action_menu.visible:
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


func _get_plot_at_position(global_pos: Vector2) -> int:
    for i in range(plot_nodes.size()):
        var rect := plot_nodes[i].get_global_rect()
        if rect.has_point(global_pos):
            return i
    return -1


## === 场景切换 ===

func _on_desktop_btn_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/desktop.tscn")


## === 操作菜单回调 ===

func _on_send_to_desktop(plot_index: int) -> void:
    var plant: Plant = GameState.get_plant(plot_index)
    if plant == null:
        return
    # 找第一个空的桌面槽位
    var slot_index := -1
    for i in range(GameState.desktop_slots.size()):
        if GameState.desktop_slots[i] == null:
            slot_index = i
            break
    if slot_index >= 0:
        GameState.set_desktop_slot(slot_index, plot_index)
        info_label.text = "%s 已摆到桌面 ✅" % plant.display_name
    else:
        # 所有槽位都有花，替换第一个
        GameState.set_desktop_slot(0, plot_index)
        info_label.text = "桌面已满，%s 替换了第1位" % plant.display_name


func _on_action_remove_plant(plot_index: int) -> void:
    GameState.remove_plant(plot_index)
    _refresh_plot(plot_index)
    _update_info()


func _on_action_menu_cancelled() -> void:
    pass  # 菜单已自行关闭


## === 信号回调 ===

func _on_seed_selected(plant_type: String) -> void:
    if _selected_plot >= 0:
        GameState.plant_seed(_selected_plot, plant_type)
        # 信号回调自动刷新格子，这里只更新信息栏
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


func _on_flower_discovered(_plant_type: String) -> void:
    _update_info()


func _on_garden_expanded(new_size: int) -> void:
    _build_grid()


func _on_game_loaded() -> void:
    _build_grid()


func _on_encyclopedia_pressed() -> void:
    # TODO: P4 图鉴界面
    info_label.text = "图鉴功能开发中..."
