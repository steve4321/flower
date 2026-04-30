extends Node
## 存档管理：JSON 文件读写

const SAVE_PATH := "user://save.json"


func _ready() -> void:
	EventBus.plant_watered.connect(_on_state_changed)
	EventBus.plant_planted.connect(_on_state_changed)
	EventBus.plant_removed.connect(_on_state_changed)
	EventBus.stage_advanced.connect(_on_state_changed)
	EventBus.breeding_started.connect(_on_state_changed)
	EventBus.breeding_revealed.connect(_on_state_changed)
	EventBus.breeding_done.connect(_on_state_changed)
	EventBus.flower_discovered.connect(_on_state_changed)
	EventBus.garden_expanded.connect(_on_state_changed)
	EventBus.desktop_changed.connect(_on_state_changed)
	EventBus.flower_stored.connect(_on_state_changed)
	EventBus.flower_retrieved.connect(_on_state_changed)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var data := {
		"version": "2.0",
		"last_save": Time.get_datetime_string_from_system(),
		"game_state": GameState.to_dictionary(),
	}
	var json := JSON.new()
	var json_str := json.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(json_str)
		file.close()
		EventBus.game_saved.emit()


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json_str := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_str) != OK:
		return false
	var data: Dictionary = json.data
	if not data is Dictionary:
		return false
	var state_data: Dictionary = data.get("game_state", {})
	if state_data.is_empty():
		return false
	GameState.from_dictionary(state_data)
	EventBus.game_loaded.emit()
	return true


func new_game() -> void:
	GameState.garden_plots.clear()
	GameState.garden_plots.resize(GameState.garden_size)
	GameState.garden_plots.fill(null)
	GameState.vase_flower_ids.clear()
	GameState.flower_storage.clear()
	GameState.seed_inventory = ["rose_red", "daisy_white", "tulip_yellow"]
	GameState.encyclopedia = {}


func _on_state_changed(_arg = null) -> void:
	save_game()
