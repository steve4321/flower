class_name PlantData extends RefCounted
## 植物数据库，定义所有植物品种的基础数据

## 培育组定义
enum BreedingGroup {
	ROSE,       ## 蔷薇系
	LILY,       ## 百合系
	DAISY,      ## 菊系
	ORCHID,     ## 兰系
	SUCCULENT,  ## 多肉系
	CACTUS,     ## 仙人掌
}

const GROUP_NAMES: Dictionary = {
	BreedingGroup.ROSE: "蔷薇系",
	BreedingGroup.LILY: "百合系",
	BreedingGroup.DAISY: "菊系",
	BreedingGroup.ORCHID: "兰系",
	BreedingGroup.SUCCULENT: "多肉系",
	BreedingGroup.CACTUS: "仙人掌",
}

## 植物数据库：type → 数据
static var PLANT_DATABASE: Dictionary = {
	# === 初始种子 ===
	"rose_red": {
		"name": "红玫瑰",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 229, "g": 57, "b": 53},
		"shape": 0, "size": 1,
		"category": "flower",
		"discover_method": "initial",
	},
	"daisy_white": {
		"name": "白雏菊",
		"group": BreedingGroup.DAISY,
		"base_color": {"r": 255, "g": 255, "b": 255},
		"shape": 1, "size": 0,
		"category": "flower",
		"discover_method": "initial",
	},
	"tulip_yellow": {
		"name": "黄郁金香",
		"group": BreedingGroup.LILY,
		"base_color": {"r": 253, "g": 216, "b": 53},
		"shape": 1, "size": 1,
		"category": "flower",
		"discover_method": "initial",
	},
	# === 同品种混色发现 ===
	"rose_pink": {
		"name": "粉玫瑰",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 244, "g": 143, "b": 177},
		"shape": 0, "size": 1,
		"category": "flower",
		"discover_method": "mix_color",
	},
	"rose_white": {
		"name": "白玫瑰",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 250, "g": 250, "b": 250},
		"shape": 0, "size": 1,
		"category": "flower",
		"discover_method": "mix_color",
	},
	"tulip_orange": {
		"name": "橙郁金香",
		"group": BreedingGroup.LILY,
		"base_color": {"r": 255, "g": 112, "b": 67},
		"shape": 1, "size": 1,
		"category": "flower",
		"discover_method": "mix_color",
	},
	"tulip_purple": {
		"name": "紫郁金香",
		"group": BreedingGroup.LILY,
		"base_color": {"r": 126, "g": 87, "b": 194},
		"shape": 1, "size": 1,
		"category": "flower",
		"discover_method": "mix_color",
	},
	# === 同培育组杂交发现 ===
	"peony": {
		"name": "牡丹",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 248, "g": 187, "b": 208},
		"shape": 1, "size": 2,
		"category": "flower",
		"discover_method": "cross_breed",
	},
	"hyacinth": {
		"name": "风信子",
		"group": BreedingGroup.LILY,
		"base_color": {"r": 100, "g": 100, "b": 220},
		"shape": 0, "size": 0,
		"category": "flower",
		"discover_method": "cross_breed",
	},
	"gesang": {
		"name": "格桑花",
		"group": BreedingGroup.DAISY,
		"base_color": {"r": 220, "g": 120, "b": 180},
		"shape": 1, "size": 0,
		"category": "flower",
		"discover_method": "cross_breed",
	},
	"gypsophila": {
		"name": "满天星",
		"group": BreedingGroup.DAISY,
		"base_color": {"r": 245, "g": 245, "b": 245},
		"shape": 1, "size": 0,
		"category": "flower",
		"discover_method": "cross_breed",
	},
	# === 多步培育发现 ===
	"sakura": {
		"name": "樱花",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 255, "g": 205, "b": 210},
		"shape": 1, "size": 1,
		"category": "flower",
		"discover_method": "gradual",
	},
	"lily": {
		"name": "百合",
		"group": BreedingGroup.LILY,
		"base_color": {"r": 255, "g": 235, "b": 238},
		"shape": 1, "size": 2,
		"category": "flower",
		"discover_method": "gradual",
	},
	"sunflower": {
		"name": "向日葵",
		"group": BreedingGroup.DAISY,
		"base_color": {"r": 255, "g": 193, "b": 7},
		"shape": 0, "size": 2,
		"category": "flower",
		"discover_method": "gradual",
	},
	"carnation": {
		"name": "康乃馨",
		"group": BreedingGroup.DAISY,
		"base_color": {"r": 233, "g": 30, "b": 99},
		"shape": 2, "size": 1,
		"category": "flower",
		"discover_method": "gradual",
	},
	"lavender": {
		"name": "薰衣草",
		"group": BreedingGroup.ORCHID,
		"base_color": {"r": 149, "g": 117, "b": 205},
		"shape": 0, "size": 1,
		"category": "flower",
		"discover_method": "gradual",
	},
	"orchid": {
		"name": "蝴蝶兰",
		"group": BreedingGroup.ORCHID,
		"base_color": {"r": 206, "g": 147, "b": 216},
		"shape": 3, "size": 1,
		"category": "flower",
		"discover_method": "gradual",
	},
	# === 多肉 ===
	"succulent_echeveria": {
		"name": "观音莲",
		"group": BreedingGroup.SUCCULENT,
		"base_color": {"r": 129, "g": 199, "b": 132},
		"shape": 1, "size": 0,
		"category": "succulent",
		"discover_method": "expansion_gift",
	},
	"succulent_haworthia": {
		"name": "玉露",
		"group": BreedingGroup.SUCCULENT,
		"base_color": {"r": 102, "g": 187, "b": 106},
		"shape": 1, "size": 0,
		"category": "succulent",
		"discover_method": "mix_color",
	},
	"succulent_bear": {
		"name": "熊童子",
		"group": BreedingGroup.SUCCULENT,
		"base_color": {"r": 174, "g": 213, "b": 129},
		"shape": 2, "size": 0,
		"category": "succulent",
		"discover_method": "mix_color",
	},
	"succulent_dragon": {
		"name": "玉龙观音",
		"group": BreedingGroup.SUCCULENT,
		"base_color": {"r": 77, "g": 182, "b": 172},
		"shape": 1, "size": 1,
		"category": "succulent",
		"discover_method": "cross_breed",
	},
	"cactus": {
		"name": "仙人掌",
		"group": BreedingGroup.CACTUS,
		"base_color": {"r": 139, "g": 195, "b": 74},
		"shape": 0, "size": 1,
		"category": "succulent",
		"discover_method": "cross_breed",
	},
	# === 稀有变异 ===
	"rare_rainbow_rose": {
		"name": "彩虹玫瑰",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 255, "g": 255, "b": 255},
		"shape": 0, "size": 1,
		"category": "rare",
		"discover_method": "rare_mutation",
		"rare_type": "rainbow_rose",
	},
	"rare_dark_mandrake": {
		"name": "暗夜曼陀罗",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 26, "g": 26, "b": 26},
		"shape": 2, "size": 1,
		"category": "rare",
		"discover_method": "rare_mutation",
		"rare_type": "dark_mandrake",
	},
	"rare_golden_sunflower": {
		"name": "金色向日葵",
		"group": BreedingGroup.DAISY,
		"base_color": {"r": 255, "g": 215, "b": 0},
		"shape": 0, "size": 2,
		"category": "rare",
		"discover_method": "rare_mutation",
		"rare_type": "golden_sunflower",
	},
	"rare_moonlight_lily": {
		"name": "月光百合",
		"group": BreedingGroup.LILY,
		"base_color": {"r": 192, "g": 192, "b": 192},
		"shape": 1, "size": 2,
		"category": "rare",
		"discover_method": "rare_mutation",
		"rare_type": "moonlight_lily",
	},
	"rare_eternal_flower": {
		"name": "永恒之花",
		"group": BreedingGroup.ROSE,
		"base_color": {"r": 255, "g": 255, "b": 255},
		"shape": 3, "size": 2,
		"category": "rare",
		"discover_method": "rare_mutation",
		"rare_type": "eternal_flower",
	},
}

## 同培育组杂交表："[group]_[type_a]_[type_b]" → 结果品种
## 键名排序无关，查询时双向检查
static var CROSS_BREED_TABLE: Dictionary = {
	# 蔷薇系内部
	"rose+sakura": "peony",
	# 百合系内部
	"tulip+lily": "hyacinth",
	# 菊系内部
	"daisy+sunflower": "gesang",
	"daisy+carnation": "gypsophila",
	# 多肉系内部
	"succulent_echeveria+succulent_haworthia": "succulent_dragon",
	"succulent_echeveria+succulent_bear": "cactus",
}


static func get_data(type: String) -> Dictionary:
	return PLANT_DATABASE.get(type, {})


static func get_name(type: String) -> String:
	return PLANT_DATABASE.get(type, {}).get("name", "???")


static func get_group(type: String) -> int:
	return PLANT_DATABASE.get(type, {}).get("group", BreedingGroup.ROSE)


static func get_category(type: String) -> String:
	return PLANT_DATABASE.get(type, {}).get("category", "flower")


static func is_rare_type(type: String) -> bool:
	return PLANT_DATABASE.get(type, {}).get("category", "") == "rare"


static func get_all_types() -> Array:
	return PLANT_DATABASE.keys()


## 查询杂交表，返回结果品种或空字符串
static func lookup_cross_breed(type_a: String, type_b: String) -> String:
	## 提取品种简称（去掉前缀如 rose_red → rose）
	var short_a := _get_short_type(type_a)
	var short_b := _get_short_type(type_b)
	var key1 := short_a + "+" + short_b
	var key2 := short_b + "+" + short_a
	if CROSS_BREED_TABLE.has(key1):
		return CROSS_BREED_TABLE[key1]
	if CROSS_BREED_TABLE.has(key2):
		return CROSS_BREED_TABLE[key2]
	return ""


static func _get_short_type(type: String) -> String:
	## rose_red → rose, daisy_white → daisy, succulent_echeveria → succulent_echeveria
	var parts := type.split("_")
	if parts.size() >= 2:
		if parts[0] in ["rose", "tulip", "daisy", "sunflower", "lily", "sakura",
				"carnation", "lavender", "orchid", "peony", "hyacinth",
				"gesang", "gypsophila"]:
			return parts[0]
		if parts[0] == "succulent":
			return type  # 多肉用全名
		if parts[0] == "cactus":
			return "cactus"
		if parts[0] == "rare":
			return type  # 稀有花不参与杂交表查询
	return type
