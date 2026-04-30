extends Node
## 全局游戏状态：花圃、桌面、种子库、图鉴、花仓库

## 花圃格子：Array of Plant or null
var garden_plots: Array = []
var garden_size: int = 6

## 桌面花瓶：插花的花 plant_id 列表（可多朵）
var vase_flower_ids: Array = []

## 花仓库：收藏的已开花植物（Array of Plant）
var flower_storage: Array = []

## 种子库：已经发现的品种列表
var seed_inventory: Array[String] = []

## 图鉴：已收录的品种
var encyclopedia: Dictionary = {}  # plant_type → true

## 花圃扩展参数
const EXPAND_TRIGGER: int = 5   # 每收集5种新花
const EXPAND_AMOUNT: int = 3    # 解锁3格
const MAX_GARDEN_SIZE: int = 20 # 最大20格


func _ready() -> void:
	garden_plots.resize(garden_size)
	garden_plots.fill(null)
	seed_inventory = ["rose_red", "daisy_white", "tulip_yellow"]


## 获取指定格位的植物
func get_plant(plot_index: int) -> Plant:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return null
	return garden_plots[plot_index]


## 种下种子
func plant_seed(plot_index: int, plant_type: String) -> Plant:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return null
	if garden_plots[plot_index] != null:
		return null
	if not plant_type in seed_inventory:
		return null

	var data := PlantData.get_data(plant_type)
	if data.is_empty():
		return null

	var p := Plant.new(plant_type, data.get("base_color", {}))
	p.display_name = data.get("name", "???")
	p.breeding_group = PlantData.GROUP_NAMES.get(data.get("group", 0), "")
	p.shape = data.get("shape", 0)
	p.size = data.get("size", 1)
	garden_plots[plot_index] = p
	EventBus.plant_planted.emit(plot_index, plant_type)
	EventBus.garden_changed.emit()
	return p


## 浇水
func water_plant(plot_index: int) -> bool:
	var p := get_plant(plot_index)
	if p == null:
		return false
	var old_stage := p.stage
	if not p.water():
		return false
	EventBus.plant_watered.emit(plot_index)
	if p.stage != old_stage:
		EventBus.stage_advanced.emit(plot_index, p.stage)
		if p.stage == Plant.Stage.FLOWERING:
			_check_discovery(p)
	return true


## 移除植物
func remove_plant(plot_index: int) -> void:
	if plot_index < 0 or plot_index >= garden_plots.size():
		return
	garden_plots[plot_index] = null
	EventBus.plant_removed.emit(plot_index)
	EventBus.garden_changed.emit()


## 培育两株花
func breed_plants(plot_a: int, plot_b: int, target_plot: int) -> Plant:
	var parent_a := get_plant(plot_a)
	var parent_b := get_plant(plot_b)
	if parent_a == null or parent_b == null:
		return null
	if parent_a.stage != Plant.Stage.FLOWERING or parent_b.stage != Plant.Stage.FLOWERING:
		return null
	if target_plot < 0 or target_plot >= garden_plots.size():
		return null
	if garden_plots[target_plot] != null:
		return null
	if not GeneSystem.can_breed_across_groups(
		PlantData.get_group(parent_a.plant_type),
		PlantData.get_group(parent_b.plant_type)):
		return null

	var result: Dictionary = GeneSystem.breed(
		parent_a.plant_type, parent_b.plant_type,
		parent_a.color, parent_b.color)

	var data := PlantData.get_data(result.plant_type)
	var child := Plant.new(result.plant_type)
	child.display_name = data.get("name", "???")
	child.breeding_group = PlantData.GROUP_NAMES.get(data.get("group", 0), "")
	child.shape = data.get("shape", 0)
	child.size = data.get("size", 1)
	child.is_rare = result.is_rare
	child.rare_type = result.rare_type
	child.setup_breeding_sprout(result.color)

	garden_plots[target_plot] = child
	EventBus.breeding_started.emit(target_plot, plot_a, plot_b)
	EventBus.garden_changed.emit()
	return child


## === 桌面花瓶 ===

## 插花到桌面花瓶（从花圃选，不消耗）
func arrange_flower(plot_index: int) -> bool:
	var p := get_plant(plot_index)
	if p == null:
		return false
	if p.stage != Plant.Stage.FLOWERING:
		return false
	if p.id in vase_flower_ids:
		return false
	vase_flower_ids.append(p.id)
	EventBus.desktop_changed.emit()
	return true


## 从花瓶移除一朵花
func remove_vase_flower(flower_id: String) -> void:
	vase_flower_ids.erase(flower_id)
	EventBus.desktop_changed.emit()


## 清空花瓶
func clear_vase() -> void:
	vase_flower_ids.clear()
	EventBus.desktop_changed.emit()


## 获取花瓶中所有植物
func get_vase_plants() -> Array:
	var result: Array = []
	for fid in vase_flower_ids:
		var found: Plant = null
		for p in garden_plots:
			if p != null and p.id == fid:
				found = p
				break
		if found == null:
			for p in flower_storage:
				if p != null and p.id == fid:
					found = p
					break
		if found != null:
			result.append(found)
	return result


## === 花仓库 ===

## 将花园中开花的植物收入仓库
func store_flower_from_garden(plot_index: int) -> bool:
	var p := get_plant(plot_index)
	if p == null:
		return false
	if p.stage != Plant.Stage.FLOWERING:
		return false
	# 清除花瓶引用
	if p.id in vase_flower_ids:
		vase_flower_ids.erase(p.id)
		EventBus.desktop_changed.emit()
	flower_storage.append(p)
	garden_plots[plot_index] = null
	EventBus.flower_stored.emit(plot_index)
	EventBus.garden_changed.emit()
	return true


## 从仓库取花放回花园空格
func retrieve_flower_to_garden(storage_index: int, plot_index: int) -> bool:
	if storage_index < 0 or storage_index >= flower_storage.size():
		return false
	if plot_index < 0 or plot_index >= garden_plots.size():
		return false
	if garden_plots[plot_index] != null:
		return false
	var p: Plant = flower_storage[storage_index]
	flower_storage.remove_at(storage_index)
	garden_plots[plot_index] = p
	EventBus.flower_retrieved.emit(plot_index)
	EventBus.garden_changed.emit()
	return true


## 培育两株仓库里的花（不消耗，结果直接变种子）
func breed_from_storage(storage_a: int, storage_b: int) -> Dictionary:
	if storage_a < 0 or storage_a >= flower_storage.size():
		return {}
	if storage_b < 0 or storage_b >= flower_storage.size():
		return {}
	var parent_a: Plant = flower_storage[storage_a]
	var parent_b: Plant = flower_storage[storage_b]
	if parent_a.stage != Plant.Stage.FLOWERING or parent_b.stage != Plant.Stage.FLOWERING:
		return {}
	if not GeneSystem.can_breed_across_groups(
		PlantData.get_group(parent_a.plant_type),
		PlantData.get_group(parent_b.plant_type)):
		return {"error": "incompatible"}

	var result: Dictionary = GeneSystem.breed(
		parent_a.plant_type, parent_b.plant_type,
		parent_a.color, parent_b.color)

	# 结果直接加入种子库
	var new_type: String = result.plant_type
	if not new_type in seed_inventory:
		seed_inventory.append(new_type)

	# 检查新发现
	var new_data: Dictionary = PlantData.get_data(new_type)
	var is_new_discovery := not encyclopedia.has(new_type)
	if is_new_discovery:
		encyclopedia[new_type] = true
		if result.is_rare:
			EventBus.rare_flower_found.emit(new_type)
		_check_garden_expansion()

	EventBus.breeding_done.emit(new_type, result.is_rare, is_new_discovery)
	return {
		"plant_type": new_type,
		"plant_name": new_data.get("name", "???"),
		"is_rare": result.is_rare,
		"rare_type": result.rare_type,
		"color": result.color,
		"is_new": is_new_discovery,
	}


## 检查新发现
func _check_discovery(plant: Plant) -> void:
	var type := plant.plant_type
	if encyclopedia.has(type):
		return
	encyclopedia[type] = true
	EventBus.flower_discovered.emit(type)

	if plant.is_rare:
		EventBus.rare_flower_found.emit(type)

	# 加入种子库
	if not type in seed_inventory:
		seed_inventory.append(type)

	# 检查花圃扩展
	_check_garden_expansion()


func _check_garden_expansion() -> void:
	var collected := encyclopedia.size()
	# 首次: 6格时需5个发现 → 扩展到9格
	# 二次: 9格时需10个发现 → 扩展到12格
	# 三次: 12格时需15个发现 → 扩展到15格
	# 上限: 15格（MAX=20但实际到15格）
	var threshold := ((garden_size - 6) / EXPAND_AMOUNT) * EXPAND_TRIGGER
	if collected >= threshold and garden_size < MAX_GARDEN_SIZE:
		garden_size = mini(garden_size + EXPAND_AMOUNT, MAX_GARDEN_SIZE)
		garden_plots.resize(garden_size)
		EventBus.garden_expanded.emit(garden_size)


## 序列化
func to_dictionary() -> Dictionary:
	var plots_data: Array = []
	for p in garden_plots:
		if p != null:
			plots_data.append(p.to_dictionary())
		else:
			plots_data.append(null)
	var storage_data: Array = []
	for p in flower_storage:
		if p != null:
			storage_data.append(p.to_dictionary())
	return {
		"garden_size": garden_size,
		"garden_plots": plots_data,
		"vase_flower_ids": vase_flower_ids,
		"seed_inventory": seed_inventory,
		"encyclopedia": encyclopedia,
		"flower_storage": storage_data,
	}


func from_dictionary(data: Dictionary) -> void:
	garden_size = data.get("garden_size", 6)
	var plots_data: Array = data.get("garden_plots", [])
	garden_plots.clear()
	for entry in plots_data:
		if entry != null and entry is Dictionary:
			garden_plots.append(Plant.from_dictionary(entry))
		else:
			garden_plots.append(null)
	while garden_plots.size() < garden_size:
		garden_plots.append(null)
	vase_flower_ids.clear()
	for fid in data.get("vase_flower_ids", []):
		vase_flower_ids.append(fid)
	seed_inventory.clear()
	for s in data.get("seed_inventory", ["rose_red", "daisy_white", "tulip_yellow"]):
		seed_inventory.append(s)
	encyclopedia = data.get("encyclopedia", {})
	flower_storage.clear()
	for entry in data.get("flower_storage", []):
		if entry != null and entry is Dictionary:
			flower_storage.append(Plant.from_dictionary(entry))
