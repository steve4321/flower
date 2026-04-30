extends Control
## 种子选择弹窗

signal seed_selected(plant_type: String)
signal cancelled()

@onready var seed_list: VBoxContainer = $Panel/Margin/VBox/Scroll/List
@onready var close_btn: Button = $Panel/Margin/VBox/Header/CloseButton


func _ready() -> void:
	close_btn.pressed.connect(func(): cancelled.emit(); hide())


func popup_seed_menu() -> void:
	_refresh_list()
	show()


func _refresh_list() -> void:
	for child in seed_list.get_children():
		child.queue_free()

	for plant_type in GameState.seed_inventory:
		var data := PlantData.get_data(plant_type)
		if data.is_empty():
			continue
		var btn := Button.new()
		btn.text = "%s (%s)" % [data.get("name", "???"), PlantData.GROUP_NAMES.get(data.get("group", 0), "")]
		btn.custom_minimum_size = Vector2(200, 36)
		var _type := plant_type  # capture for lambda
		btn.pressed.connect(func(): seed_selected.emit(_type); hide())
		seed_list.add_child(btn)
