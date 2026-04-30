extends PanelContainer
## 单个花盆格子：显示植物、处理点击交互

signal plot_clicked(plot_index: int)

@export var plot_index: int = -1

var _current_plant: Plant = null
var _highlighted: bool = false

@onready var plant_icon: Label = $VBox/PlantIcon
@onready var stage_label: Label = $VBox/StageLabel
@onready var name_label: Label = $VBox/NameLabel
@onready var water_bar: ProgressBar = $VBox/WaterBar
@onready var water_label: Label = $VBox/WaterBar/WaterLabel
@onready var empty_label: Label = $VBox/EmptyLabel


func _ready() -> void:
	gui_input.connect(_on_gui_input)


func setup(index: int) -> void:
	plot_index = index
	_update_display()


func get_plant() -> Plant:
	return _current_plant


func set_plant(plant: Plant) -> void:
	_current_plant = plant
	_update_display()


func clear_plant() -> void:
	_current_plant = null
	_update_display()


func update_display() -> void:
	_update_display()


func set_highlight(enabled: bool) -> void:
	_highlighted = enabled
	_update_display()


func _update_display() -> void:
	if _current_plant == null:
		empty_label.visible = true
		plant_icon.visible = false
		stage_label.visible = false
		name_label.visible = false
		water_bar.visible = false
		water_label.visible = false
		# 空格显示
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.35, 0.25, 0.18, 0.8)
		style.set_corner_radius_all(8)
		style.border_color = Color(0.45, 0.35, 0.25)
		style.set_border_width_all(3)
		add_theme_stylebox_override("panel", style)
		return

	empty_label.visible = false
	plant_icon.visible = true
	stage_label.visible = true
	name_label.visible = true
	water_bar.visible = _current_plant.stage != Plant.Stage.FLOWERING
	water_label.visible = _current_plant.stage != Plant.Stage.FLOWERING

	# 植物图标（临时：用emoji/文字）
	var stage_icons: PackedStringArray = ["🟤", "🌱", "🌿", "🪴", "🌸"]
	plant_icon.text = stage_icons[_current_plant.stage]
	plant_icon.modulate = _current_plant.get_display_color()

	# 阶段名称
	stage_label.text = _current_plant.get_stage_name()

	# 植物名称
	name_label.text = _current_plant.display_name

	# 浇水进度
	if _current_plant.stage != Plant.Stage.FLOWERING:
		var requirement: int = Plant.STAGE_WATER_REQUIREMENTS[_current_plant.stage]
		var progress := float(_current_plant.stage_water_count) / float(maxi(requirement, 1)) * 100.0
		water_bar.value = progress
		water_label.text = "%d/%d" % [_current_plant.stage_water_count, requirement]
	else:
		stage_label.text = "🌸 开花"

	# 背景色：开花时绿色，普通时泥土色，高亮时金色边框
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	if _current_plant.stage == Plant.Stage.FLOWERING:
		style.bg_color = Color(0.2, 0.35, 0.15, 0.9)
		style.border_color = Color(0.3, 0.5, 0.2)
	else:
		style.bg_color = Color(0.3, 0.22, 0.15, 0.85)
		style.border_color = Color(0.4, 0.3, 0.2)
	style.set_border_width_all(3)
	if _highlighted:
		style.border_color = Color(1.0, 0.85, 0.2)
		style.set_border_width_all(4)
	add_theme_stylebox_override("panel", style)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			plot_clicked.emit(plot_index)
