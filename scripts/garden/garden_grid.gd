extends Control
## 花圃网格管理：创建/管理所有格子，处理交互

enum Mode { NORMAL, BREEDING_SELECT }

const PLOT_SCENE := preload("res://scenes/ui/garden_plot.tscn")

@onready var grid_container: GridContainer = $Background/Margin/VBox/GridContainer
@onready var seed_menu: Control = $SeedMenu
@onready var flower_action_menu: Control = $FlowerActionMenu
@onready var info_label: Label = $Background/Margin/VBox/InfoBar/InfoLabel
@onready var encyclopedia_btn: Button = $Background/Margin/VBox/InfoBar/EncyclopediaButton
@onready var desktop_btn: Button = $Background/Margin/VBox/InfoBar/DesktopButton

var plot_nodes: Array[PanelContainer] = []
var _selected_plot: int = -1
var _mode: Mode = Mode.NORMAL
var _breeding_parent_a: int = -1


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

    seed_menu.seed_selected.connect(_on_seed_selected)
    seed_menu.cancelled.connect(_on_seed_menu_cancelled)

    flower_action_menu.send_to_desktop.connect(_on_send_to_desktop)
    flower_action_menu.start_breeding.connect(_on_start_breeding)
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
    _update_breeding_highlights()


func _refresh_plot(index: int) -> void:
    if index >= 0 and index < plot_nodes.size() and index < GameState.garden_plots.size():
        plot_nodes[index].set_plant(GameState.garden_plots[index])


func _update_info() -> void:
    var collected := GameState.encyclopedia.size()
    var total := PlantData.PLANT_DATABASE.size()
    info_label.text = "已收集: %d/%d | 花圃: %d格 | 种子: %d种" % [collected, total, GameState.garden_size, GameState.seed_inventory.size()]


## === 培育高亮 ===

func _update_breeding_highlights() -> void:
    for i in range(plot_nodes.size()):
        if _mode == Mode.BREEDING_SELECT:
            var plant: Plant = GameState.get_plant(i)
            var eligible := plant != null and plant.stage == Plant.Stage.FLOWERING and i != _breeding_parent_a
            plot_nodes[i].set_highlight(eligible)
        else:
            plot_nodes[i].set_highlight(false)


func _enter_breeding_mode(parent_a: int) -> void:
    _mode = Mode.BREEDING_SELECT
    _breeding_parent_a = parent_a
    var parent: Plant = GameState.get_plant(parent_a)
    info_label.text = "🌱 培育模式：选择第二朵花与 %s 配对 | 右键取消" % (parent.display_name if parent else "???")
    _update_breeding_highlights()


func _exit_breeding_mode() -> void:
    _mode = Mode.NORMAL
    _breeding_parent_a = -1
    _update_breeding_highlights()
    _update_info()


## === 交互处理 ===

func _on_plot_clicked(index: int) -> void:
    var plant: Plant = GameState.get_plant(index)

    match _mode:
        Mode.BREEDING_SELECT:
            _handle_breeding_click(index, plant)
        Mode.NORMAL:
            _handle_normal_click(index, plant)


func _handle_normal_click(index: int, plant: Plant) -> void:
    if plant == null:
        # 空格 → 打开种子选择
        _selected_plot = index
        seed_menu.popup_seed_menu()
    elif plant.stage == Plant.Stage.FLOWERING:
        # 开花 → 打开操作菜单
        flower_action_menu.popup(index, plant.display_name)
    else:
        # 有植物但未开花 → 浇水
        GameState.water_plant(index)
        _update_info()


func _handle_breeding_click(index: int, plant: Plant) -> void:
    if plant == null or plant.stage != Plant.Stage.FLOWERING or index == _breeding_parent_a:
        info_label.text = "⚠️ 请选择另一朵已开花的花"
        return

    # 检查培育可行性
    var parent_a: Plant = GameState.get_plant(_breeding_parent_a)
    if parent_a == null:
        info_label.text = "⚠️ 亲本已不存在"
        _exit_breeding_mode()
        return

    if not GeneSystem.can_breed_across_groups(
        PlantData.get_group(parent_a.plant_type),
        PlantData.get_group(plant.plant_type)):
        info_label.text = "⚠️ 花卉和多肉/仙人掌无法培育"
        _exit_breeding_mode()
        return

    # 找空格放芽苗
    var target_plot := _find_empty_plot()
    if target_plot < 0:
        info_label.text = "⚠️ 没有空格位了，先移除一株植物"
        _exit_breeding_mode()
        return

    # 执行培育
    var child: Plant = GameState.breed_plants(_breeding_parent_a, index, target_plot)
    if child == null:
        info_label.text = "⚠️ 培育失败"
        _exit_breeding_mode()
        return

    var result_type := _get_breed_result_description(child)
    info_label.text = "🌱 培育成功！新芽苗出现在第%d格 — %s" % [target_plot + 1, result_type]
    _exit_breeding_mode()


func _get_breed_result_description(plant: Plant) -> String:
    if plant.is_rare:
        return "✨ 稀有花！"
    if plant.is_breeding_sprout:
        return "浇满水开花后揭晓颜色"
    return plant.display_name


func _find_empty_plot() -> int:
    for i in range(GameState.garden_plots.size()):
        if GameState.garden_plots[i] == null:
            return i
    return -1


func _input(event: InputEvent) -> void:
    # 任何弹窗打开时忽略右键操作
    if (seed_menu != null and seed_menu.visible) or (flower_action_menu != null and flower_action_menu.visible):
        return

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
        if _mode == Mode.BREEDING_SELECT:
            _exit_breeding_mode()
            get_viewport().set_input_as_handled()
            return
        # 右键移除植物
        var clicked_plot := _get_plot_at_position(event.global_position)
        if clicked_plot >= 0:
            var plant: Plant = GameState.get_plant(clicked_plot)
            if plant != null:
                GameState.remove_plant(clicked_plot)
                _refresh_plot(clicked_plot)
                _update_info()

    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if _mode == Mode.BREEDING_SELECT:
            _exit_breeding_mode()
            get_viewport().set_input_as_handled()


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


func _on_start_breeding(plot_index: int) -> void:
    _enter_breeding_mode(plot_index)


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


func _on_garden_expanded(new_size: int) -> void:
    _build_grid()


func _on_game_loaded() -> void:
    _build_grid()


func _on_encyclopedia_pressed() -> void:
    info_label.text = "图鉴功能开发中..."
