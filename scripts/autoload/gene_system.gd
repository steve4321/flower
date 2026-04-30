extends Node
## 基因系统：颜色混合、杂交判定、稀有花检测

## 颜色混合（可调参数）
const MIX_COLOR_OFFSET: float = 20.0
const RARE_BASE_CHANCE: float = 0.03
const CROSS_BREED_CHANCE: float = 0.27

## 稀有花颜色阈值（可调）
const RARE_RGB_HIGH: int = 200
const RARE_RGB_LOW: int = 50
const RARE_GOLDEN_G: int = 180
const RARE_MOONLIGHT_G: int = 180
const RARE_MOONLIGHT_LOW: int = 80


## 混合两株花的颜色
static func mix_colors(color_a: Dictionary, color_b: Dictionary) -> Dictionary:
	var weight := randf()
	return {
		"r": clampi(int(lerpf(color_a.r, color_b.r, weight) + randf_range(-MIX_COLOR_OFFSET, MIX_COLOR_OFFSET)), 0, 255),
		"g": clampi(int(lerpf(color_a.g, color_b.g, weight) + randf_range(-MIX_COLOR_OFFSET, MIX_COLOR_OFFSET)), 0, 255),
		"b": clampi(int(lerpf(color_a.b, color_b.b, weight) + randf_range(-MIX_COLOR_OFFSET, MIX_COLOR_OFFSET)), 0, 255),
	}


## 培育主逻辑：给定两个亲本，返回子代结果
## 返回 Dictionary: { "plant_type": String, "color": Dictionary, "is_rare": bool, "rare_type": String }
static func breed(parent_a_type: String, parent_b_type: String,
		parent_a_color: Dictionary, parent_b_color: Dictionary) -> Dictionary:
	var group_a: int = PlantData.get_group(parent_a_type)
	var group_b: int = PlantData.get_group(parent_b_type)
	var same_group: bool = (group_a == group_b)

	# 1. 稀有变异判定（3%）
	if randf() < RARE_BASE_CHANCE:
		var mixed := mix_colors(parent_a_color, parent_b_color)
		var rare_type := check_rare(mixed, group_a)
		if rare_type != "":
			var rare_plant_type := _rare_type_to_plant(rare_type)
			if rare_plant_type != "":
				return {
					"plant_type": rare_plant_type,
					"color": PlantData.get_data(rare_plant_type).get("base_color", mixed),
					"is_rare": true,
					"rare_type": rare_type,
				}

	# 2. 同组杂交判定（27%，仅同培育组）
	if same_group and randf() < CROSS_BREED_CHANCE:
		var cross_result := PlantData.lookup_cross_breed(parent_a_type, parent_b_type)
		if cross_result != "":
			var mixed := mix_colors(parent_a_color, parent_b_color)
			return {
				"plant_type": cross_result,
				"color": mixed,
				"is_rare": false,
				"rare_type": "",
			}

	# 3. 混色（默认70%+，或不同组退回）
	var mixed := mix_colors(parent_a_color, parent_b_color)
	return {
		"plant_type": parent_a_type,  # 继承亲本A品种
		"color": mixed,
		"is_rare": false,
		"rare_type": "",
	}


## 检查颜色是否触发稀有花
static func check_rare(color: Dictionary, group: int) -> String:
	# 彩虹玫瑰：蔷薇系培育时，RGB均>200
	if group == PlantData.BreedingGroup.ROSE:
		if color.r > RARE_RGB_HIGH and color.g > RARE_RGB_HIGH and color.b > RARE_RGB_HIGH:
			return "rainbow_rose"
	# 金色向日葵：菊系培育时
	if group == PlantData.BreedingGroup.DAISY:
		if color.r > RARE_RGB_HIGH and color.g > RARE_GOLDEN_G and color.b < RARE_RGB_LOW:
			return "golden_sunflower"
	# 月光百合：百合系培育时
	if group == PlantData.BreedingGroup.LILY:
		if color.r < RARE_MOONLIGHT_LOW and color.g > RARE_MOONLIGHT_G and color.b > RARE_MOONLIGHT_G:
			return "moonlight_lily"
	# 暗夜曼陀罗：任意培育
	if color.r < RARE_RGB_LOW and color.g < RARE_RGB_LOW and color.b < RARE_RGB_LOW:
		return "dark_mandrake"
	# 永恒之花：fallback
	return "eternal_flower"


## 两个不同培育组能否培育
static func can_breed_across_groups(group_a: int, group_b: int) -> bool:
	# 花×多肉/仙人掌 → 不行
	var is_flower_a := group_a in [PlantData.BreedingGroup.ROSE, PlantData.BreedingGroup.LILY,
		PlantData.BreedingGroup.DAISY, PlantData.BreedingGroup.ORCHID]
	var is_flower_b := group_b in [PlantData.BreedingGroup.ROSE, PlantData.BreedingGroup.LILY,
		PlantData.BreedingGroup.DAISY, PlantData.BreedingGroup.ORCHID]
	var is_succulent_a := group_a in [PlantData.BreedingGroup.SUCCULENT, PlantData.BreedingGroup.CACTUS]
	var is_succulent_b := group_b in [PlantData.BreedingGroup.SUCCULENT, PlantData.BreedingGroup.CACTUS]
	if is_flower_a and is_succulent_b:
		return false
	if is_succulent_a and is_flower_b:
		return false
	return true


static func _rare_type_to_plant(rare_type: String) -> String:
	var mapping := {
		"rainbow_rose": "rare_rainbow_rose",
		"dark_mandrake": "rare_dark_mandrake",
		"golden_sunflower": "rare_golden_sunflower",
		"moonlight_lily": "rare_moonlight_lily",
		"eternal_flower": "rare_eternal_flower",
	}
	return mapping.get(rare_type, "")
