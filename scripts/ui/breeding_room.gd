extends Control
## 培育室：从仓库选两朵花培育，结果直接变种子

const FLOWER_PICKER_SCENE := preload("res://scenes/ui/flower_picker.tscn")

@onready var back_btn: Button = $Background/Margin/VBox/TopBar/BackButton
@onready var storage_count: Label = $Background/Margin/VBox/TopBar/StorageCount
@onready var parent_a_slot: PanelContainer = $Background/Margin/VBox/BreedArea/ParentA
@onready var parent_a_icon: Label = $Background/Margin/VBox/BreedArea/ParentA/VBox/Icon
@onready var parent_a_name: Label = $Background/Margin/VBox/BreedArea/ParentA/VBox/NameLabel
@onready var parent_a_group: Label = $Background/Margin/VBox/BreedArea/ParentA/VBox/GroupLabel
@onready var parent_a_btn: Button = $Background/Margin/VBox/BreedArea/ParentA/VBox/SelectBtn
@onready var parent_b_slot: PanelContainer = $Background/Margin/VBox/BreedArea/ParentB
@onready var parent_b_icon: Label = $Background/Margin/VBox/BreedArea/ParentB/VBox/Icon
@onready var parent_b_name: Label = $Background/Margin/VBox/BreedArea/ParentB/VBox/NameLabel
@onready var parent_b_group: Label = $Background/Margin/VBox/BreedArea/ParentB/VBox/GroupLabel
@onready var parent_b_btn: Button = $Background/Margin/VBox/BreedArea/ParentB/VBox/SelectBtn
@onready var breed_btn: Button = $Background/Margin/VBox/BreedArea/BreedButton
@onready var result_label: Label = $Background/Margin/VBox/ResultArea/ResultLabel
@onready var hint_label: Label = $Background/Margin/VBox/HintLabel

var _parent_a_index: int = -1
var _parent_b_index: int = -1
var _picking_for: String = ""  # "a" or "b"
var flower_picker: Control = null


func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	parent_a_btn.pressed.connect(_on_pick_parent_a)
	parent_b_btn.pressed.connect(_on_pick_parent_b)
	breed_btn.pressed.connect(_on_breed_pressed)
	EventBus.breeding_done.connect(_on_breeding_done)

	# 创建花选择器
	flower_picker = FLOWER_PICKER_SCENE.instantiate()
	add_child(flower_picker)
	flower_picker.flower_selected.connect(_on_flower_picked)
	flower_picker.cancelled.connect(_on_picker_cancelled)

	_update_display()


func _update_display() -> void:
	storage_count.text = "仓库: %d朵花" % GameState.flower_storage.size()
	_update_parent_slot("a")
	_update_parent_slot("b")
	_update_breed_button()
	hint_label.text = "💡 从仓库选两朵花，培育出新的种子！花不会被消耗"


func _update_parent_slot(which: String) -> void:
	var index := _parent_a_index if which == "a" else _parent_b_index
	var icon: Label = parent_a_icon if which == "a" else parent_b_icon
	var name_lbl: Label = parent_a_name if which == "a" else parent_b_name
	var group_lbl: Label = parent_a_group if which == "a" else parent_b_group
	var btn: Button = parent_a_btn if which == "a" else parent_b_btn

	if index < 0 or index >= GameState.flower_storage.size():
		icon.text = "❓"
		name_lbl.text = "未选择"
		group_lbl.text = ""
		btn.text = "选择花朵"
		return

	var plant: Plant = GameState.flower_storage[index]
	icon.text = "🌸"
	icon.modulate = plant.get_display_color()
	name_lbl.text = plant.display_name
	group_lbl.text = plant.breeding_group
	btn.text = "重新选择"


func _update_breed_button() -> void:
	var can_breed := _parent_a_index >= 0 and _parent_b_index >= 0
	if can_breed:
		var plant_a: Plant = GameState.flower_storage[_parent_a_index]
		var plant_b: Plant = GameState.flower_storage[_parent_b_index]
		can_breed = GeneSystem.can_breed_across_groups(
			PlantData.get_group(plant_a.plant_type),
			PlantData.get_group(plant_b.plant_type))
		if not can_breed:
			result_label.text = "⚠️ 花卉和多肉/仙人掌无法培育"
	breed_btn.disabled = not can_breed


func _on_pick_parent_a() -> void:
	_picking_for = "a"
	var disabled: Array[int] = []
	if _parent_b_index >= 0:
		disabled.append(_parent_b_index)
	flower_picker.popup(disabled)


func _on_pick_parent_b() -> void:
	_picking_for = "b"
	var disabled: Array[int] = []
	if _parent_a_index >= 0:
		disabled.append(_parent_a_index)
	flower_picker.popup(disabled)


func _on_flower_picked(storage_index: int) -> void:
	if _picking_for == "a":
		_parent_a_index = storage_index
	else:
		_parent_b_index = storage_index
	result_label.text = ""
	_update_display()


func _on_picker_cancelled() -> void:
	_picking_for = ""


func _on_breed_pressed() -> void:
	if _parent_a_index < 0 or _parent_b_index < 0:
		return
	result_label.text = "培育中..."
	breed_btn.disabled = true

	var result: Dictionary = GameState.breed_from_storage(_parent_a_index, _parent_b_index)
	if result.is_empty():
		result_label.text = "⚠️ 培育失败"
		_update_breed_button()
		return
	if result.has("error"):
		if result.error == "incompatible":
			result_label.text = "⚠️ 花卉和多肉/仙人掌无法培育"
		else:
			result_label.text = "⚠️ 培育失败"
		_update_breed_button()
		return

	# 显示结果
	var msg: String = "🌱 获得：%s" % result.plant_name
	if result.is_rare:
		msg = "✨ 稀有花！获得：%s" % result.plant_name
	if result.is_new:
		msg += " 🎉新发现！"
	msg += "（已加入种子库）"
	result_label.text = msg


func _on_breeding_done(_plant_type: String, _is_rare: bool, _is_new: bool) -> void:
	_update_display()


func _on_back_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/garden.tscn")
