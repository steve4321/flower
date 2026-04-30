class_name Plant extends RefCounted
## 植物数据类，管理单株植物的所有状态

signal stage_changed(new_stage: int)

enum Stage {SEED, SPROUT, SEEDLING, MATURE, FLOWERING}

const STAGE_NAMES: PackedStringArray = ["种子", "发芽", "幼苗", "成株", "开花"]

## 每个阶段需要的浇水次数（可调参数）
const STAGE_WATER_REQUIREMENTS: Dictionary = {
	Stage.SEED: 2,
	Stage.SPROUT: 2,
	Stage.SEEDLING: 3,
	Stage.MATURE: 3,
	Stage.FLOWERING: 0,
}

var id: String = ""
var plant_type: String = ""
var display_name: String = ""
var breeding_group: String = ""

var stage: Stage = Stage.SEED
var water_count: int = 0
var stage_water_count: int = 0

var color: Dictionary = {"r": 128, "g": 128, "b": 128}
var shape: int = 0
var size: int = 1

var is_rare: bool = false
var rare_type: String = ""

## 是否为培育芽苗（颜色隐藏，开花时揭晓）
var is_breeding_sprout: bool = false
## 培育芽苗的预设颜色（揭晓前隐藏）
var _hidden_color: Dictionary = {"r": 128, "g": 128, "b": 128}


func _init(type: String = "", color_override: Dictionary = {}) -> void:
	plant_type = type
	if not color_override.is_empty():
		color = color_override.duplicate(true)
	id = _generate_id()


## 浇水，返回 true 表示浇水成功
func water() -> bool:
	if stage == Stage.FLOWERING:
		return false
	water_count += 1
	stage_water_count += 1
	var requirement: int = STAGE_WATER_REQUIREMENTS[stage]
	if stage_water_count >= requirement:
		_advance_stage()
	return true


func _advance_stage() -> void:
	if stage < Stage.FLOWERING:
		stage += 1
		stage_water_count = 0
		if stage == Stage.FLOWERING and is_breeding_sprout:
			color = _hidden_color.duplicate(true)
			is_breeding_sprout = false
		stage_changed.emit(stage)


func get_display_color() -> Color:
	if is_breeding_sprout:
		return Color(0.5, 0.5, 0.5)
	return Color(color.r / 255.0, color.g / 255.0, color.b / 255.0)


func get_breed_hint_color() -> Color:
	## 培育芽苗每次浇水后颜色微微变化，暗示最终结果
	if not is_breeding_sprout:
		return get_display_color()
	var progress := float(stage_water_count) / float(STAGE_WATER_REQUIREMENTS[stage])
	var hint_r := lerpf(0.5, _hidden_color.r / 255.0, progress)
	var hint_g := lerpf(0.5, _hidden_color.g / 255.0, progress)
	var hint_b := lerpf(0.5, _hidden_color.b / 255.0, progress)
	return Color(hint_r, hint_g, hint_b)


func setup_breeding_sprout(hidden_color: Dictionary) -> void:
	is_breeding_sprout = true
	_hidden_color = hidden_color.duplicate(true)


func get_stage_name() -> String:
	return STAGE_NAMES[stage]


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"plant_type": plant_type,
		"display_name": display_name,
		"breeding_group": breeding_group,
		"stage": stage,
		"water_count": water_count,
		"stage_water_count": stage_water_count,
		"color": color,
		"shape": shape,
		"size": size,
		"is_rare": is_rare,
		"rare_type": rare_type,
		"is_breeding_sprout": is_breeding_sprout,
		"hidden_color": _hidden_color,
	}


static func from_dictionary(data: Dictionary) -> Plant:
	var p := Plant.new(data.get("plant_type", ""), data.get("color", {}))
	p.id = data.get("id", p.id)
	p.display_name = data.get("display_name", "")
	p.breeding_group = data.get("breeding_group", "")
	p.stage = data.get("stage", 0) as Stage
	p.water_count = data.get("water_count", 0)
	p.stage_water_count = data.get("stage_water_count", 0)
	p.shape = data.get("shape", 0)
	p.size = data.get("size", 1)
	p.is_rare = data.get("is_rare", false)
	p.rare_type = data.get("rare_type", "")
	p.is_breeding_sprout = data.get("is_breeding_sprout", false)
	if p.is_breeding_sprout:
		p._hidden_color = data.get("hidden_color", {"r": 128, "g": 128, "b": 128})
	return p


func _generate_id() -> String:
	return "p_%d_%d" % [Time.get_ticks_msec(), randi() % 100000]
