extends Control
## 图鉴界面：展示已发现/未发现的花，分类筛选

signal closed()

@onready var grid: GridContainer = $Panel/Margin/VBox/Scroll/Grid
@onready var filter_all: Button = $Panel/Margin/VBox/FilterBar/FilterAll
@onready var filter_flower: Button = $Panel/Margin/VBox/FilterBar/FilterFlower
@onready var filter_succulent: Button = $Panel/Margin/VBox/FilterBar/FilterSucculent
@onready var filter_rare: Button = $Panel/Margin/VBox/FilterBar/FilterRare
@onready var count_label: Label = $Panel/Margin/VBox/FilterBar/CountLabel
@onready var close_btn: Button = $Panel/Margin/VBox/FilterBar/CloseButton
@onready var detail_panel: PanelContainer = $Panel/Margin/VBox/DetailPanel
@onready var detail_icon: Label = $Panel/Margin/VBox/DetailPanel/HBox/Icon
@onready var detail_name: Label = $Panel/Margin/VBox/DetailPanel/HBox/VBox/NameLabel
@onready var detail_group: Label = $Panel/Margin/VBox/DetailPanel/HBox/VBox/GroupLabel
@onready var detail_desc: Label = $Panel/Margin/VBox/DetailPanel/HBox/VBox/DescLabel

var _current_filter: String = "all"


func _ready() -> void:
    filter_all.pressed.connect(func(): _set_filter("all"))
    filter_flower.pressed.connect(func(): _set_filter("flower"))
    filter_succulent.pressed.connect(func(): _set_filter("succulent"))
    filter_rare.pressed.connect(func(): _set_filter("rare"))
    close_btn.pressed.connect(func(): closed.emit(); hide())
    detail_panel.visible = false


func popup() -> void:
    _current_filter = "all"
    _refresh()
    show()


func _set_filter(filter: String) -> void:
    _current_filter = filter
    _refresh()


func _refresh() -> void:
    # 清除旧格子
    for child in grid.get_children():
        child.queue_free()

    detail_panel.visible = false

    var all_types: Array = PlantData.get_all_types()
    var filtered: Array = []
    for plant_type in all_types:
        var data: Dictionary = PlantData.get_data(plant_type)
        if data.is_empty():
            continue
        var category: String = data.get("category", "flower")
        if _current_filter == "all" or _current_filter == category:
            filtered.append(plant_type)

    var discovered: int = 0
    for plant_type in filtered:
        var data: Dictionary = PlantData.get_data(plant_type)
        var is_found: bool = GameState.encyclopedia.has(plant_type)
        if is_found:
            discovered += 1

        var btn := Button.new()
        btn.custom_minimum_size = Vector2(64, 64)

        if is_found:
            var name: String = data.get("name", "???")
            var color: Dictionary = data.get("base_color", {})
            var c := Color(color.get("r", 128) / 255.0, color.get("g", 128) / 255.0, color.get("b", 128) / 255.0)
            btn.text = "🌸"
            btn.modulate = c
            btn.tooltip_text = name
            var _type: String = plant_type
            btn.pressed.connect(_show_detail.bind(_type))
        else:
            btn.text = "❓"
            btn.modulate = Color(0.3, 0.3, 0.3, 1.0)
            btn.tooltip_text = "???"
            btn.disabled = true

        grid.add_child(btn)

    var total_in_filter: int = filtered.size()
    count_label.text = "%d/%d" % [discovered, total_in_filter]


func _show_detail(plant_type: String) -> void:
    var data: Dictionary = PlantData.get_data(plant_type)
    if data.is_empty():
        return

    var name: String = data.get("name", "???")
    var group: int = data.get("group", 0)
    var category: String = data.get("category", "flower")
    var color: Dictionary = data.get("base_color", {})
    var c := Color(color.get("r", 128) / 255.0, color.get("g", 128) / 255.0, color.get("b", 128) / 255.0)

    detail_icon.text = "🌸"
    detail_icon.modulate = c
    detail_name.text = name

    var group_name: String = PlantData.GROUP_NAMES.get(group, "未知")
    var discover_method: String = data.get("discover_method", "")
    var method_text: String = _method_description(discover_method)
    detail_group.text = "系: %s | 类: %s" % [group_name, category]
    detail_desc.text = method_text

    detail_panel.visible = true


func _method_description(method: String) -> String:
    match method:
        "initial":
            return "初始种子"
        "mix_color":
            return "同品种混色培育获得"
        "cross_breed":
            return "同系杂交培育获得"
        "gradual":
            return "多步培育发现"
        "expansion_gift":
            return "花圃扩展赠送"
        "rare_mutation":
            return "✨ 稀有变异！极低概率出现"
        _:
            return ""
