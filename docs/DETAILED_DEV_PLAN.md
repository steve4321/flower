# Flower Desktop - 详细开发计划
**版本**: 1.0  
**目标引擎**: Godot 4.2+  
**最后更新**: 2026-03-30

---

## 目录

1. [项目概述与架构](#1-项目概述与架构)
2. [场景实现指南](#2-场景实现指南)
3. [核心系统详解](#3-核心系统详解)
4. [UI/UX 设计规范](#4-uiux-设计规范)
5. [游戏数值平衡](#5-游戏数值平衡)
6. [资源管线](#6-资源管线)
7. [实施路线图](#7-实施路线图)

---

# 1. 项目概述与架构

## 1.1 项目信息

| 项目 | 内容 |
|-----|------|
| 项目名称 | Flower Desktop |
| 引擎 | Godot 4.2+ |
| 语言 | GDScript |
| 平台 | Windows / Linux (悬浮窗) |
| 显示模式 | 嵌入式底部悬浮窗, Always-on-top |
| 分辨率 | 动态: 屏幕宽度30-50% × 180px, 可调节 |

## 1.2 系统架构图

### Autoload 体系（单例）

```
Project Autoload
├── GameState          # 全局游戏状态、单例数据
├── GeneSystem         # 基因计算、遗传、突变
├── SaveManager        # 存档读写、自动存档
├── AudioManager       # BGM/SFX 播放管理
└── EventBus           # 信号总线、事件分发
```

### 场景树（Scene Tree）

```
main (Node)
├── WindowController   # 窗口位置/大小/置顶控制
├── MainPanel (MarginContainer)
│   ├── TitleBar (HBoxContainer)       # 可选拖拽区 + 标题
│   ├── ContentArea (HBoxContainer)
│   │   ├── PotSlot_0 (PotSlot)
│   │   ├── PotSlot_1 (PotSlot)
│   │   ├── PotSlot_2 (PotSlot)
│   │   ├── PotSlot_3 (PotSlot)
│   │   └── PotSlot_4 (PotSlot)
│   └── ActionBar (HBoxContainer)
│       ├── CareButtons (HBoxContainer)
│       │   ├── WaterButton
│       │   ├── FertilizeButton
│       │   ├── SunlightButton
│       │   └── PruneButton
│       ├── Separator
│       └── NavButtons (HBoxContainer)
│           ├── EncyclopediaButton
│           ├── ShopButton
│           └── SettingsButton
├── Overlays (CanvasLayer)
│   ├── PotDetailPopup (PopupPanel)
│   ├── BreedingDialog (PopupPanel)
│   ├── EncyclopediaPanel (PopupPanel)
│   └── ShopPanel (PopupPanel)
├── ParticleLayer (CanvasLayer)
│   ├── WaterParticles (GPUParticles2D)
│   ├── FertilizerParticles (GPUParticles2D)
│   └── SunlightParticles (GPUParticles2D)
└── AudioPlayer (AudioStreamPlayer)
```

## 1.3 数据流图

```
[用户操作]
     │
     ▼
[UI Scene (输入)] ──signal──► [EventBus]
                                       │
     ┌─────────────────────────────────┼─────────────────┐
     ▼                                 ▼                 ▼
[GameState]                    [CareSystem]      [BreedingSystem]
- _plants: Dictionary          - apply_water()   - select_parents()
- _coins: int                   - apply_fertilizer()- combine_genes()
- _encyclopedia: Set            - apply_sunlight() - check_rare()
     │                           - decay_stats()    - generate_seed()
     ▼
[SaveManager]
- auto_save() [每5分钟]
- save_to_disk()
- load_from_disk()

     │
     ▼
[文件系统] ◄──► [user://save.json]
```

## 1.4 类层次结构

### Plant 基类体系

```gdscript
# scripts/core/plant.gd
class_name Plant extends Node
## 植物基类，所有植物的父类

signal stage_changed(stage: int)
signal stats_changed(stats: Dictionary)
signal died()

enum Stage { SEED = 0, SPROUT = 1, SEEDLING = 2, MATURE = 3, FLOWERING = 4 }

const STAGE_NAMES := ["种子", "发芽", "幼苗", "成株", "开花"]

var plant_id: String = ""
var plant_type: String = ""
var display_name: String = ""

var genes: Dictionary = {
    "r": 128, "g": 128, "b": 128,
    "shape": 0,
    "size": 1,
    "bloom": 1
}

var stage: Stage = Stage.SEED
var growth_progress: float = 0.0
var is_rare: bool = false
var rare_type: String = ""

var stats: Dictionary = {
    "water": 50.0,
    "fertilizer": 50.0,
    "sunlight": 50.0,
    "health": 100.0
}

var care_cooldowns: Dictionary = {
    "water": 0.0,
    "fertilizer": 0.0,
    "sunlight": 0.0,
    "prune": 0.0
}

var stage_requirements: Dictionary = {
    Stage.SEED:     {"water": 20.0, "fertilizer": 0.0,  "sunlight": 0.0},
    Stage.SPROUT:   {"water": 30.0, "fertilizer": 0.0,  "sunlight": 20.0},
    Stage.SEEDLING: {"water": 40.0, "fertilizer": 10.0, "sunlight": 0.0},
    Stage.MATURE:   {"water": 50.0, "fertilizer": 50.0, "sunlight": 50.0},
    Stage.FLOWERING: {"water": 30.0, "fertilizer": 30.0, "sunlight": 30.0}
}

var stage_durations: Dictionary = {
    Stage.SEED:      3600.0,
    Stage.SPROUT:    7200.0,
    Stage.SEEDLING: 14400.0,
    Stage.MATURE:   28800.0,
    Stage.FLOWERING: 0.0
}

func _init(type: String = "", genes_override: Dictionary = {}) -> void:
    plant_type = type
    if not genes_override.is_empty():
        genes = genes_override.duplicate(true)

func _process(delta: float) -> void:
    _process_decay(delta)
    _process_growth(delta)
    _process_care_cooldowns(delta)
    _check_health()

func _process_decay(delta: float) -> void:
    stats.water     = clampf(stats.water - 2.0 * delta / 3600.0, 0.0, 100.0)
    stats.fertilizer = clampf(stats.fertilizer - 1.0 * delta / 3600.0, 0.0, 100.0)
    stats.sunlight   = clampf(stats.sunlight - 3.0 * delta / 3600.0, 0.0, 100.0)

func _process_growth(delta: float) -> void:
    if stage == Stage.FLOWERING:
        return
    if not _meets_requirements():
        return
    var speed_mult := _get_growth_multiplier()
    growth_progress += delta * speed_mult
    _check_stage_transition()

func _meets_requirements() -> bool:
    var reqs: Dictionary = stage_requirements[stage]
    return stats.water >= reqs.water and \
           stats.fertilizer >= reqs.fertilizer and \
           stats.sunlight >= reqs.sunlight

func _get_growth_multiplier() -> float:
    var all_above_50 := stats.values().all(func(v): return v >= 50.0)
    return 1.1 if all_above_50 else 1.0

func _check_stage_transition() -> void:
    var threshold: float = stage_durations[stage]
    if threshold > 0.0 and growth_progress >= threshold:
        growth_progress = 0.0
        stage = mini(stage + 1, Stage.FLOWERING)
        stage_changed.emit(stage)

func _check_health() -> void:
    var critical := [stats.water, stats.fertilizer, stats.sunlight].any(
        func(v): return v < 10.0
    )
    if critical:
        stats.health = maxf(0.0, stats.health - 0.5)
        if stats.health <= 0.0:
            died.emit()

func _process_care_cooldowns(delta: float) -> void:
    for key in care_cooldowns:
        care_cooldowns[key] = maxf(0.0, care_cooldowns[key] - delta)

func water(amount: float = 30.0) -> bool:
    if care_cooldowns.water > 0.0:
        return false
    stats.water = clampf(stats.water + amount, 0.0, 100.0)
    care_cooldowns.water = 0.0
    stats_changed.emit(stats)
    return true

func fertilize(amount: float = 20.0) -> bool:
    if care_cooldowns.fertilizer > 0.0:
        return false
    stats.fertilizer = clampf(stats.fertilizer + amount, 0.0, 100.0)
    care_cooldowns.fertilizer = 43200.0  # 12小时
    stats_changed.emit(stats)
    return true

func sunlight_boost(amount: float = 50.0) -> bool:
    if care_cooldowns.sunlight > 0.0:
        return false
    stats.sunlight = clampf(stats.sunlight + amount, 0.0, 100.0)
    care_cooldowns.sunlight = 0.0
    stats_changed.emit(stats)
    return true

func prune() -> bool:
    if care_cooldowns.prune > 0.0:
        return false
    if stage < Stage.MATURE:
        return false
    stats.health = clampf(stats.health + 30.0, 0.0, 100.0)
    care_cooldowns.prune = 86400.0  # 24小时
    stats_changed.emit(stats)
    return true

func get_display_color() -> Color:
    return Color(genes.r / 255.0, genes.g / 255.0, genes.b / 255.0, 1.0)

func get_state() -> Dictionary:
    return {
        "plant_id": plant_id,
        "plant_type": plant_type,
        "genes": genes,
        "stage": stage,
        "growth_progress": growth_progress,
        "stats": stats,
        "care_cooldowns": care_cooldowns,
        "is_rare": is_rare,
        "rare_type": rare_type
    }

func to_dictionary() -> Dictionary:
    return get_state()
```

```gdscript
# scripts/core/flower.gd
class_name Flower extends Plant
## 花卉类，继承Plant

func _init(type: String = "", genes_override: Dictionary = {}). \
    super(type, genes_override) -> void:
    pass  # 花卉特有逻辑扩展点
```

```gdscript
# scripts/core/succulent.gd
class_name Succulent extends Plant
## 多肉类，继承Plant

func _process_decay(delta: float) -> void:
    # 多肉水分消耗减半
    stats.water = clampf(stats.water - 1.0 * delta / 3600.0, 0.0, 100.0)
    stats.fertilizer = clampf(stats.fertilizer - 0.5 * delta / 3600.0, 0.0, 100.0)
    stats.sunlight = clampf(stats.sunlight - 3.0 * delta / 3600.0, 0.0, 100.0)
```

## 1.5 枚举定义

```gdscript
# scripts/core/enums.gd
class_name Enums

enum FlowerShape {
    POINTED = 0,   # 尖瓣
    ROUND = 1,     # 圆瓣
    SERRATED = 2,  # 锯齿
    FANCY = 3      # 异形
}

enum PlantSize {
    SMALL = 0,
    MEDIUM = 1,
    LARGE = 2
}

enum BloomLength {
    SHORT = 0,
    MEDIUM = 1,
    LONG = 2
}

enum Rarity {
    COMMON = 0,
    UNCOMMON = 1,
    RARE = 2,
    EPIC = 3,
    LEGENDARY = 4
}

enum CareAction {
    WATER = 0,
    FERTILIZE = 1,
    SUNLIGHT = 2,
    PRUNE = 3
}

enum RareFlowerType {
    RAINBOW_ROSE = "rainbow_rose",
    DARK_MANDRAKE = "dark_mandrake",
    GOLDEN_SUNFLOWER = "golden_sunflower",
    MOONLIGHT_LILY = "moonlight_lily",
    ETERNAL_FLOWER = "eternal_flower"
}
```

## 1.6 PlantData 数据表

```gdscript
# scripts/data/plant_data.gd
class_name PlantData

static var PLANT_DATABASE: Dictionary = {
    # === 基础花卉 ===
    "rose_red": {
        "name": "红玫瑰", "category": "flower",
        "base_genes": {"r": 229, "g": 57, "b": 53, "shape": 0, "size": 1, "bloom": 1},
        "growth_time": 54000.0, "seed_price": 10, "sell_price": 10
    },
    "rose_white": {
        "name": "白玫瑰", "category": "flower",
        "base_genes": {"r": 250, "g": 250, "b": 250, "shape": 0, "size": 1, "bloom": 1},
        "growth_time": 54000.0, "seed_price": 10, "sell_price": 10
    },
    "rose_pink": {
        "name": "粉玫瑰", "category": "flower",
        "base_genes": {"r": 244, "g": 143, "b": 177, "shape": 0, "size": 1, "bloom": 1},
        "growth_time": 54000.0, "seed_price": 10, "sell_price": 10
    },
    "tulip_yellow": {
        "name": "黄郁金香", "category": "flower",
        "base_genes": {"r": 253, "g": 216, "b": 53, "shape": 1, "size": 1, "bloom": 1},
        "growth_time": 43200.0, "seed_price": 8, "sell_price": 8
    },
    "tulip_orange": {
        "name": "橙郁金香", "category": "flower",
        "base_genes": {"r": 255, "g": 112, "b": 67, "shape": 1, "size": 1, "bloom": 1},
        "growth_time": 43200.0, "seed_price": 8, "sell_price": 8
    },
    "tulip_purple": {
        "name": "紫郁金香", "category": "flower",
        "base_genes": {"r": 126, "g": 87, "b": 194, "shape": 1, "size": 1, "bloom": 1},
        "growth_time": 43200.0, "seed_price": 8, "sell_price": 8
    },
    "sunflower": {
        "name": "向日葵", "category": "flower",
        "base_genes": {"r": 255, "g": 193, "b": 7, "shape": 0, "size": 2, "bloom": 2},
        "growth_time": 72000.0, "seed_price": 15, "sell_price": 15
    },
    "daisy": {
        "name": "雏菊", "category": "flower",
        "base_genes": {"r": 255, "g": 255, "b": 255, "shape": 1, "size": 0, "bloom": 1},
        "growth_time": 36000.0, "seed_price": 5, "sell_price": 5
    },
    "lavender": {
        "name": "薰衣草", "category": "flower",
        "base_genes": {"r": 149, "g": 117, "b": 205, "shape": 0, "size": 1, "bloom": 1},
        "growth_time": 50400.0, "seed_price": 12, "sell_price": 12
    },
    "lily": {
        "name": "百合", "category": "flower",
        "base_genes": {"r": 255, "g": 235, "b": 238, "shape": 1, "size": 2, "bloom": 1},
        "growth_time": 64800.0, "seed_price": 20, "sell_price": 20
    },
    "carnation": {
        "name": "康乃馨", "category": "flower",
        "base_genes": {"r": 233, "g": 30, "b": 99, "shape": 2, "size": 1, "bloom": 1},
        "growth_time": 57600.0, "seed_price": 15, "sell_price": 15
    },
    "peony": {
        "name": "牡丹", "category": "flower",
        "base_genes": {"r": 248, "g": 187, "b": 208, "shape": 1, "size": 2, "bloom": 2},
        "growth_time": 79200.0, "seed_price": 25, "sell_price": 25
    },
    "sakura": {
        "name": "樱花", "category": "flower",
        "base_genes": {"r": 255, "g": 205, "b": 210, "shape": 1, "size": 1, "bloom": 0},
        "growth_time": 50400.0, "seed_price": 12, "sell_price": 12
    },
    "orchid": {
        "name": "蝴蝶兰", "category": "flower",
        "base_genes": {"r": 206, "g": 147, "b": 216, "shape": 3, "size": 1, "bloom": 1},
        "growth_time": 64800.0, "seed_price": 20, "sell_price": 20
    },
    # === 多肉/仙人掌 ===
    "succulent_001": {
        "name": "观音莲", "category": "succulent",
        "base_genes": {"r": 129, "g": 199, "b": 132, "shape": 1, "size": 0, "bloom": 0},
        "growth_time": 28800.0, "seed_price": 5, "sell_price": 5
    },
    "succulent_002": {
        "name": "玉露", "category": "succulent",
        "base_genes": {"r": 102, "g": 187, "b": 106, "shape": 1, "size": 0, "bloom": 0},
        "growth_time": 36000.0, "seed_price": 8, "sell_price": 8
    },
    "succulent_003": {
        "name": "熊童子", "category": "succulent",
        "base_genes": {"r": 174, "g": 213, "b": 129, "shape": 2, "size": 0, "bloom": 0},
        "growth_time": 43200.0, "seed_price": 10, "sell_price": 10
    },
    "succulent_004": {
        "name": "玉龙观音", "category": "succulent",
        "base_genes": {"r": 77, "g": 182, "b": 172, "shape": 1, "size": 1, "bloom": 0},
        "growth_time": 50400.0, "seed_price": 12, "sell_price": 12
    },
    "cactus": {
        "name": "仙人掌", "category": "succulent",
        "base_genes": {"r": 139, "g": 195, "b": 74, "shape": 0, "size": 1, "bloom": 0},
        "growth_time": 57600.0, "seed_price": 15, "sell_price": 15
    },
    # === 稀有花卉 ===
    "rainbow_rose": {
        "name": "彩虹玫瑰", "category": "rare",
        "base_genes": {"r": 255, "g": 255, "b": 255, "shape": 0, "size": 1, "bloom": 2},
        "growth_time": 54000.0, "seed_price": 0, "sell_price": 75, "is_rare": true
    },
    "dark_mandrake": {
        "name": "暗夜曼陀罗", "category": "rare",
        "base_genes": {"r": 26, "g": 26, "b": 26, "shape": 2, "size": 1, "bloom": 1},
        "growth_time": 54000.0, "seed_price": 0, "sell_price": 80, "is_rare": true
    },
    "golden_sunflower": {
        "name": "金色向日葵", "category": "rare",
        "base_genes": {"r": 255, "g": 215, "b": 0, "shape": 0, "size": 2, "bloom": 2},
        "growth_time": 72000.0, "seed_price": 0, "sell_price": 100, "is_rare": true
    },
    "moonlight_lily": {
        "name": "月光百合", "category": "rare",
        "base_genes": {"r": 192, "g": 192, "b": 192, "shape": 1, "size": 2, "bloom": 1},
        "growth_time": 64800.0, "seed_price": 0, "sell_price": 90, "is_rare": true
    },
    "eternal_flower": {
        "name": "永恒之花", "category": "rare",
        "base_genes": {"r": 255, "g": 255, "b": 255, "shape": 3, "size": 2, "bloom": 2},
        "growth_time": 86400.0, "seed_price": 0, "sell_price": 100, "is_rare": true
    }
}

static func get_data(type: String) -> Dictionary:
    return PLANT_DATABASE.get(type, {})

static func get_name(type: String) -> String:
    return PLANT_DATABASE.get(type, {}).get("name", "未知")

static func get_category(type: String) -> String:
    return PLANT_DATABASE.get(type, {}).get("category", "flower")

static func get_seed_price(type: String) -> int:
    return PLANT_DATABASE.get(type, {}).get("seed_price", 10)

static func get_sell_price(type: String) -> int:
    return PLANT_DATABASE.get(type, {}).get("sell_price", 10)

static func get_all_types() -> Array:
    return PLANT_DATABASE.keys()
```

---

# 2. 场景实现指南

## 2.1 main.tscn

**路径**: `scenes/main.tscn`

### 用途
游戏入口点，负责窗口初始化、Autoload 确认、场景树构建。

### 节点结构
```
main (Node)
├── WindowController (Node)
├── MainPanel (MarginContainer)
├── Overlays (CanvasLayer)
├── ParticleLayer (CanvasLayer)
└── AudioPlayer (AudioStreamPlayer)
```

### 关键实现

```gdscript
# scripts/main.gd
class_name Main extends Node2D

@onready var window_controller: WindowController = $WindowController
@onready var main_panel: MarginContainer = $MainPanel
@onready var overlays: CanvasLayer = $Overlays
@onready var particle_layer: CanvasLayer = $ParticleLayer

var pot_slots: Array[PotSlot] = []
var selected_pot_index: int = -1

func _ready() -> void:
    _verify_autoloads()
    _setup_window()
    _init_pot_slots()
    _connect_eventbus()
    _load_or_new_game()
    _start_auto_save()

func _verify_autoloads() -> void:
    assert(has_node("/root/GameState"), "GameState autoload missing")
    assert(has_node("/root/GeneSystem"), "GeneSystem autoload missing")
    assert(has_node("/root/SaveManager"), "SaveManager autoload missing")
    assert(has_node("/root/AudioManager"), "AudioManager autoload missing")
    assert(has_node("/root/EventBus"), "EventBus autoload missing")

func _setup_window() -> void:
    window_controller.setup_floating_window()

func _init_pot_slots() -> void:
    for i in range(5):
        var slot: PotSlot = main_panel.get_node("ContentArea/PotSlot_%d" % i)
        slot.pot_index = i
        slot.clicked.connect(_on_pot_slot_clicked.bind(i))
        pot_slots.append(slot)

func _on_pot_slot_clicked(index: int) -> void:
    selected_pot_index = index
    var plant: Plant = GameState.get_plant(index)
    if plant != null:
        overlays.open_pot_detail(index, plant)
    else:
        overlays.open_seed_selection(index)

func _load_or_new_game() -> void:
    if SaveManager.has_save():
        SaveManager.load_game()
    else:
        GameState.init_new_game()

func _start_auto_save() -> void:
    var timer := Timer.new()
    timer.autostart = true
    timer.wait_time = 300.0  # 5分钟
    timer.timeout.connect(SaveManager.auto_save)
    add_child(timer)

func _connect_eventbus() -> void:
    EventBus.plant_watered.connect(_on_plant_watered)
    EventBus.plant_fertilized.connect(_on_plant_fertilized)
    EventBus.plant_sunlight.connect(_on_plant_sunlight)
    EventBus.plant_pruned.connect(_on_plant_pruned)
    EventBus.game_saved.connect(_on_game_saved)

func _on_plant_watered(pot_index: int) -> void:
    if pot_index < pot_slots.size():
        particle_layer.show_water_effect(pot_slots[pot_index].global_position)

func _on_plant_fertilized(pot_index: int) -> void:
    if pot_index < pot_slots.size():
        particle_layer.show_fertilizer_effect(pot_slots[pot_index].global_position)

func _on_plant_sunlight(pot_index: int) -> void:
    if pot_index < pot_slots.size():
        particle_layer.show_sunlight_effect(pot_slots[pot_index].global_position)

func _on_plant_pruned(pot_index: int) -> void:
    AudioManager.play_sfx("prune")

func _on_game_saved() -> void:
    pass  # 可选：UI提示存档完成
```

### 窗口初始化逻辑

```gdscript
# scripts/core/window_controller.gd
class_name WindowController extends Node

const MIN_WINDOW_WIDTH := 300
const MAX_WINDOW_WIDTH := 1200
const WINDOW_HEIGHT := 180
const BOTTOM_OFFSET := 0

func setup_floating_window() -> void:
    var screen_size := DisplayServer.screen_size_get(0)
    var screen_width: int = screen_size.x
    var window_width: int = clampi(
        int(screen_width * 0.4),
        MIN_WINDOW_WIDTH,
        MAX_WINDOW_WIDTH
    )
    var window_height: int = WINDOW_HEIGHT
    var window_pos := Vector2i(
        (screen_width - window_width) / 2,
        screen_size.y - window_height - BOTTOM_OFFSET
    )

    DisplayServer.window_set_size(
        Vector2i(window_width, window_height), 0
    )
    DisplayServer.window_set_position(window_pos, 0)
    DisplayServer.window_set_flag(
        DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true
    )
```

## 2.2 ui/main_panel.tscn

**路径**: `scenes/ui/main_panel.tscn`

### 用途
游戏主面板容器，管理 5 个花盆位和底部操作栏。

### 节点结构
```
main_panel (MarginContainer)
├── theme (Theme)
├── custom_constants/margin_left: 8
├── custom_constants/margin_right: 8
├── custom_constants/margin_top: 8
├── custom_constants/margin_bottom: 8
└── VBoxContainer (VBoxContainer)
    ├── ContentArea (HBoxContainer)
    │   ├── PotSlot_0 (PotSlot)
    │   ├── PotSlot_1 (PotSlot)
    │   ├── PotSlot_2 (PotSlot)
    │   ├── PotSlot_3 (PotSlot)
    │   └── PotSlot_4 (PotSlot)
    └── ActionBar (HBoxContainer)
        ├── CareButtons (HBoxContainer)
        │   ├── WaterButton (TextureButton)
        │   ├── FertilizeButton (TextureButton)
        │   ├── SunlightButton (TextureButton)
        │   └── PruneButton (TextureButton)
        ├── Separator (VSeparator)
        └── NavButtons (HBoxContainer)
            ├── EncyclopediaButton (TextureButton)
            ├── ShopButton (TextureButton)
            └── SettingsButton (TextureButton)
```

### 布局规则

| 区域 | 布局方式 | 间距 |
|-----|---------|------|
| ContentArea | HBoxContainer, size_flags_stretch_ratio=1 | 8px |
| PotSlot | custom_minimum_size=80x120, size_flags_*=SIZE_EXPAND | - |
| ActionBar | HBoxContainer | 8px |
| CareButtons | HBoxContainer | 4px |
| NavButtons | HBoxContainer | 8px |

### 响应式行为

```gdscript
# scripts/ui/main_panel.gd
class_name MainPanel extends MarginContainer

@onready var content_area: HBoxContainer = $VBoxContainer/ContentArea
@onready var action_bar: HBoxContainer = $VBoxContainer/ActionBar

func _ready() -> void:
    resized.connect(_on_resized)

func _on_resized() -> void:
    var available_width: float = size.x
    var num_slots: int = 5
    var slot_width: float = (available_width - 8 * 6) / num_slots
    slot_width = clampf(slot_width, 60.0, 140.0)
    for slot in content_area.get_children():
        if slot is PotSlot:
            slot.custom_minimum_size.x = slot_width
```

## 2.3 ui/pot_slot.tscn

**路径**: `scenes/ui/pot_slot.tscn`

### 用途
单个花盆位，显示植物状态、生长阶段，支持点击选择。

### 节点结构
```
pot_slot (PanelContainer)
├── theme_override_styles/panel: StyleBoxFlat
├── SizeFlags: SIZE_EXPAND
├── signal: clicked(pot_index: int)
├── PlantVisual (Node2D)
│   ├── PotSprite (Sprite2D)
│   ├── PlantSprite (AnimatedSprite2D)
│   └── RareGlow (GPUParticles2D)
├── StatusIndicator (HBoxContainer)
│   ├── WaterIcon (TextureRect)
│   ├── WaterBar (TextureProgressBar)
│   ├── StageLabel (Label)
│   └── HealthIcon (TextureRect)
├── EmptyIndicator (Label)
└── HoverHighlight (Panel)
```

### 状态定义

| 状态 | 视觉表现 |
|-----|---------|
| 空盆 (empty) | 显示空盆图标, 深色背景 |
| 有植物 (planted) | 显示植物sprite, stat条 |
| 选中 (selected) | 边框高亮 #4CAF50 |
| 枯萎 (withering) | 植物变灰, 警告图标 |
| 稀有 (rare) | 金色光晕粒子 |

### 交互信号

```gdscript
# scripts/ui/pot_slot.gd
class_name PotSlot extends PanelContainer

signal clicked(pot_index: int)

@export var pot_index: int = 0

@onready var plant_visual: Node2D = $PlantVisual
@onready var plant_sprite: AnimatedSprite2D = $PlantVisual/PlantSprite
@onready var status_indicator: HBoxContainer = $StatusIndicator
@onready var water_bar: TextureProgressBar = $StatusIndicator/WaterBar
@onready var stage_label: Label = $StatusIndicator/StageLabel
@onready var empty_label: Label = $EmptyIndicator
@onready var rare_glow: GPUParticles2D = $PlantVisual/RareGlow

var is_selected: bool = false
var _current_plant: Plant = null

func _ready() -> void:
    mouse_entered.connect(_on_mouse_enter)
    mouse_exited.connect(_on_mouse_exit)
    gui_input.connect(_on_gui_input.bind())
    rare_glow.emitting = false

func _on_gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            clicked.emit(pot_index)

func _on_mouse_enter() -> void:
    modulate = Color(1.1, 1.1, 1.1, 1.0)

func _on_mouse_exit() -> void:
    if not is_selected:
        modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_selected(selected: bool) -> void:
    is_selected = selected

func update_from_plant(plant: Plant = null) -> void:
    _current_plant = plant
    if plant == null:
        _show_empty()
    else:
        _show_plant(plant)

func _show_empty() -> void:
    empty_label.visible = true
    plant_visual.visible = false
    status_indicator.visible = false
    rare_glow.emitting = false

func _show_plant(plant: Plant) -> void:
    empty_label.visible = false
    plant_visual.visible = true
    status_indicator.visible = true

    # Update sprite based on stage
    var stage_frames := _get_stage_sprite_frames(plant.plant_type, plant.stage)
    plant_sprite.sprite_frames = stage_frames
    plant_sprite.play()

    # Update color from genes
    plant_sprite.modulate = plant.get_display_color()

    # Update water bar
    water_bar.value = plant.stats.water

    # Update stage label
    stage_label.text = Plant.Stage.keys()[plant.stage]

    # Rare glow
    rare_glow.emitting = plant.is_rare

func _get_stage_sprite_frames(plant_type: String, stage: int) -> SpriteFrames:
    # Return appropriate sprite frames for the plant type and growth stage
    # This would load from assets/sprites/plants/{type}/stage_{stage}.tres
    return ResourceLoader.load("res://assets/sprites/plants/%s/stage_%d.tres" % [plant_type, stage])
```

## 2.4 ui/action_bar.tscn

**路径**: `scenes/ui/action_bar.tscn`

### 用途
底部工具栏，包含照料按钮（浇水/施肥/晒太阳/修剪）和导航按钮（图鉴/商店/设置）。

### 节点结构
```
action_bar (HBoxContainer)
├── CareButtons (HBoxContainer)
│   ├── WaterButton (TextureButton)
│   │   ├── icon_water.png
│   │   └── signal: pressed
│   ├── FertilizeButton (TextureButton)
│   │   ├── icon_fertilizer.png
│   │   └── signal: pressed
│   ├── SunlightButton (TextureButton)
│   │   ├── icon_sunlight.png
│   │   └── signal: pressed
│   └── PruneButton (TextureButton)
│       ├── icon_prune.png
│       └── signal: pressed
├── Separator (VSeparator)
└── NavButtons (HBoxContainer)
    ├── EncyclopediaButton (TextureButton)
    │   └── signal: pressed
    ├── ShopButton (TextureButton)
    │   └── signal: pressed
    └── SettingsButton (TextureButton)
        └── signal: pressed
```

### 照料按钮逻辑

```gdscript
# scripts/ui/action_bar.gd
class_name ActionBar extends HBoxContainer

@onready var water_btn: TextureButton = $CareButtons/WaterButton
@onready var fertilize_btn: TextureButton = $CareButtons/FertilizeButton
@onready var sunlight_btn: TextureButton = $CareButtons/SunlightButton
@onready var prune_btn: TextureButton = $CareButtons/PruneButton
@onready var encyclopedia_btn: TextureButton = $NavButtons/EncyclopediaButton
@onready var shop_btn: TextureButton = $NavButtons/ShopButton

var selected_pot_index: int = -1

func _ready() -> void:
    water_btn.pressed.connect(_on_water_pressed)
    fertilize_btn.pressed.connect(_on_fertilize_pressed)
    sunlight_btn.pressed.connect(_on_sunlight_pressed)
    prune_btn.pressed.connect(_on_prune_pressed)
    encyclopedia_btn.pressed.connect(_on_encyclopedia_pressed)
    shop_btn.pressed.connect(_on_shop_pressed)
    EventBus.pot_selected.connect(_on_pot_selected)

func set_selected_pot(index: int) -> void:
    selected_pot_index = index
    _update_button_states()

func _on_pot_selected(index: int) -> void:
    set_selected_pot(index)

func _on_water_pressed() -> void:
    if selected_pot_index < 0:
        return
    var plant: Plant = GameState.get_plant(selected_pot_index)
    if plant != null and plant.water():
        EventBus.plant_watered.emit(selected_pot_index, 30)

func _on_fertilize_pressed() -> void:
    if selected_pot_index < 0:
        return
    var plant: Plant = GameState.get_plant(selected_pot_index)
    if plant != null and plant.fertilize():
        EventBus.plant_fertilized.emit(selected_pot_index, 20)

func _on_sunlight_pressed() -> void:
    if selected_pot_index < 0:
        return
    var plant: Plant = GameState.get_plant(selected_pot_index)
    if plant != null and plant.sunlight_boost():
        EventBus.plant_sunlight.emit(selected_pot_index, 50)

func _on_prune_pressed() -> void:
    if selected_pot_index < 0:
        return
    var plant: Plant = GameState.get_plant(selected_pot_index)
    if plant != null and plant.prune():
        EventBus.plant_pruned.emit(selected_pot_index)

func _on_encyclopedia_pressed() -> void:
    get_tree().current_scene.show_encyclopedia()

func _on_shop_pressed() -> void:
    get_tree().current_scene.show_shop()

func _update_button_states() -> void:
    var plant: Plant = GameState.get_plant(selected_pot_index) if selected_pot_index >= 0 else null
    var has_plant: bool = plant != null
    var can_prune: bool = has_plant and plant.stage >= Plant.Stage.MATURE
    var prune_on_cooldown: bool = has_plant and plant.care_cooldowns.prune > 0

    water_btn.disabled = not has_plant
    fertilize_btn.disabled = not has_plant
    sunlight_btn.disabled = not has_plant
    prune_btn.disabled = not can_prune
    if prune_on_cooldown:
        prune_btn.modulate = Color(0.5, 0.5, 0.5, 1.0)
    else:
        prune_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
```

## 2.5 ui/pot_detail.tscn

**路径**: `scenes/ui/pot_detail.tscn`

### 用途
植物详情弹窗，显示选中植物的完整信息、操作按钮。

### 节点结构
```
pot_detail_popup (PopupPanel)
├── CloseButton (TextureButton) # 右上角X
├── Header (HBoxContainer)
│   ├── PlantIcon (Sprite2D)
│   ├── PlantNameLabel (Label)
│   └── LevelLabel (Label)
├── PlantDisplay (Node2D)
│   ├── AnimatedSprite2D
│   └── RareSparkle (GPUParticles2D)
├── StatsContainer (VBoxContainer)
│   ├── WaterRow (HBoxContainer)
│   │   ├── WaterIcon (TextureRect)
│   │   ├── WaterBar (ProgressBar)
│   │   └── WaterValue (Label)
│   ├── FertilizerRow (HBoxContainer)
│   │   ├── FertilizerIcon (TextureRect)
│   │   ├── FertilizerBar (ProgressBar)
│   │   └── FertilizerValue (Label)
│   ├── SunlightRow (HBoxContainer)
│   │   ├── SunlightIcon (TextureRect)
│   │   ├── SunlightBar (ProgressBar)
│   │   └── SunlightValue (Label)
│   └── HealthRow (HBoxContainer)
│       ├── HealthIcon (TextureRect)
│       └── HealthLabel (Label)
├── Separator (HSeparator)
├── InfoSection (VBoxContainer)
│   ├── StageInfo (HBoxContainer)
│   │   ├── StageLabel (Label)
│   │   └── StageProgressBar (ProgressBar)
│   └── GeneInfo (HBoxContainer)
│       ├── GeneLabel (Label)
│       ├── GeneDisplay (HBoxContainer)
│       │   ├── GeneChip_R (ColorRect)
│       │   ├── GeneChip_G (ColorRect)
│       │   ├── GeneChip_B (ColorRect)
│       │   ├── GeneChip_Shape (Label)
│       │   └── GeneChip_Size (Label)
│       └── RareBadge (Label) # 稀有时显示
└── ActionButtons (HBoxContainer)
    ├── BreedButton (Button)
    ├── HarvestButton (Button)
    └── ReleaseButton (Button)
```

### 实现

```gdscript
# scripts/ui/pot_detail.gd
class_name PotDetailPopup extends PopupPanel

@onready var plant_name_label: Label = $Header/PlantNameLabel
@onready var plant_display: Node2D = $PlantDisplay
@onready var water_bar: ProgressBar = $StatsContainer/WaterRow/WaterBar
@onready var water_value: Label = $StatsContainer/WaterRow/WaterValue
@onready var fertilizer_bar: ProgressBar = $StatsContainer/FertilizerRow/FertilizerBar
@onready var sunlight_bar: ProgressBar = $StatsContainer/SunlightRow/SunlightBar
@onready var stage_label: Label = $StatsContainer/StageInfo/StageLabel
@onready var stage_progress: ProgressBar = $StatsContainer/StageInfo/StageProgressBar
@onready var gene_chips: HBoxContainer = $StatsContainer/InfoSection/GeneDisplay
@onready var rare_badge: Label = $StatsContainer/InfoSection/RareBadge
@onready var breed_btn: Button = $ActionButtons/BreedButton
@onready var harvest_btn: Button = $ActionButtons/HarvestButton
@onready var release_btn: Button = $ActionButtons/ReleaseButton

var current_pot_index: int = -1
var current_plant: Plant = null

func open(pot_index: int, plant: Plant) -> void:
    current_pot_index = pot_index
    current_plant = plant
    _update_display()
    _connect_plant_signals()
    popup_centered(Vector2(320, 480))

func _update_display() -> void:
    if current_plant == null:
        return
    var data: Dictionary = PlantData.get_data(current_plant.plant_type)
    plant_name_label.text = data.get("name", "未知")
    _update_stats()
    _update_stage()
    _update_genes()
    _update_actions()

func _update_stats() -> void:
    water_bar.value = current_plant.stats.water
    water_value.text = "%d%%" % int(current_plant.stats.water)
    fertilizer_bar.value = current_plant.stats.fertilizer
    sunlight_bar.value = current_plant.stats.sunlight

func _update_stage() -> void:
    var stage_name := Plant.Stage.keys()[current_plant.stage]
    stage_label.text = "阶段: %s" % stage_name
    if current_plant.stage == Plant.Stage.FLOWERING:
        stage_progress.value = 100.0
    else:
        var duration: float = current_plant.stage_durations[current_plant.stage]
        stage_progress.value = (current_plant.growth_progress / duration) * 100.0 if duration > 0 else 0.0

func _update_genes() -> void:
    # Update gene chip colors
    var r_chip: ColorRect = gene_chips.get_node("GeneChip_R")
    var g_chip: ColorRect = gene_chips.get_node("GeneChip_G")
    var b_chip: ColorRect = gene_chips.get_node("GeneChip_B")
    r_chip.color = Color(current_plant.genes.r / 255.0, 0, 0)
    g_chip.color = Color(0, current_plant.genes.g / 255.0, 0)
    b_chip.color = Color(0, 0, current_plant.genes.b / 255.0)

    var shape_names := ["尖瓣", "圆瓣", "锯齿", "异形"]
    var size_names := ["小", "中", "大"]
    gene_chips.get_node("GeneChip_Shape/Label").text = shape_names[current_plant.genes.shape]
    gene_chips.get_node("GeneChip_Size/Label").text = size_names[current_plant.genes.size]

    if current_plant.is_rare:
        rare_badge.visible = true
        rare_badge.text = "★ %s" % current_plant.rare_type
    else:
        rare_badge.visible = false

func _update_actions() -> void:
    var is_flowering: bool = current_plant.stage == Plant.Stage.FLOWERING
    breed_btn.disabled = not is_flowering
    harvest_btn.disabled = not is_flowering

func _connect_plant_signals() -> void:
    if current_plant != null:
        current_plant.stats_changed.connect(_on_stats_changed)
        current_plant.stage_changed.connect(_on_stage_changed)

func _on_stats_changed(stats: Dictionary) -> void:
    _update_stats()

func _on_stage_changed(stage: int) -> void:
    _update_stage()
    _update_actions()

func _on_breed_pressed() -> void:
    get_tree().current_scene.open_breeding(current_pot_index)

func _on_harvest_pressed() -> void:
    if current_plant == null:
        return
    var seeds := _calculate_seeds()
    GameState.add_seeds(seeds)
    GameState.remove_plant(current_pot_index)
    EventBus.plant_harvested.emit(current_pot_index)
    hide()

func _on_release_pressed() -> void:
    GameState.remove_plant(current_pot_index)
    EventBus.plant_released.emit(current_pot_index)
    hide()

func _calculate_seeds() -> int:
    var base: int = 1
    var luck_mod: int = randi() % 3  # 0-2
    var rare_bonus: int = 2 if current_plant.is_rare else 0
    return base + luck_mod + rare_bonus
```

## 2.6 ui/breeding.tscn

**路径**: `scenes/ui/breeding.tscn`

### 用途
培育界面，选择两个亲本，查看培育预览，执行培育。

### 节点结构
```
breeding_dialog (PopupPanel)
├── TitleLabel (Label)
├── InstructionLabel (Label)
├── ParentSelection (HBoxContainer)
│   ├── ParentASlot (PanelContainer)
│   │   ├── EmptyLabel (Label) # 无选中时
│   │   └── PlantPreview (Node2D) # 选中后
│   ├── PlusSign (Label)
│   └── ParentBSlot (PanelContainer)
│       ├── EmptyLabel (Label)
│       └── PlantPreview (Node2D)
├── PreviewSection (VBoxContainer)
│   ├── DividerLine (HSeparator)
│   ├── PreviewTitle (Label)
│   └── GenePreview (HBoxContainer)
│       ├── ColorPreviewSwatch (ColorRect)
│       ├── InheritedGenesLabel (Label)
│       └── RareProbabilityLabel (Label)
├── ActionButtons (HBoxContainer)
│   ├── StartBreedButton (Button)
│   └── CancelButton (Button)
└── ResultPanel (PanelContainer) # 培育完成后显示
    ├── ResultLabel (Label)
    ├── NewPlantPreview (Node2D)
    ├── IsRareLabel (Label)
    └── ConfirmButton (Button)
```

### 培育逻辑

```gdscript
# scripts/ui/breeding_dialog.gd
class_name BreedingDialog extends PopupPanel

@onready var parent_a_slot: PanelContainer = $ParentSelection/ParentASlot
@onready var parent_b_slot: PanelContainer = $ParentSelection/ParentBSlot
@onready var color_preview: ColorRect = $PreviewSection/GenePreview/ColorPreviewSwatch
@onready var genes_preview_label: Label = $PreviewSection/GenePreview/InheritedGenesLabel
@onready var rare_prob_label: Label = $PreviewSection/GenePreview/RareProbabilityLabel
@onready var start_breed_btn: Button = $ActionButtons/StartBreedButton
@onready var result_panel: PanelContainer = $ResultPanel

var selected_parent_a_pot: int = -1
var selected_parent_b_pot: int = -1
var current_breeding_slot: int = -1  # 培育结果放入哪个花盆

func open(breeding_into_pot: int) -> void:
    current_breeding_slot = breeding_into_pot
    selected_parent_a_pot = -1
    selected_parent_b_pot = -1
    result_panel.visible = false
    start_breed_btn.disabled = true
    _clear_preview()
    popup_centered(Vector2(360, 400))

func _clear_preview() -> void:
    color_preview.color = Color(0.5, 0.5, 0.5)
    genes_preview_label.text = "请选择两个亲本"
    rare_prob_label.text = "稀有概率: --"

func _on_parent_slot_clicked(slot_index: int) -> void:
    if selected_parent_a_pot < 0:
        selected_parent_a_pot = slot_index
    elif selected_parent_b_pot < 0 and slot_index != selected_parent_a_pot:
        selected_parent_b_pot = slot_index
    else:
        return  # 已选满
    _update_preview()

func _update_preview() -> void:
    if selected_parent_a_pot < 0 or selected_parent_b_pot < 0:
        return
    var plant_a: Plant = GameState.get_plant(selected_parent_a_pot)
    var plant_b: Plant = GameState.get_plant(selected_parent_b_pot)
    if plant_a == null or plant_b == null:
        return

    # Preview inherited genes
    var preview_genes := GeneSystem.preview_genes(plant_a.genes, plant_b.genes)
    var r: int = preview_genes.r
    var g: int = preview_genes.g
    var b: int = preview_genes.b
    color_preview.color = Color(r / 255.0, g / 255.0, b / 255.0)
    genes_preview_label.text = "R=%d G=%d B=%d" % [r, g, b]

    # Rare probability
    var rare_prob := GeneSystem.calculate_rare_probability(preview_genes)
    rare_prob_label.text = "稀有概率: %d%%" % int(rare_prob * 100)

    start_breed_btn.disabled = false

func _on_start_breed_pressed() -> void:
    var plant_a: Plant = GameState.get_plant(selected_parent_a_pot)
    var plant_b: Plant = GameState.get_plant(selected_parent_b_pot)
    if plant_a == null or plant_b == null:
        return

    var child_genes: Dictionary = GeneSystem.combine_genes(plant_a.genes, plant_b.genes)
    var rare_type: String = GeneSystem.check_rare_flower(child_genes)
    var is_rare: bool = rare_type != ""

    # Create seed/plant in target pot
    GameState.create_plant_from_breeding(
        current_breeding_slot,
        plant_a.plant_type,
        child_genes,
        is_rare,
        rare_type
    )

    EventBus.plant_bred.emit(
        current_breeding_slot,
        plant_a.plant_type,
        plant_b.plant_type,
        is_rare,
        rare_type
    )

    _show_result(child_genes, is_rare, rare_type)

func _show_result(genes: Dictionary, is_rare: bool, rare_type: String) -> void:
    result_panel.visible = true
    var r: int = genes.r
    var g: int = genes.g
    var b: int = genes.b
    $ResultPanel/NewPlantPreview.modulate = Color(r/255.0, g/255.0, b/255.0)
    if is_rare:
        $ResultPanel/IsRareLabel.text = "★ 稀有: %s ★" % rare_type
        $ResultPanel/IsRareLabel.visible = true
    else:
        $ResultPanel/IsRareLabel.visible = false
```

## 2.7 ui/encyclopedia.tscn

**路径**: `scenes/ui/encyclopedia.tscn`

### 用途
图鉴界面，展示已收集和未解锁的植物条目。

### 节点结构
```
encyclopedia_panel (PopupPanel)
├── Header (HBoxContainer)
│   ├── TitleLabel (Label)
│   ├── ProgressLabel (Label) # "已收集: 12/30"
│   └── CloseButton (TextureButton)
├── FilterTabs (HBoxContainer)
│   ├── AllTab (Button)
│   ├── FlowerTab (Button)
│   ├── SucculentTab (Button)
│   └── RareTab (Button)
├── CollectionGrid (ScrollContainer)
│   └── GridContainer (GridContainer)
│       # 动态生成 EntryCard 子节点
│       └── EntryCard (PanelContainer) × N
│           ├── PlantIcon (Sprite2D)
│           ├── NameLabel (Label)
│           ├── CollectedBadge (Label) # "✓" 或 "🔒"
│           └── HoverPanel (Panel)
└── DetailPanel (PanelContainer) # 选中条目详情
    ├── PlantIcon (Sprite2D)
    ├── NameLabel (Label)
    ├── GeneInfoLabel (Label)
    ├── DescriptionLabel (Label)
    └── UnlockMethodLabel (Label)
```

### 网格布局

| 属性 | 值 |
|-----|------|
| 网格列数 | 4 |
| 卡片尺寸 | 72×90px |
| 卡片间距 | 8px |
| 滚动方向 | 垂直 |

### EntryCard 状态

| 状态 | 视觉 |
|-----|------|
| 已收集 | 正常色彩 + 绿色勾选图标 |
| 未解锁 | 灰度 + 锁定图标 |
| 稀有已解锁 | 正常色彩 + 金色边框 + ★ 图标 |
| 悬停 | 亮度+10%, 显示详情面板 |

```gdscript
# scripts/ui/encyclopedia.gd
class_name EncyclopediaPanel extends PopupPanel

@onready var progress_label: Label = $Header/ProgressLabel
@onready var grid_container: GridContainer = $CollectionGrid/GridContainer
@onready var filter_tabs: HBoxContainer = $FilterTabs
@onready var detail_panel: PanelContainer = $DetailPanel

var all_types: Array = PlantData.get_all_types()
var collected_types: Array = []
var current_filter: String = "all"

func open() -> void:
    collected_types = GameState.get_encyclopedia()
    _update_progress()
    _rebuild_grid()
    popup_centered(Vector2(400, 500))

func _update_progress() -> void:
    progress_label.text = "已收集: %d/%d" % [collected_types.size(), all_types.size()]

func _rebuild_grid() -> void:
    # Clear existing cards
    for child in grid_container.get_children():
        child.queue_free()

    var filtered: Array = _get_filtered_types()
    for plant_type in filtered:
        var card := _create_entry_card(plant_type)
        grid_container.add_child(card)

    # Reflow grid
    grid_container.get_parent().call_deferred("ensure_control_visible", grid_container)

func _get_filtered_types() -> Array:
    match current_filter:
        "flower":
            return all_types.filter(func(t): return PlantData.get_category(t) == "flower")
        "succulent":
            return all_types.filter(func(t): return PlantData.get_category(t) == "succulent")
        "rare":
            return all_types.filter(func(t): return PlantData.get_category(t) == "rare")
        _:
            return all_types

func _create_entry_card(plant_type: String) -> PanelContainer:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(72, 90)
    var data: Dictionary = PlantData.get_data(plant_type)
    var is_collected: bool = collected_types.has(plant_type)

    # Background style
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.2, 0.2, 0.8) if is_collected else Color(0.1, 0.1, 0.1, 0.6)
    style.set_corner_radius_all(6)
    if is_collected and PlantData.get_category(plant_type) == "rare":
        style.border_color = Color(1.0, 0.84, 0.0, 1.0)  # Gold border
        style.border_width_left = 2
    card.add_theme_stylebox_override("panel", style)

    var vbox := VBoxContainer.new()
    card.add_child(vbox)

    var icon := Sprite2D.new()
    if is_collected:
        icon.texture = _load_plant_icon(plant_type)
        icon.modulate = _get_plant_color(plant_type)
    else:
        icon.texture = _load_locked_icon()
        icon.modulate = Color(0.4, 0.4, 0.4)
    icon.scale = Vector2(0.5, 0.5)

    var name_lbl := Label.new()
    name_lbl.text = data.get("name", "???")
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_lbl.add_theme_font_size_override("font_size", 10)

    var badge_lbl := Label.new()
    badge_lbl.text = "✓" if is_collected else "🔒"
    badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    vbox.add_child(icon)
    vbox.add_child(name_lbl)
    vbox.add_child(badge_lbl)

    card.gui_input.connect(_on_card_input.bind(plant_type, card))
    return card

func _on_card_input(event: InputEvent, plant_type: String, card: PanelContainer) -> void:
    if event is InputEventMouseButton and event.pressed:
        _show_detail(plant_type)

func _show_detail(plant_type: String) -> void:
    var data: Dictionary = PlantData.get_data(plant_type)
    detail_panel.get_node("NameLabel").text = data.get("name", "未知")
    detail_panel.get_node("GeneInfoLabel").text = "RGB: %d,%d,%d" % [
        data.base_genes.r, data.base_genes.g, data.base_genes.b
    ]
    var is_collected: bool = collected_types.has(plant_type)
    var desc: String = "已解锁" if is_collected else "未解锁 - 需通过培育获得"
    detail_panel.get_node("DescriptionLabel").text = desc
```

## 2.8 ui/shop.tscn

**路径**: `scenes/ui/shop.tscn`

### 用途
商店界面，购买种子和道具。

### 节点结构
```
shop_panel (PopupPanel)
├── Header (HBoxContainer)
│   ├── TitleLabel (Label)
│   ├── CoinDisplay (HBoxContainer)
│   │   ├── CoinIcon (TextureRect)
│   │   └── CoinLabel (Label)
│   └── CloseButton (TextureButton)
├── ItemCategories (HBoxContainer)
│   ├── SeedsTab (Button)
│   └── ItemsTab (Button)
├── ItemList (ScrollContainer)
│   └── VBoxContainer (VBoxContainer)
│       # 动态生成 ShopItemRow
│       └── ShopItemRow (HBoxContainer) × N
│           ├── ItemIcon (TextureRect)
│           ├── ItemInfo (VBoxContainer)
│           │   ├── ItemName (Label)
│           │   └── ItemDesc (Label)
│           ├── PriceTag (HBoxContainer)
│           │   ├── CoinIcon (TextureRect)
│           │   └── PriceLabel (Label)
│           └── BuyButton (Button)
└── ShopItemRow 模板:
    ├── ItemIcon: 48x48
    ├── ItemName: Label, font_size=14
    ├── ItemDesc: Label, font_size=11, color=#888
    ├── PriceLabel: Label, font_size=13
    └── BuyButton: 60x28, disabled when can't afford
```

### 商店物品数据

| ID | 名称 | 价格 | 类型 |
|----|------|------|------|
| seed_rose_red | 红玫瑰种子 | 10 | seed |
| seed_rose_white | 白玫瑰种子 | 10 | seed |
| seed_rose_pink | 粉玫瑰种子 | 10 | seed |
| seed_tulip_yellow | 黄郁金香种子 | 8 | seed |
| seed_tulip_orange | 橙郁金香种子 | 8 | seed |
| seed_tulip_purple | 紫郁金香种子 | 8 | seed |
| seed_sunflower | 向日葵种子 | 15 | seed |
| seed_daisy | 雏菊种子 | 5 | seed |
| seed_lavender | 薰衣草种子 | 12 | seed |
| seed_lily | 百合种子 | 20 | seed |
| seed_carnation | 康乃馨种子 | 15 | seed |
| seed_peony | 牡丹种子 | 25 | seed |
| seed_sakura | 樱花种子 | 12 | seed |
| seed_orchid | 蝴蝶兰种子 | 20 | seed |
| seed_succulent_001 | 观音莲种子 | 5 | seed |
| seed_succulent_002 | 玉露种子 | 8 | seed |
| seed_succulent_003 | 熊童子种子 | 10 | seed |
| seed_succulent_004 | 玉龙观音种子 | 12 | seed |
| seed_cactus | 仙人掌种子 | 15 | seed |
| item_basic_fertilizer | 基础肥料 | 10 | item |
| item_advanced_fertilizer | 高级肥料 | 50 | item |
| item_growth_hormone | 生长激素 | 30 | item |
| item_rare_catalyst | 稀有催化剂 | 200 | item |

### 购买流程

```gdscript
# scripts/ui/shop.gd
class_name ShopPanel extends PopupPanel

@onready var coin_label: Label = $Header/CoinDisplay/CoinLabel
@onready var item_list: VBoxContainer = $ItemList/VBoxContainer
@onready var seeds_tab: Button = $ItemCategories/SeedsTab
@onready var items_tab: Button = $ItemCategories/ItemsTab

const SHOP_ITEMS: Array[Dictionary] = [
    {"id": "seed_rose_red", "name": "红玫瑰种子", "desc": "经典红色玫瑰",
        "price": 10, "type": "seed", "plant_type": "rose_red"},
    {"id": "seed_rose_white", "name": "白玫瑰种子", "desc": "纯洁白色玫瑰",
        "price": 10, "type": "seed", "plant_type": "rose_white"},
    {"id": "seed_rose_pink", "name": "粉玫瑰种子", "desc": "浪漫粉色玫瑰",
        "price": 10, "type": "seed", "plant_type": "rose_pink"},
    {"id": "seed_tulip_yellow", "name": "黄郁金香种子", "desc": "明亮黄色",
        "price": 8, "type": "seed", "plant_type": "tulip_yellow"},
    {"id": "seed_tulip_orange", "name": "橙郁金香种子", "desc": "活力橙色",
        "price": 8, "type": "seed", "plant_type": "tulip_orange"},
    {"id": "seed_tulip_purple", "name": "紫郁金香种子", "desc": "神秘紫色",
        "price": 8, "type": "seed", "plant_type": "tulip_purple"},
    {"id": "seed_sunflower", "name": "向日葵种子", "desc": "阳光金色",
        "price": 15, "type": "seed", "plant_type": "sunflower"},
    {"id": "seed_daisy", "name": "雏菊种子", "desc": "清新小白花",
        "price": 5, "type": "seed", "plant_type": "daisy"},
    {"id": "seed_lavender", "name": "薰衣草种子", "desc": "宁静淡紫色",
        "price": 12, "type": "seed", "plant_type": "lavender"},
    {"id": "seed_lily", "name": "百合种子", "desc": "优雅大花",
        "price": 20, "type": "seed", "plant_type": "lily"},
    {"id": "seed_carnation", "name": "康乃馨种子", "desc": "温馨之花",
        "price": 15, "type": "seed", "plant_type": "carnation"},
    {"id": "seed_peony", "name": "牡丹种子", "desc": "国色天香",
        "price": 25, "type": "seed", "plant_type": "peony"},
    {"id": "seed_sakura", "name": "樱花种子", "desc": "浪漫粉红",
        "price": 12, "type": "seed", "plant_type": "sakura"},
    {"id": "seed_orchid", "name": "蝴蝶兰种子", "desc": "高贵典雅",
        "price": 20, "type": "seed", "plant_type": "orchid"},
    {"id": "seed_succulent_001", "name": "观音莲种子", "desc": "小巧莲座",
        "price": 5, "type": "seed", "plant_type": "succulent_001"},
    {"id": "seed_succulent_002", "name": "玉露种子", "desc": "晶莹剔透",
        "price": 8, "type": "seed", "plant_type": "succulent_002"},
    {"id": "seed_succulent_003", "name": "熊童子种子", "desc": "萌趣爪形",
        "price": 10, "type": "seed", "plant_type": "succulent_003"},
    {"id": "seed_succulent_004", "name": "玉龙观音种子", "desc": "大气莲座",
        "price": 12, "type": "seed", "plant_type": "succulent_004"},
    {"id": "seed_cactus", "name": "仙人掌种子", "desc": "坚韧生命",
        "price": 15, "type": "seed", "plant_type": "cactus"},
    {"id": "item_basic_fertilizer", "name": "基础肥料", "desc": "肥料+50%",
        "price": 10, "type": "item"},
    {"id": "item_advanced_fertilizer", "name": "高级肥料", "desc": "肥料+100%",
        "price": 50, "type": "item"},
    {"id": "item_growth_hormone", "name": "生长激素", "desc": "加速1小时",
        "price": 30, "type": "item"},
    {"id": "item_rare_catalyst", "name": "稀有催化剂", "desc": "稀有概率+2%",
        "price": 200, "type": "item"}
]

var current_category: String = "seed"

func open() -> void:
    _update_coin_display()
    _rebuild_item_list()
    popup_centered(Vector2(360, 450))

func _update_coin_display() -> void:
    coin_label.text = str(GameState.get_coins())

func _rebuild_item_list() -> void:
    for child in item_list.get_children():
        child.queue_free()

    var filtered: Array = SHOP_ITEMS.filter(
        func(item): return item.type == current_category
    )
    for item in filtered:
        var row := _create_shop_row(item)
        item_list.add_child(row)

func _create_shop_row(item: Dictionary) -> HBoxContainer:
    var row := HBoxContainer.new()
    row.custom_minimum_size.y = 48
    row.alignment = BoxContainer.ALIGNMENT_CENTER

    var icon := TextureRect.new()
    icon.custom_minimum_size = Vector2(40, 40)
    icon.texture = _load_item_icon(item.id)

    var info_vbox := VBoxContainer.new()
    var name_lbl := Label.new()
    name_lbl.text = item.name
    name_lbl.add_theme_font_size_override("font_size", 13)
    var desc_lbl := Label.new()
    desc_lbl.text = item.desc
    desc_lbl.add_theme_font_size_override("font_size", 10)
    desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
    info_vbox.add_child(name_lbl)
    info_vbox.add_child(desc_lbl)

    var price_lbl := Label.new()
    price_lbl.text = str(item.price)
    price_lbl.add_theme_font_size_override("font_size", 13)

    var buy_btn := Button.new()
    buy_btn.text = "购买"
    buy_btn.custom_minimum_size = Vector2(60, 28)
    buy_btn.pressed.connect(_on_buy_pressed.bind(item))

    if GameState.get_coins() < item.price:
        buy_btn.disabled = true

    row.add_child(icon)
    row.add_child(info_vbox)
    row.add_child(price_lbl)
    row.add_child(buy_btn)

    return row

func _on_buy_pressed(item: Dictionary) -> void:
    var price: int = item.price
    if GameState.get_coins() < price:
        return

    GameState.spend_coins(price)

    if item.type == "seed":
        # Add to inventory for planting
        GameState.add_seed_to_inventory(item.plant_type)
    elif item.type == "item":
        _use_item(item.id)

    _update_coin_display()
    AudioManager.play_sfx("purchase")

func _use_item(item_id: String) -> void:
    match item_id:
        "item_basic_fertilizer":
            GameState.apply_global_fertilizer(50.0)
        "item_advanced_fertilizer":
            GameState.apply_global_fertilizer(100.0)
        "item_growth_hormone":
            GameState.apply_global_growth_hormone(3600.0)
        "item_rare_catalyst":
            GameState.increase_rare_chance(0.02)

func _on_seeds_tab_pressed() -> void:
    current_category = "seed"
    seeds_tab.button_pressed = true
    items_tab.button_pressed = false
    _rebuild_item_list()

func _on_items_tab_pressed() -> void:
    current_category = "item"
    seeds_tab.button_pressed = false
    items_tab.button_pressed = true
    _rebuild_item_list()

func _load_item_icon(item_id: String) -> Texture2D:
    var icon_path := "res://assets/sprites/items/%s.png" % item_id
    if ResourceLoader.exists(icon_path):
        return ResourceLoader.load(icon_path)
    return ResourceLoader.load("res://assets/sprites/items/default.png")
```

## 2.9 plants/base_plant.tscn

**路径**: `scenes/plants/base_plant.tscn`

### 用途
植物视觉表现基础场景，包含不同生长阶段的精灵动画。

### 节点结构
```
base_plant (Node2D)
├── PotBase (Sprite2D)  # 固定显示花盆底部
├── PlantBody (AnimatedSprite2D)  # 随阶段变化
│   ├── animations: [seed, sprout, seedling, mature, flowering]
│   └── sprite_frames: SpriteFrames resource
├── Flower (Sprite2D)  # 开花阶段额外显示
├── RareGlow (GPUParticles2D)  # 稀有光效
└── Shadow (Sprite2D)  # 地面阴影
```

### 生长阶段视觉

| 阶段 | 精灵帧 | 动画 |
|-----|--------|------|
| SEED | seed.png | 无动画，埋在土里 |
| SPROUT | sprout_0.png, sprout_1.png | 轻微摇动, 8fps |
| SEEDLING | seedling_0.png, seedling_1.png, seedling_2.png | 生长动画, 8fps |
| MATURE | mature_0.png, mature_1.png | 随风摇摆, 6fps |
| FLOWERING | flower_*.png (按形状变化) | 绽放动画, 10fps |

### 稀有花绽放特效

```gdscript
# scripts/plants/base_plant.gd
class_name BasePlant extends Node2D

@export var plant_type: String = "rose_red"
@export var stage: int = 0

@onready var plant_body: AnimatedSprite2D = $PlantBody
@onready var flower_sprite: Sprite2D = $Flower
@onready var rare_glow: GPUParticles2D = $RareGlow

func setup(type: String, genes: Dictionary, current_stage: int, is_rare: bool) -> void:
    plant_type = type
    _load_sprites_for_type(type)
    set_stage(current_stage)
    _apply_gene_color(genes)
    if is_rare:
        rare_glow.emitting = true
        rare_glow.amount = 30
    else:
        rare_glow.emitting = false

func set_stage(new_stage: int) -> void:
    stage = new_stage
    var anim_name := Plant.Stage.keys()[stage].to_lower()
    if plant_body.sprite_frames and plant_body.sprite_frames.has_animation(anim_name):
        plant_body.play(anim_name)

    # Show flower sprite only at flowering stage
    flower_sprite.visible = (stage == Plant.Stage.FLOWERING)

func _load_sprites_for_type(type: String) -> void:
    var frames_path := "res://assets/sprites/plants/%s/frames.tres" % type
    if ResourceLoader.exists(frames_path):
        plant_body.sprite_frames = ResourceLoader.load(frames_path)

func _apply_gene_color(genes: Dictionary) -> void:
    var col := Color(genes.r / 255.0, genes.g / 255.0, genes.b / 255.0)
    plant_body.modulate = col
    flower_sprite.modulate = col
```

## 2.10 effects/particle_effects.tscn

**路径**: `scenes/effects/particle_effects.tscn`

### 用途
粒子特效层，提供浇水/施肥/阳光粒子效果。

### 节点结构
```
particle_layer (CanvasLayer)
├── WaterEmitter (GPUParticles2D)
│   ├── texture: water_drop.png
│   ├── lifetime: 1.0
│   ├── speed: 100-200
│   ├── gravity: Vector2(0, 300)
│   ├── emission_shape: EMISSION_SHAPE_POINT
│   └── color: #4FC3F7 (浅蓝)
├── FertilizerEmitter (GPUParticles2D)
│   ├── texture: fertilizer_particle.png
│   ├── lifetime: 2.0
│   ├── speed: 20-50
│   ├── gravity: Vector2(0, 50)
│   └── color: #8D6E63 (土棕)
├── SunlightEmitter (GPUParticles2D)
│   ├── texture: light_sparkle.png
│   ├── lifetime: 1.5
│   ├── speed: 30-80
│   ├── gravity: Vector2(0, -100)
│   └── color: #FFF176 (暖黄)
└── RareSparkleEmitter (GPUParticles2D)
    ├── texture: star.png
    ├── lifetime: 3.0
    ├── speed: 50-150
    ├── gravity: Vector2(0, 0)
    ├── color: #FFD700 (金色)
    └── explosion: true
```

### 触发接口

```gdscript
# scripts/effects/particle_layer.gd
class_name ParticleLayer extends CanvasLayer

@onready var water_emitter: GPUParticles2D = $WaterEmitter
@onready var fertilizer_emitter: GPUParticles2D = $FertilizerEmitter
@onready var sunlight_emitter: GPUParticles2D = $SunlightEmitter
@onready var rare_emitter: GPUParticles2D = $RareSparkleEmitter

func _ready() -> void:
    # All emitters start non-emitting, trigger on demand
    water_emitter.emitting = false
    fertilizer_emitter.emitting = false
    sunlight_emitter.emitting = false
    rare_emitter.emitting = false

func show_water_effect(world_position: Vector2) -> void:
    water_emitter.global_position = world_position + Vector2(0, -20)
    water_emitter.emitting = true
    AudioManager.play_sfx("water")
    await get_tree().create_timer(1.5).timeout
    water_emitter.emitting = false

func show_fertilizer_effect(world_position: Vector2) -> void:
    fertilizer_emitter.global_position = world_position + Vector2(0, -10)
    fertilizer_emitter.emitting = true
    AudioManager.play_sfx("fertilizer")
    await get_tree().create_timer(2.0).timeout
    fertilizer_emitter.emitting = false

func show_sunlight_effect(world_position: Vector2) -> void:
    sunlight_emitter.global_position = world_position + Vector2(0, -30)
    sunlight_emitter.emitting = true
    AudioManager.play_sfx("sunlight")
    await get_tree().create_timer(1.5).timeout
    sunlight_emitter.emitting = false

func show_rare_celebration(world_position: Vector2) -> void:
    rare_emitter.global_position = world_position
    rare_emitter.amount = 60
    rare_emitter.emitting = true
    AudioManager.play_sfx("rare_success")
    await get_tree().create_timer(3.0).timeout
    rare_emitter.emitting = false
```

---

# 3. 核心系统详解

## 3.1 GameState (Autoload)

```gdscript
# scripts/autoload/game_state.gd
class_name GameState extends Node

const MAX_POTS := 5
const STARTING_COINS := 100

var _plants: Dictionary = {}  # pot_index -> Plant instance
var _coins: int = STARTING_COINS
var _encyclopedia: Array = []
var _inventory_seeds: Dictionary = {}  # plant_type -> count
var _rare_chance_boost: float = 0.0  # 稀有催化剂加成

func _ready() -> void:
    pass

func init_new_game() -> void:
    _plants.clear()
    _coins = STARTING_COINS
    _encyclopedia.clear()
    _inventory_seeds.clear()
    _rare_chance_boost = 0.0
    EventBus.game_initialized.emit()

func get_plant(pot_index: int) -> Plant:
    return _plants.get(pot_index)

func plant_seed(pot_index: int, plant_type: String) -> bool:
    if _plants.has(pot_index) and _plants[pot_index] != null:
        return false  # Pot already occupied
    if _inventory_seeds.get(plant_type, 0) <= 0:
        return false  # No seeds available

    _inventory_seeds[plant_type] -= 1
    var data: Dictionary = PlantData.get_data(plant_type)
    var genes: Dictionary = data.get("base_genes", {}).duplicate(true)
    var new_plant: Plant = _create_plant_instance(plant_type, genes)
    new_plant.plant_id = _generate_plant_id()
    new_plant.display_name = data.get("name", "未知")
    new_plant.died.connect(_on_plant_died.bind(pot_index))
    _plants[pot_index] = new_plant

    EventBus.plant_planted.emit(pot_index, plant_type)
    return true

func _create_plant_instance(plant_type: String, genes: Dictionary) -> Plant:
    var category: String = PlantData.get_category(plant_type)
    match category:
        "succulent":
            var p := Succulent.new(plant_type, genes)
            return p
        _:
            var p := Flower.new(plant_type, genes)
            return p

func remove_plant(pot_index: int) -> void:
    if _plants.has(pot_index):
        var plant: Plant = _plants[pot_index]
        if plant != null:
            plant.queue_free()
        _plants.erase(pot_index)
        EventBus.plant_removed.emit(pot_index)

func create_plant_from_breeding(pot_index: int, parent_type: String,
        child_genes: Dictionary, is_rare: bool, rare_type: String) -> void:
    var plant := Flower.new(parent_type, child_genes)
    plant.plant_id = _generate_plant_id()
    plant.is_rare = is_rare
    plant.rare_type = rare_type
    plant.died.connect(_on_plant_died.bind(pot_index))
    _plants[pot_index] = plant
    if is_rare:
        EventBus.rare_flower_unlocked.emit(rare_type)

func get_coins() -> int:
    return _coins

func add_coins(amount: int) -> void:
    _coins += amount
    EventBus.coins_changed.emit(_coins)

func spend_coins(amount: int) -> bool:
    if _coins < amount:
        return false
    _coins -= amount
    EventBus.coins_changed.emit(_coins)
    return true

func add_seed_to_inventory(plant_type: String) -> void:
    _inventory_seeds[plant_type] = _inventory_seeds.get(plant_type, 0) + 1
    EventBus.inventory_changed.emit()

func get_seeds_in_inventory(plant_type: String) -> int:
    return _inventory_seeds.get(plant_type, 0)

func get_all_inventory_seeds() -> Dictionary:
    return _inventory_seeds.duplicate()

func add_encyclopedia_entry(plant_type: String) -> void:
    if not _encyclopedia.has(plant_type):
        _encyclopedia.append(plant_type)
        add_coins(20)  # First-time bonus
        EventBus.encyclopedia_updated.emit(plant_type)

func get_encyclopedia() -> Array:
    return _encyclopedia.duplicate()

func get_rare_chance_boost() -> float:
    return _rare_chance_boost

func increase_rare_chance(boost: float) -> void:
    _rare_chance_boost += boost

func apply_global_fertilizer(amount: float) -> void:
    for plant in _plants.values():
        if plant != null:
            plant.stats.fertilizer = clampf(plant.stats.fertilizer + amount, 0.0, 100.0)
            plant.stats_changed.emit(plant.stats)

func apply_global_growth_hormone(seconds: float) -> void:
    for plant in _plants.values():
        if plant != null and plant.stage < Plant.Stage.FLOWERING:
            plant.growth_progress += seconds

func _generate_plant_id() -> String:
    return "plant_%d_%d" % [Time.get_unix_time_from_system(), randi() % 10000]

func _on_plant_died(pot_index: int) -> void:
    EventBus.plant_died.emit(pot_index)
    remove_plant(pot_index)

func save_state() -> Dictionary:
    var pots_data: Array = []
    for i in range(MAX_POTS):
        if _plants.has(i) and _plants[i] != null:
            pots_data.append({
                "id": i,
                "plant_data": _plants[i].to_dictionary()
            })
        else:
            pots_data.append({"id": i, "plant_data": null})
    return {
        "version": "1.0",
        "last_save": Time.get_datetime_string_from_system(),
        "coins": _coins,
        "encyclopedia": _encyclopedia,
        "inventory_seeds": _inventory_seeds,
        "rare_chance_boost": _rare_chance_boost,
        "pots": pots_data
    }

func load_state(data: Dictionary) -> void:
    _coins = data.get("coins", STARTING_COINS)
    _encyclopedia = data.get("encyclopedia", [])
    _inventory_seeds = data.get("inventory_seeds", {})
    _rare_chance_boost = data.get("rare_chance_boost", 0.0)
    _plants.clear()
    for pot_entry in data.get("pots", []):
        var idx: int = pot_entry.id
        var plant_data: Dictionary = pot_entry.get("plant_data")
        if plant_data != null:
            var plant := _reconstruct_plant(plant_data)
            if plant != null:
                _plants[idx] = plant
```

## 3.2 GeneSystem (Autoload)

```gdscript
# scripts/autoload/gene_system.gd
class_name GeneSystem extends Node

const BASE_MUTATION_CHANCE := 0.05
const MUTATION_RANGE := 20

func combine_genes(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
    var child: Dictionary = {}

    # Color genes - Mendelian inheritance
    child.r = _inherit_color_gene(parent_a.r, parent_b.r)
    child.g = _inherit_color_gene(parent_a.g, parent_b.g)
    child.b = _inherit_color_gene(parent_a.b, parent_b.b)

    # Shape gene - dominant优先
    child.shape = _inherit_shape_gene(parent_a.shape, parent_b.shape)

    # Size gene - quantitative trait with regression to mean
    child.size = _inherit_size_gene(parent_a.size, parent_b.size)

    # Bloom gene - quantitative trait
    child.bloom = _inherit_bloom_gene(parent_a.bloom, parent_b.bloom)

    # Apply mutation
    var mutation_chance := BASE_MUTATION_CHANCE + GameState.get_rare_chance_boost()
    if randf() < mutation_chance:
        child = _apply_mutations(child)

    return child

func _inherit_color_gene(a: int, b: int) -> int:
    return a if randf() < 0.5 else b

func _inherit_shape_gene(a: int, b: int) -> int:
    # Dominant shapes: 0 (pointed), 1 (round) are dominant over 2, 3
    var dom_a: bool = a <= 1
    var dom_b: bool = b <= 1
    if dom_a and dom_b:
        return a if randf() < 0.5 else b
    elif dom_a or dom_b:
        return a if dom_a else b
    else:
        return a if randf() < 0.5 else b  # Both recessive

func _inherit_size_gene(a: int, b: int) -> int:
    var base := float(a + b) / 2.0
    var offset := randi_range(-1, 1)
    return clampi(int(base) + offset, 0, 2)

func _inherit_bloom_gene(a: int, b: int) -> int:
    var base := float(a + b) / 2.0
    var offset := randi_range(-1, 1)
    return clampi(int(base) + offset, 0, 2)

func _apply_mutations(genes: Dictionary) -> Dictionary:
    genes.r = _mutate_gene(genes.r, 0, 255)
    genes.g = _mutate_gene(genes.g, 0, 255)
    genes.b = _mutate_gene(genes.b, 0, 255)
    if randf() < 0.2:  # 20% chance shape mutates
        genes.shape = clampi(genes.shape + randi_range(-1, 1), 0, 3)
    if randf() < 0.2:
        genes.size = clampi(genes.size + randi_range(-1, 1), 0, 2)
    if randf() < 0.2:
        genes.bloom = clampi(genes.bloom + randi_range(-1, 1), 0, 2)
    return genes

func _mutate_gene(value: int, min_val: int, max_val: int) -> int:
    var offset := randi_range(-MUTATION_RANGE, MUTATION_RANGE)
    return clampi(value + offset, min_val, max_val)

func check_rare_flower(genes: Dictionary) -> String:
    # Rainbow Rose: all RGB > 200
    if genes.r > 200 and genes.g > 200 and genes.b > 200:
        return "rainbow_rose"
    # Dark Mandrake: all RGB < 50
    if genes.r < 50 and genes.g < 50 and genes.b < 50:
        return "dark_mandrake"
    # Golden Sunflower: high R, high G, low B
    if genes.r > 200 and genes.g > 180 and genes.b < 50:
        return "golden_sunflower"
    # Moonlight Lily: low R, high G, high B
    if genes.r < 50 and genes.g > 200 and genes.b > 200:
        return "moonlight_lily"
    # Eternal Flower: all extreme (all high OR all low)
    var all_high := genes.r > 200 and genes.g > 200 and genes.b > 200
    var all_low := genes.r < 50 and genes.g < 50 and genes.b < 50
    if all_high or all_low:
        return "eternal_flower"
    return ""

func calculate_rare_probability(genes: Dictionary) -> float:
    var base := BASE_MUTATION_CHANCE + GameState.get_rare_chance_boost()
    # Increase probability if genes are already near rare thresholds
    var near_rainbow := (genes.r > 180 and genes.g > 180 and genes.b > 180)
    var near_dark := (genes.r < 80 and genes.g < 80 and genes.b < 80)
    if near_rainbow or near_dark:
        base += 0.02
    return minf(base, 0.15)

func preview_genes(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
    # Preview what genes might result (without mutation)
    var preview: Dictionary = {}
    preview.r = parent_a.r if randf() < 0.5 else parent_b.r
    preview.g = parent_a.g if randf() < 0.5 else parent_b.g
    preview.b = parent_a.b if randf() < 0.5 else parent_b.b
    preview.shape = parent_a.shape if randf() < 0.5 else parent_b.shape
    preview.size = int((parent_a.size + parent_b.size) / 2.0)
    preview.bloom = int((parent_a.bloom + parent_b.bloom) / 2.0)
    return preview
```

## 3.3 SaveManager (Autoload)

```gdscript
# scripts/autoload/save_manager.gd
class_name SaveManager extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := "1.0"

var _is_saving: bool = false

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func auto_save() -> void:
    if _is_saving:
        return
    save_game()

func save_game() -> void:
    _is_saving = true
    var save_data: Dictionary = GameState.save_state()
    save_data.version = SAVE_VERSION
    save_data.last_save = Time.get_datetime_string_from_system()

    var json_str := JSON.stringify(save_data, "\t")
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(json_str)
        file.close()
        EventBus.game_saved.emit()
    _is_saving = false

func load_game() -> bool:
    if not has_save():
        return false

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("Failed to open save file")
        return false

    var json_str := file.get_as_text()
    file.close()

    var json := JSON.new()
    var parse_result := json.parse(json_str)
    if parse_result != OK:
        push_error("Failed to parse save JSON")
        return false

    var data: Dictionary = json.data
    var save_version: String = data.get("version", "0.0")

    # Migration if needed
    if save_version != SAVE_VERSION:
        data = _migrate_save(data, save_version)

    GameState.load_state(data)
    EventBus.game_loaded.emit()
    return true

func _migrate_save(data: Dictionary, from_version: String) -> Dictionary:
    # Placeholder for future migrations
    # Example: if from_version == "0.9": data = _migrate_0_9_to_1_0(data)
    return data

func delete_save() -> void:
    if has_save():
        DirAccess.remove_absolute(SAVE_PATH)
```

## 3.4 EventBus (Autoload)

```gdscript
# scripts/autoload/event_bus.gd
class_name EventBus extends Node

# Plant lifecycle
signal plant_planted(pot_index: int, plant_type: String)
signal plant_removed(pot_index: int)
signal plant_died(pot_index: int)
signal plant_harvested(pot_index: int)
signal plant_released(pot_index: int)

# Care actions
signal plant_watered(pot_index: int, amount: float)
signal plant_fertilized(pot_index: int, amount: float)
signal plant_sunlight(pot_index: int, amount: float)
signal plant_pruned(pot_index: int)

# Breeding
signal plant_bred(pot_index: int, parent_a_type: String, parent_b_type: String,
                   is_rare: bool, rare_type: String)

# Rare flowers
signal rare_flower_unlocked(rare_type: String)

# UI state
signal pot_selected(pot_index: int)
signal encyclopedia_updated(plant_type: String)
signal inventory_changed()
signal coins_changed(new_amount: int)

# Game lifecycle
signal game_initialized()
signal game_saved()
signal game_loaded()
```

## 3.5 AudioManager (Autoload)

```gdscript
# scripts/autoload/audio_manager.gd
class_name AudioManager extends Node

@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

var _sfx_volume: float = 0.8
var _bgm_volume: float = 0.6
var _current_bgm: String = ""

func _ready() -> void:
    sfx_player.volume_db = linear_to_db(_sfx_volume)
    bgm_player.volume_db = linear_to_db(_bgm_volume)

func play_sfx(sfx_name: String) -> void:
    var path := "res://assets/audio/sfx/%s.wav" % sfx_name
    if ResourceLoader.exists(path):
        var stream: AudioStream = ResourceLoader.load(path)
        sfx_player.stream = stream
        sfx_player.play()
    else:
        push_warning("SFX not found: %s" % sfx_name)

func play_bgm(bgm_name: String, loop: bool = true) -> void:
    if _current_bgm == bgm_name:
        return
    var path := "res://assets/audio/bgm/%s.ogg" % bgm_name
    if ResourceLoader.exists(path):
        var stream: AudioStream = ResourceLoader.load(path)
        bgm_player.stream = stream
        bgm_player.bus = "BGM"
        bgm_player.play()
        _current_bgm = bgm_name

func set_sfx_volume(volume: float) -> void:
    _sfx_volume = clampf(volume, 0.0, 1.0)
    sfx_player.volume_db = linear_to_db(_sfx_volume)

func set_bgm_volume(volume: float) -> void:
    _bgm_volume = clampf(volume, 0.0, 1.0)
    bgm_player.volume_db = linear_to_db(_bgm_volume)
```

---

# 4. UI/UX 设计规范

## 4.1 色彩系统

| 用途 | 颜色名 | Hex | RGB | 使用场景 |
|-----|--------|-----|-----|---------|
| 主色 | Primary Green | #4CAF50 | 76,175,80 | 按钮、选中态、进度条 |
| 辅助色 | Soil Brown | #8D6E63 | 141,110,99 | 花盆、泥土图标 |
| 强调色 | Petal Pink | #F48FB1 | 244,143,177 | 稀有花、特殊提示 |
| 背景色 | Semi-White | #FFFFFF80 | 255,255,255,50% | 面板背景 |
| 深背景 | Dark Panel | #2D2D2DCC | 45,45,45,80% | 弹窗背景 |
| 文字主色 | Text Dark | #424242 | 66,66,66 | 正文 |
| 文字次色 | Text Light | #757575 | 117,117,117 | 辅助说明 |
| 稀有金 | Rare Gold | #FFD700 | 255,215,0 | 稀有花边框、光效 |
| 稀有暗紫 | Rare Purple | #4A148C | 74,20,140 | 暗夜曼陀罗主色 |
| 水蓝 | Water Blue | #4FC3F7 | 79,195,247 | 水分条、浇水效果 |
| 肥料棕 | Fertilizer Brown | #8D6E63 | 141,110,99 | 肥料条 |
| 阳光黄 | Sunlight Yellow | #FFF176 | 255,241,118 | 阳光条、阳光效果 |
| 危险红 | Warning Red | #EF5350 | 239,83,80 | 枯萎、危险提示 |
| 成功绿 | Success Green | #66BB6A | 102,187,106 | 成功、收获 |

## 4.2 字体规范

| 用途 | 字体 | 大小 | 字重 | 行高 |
|-----|------|------|------|------|
| 主标题 | Noto Sans SC / Source Han Sans | 18px | Bold (700) | 1.4 |
| 副标题 | Noto Sans SC | 15px | Medium (500) | 1.4 |
| 正文 | Noto Sans SC | 13px | Regular (400) | 1.5 |
| 辅助文字 | Noto Sans SC | 11px | Regular (400) | 1.4 |
| 数字显示 | JetBrains Mono / Roboto Mono | 14px | Regular (400) | 1.2 |
| 按钮文字 | Noto Sans SC | 13px | Medium (500) | 1.0 |
| 标签文字 | Noto Sans SC | 11px | Medium (500) | 1.0 |

> **中文字体备选**: 系统默认无衬线字体 fallback chain:
> `"Noto Sans SC", "Source Han Sans SC", "Microsoft YaHei", "PingFang SC", "sans-serif"`

## 4.3 间距系统

基础单位: **4px**

| Token | 值 | 使用场景 |
|-------|-----|---------|
| spacing-xs | 4px | 图标与标签间距 |
| spacing-sm | 8px | 卡片内元素间距 |
| spacing-md | 12px | 列表项间距 |
| spacing-lg | 16px | 面板内分组间距 |
| spacing-xl | 24px | 区块之间间距 |
| spacing-xxl | 32px | 大区块之间间距 |

### 花盆网格间距
- 花盆之间: 8px (spacing-sm)
- 花盆内边距: 4px (spacing-xs)
- 操作栏按钮间距: 4px (spacing-xs)

### 弹窗间距
- 弹窗外边距: 16px (spacing-lg)
- 弹窗内分组间距: 12px (spacing-md)
- 弹窗内元素间距: 8px (spacing-sm)

## 4.4 动画规范

### 全局动画参数

| 属性 | 默认值 |
|-----|--------|
| 持续时间-短 | 150ms |
| 持续时间-中 | 250ms |
| 持续时间-长 | 400ms |
| 缓动函数-默认 | EASE_OUT |
| 缓动函数-强调 | EASE_IN_OUT |
| 缓动函数-弹性 | EASE_ELASTIC |

### 具体动画定义

| 动画名 | 对象 | 类型 | 持续时间 | 缓动 | 说明 |
|--------|------|------|---------|------|------|
| panel_popup | PopupPanel | scale 0.8→1.0 + fade | 250ms | ease_out | 弹窗出现 |
| panel_close | PopupPanel | scale 1.0→0.9 + fade | 150ms | ease_in | 弹窗关闭 |
| button_hover | TextureButton | modulate 1.0→1.1 | 150ms | ease_out | 按钮悬停 |
| button_press | TextureButton | scale 1.0→0.95→1.0 | 150ms | ease_out | 按钮按下 |
| stat_bar_fill | ProgressBar | value 插值 | 300ms | ease_out | 属性条变化 |
| plant_stage_up | AnimatedSprite2D | 播放下一阶段动画 | 500ms | - | 生长阶段提升 |
| water_splash | GPUParticles2D | emitting=true, lifetime | 1000ms | - | 浇水粒子 |
| rare_sparkle | GPUParticles2D | emitting=true, 爆发 | 3000ms | - | 稀有花光效 |
| pot_slot_select | PanelContainer | border_color → primary | 150ms | ease_out | 花盆选中 |
| coin_increase | Label | scale 1.0→1.2→1.0 | 300ms | ease_elastic | 金币增加 |
| harvest_pop | Node2D | scale 1.0→1.3→0 | 400ms | ease_out | 收获弹出 |

### 粒子效果参数

| 粒子类型 | 数量 | 初始速度 | 重力 | 生命周期 | 颜色 |
|---------|------|---------|------|---------|------|
| 浇水 | 20 | 100-200 px/s | 300 px/s² (向下) | 1.0s | #4FC3F7 |
| 施肥 | 15 | 20-50 px/s | 50 px/s² | 2.0s | #8D6E63 |
| 阳光 | 30 | 30-80 px/s | -100 px/s² (向上) | 1.5s | #FFF176 |
| 稀有金光 | 60 | 50-150 px/s | 0 | 3.0s | #FFD700 |

## 4.5 按钮状态

### 状态定义

| 状态 | transform | modulate | 可见性 |
|------|-----------|----------|--------|
| Normal | scale(1.0) | (1,1,1,1) | 全部 |
| Hover | scale(1.05) | (1.1,1.1,1.1,1) | 全部 |
| Pressed | scale(0.95) | (0.95,0.95,0.95,1) | 全部 |
| Disabled | scale(1.0) | (0.5,0.5,0.5,1) | 全部 |

### 状态转换触发

- **Hover**: `mouse_entered` 信号 → 150ms动画过渡
- **Press**: `gui_input` 捕获 `InputEventMouseButton` (pressed=true) → 立即
- **Disabled**: `disabled = true` 属性 → 立即应用灰度

## 4.6 交互反馈

### 照料按钮点击反馈

| 操作 | 视觉反馈 | 音频反馈 | 逻辑反馈 |
|------|---------|---------|---------|
| 浇水 | 水滴粒子喷溅 | water.wav | stats.water += 30 |
| 施肥 | 施肥粒子飘落 | fertilizer.wav | stats.fertilizer += 20, 12h冷却 |
| 晒太阳 | 光斑闪烁 | sunlight.wav | stats.sunlight += 50 |
| 修剪 | 叶片飘落 | prune.wav | stats.health += 30, 24h冷却 |

### 花盆选中反馈

1. 点击空盆 → 边框高亮(#4CAF50) + 打开种子选择弹窗
2. 点击有植物的花盆 → 边框高亮 + 打开植物详情弹窗
3. 选中时再次点击 → 取消选中 + 关闭详情

## 4.7 无障碍设计

| 考虑因素 | 实现方案 |
|---------|---------|
| 键盘导航 | 所有按钮支持 `focus_mode = FOCUS_ALL`, Tab键切换 |
| 焦点指示 | Focus阶段: 2px虚线边框 #4CAF50 |
| 屏幕阅读器 | 按钮 `tooltip_text` 设置文字描述 |
| 颜色对比 | 正文与背景对比度 ≥ 4.5:1 |
| 字号可缩放 | 使用 `add_theme_font_size_override` 允许系统字号 |
| 动画减少 | 提供"减少动画"选项，关闭非必要动画 |
| 音效替代 | 重要操作同时有视觉提示 |

---

# 5. 游戏数值平衡

## 5.1 生长时间表

| 阶段 | 英文名 | 时长(秒) | 时长(小时) | 累计时长 |
|-----|--------|---------|-----------|---------|
| 种子 | SEED | 3,600 | 1h | 1h |
| 发芽 | SPROUT | 7,200 | 2h | 3h |
| 幼苗 | SEEDLING | 14,400 | 4h | 7h |
| 成株 | MATURE | 28,800 | 8h | 15h |
| 开花 | FLOWERING | 永久 | - | - |

### 各植物总生长时间

| 植物 | 种子→开花总时长 | 对应天数(游戏内) |
|-----|----------------|----------------|
| 观音莲 | 28,800s (8h) | 最快 |
| 雏菊 | 36,000s (10h) | |
| 黄/橙/紫郁金香 | 43,200s (12h) | |
| 熊童子 | 43,200s (12h) | |
| 樱花/薰衣草 | 50,400s (14h) | |
| 粉/白/红玫瑰 | 54,000s (15h) | |
| 康乃馨 | 57,600s (16h) | |
| 仙人掌 | 57,600s (16h) | |
| 百合/蝴蝶兰 | 64,800s (18h) | |
| 向日葵 | 72,000s (20h) | |
| 牡丹 | 79,200s (22h) | |
| 永恒之花 | 86,400s (24h) | 最慢 |

## 5.2 属性消耗率 (每小时)

| 属性 | 基础消耗/h | 多肉消耗/h | 说明 |
|------|-----------|-----------|------|
| 水分 | -2.0 | -1.0 | 多肉减半 |
| 肥料 | -1.0 | -0.5 | 多肉减半 |
| 阳光 | -3.0 | -3.0 | 不变 |

### 照料操作效果

| 操作 | 恢复量 | 冷却时间 | 备注 |
|------|--------|---------|------|
| 浇水 | +30% | 即时 (0s) | 可连续使用 |
| 施肥(基础) | +20% | 12小时 | |
| 施肥(高级) | +50% | 12小时 | |
| 晒太阳 | +50% | 即时 (0s) | |
| 生长激素 | 加速1小时 | 即时 | 不加属性 |
| 稀有催化剂 | +2%稀有概率 | 即时 | 本次培育 |
| 修剪 | +30%健康 | 24小时 | 仅成株/开花 |

### 生长需求阈值

| 阶段 | 水分要求 | 肥料要求 | 阳光要求 |
|-----|---------|---------|---------|
| 种子 | >20% | - | - |
| 发芽 | >30% | - | >20% |
| 幼苗 | >40% | >10% | - |
| 成株 | >50% | >50% | >50% |
| 开花 | >30% | >30% | >30% |

### 生长速度倍率

| 条件 | 倍率 |
|------|------|
| 全部属性 >50% | ×1.1 (加速10%) |
| 任意属性 <20% | ×0.0 (停滞) |
| 正常条件 | ×1.0 |

### 健康度计算

| 条件 | 每秒健康损失 |
|------|------------|
| 任意属性 <10% | -0.5 |
| 全部属性 >50% | +0.1 (恢复) |
| 正常状态 | 0 |
| 健康=0时 | 植物死亡 |

## 5.3 货币经济

### 金币获取

| 途径 | 数量 | 备注 |
|------|------|------|
| 初始赠送 | 100 | 新游戏 |
| 收获普通花卉 | 5-15 | 随机 |
| 收获稀有花卉 | 50-100 | 随机 |
| 首次图鉴解锁 | +20 | 每种仅首次 |
| 每日登录奖励 | 10 | 每日一次 |

### 金币消耗

| 物品 | 价格 | 备注 |
|------|------|------|
| 种子(雏菊) | 5 | 最便宜 |
| 种子(玫瑰系) | 10 | 基础价格 |
| 种子(向日葵) | 15 | |
| 种子(牡丹) | 25 | 最贵种子 |
| 基础肥料 | 10 | |
| 高级肥料 | 50 | |
| 生长激素 | 30 | |
| 稀有催化剂 | 200 | |

### 经济平衡建议

- 每小时自然消耗: 约6金币价值 (2水+1肥+3阳光 → 若折算)
- 普通花卉收获: 5-15金币
- 稀有花卉收获: 50-100金币
- 每日维持: 约144金币 (24小时 × 6/h)
- 建议每日收益: 30-50金币 (不肝)

## 5.4 稀有花概率

| 稀有花 | 基础概率 | 催化剂加成后 | 基因条件 |
|-------|---------|-------------|---------|
| 彩虹玫瑰 | 5% | 7% | R>200, G>200, B>200 |
| 暗夜曼陀罗 | 5% | 7% | R<50, G<50, B<50 |
| 金色向日葵 | 5% | 7% | R>200, G>180, B<50 |
| 月光百合 | 5% | 7% | R<50, G>200, B>200 |
| 永恒之花 | 5% | 7% | 全部极高或极低 |

> **注**: 稀有概率在基因突变阶段生效，而非培育开始时。
> 使用稀有催化剂后，本次基因突变概率+2%，累加到现有概率。

---

# 6. 资源管线

## 6.1 精灵图集 (Sprite Sheets)

### 植物精灵表

每种植物需要以下精灵:

| 文件名格式 | 内容 | 帧数 | 尺寸 |
|-----------|------|------|------|
| `plants/{type}/seed.png` | 种子埋在土中 | 1 | 64×64 |
| `plants/{type}/sprout_*.png` | 发芽,出土 | 2 | 64×64 |
| `plants/{type}/seedling_*.png` | 幼苗,2-3片叶 | 3 | 64×64 |
| `plants/{type}/mature_*.png` | 成株,完整但未开花 | 2 | 64×64 |
| `plants/{type}/flower_*.png` | 开花,按shape基因变化 | 3 | 64×64 |
| `plants/{type}/withered.png` | 枯萎状态 | 1 | 64×64 |

> `*` 表示帧序号 (0, 1, 2...)

### 花瓣形状精灵变体

同一植物的不同花瓣形状 (由 shape 基因决定):

| 形状值 | 名称 | 花朵精灵后缀 |
|-------|------|------------|
| 0 | POINTED (尖瓣) | `_pointed` |
| 1 | ROUND (圆瓣) | `_round` |
| 2 | SERRATED (锯齿) | `_serrated` |
| 3 | FANCY (异形) | `_fancy` |

所以 `flower_rose_red_pointed.png` = 红玫瑰尖瓣花朵。

### UI 精灵

| 文件 | 尺寸 | 格式 |
|------|------|------|
| `ui/pot_slot_bg.png` | 80×120 | 半透明圆角矩形 |
| `ui/empty_pot.png` | 60×60 | 空盆占位图 |
| `ui/btn_water.png` | 40×40 | 浇水按钮图标 |
| `ui/btn_fertilizer.png` | 40×40 | 施肥按钮图标 |
| `ui/btn_sunlight.png` | 40×40 | 晒太阳按钮图标 |
| `ui/btn_prune.png` | 40×40 | 修剪按钮图标 |
| `ui/btn_encyclopedia.png` | 40×40 | 图鉴按钮图标 |
| `ui/btn_shop.png` | 40×40 | 商店按钮图标 |
| `ui/btn_settings.png` | 40×40 | 设置按钮图标 |
| `ui/icon_water_bar.png` | 16×16 | 水分图标 |
| `ui/icon_sun_bar.png` | 16×16 | 阳光图标 |
| `ui/icon_fertilizer_bar.png` | 16×16 | 肥料图标 |
| `ui/icon_health.png` | 16×16 | 健康图标 |
| `ui/coin_icon.png` | 24×24 | 金币图标 |

### 粒子精灵

| 文件 | 尺寸 | 说明 |
|------|------|------|
| `effects/water_drop.png` | 16×16 | 水滴,蓝白色 |
| `effects/fertilizer_powder.png` | 12×12 | 肥料颗粒,棕褐色 |
| `effects/light_sparkle.png` | 16×16 | 光斑,暖黄色 |
| `effects/rare_star.png` | 24×24 | 稀有金光,金色 |

## 6.2 动画规格

### 植物生长动画

| 阶段 | 文件 | fps | 帧数 | 循环 | 过渡方式 |
|------|------|-----|------|------|---------|
| 发芽 | sprout_*.png | 4 | 2 | 否 | 播放一次 |
| 幼苗 | seedling_*.png | 6 | 3 | 是 | 循环 |
| 成株 | mature_*.png | 4 | 2 | 是 | 循环 |
| 开花绽放 | flower_*.png | 8 | 3 | 否 | 播放一次后停留末帧 |

### UI 动画

| 动画名 | 目标 | 属性 | 起始值 | 结束值 | 时长 | 缓动 |
|--------|------|------|--------|--------|------|------|
| popup_in | PopupPanel | scale + opacity | 0.8, 0 | 1.0, 1 | 250ms | ease_out |
| popup_out | PopupPanel | scale + opacity | 1.0, 1 | 0.9, 0 | 150ms | ease_in |
| button_bounce | Button | scale | 1.0 | 1.1 | 200ms | ease_elastic |
| coin_pop | Label | scale | 1.0 | 1.3 | 300ms | ease_elastic |

## 6.3 音效清单

### 音效文件要求

| 格式 | 采样率 | 声道 | 建议时长 |
|------|--------|------|---------|
| WAV | 48kHz | 单声道 | <2s (SFX) |
| OGG | 48kHz | 立体声 | <5min (BGM) |

### SFX 列表

| 事件 | 文件名 | 建议时长 | 描述 |
|------|--------|---------|------|
| 浇水 | `water.wav` | 0.5s | 清脆水滴声 |
| 施肥 | `fertilizer.wav` | 0.8s | 沙沙声 |
| 晒太阳 | `sunlight.wav` | 0.4s | 温暖光效声 |
| 修剪 | `prune.wav` | 0.6s | 剪切/咔嚓声 |
| 收获 | `harvest.wav` | 1.0s | 采摘成功音效 |
| 购买 | `purchase.wav` | 0.5s | 确认购买音效 |
| 培育成功 | `breed_success.wav` | 1.5s | 培育完成叮咚 |
| 稀有成功 | `rare_success.wav` | 2.0s | 特殊旋律+金光 |
| 按钮点击 | `click.wav` | 0.1s | 通用点击 |
| 弹窗打开 | `popup_open.wav` | 0.2s | 轻微弹出音 |
| 弹窗关闭 | `popup_close.wav` | 0.15s | 轻微收回音 |
| 植物死亡 | `plant_die.wav` | 1.2s | 枯萎/消失音效 |
| 种子种下 | `plant_seed.wav` | 0.4s | 埋入土中音效 |
| 生长阶段提升 | `growth_stage.wav` | 0.8s | 生长音效 |

### BGM 列表

| 场景 | 文件名 | 建议时长 | 风格 |
|------|--------|---------|------|
| 主界面循环 | `bgm_main.ogg` | 60-90s | 轻柔自然音乐 |
| 培育界面 | `bgm_breeding.ogg` | 循环 | 期待感、神秘感 |
| 稀有花出现 | `bgm_rare.ogg` | 30s | 特殊旋律(不使用循环) |

> BGM 音量默认60%，可由玩家调节。
> SFX 音量默认80%。

## 6.4 字体资源

| 用途 | 字体文件名 | 字重 | 包含字符集 |
|------|----------|------|----------|
| 界面文字 | `NotoSansSC-Regular.ttf` | 400 | 中文+拉丁+数字 |
| 界面文字 | `NotoSansSC-Medium.ttf` | 500 | 中文+拉丁+数字 |
| 界面文字 | `NotoSansSC-Bold.ttf` | 700 | 中文+拉丁+数字 |
| 数字/等宽 | `JetBrainsMono-Regular.ttf` | 400 | 数字+符号 |

> 字体来源: Google Fonts (Noto Sans SC), JetBrains (JetBrains Mono)
> 需购买商业授权或使用SIL Open Font License字体。

---

# 7. 实施路线图

## 阶段 1: 项目基础与 MVP (预计 7 天)

### 目标
可运行的最小产品: 5个花盆位，3种植物，种植→生长→收获完整流程。

### 任务清单

#### 1.1 项目初始化 (第1天)
**文件**: `project.godot`

```gdscript
# project.godot 关键配置
[display]
window/size/viewport_width=400
window/size/viewport_height=180
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[autoload]
GameState="*res://scripts/autoload/game_state.gd"
SaveManager="*res://scripts/autoload/save_manager.gd"
EventBus="*res://scripts/autoload/event_bus.gd"
AudioManager="*res://scripts/autoload/audio_manager.gd"
GeneSystem="*res://scripts/autoload/gene_system.gd"
```

**创建的文件**:
- `scenes/main.tscn` - 主场景入口
- `scenes/ui/main_panel.tscn` - 主面板
- `scenes/ui/pot_slot.tscn` - 花盆位
- `scripts/main.gd`
- `scripts/ui/main_panel.gd`
- `scripts/ui/pot_slot.gd`
- `scripts/core/enums.gd`
- `scripts/autoload/event_bus.gd`
- `scripts/autoload/game_state.gd`
- `scripts/autoload/save_manager.gd`

**实现函数**:
- `WindowController.setup_floating_window()` - 底部悬浮窗
- `Main._ready()` - 初始化流程
- `MainPanel._on_resized()` - 响应式布局
- `PotSlot.update_from_plant()` - 显示植物
- `GameState.init_new_game()` - 初始化空游戏
- `GameState.plant_seed()` - 种植种子
- `GameState.get_plant()` - 获取植物

#### 1.2 植物基础类 (第2-3天)
**创建的文件**:
- `scripts/core/plant.gd` - Plant基类
- `scripts/core/flower.gd` - Flower子类
- `scripts/core/succulent.gd` - Succulent子类
- `scripts/data/plant_data.gd` - 植物数据库
- `scenes/plants/base_plant.tscn` - 植物视觉场景

**实现函数**:
- `Plant._process()` - 计时器驱动
- `Plant._process_decay()` - 每小时属性衰减
- `Plant._process_growth()` - 生长进度推进
- `Plant._check_stage_transition()` - 阶段升级
- `Plant.water()` / `fertilize()` / `sunlight_boost()` / `prune()`
- `Plant.to_dictionary()` / `Plant.from_dictionary()`
- `Succulent._process_decay()` - 多肉减半消耗
- `PlantData.PLANT_DATABASE` - 14种花卉+5种多肉数据

**单元测试** (GUT):
- 植物衰减计算正确
- 阶段转换条件正确
- 属性clamp范围正确

#### 1.3 花盆位与交互 (第4-5天)
**修改的文件**: `scenes/ui/pot_slot.tscn`, `scenes/ui/action_bar.tscn`

**新增文件**:
- `scripts/ui/action_bar.gd`
- `scripts/ui/pot_detail_popup.gd` (简化版)

**实现函数**:
- `PotSlot._on_gui_input()` - 点击选中
- `PotSlot.set_selected()` - 高亮选中态
- `ActionBar._on_water_pressed()` - 浇水逻辑
- `ActionBar._on_fertilize_pressed()` - 施肥逻辑
- `ActionBar._on_sunlight_pressed()` - 晒太阳逻辑
- `ActionBar._on_prune_pressed()` - 修剪逻辑
- `ActionBar.set_selected_pot()` - 更新选中花盆
- `EventBus.pot_selected.emit()` - 花盆选中信号

**测试场景**:
1. 点击空花盆 → 无响应(需先选花盆)
2. 选中花盆后点击浇水 → 水分+30
3. 冷却中再次点击 → 按钮禁用

#### 1.4 简单 UI 弹窗 (第6-7天)
**新增文件**:
- `scenes/ui/pot_detail.tscn` (简化版，无培育)
- `scripts/ui/pot_detail_popup.gd`

**实现函数**:
- `PotDetailPopup.open()` - 显示植物详情
- `PotDetailPopup._update_stats()` - 更新属性条
- `PotDetailPopup._update_stage()` - 更新阶段显示
- `PotDetailPopup._on_harvest_pressed()` - 收获逻辑
- `PotDetailPopup._on_release_pressed()` - 放生逻辑
- `GameState.add_coins()` - 收获得金币

**验收标准**:
- 可种植3种基础植物(红玫瑰、黄郁金香、雏菊)
- 植物经历5个生长阶段
- 开花后可收获获得金币
- 所有UI响应点击

---

## 阶段 2: 生长与照料系统 (预计 5 天)

### 目标
完整的照料机制(浇水/施肥/晒太阳/修剪)、属性衰减、生长条件判断。

### 任务清单

#### 2.1 照料系统完善 (第8-9天)
**修改文件**: `scripts/core/plant.gd`

**新增功能**:
- 照料冷却时间系统 (`care_cooldowns`)
- 施肥12小时冷却
- 修剪24小时冷却(限成株/开花)
- 全部>50%时生长加速10%

**实现函数**:
- `Plant._process_care_cooldowns()` - 每帧冷却递减
- `Plant._meets_requirements()` - 检查当前阶段需求
- `Plant._get_growth_multiplier()` - 计算生长倍率
- `Plant._check_health()` - 健康度损耗与死亡
- `Plant.died` signal

#### 2.2 属性条 UI (第10天)
**修改文件**: `scenes/ui/pot_detail.tscn`, `scenes/ui/pot_slot.tscn`

**实现**:
- 3个属性条 (水分/肥料/阳光) 的 ProgressBar
- 数值百分比标签
- 颜色编码 (高=绿, 中=黄, 低=红)
- 健康指示器

**属性条颜色阈值**:
| 范围 | 颜色 |
|------|------|
| 70-100% | #4CAF50 (绿) |
| 30-69% | #FFC107 (黄) |
| 0-29% | #EF5350 (红) |

#### 2.3 粒子特效 (第11-12天)
**新增文件**:
- `scenes/effects/particle_effects.tscn`
- `scripts/effects/particle_layer.gd`

**实现函数**:
- `ParticleLayer.show_water_effect()`
- `ParticleLayer.show_fertilizer_effect()`
- `ParticleLayer.show_sunlight_effect()`

**验收标准**:
- 每次照料操作触发对应粒子效果
- 粒子位置跟随花盆
- 属性条实时更新

---

## 阶段 3: 基因与培育系统 (预计 8 天)

### 目标
完整的基因遗传、突变、稀有花检测、培育流程。

### 任务清单

#### 3.1 GeneSystem 实现 (第13-14天)
**新增文件**: `scripts/autoload/gene_system.gd`

**实现函数**:
- `GeneSystem.combine_genes()` - 完整基因组合
- `GeneSystem._inherit_color_gene()` - RGB各50%
- `GeneSystem._inherit_shape_gene()` - 显性优先
- `GeneSystem._inherit_size_gene()` - 数量性状中间值
- `GeneSystem._inherit_bloom_gene()`
- `GeneSystem._apply_mutations()` - 5%概率突变
- `GeneSystem._mutate_gene()` - RGB偏移±20
- `GeneSystem.check_rare_flower()` - 5种稀有花检测
- `GeneSystem.preview_genes()` - 培育预览

#### 3.2 培育界面 (第15-16天)
**新增文件**:
- `scenes/ui/breeding.tscn`
- `scripts/ui/breeding_dialog.gd`

**实现函数**:
- `BreedingDialog.open()` - 打开培育弹窗
- `BreedingDialog._on_parent_slot_clicked()` - 选择亲本
- `BreedingDialog._update_preview()` - 预览基因结果
- `BreedingDialog._on_start_breed_pressed()` - 执行培育
- `BreedingDialog._show_result()` - 显示培育结果

#### 3.3 种子系统 (第17-18天)
**修改文件**: `scripts/autoload/game_state.gd`

**新增功能**:
- 种子背包 (`_inventory_seeds`)
- 培育生成新种子
- 种子继承母株50%基因
- 收获获得1-3颗种子

**实现函数**:
- `GameState.create_plant_from_breeding()` - 培育后创建植物
- `GameState.add_seed_to_inventory()` - 添加种子
- `GameState.get_seeds_in_inventory()` - 查询种子数量
- `GeneSystem.mutate_genes_on_harvest()` - 收获时5%基因突变

#### 3.4 稀有花特效 (第19-20天)
**新增文件**: `scripts/effects/rare_effects.gd`

**实现函数**:
- `ParticleLayer.show_rare_celebration()` - 稀有花获得特效
- `AudioManager.play_rare_celebration()` - 稀有音效
- 图鉴自动解锁稀有条目

**验收标准**:
- 培育显示基因预览
- 培育瞬间完成，获得新种子
- 5%概率出稀有花
- 稀有花有特殊光效和音效

---

## 阶段 4: 内容与 UI 完整化 (预计 6 天)

### 目标
图鉴系统、商店系统、全部19种植物解锁。

### 任务清单

#### 4.1 图鉴系统 (第21-22天)
**新增文件**:
- `scenes/ui/encyclopedia.tscn`
- `scripts/ui/encyclopedia.gd`

**实现函数**:
- `EncyclopediaPanel.open()` - 打开图鉴
- `EncyclopediaPanel._rebuild_grid()` - 动态生成卡片
- `EncyclopediaPanel._create_entry_card()` - 创建条目卡片
- `EncyclopediaPanel._get_filtered_types()` - 分类筛选
- `EncyclopediaPanel._show_detail()` - 显示详情
- `GameState.add_encyclopedia_entry()` - 解锁条目

**卡片状态**:
- 已收集: 正常色彩+勾选
- 未解锁: 灰度+锁图标
- 稀有已解锁: 正常+金色边框

#### 4.2 商店系统 (第23-24天)
**新增文件**:
- `scenes/ui/shop.tscn`
- `scripts/ui/shop.gd`

**实现函数**:
- `ShopPanel.open()` - 打开商店
- `ShopPanel._rebuild_item_list()` - 生成商品列表
- `ShopPanel._create_shop_row()` - 创建商品行
- `ShopPanel._on_buy_pressed()` - 执行购买
- `ShopPanel._use_item()` - 使用道具效果
- `GameState.spend_coins()` / `get_coins()`
- `GameState.apply_global_fertilizer()` - 全局施肥
- `GameState.apply_global_growth_hormone()` - 全局加速

#### 4.3 设置弹窗 (第25天)
**新增文件**:
- `scenes/ui/settings_popup.tscn`
- `scripts/ui/settings_popup.gd`

**实现函数**:
- `SettingsPopup.open()` - 打开设置
- `SettingsPopup._on_sfx_slider_changed()` - SFX音量
- `SettingsPopup._on_bgm_slider_changed()` - BGM音量
- `AudioManager.set_sfx_volume()`
- `AudioManager.set_bgm_volume()`

**验收标准**:
- 图鉴显示19种植物+5种稀有
- 商店可购买所有种子和道具
- 首次解锁图鉴奖励20金币
- 设置可调节音量

---

## 阶段 5: 存档与音效 (预计 4 天)

### 目标
完整存档系统、背景音乐、全部音效。

### 任务清单

#### 5.1 存档系统完善 (第26-27天)
**修改文件**: `scripts/autoload/save_manager.gd`, `scripts/autoload/game_state.gd`

**实现函数**:
- `SaveManager.save_game()` - 完整JSON序列化
- `SaveManager.load_game()` - 反序列化重建
- `SaveManager._migrate_save()` - 版本迁移
- `SaveManager.has_save()` - 检查存档
- `GameState.save_state()` - 获取完整状态
- `GameState.load_state()` - 恢复状态

**自动存档触发**:
1. 每5分钟自动存档 (`Timer`)
2. 收获/培育后立即存档
3. 游戏退出时 (`_notification(NOTIFICATION_WM_CLOSE_REQUEST)`)

**存档结构**:
```json
{
  "version": "1.0",
  "last_save": "2024-01-15T10:30:00",
  "coins": 1500,
  "encyclopedia": ["rose_red", "tulip_yellow", "cactus"],
  "inventory_seeds": {"rose_red": 3, "tulip_yellow": 1},
  "rare_chance_boost": 0.0,
  "pots": [
    {"id": 0, "plant_data": { ... }},
    {"id": 1, "plant_data": null}
  ]
}
```

#### 5.2 音效集成 (第28-29天)
**新增资源**:
- `assets/audio/sfx/` - 所有SFX文件(.wav)
- `assets/audio/bgm/` - BGM文件(.ogg)

**集成代码**:
- `AudioManager.play_sfx()` - 播放音效
- `AudioManager.play_bgm()` - 播放BGM
- 各场景中调用音效
- 音量滑块联动

#### 5.3 音乐管理器 (第30天)
**完善 `AudioManager`**:
- BGM淡入淡出过渡
- 静音选项
- 游戏暂停时音乐暂停

**验收标准**:
- 所有交互有对应音效
- BGM持续循环播放
- 存档/读档正常工作
- 游戏关闭自动存档

---

## 阶段 6: 优化与多平台 (预计 4 天)

### 目标
性能优化、多平台导出、打包发布。

### 任务清单

#### 6.1 性能优化 (第31-32天)
**优化项**:

1. **粒子对象池**: 复用GPUParticles2D节点，避免频繁创建销毁
2. **属性计算缓存**: 基因→颜色转换缓存，避免每帧计算
3. **植物更新节流**: 状态栏每0.5秒更新一次，而非每帧
4. **内存释放**: 植物死亡后正确释放( queue_free() )

```gdscript
# 粒子对象池示例
class_name ParticlePool
var _pool: Array[GPUParticles2D] = []
const POOL_SIZE := 10

func _ready() -> void:
    for i in range(POOL_SIZE):
        var p: GPUParticles2D = _create_particle_instance()
        _pool.append(p)

func acquire() -> GPUParticles2D:
    for p in _pool:
        if not p.emitting:
            return p
    # Pool exhausted, create new
    var new_p: GPUParticles2D = _create_particle_instance()
    _pool.append(new_p)
    return new_p
```

#### 6.2 多平台导出 (第33天)
**平台配置**:

| 平台 | 导出命令 | 输出文件 |
|------|---------|---------|
| Windows | `godot --export-release "Windows"` | game.exe |
| Linux | `godot --export-release "Linux/X11"` | game.x86_64 |
| macOS | `godot --export-release "macOS"` | game.dmg |

**嵌入式窗口导出配置**:
```
[display]
window/per_pixel_transparency/enabled=true
window/embed_within_window=true
```

#### 6.3 发行准备 (第34天)
- 编写 `README.md`
- 准备应用图标 (ICO/ICNS)
- 配置窗口元数据 (标题、版本号)
- 测试导出包运行

---

## 附录 A: 快捷键表

| 按键 | 功能 | 适用场景 |
|------|------|---------|
| 1-5 | 选择花盆位 | 全局 |
| Q | 浇水 | 全局(选中花盆后) |
| W | 施肥 | 全局(选中花盆后) |
| E | 晒太阳 | 全局(选中花盆后) |
| R | 修剪 | 全局(选中花盆后) |
| I | 打开图鉴 | 全局 |
| B | 打开商店 | 全局 |
| Esc | 关闭弹窗 | 弹窗打开时 |
| Enter | 确认 | 弹窗中 |
| Delete | 放生植物 | 详情弹窗中 |

---

## 附录 B: Git 分支策略

```
main          - 稳定发布版本
develop       - 开发主线
feature/*     - 功能分支 (feature/gene-system, feature/shop, etc.)
bugfix/*      - Bug修复分支
release/*     - 发布准备分支
```

**分支命名**: `feature/基因系统`, `bugfix/存档崩溃`, `release/v1.0`

---

## 附录 C: 目录结构总览

```
flower-desktop/
├── project.godot
├── README.md
├── LICENSE
├── assets/
│   ├── sprites/
│   │   ├── ui/
│   │   │   ├── pot_slot_bg.png
│   │   │   ├── empty_pot.png
│   │   │   ├── btn_*.png
│   │   │   ├── icon_*.png
│   │   │   └── coin_icon.png
│   │   ├── plants/
│   │   │   ├── rose_red/
│   │   │   │   ├── seed.png
│   │   │   │   ├── sprout_0.png
│   │   │   │   ├── sprout_1.png
│   │   │   │   ├── seedling_0.png
│   │   │   │   ├── seedling_1.png
│   │   │   │   ├── seedling_2.png
│   │   │   │   ├── mature_0.png
│   │   │   │   ├── mature_1.png
│   │   │   │   ├── flower_pointed.png
│   │   │   │   ├── flower_round.png
│   │   │   │   ├── flower_serrated.png
│   │   │   │   ├── flower_fancy.png
│   │   │   │   ├── withered.png
│   │   │   │   └── frames.tres
│   │   │   ├── rose_white/
│   │   │   └── ... (其他植物同结构)
│   │   └── effects/
│   │       ├── water_drop.png
│   │       ├── fertilizer_powder.png
│   │       ├── light_sparkle.png
│   │       └── rare_star.png
│   ├── audio/
│   │   ├── sfx/
│   │   │   ├── water.wav
│   │   │   ├── fertilizer.wav
│   │   │   ├── sunlight.wav
│   │   │   ├── prune.wav
│   │   │   ├── harvest.wav
│   │   │   ├── purchase.wav
│   │   │   ├── breed_success.wav
│   │   │   ├── rare_success.wav
│   │   │   ├── click.wav
│   │   │   ├── popup_open.wav
│   │   │   ├── popup_close.wav
│   │   │   ├── plant_die.wav
│   │   │   ├── plant_seed.wav
│   │   │   └── growth_stage.wav
│   │   └── bgm/
│   │       ├── bgm_main.ogg
│   │       └── bgm_rare.ogg
│   └── fonts/
│       ├── NotoSansSC-Regular.ttf
│       ├── NotoSansSC-Medium.ttf
│       ├── NotoSansSC-Bold.ttf
│       └── JetBrainsMono-Regular.ttf
├── scenes/
│   ├── main.tscn
│   ├── ui/
│   │   ├── main_panel.tscn
│   │   ├── pot_slot.tscn
│   │   ├── action_bar.tscn
│   │   ├── pot_detail.tscn
│   │   ├── breeding.tscn
│   │   ├── encyclopedia.tscn
│   │   ├── shop.tscn
│   │   └── settings_popup.tscn
│   ├── plants/
│   │   └── base_plant.tscn
│   └── effects/
│       └── particle_effects.tscn
└── scripts/
    ├── main.gd
    ├── core/
    │   ├── plant.gd
    │   ├── flower.gd
    │   ├── succulent.gd
    │   ├── enums.gd
    │   └── window_controller.gd
    ├── data/
    │   └── plant_data.gd
    ├── autoload/
    │   ├── game_state.gd
    │   ├── gene_system.gd
    │   ├── save_manager.gd
    │   ├── audio_manager.gd
    │   └── event_bus.gd
    ├── ui/
    │   ├── main_panel.gd
    │   ├── pot_slot.gd
    │   ├── action_bar.gd
    │   ├── pot_detail_popup.gd
    │   ├── breeding_dialog.gd
    │   ├── encyclopedia.gd
    │   ├── shop.gd
    │   └── settings_popup.gd
    └── effects/
        ├── particle_layer.gd
        └── rare_effects.gd
```

---

*本文档为 Flower Desktop 完整开发蓝图，覆盖从项目初始化到多平台发布的全部技术细节。*
