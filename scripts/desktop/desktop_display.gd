extends Control
## 桌面展示主场景：3个花位 + idle动画 + 场景切换

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/desktop_slot.tscn")
const IDLE_SCRIPT: GDScript = preload("res://scripts/desktop/idle_animator.gd")

@onready var slot_container: HBoxContainer = $VBox/Bar/SlotContainer
@onready var garden_btn: Button = $VBox/Bar/GardenButton

var slot_nodes: Array[PanelContainer] = []
var idle_nodes: Array[Node] = []


func _ready() -> void:
	_load_save()
	_connect_signals()
	_build_slots()


func _load_save() -> void:
	if SaveManager.has_save():
		SaveManager.load_game()
	else:
		SaveManager.new_game()


func _connect_signals() -> void:
	garden_btn.pressed.connect(_on_garden_btn_pressed)
	EventBus.desktop_changed.connect(_on_desktop_changed)
	EventBus.game_loaded.connect(_on_game_loaded)


func _on_garden_btn_pressed() -> void:
	SFXPlayer.play_click()
	get_tree().change_scene_to_file("res://scenes/garden.tscn")


func _on_slot_clicked(_slot_index: int) -> void:
	# 点击桌面任何位置都跳转到花圃
	_on_garden_btn_pressed()


## === 信号回调 ===

func _on_desktop_changed() -> void:
	_refresh_slots()


func _on_game_loaded() -> void:
	_refresh_slots()
