extends PanelContainer
## 桌面展示位：显示一朵花 + idle动画

signal slot_clicked(slot_index: int)

@export var slot_index: int = -1

var _plant: Plant = null

@onready var flower_icon: Label = $VBox/FlowerIcon
@onready var flower_name: Label = $VBox/FlowerName
@onready var empty_hint: Label = $VBox/EmptyHint


func _ready() -> void:
    gui_input.connect(_on_gui_input)


func setup(index: int) -> void:
    slot_index = index


func set_plant(plant: Plant) -> void:
    _plant = plant
    _update_display()


func clear_plant() -> void:
    _plant = null
    _update_display()


func get_plant() -> Plant:
    return _plant


func get_plant_type() -> String:
    if _plant != null:
        return _plant.plant_type
    return ""


func _update_display() -> void:
    if _plant == null:
        flower_icon.visible = false
        flower_name.visible = false
        empty_hint.visible = true
        var style := StyleBoxFlat.new()
        style.bg_color = Color(1, 1, 1, 0.08)
        style.set_corner_radius_all(10)
        add_theme_stylebox_override("panel", style)
        return

    flower_icon.visible = true
    flower_name.visible = true
    empty_hint.visible = false
    flower_icon.text = "🌸"
    flower_icon.modulate = _plant.get_display_color()
    flower_name.text = _plant.display_name

    var style := StyleBoxFlat.new()
    style.bg_color = Color(1, 1, 1, 0.12)
    style.set_corner_radius_all(10)
    style.set_border_width_all(1)
    style.border_color = Color(1, 1, 1, 0.2)
    add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        slot_clicked.emit(slot_index)
