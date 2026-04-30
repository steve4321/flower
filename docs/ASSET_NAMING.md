# Flower Desktop — 美术资源命名规则与配置方法

> 最后更新: 2026-04-30
> 状态: 规范初稿，待美术确认后生效

---

## 目录

1. [目录结构](#1-目录结构)
2. [植物精灵命名规则](#2-植物精灵命名规则)
3. [UI 资源命名规则](#3-ui-资源命名规则)
4. [场景背景命名规则](#4-场景背景命名规则)
5. [特效动画命名规则](#5-特效动画命名规则)
6. [音效资源命名规则](#6-音效资源命名规则)
7. [代码配置方法](#7-代码配置方法)
8. [动态着色系统](#8-动态着色系统)
9. [懒加载与回退机制](#9-懒加载与回退机制)

---

## 1. 目录结构

```
res://
├── sprites/                          # 所有 2D 精灵资源
│   ├── plants/                       # 植物精灵（动态着色白底）
│   │   ├── flower/                   # 花卉（17种）
│   │   │   ├── rose_red_0_seed.png
│   │   │   ├── rose_red_1_sprout.png
│   │   │   ├── rose_red_2_seedling.png
│   │   │   ├── rose_red_3_mature.png
│   │   │   ├── rose_red_4_flowering.png
│   │   │   ├── ...
│   │   ├── succulent/               # 多肉（4种）
│   │   │   ├── succulent_echeveria_0_seed.png
│   │   │   ├── ...
│   │   ├── cactus/                  # 仙人掌（1种）
│   │   │   ├── cactus_0_seed.png
│   │   │   ├── ...
│   │   └── rare/                    # 稀有花（5种）
│   │       ├── rare_rainbow_rose_0_seed.png
│   │       ├── ...
│   ├── ui/                          # UI 资源
│   │   ├── icon_water.png
│   │   ├── icon_collect.png
│   │   ├── icon_breed.png
│   │   ├── panel_breeding_room.png
│   │   ├── ...
│   ├── background/                  # 场景背景
│   │   ├── bg_garden.png
│   │   ├── bg_desktop.png
│   │   ├── bg_breeding_room.png
│   │   └── ...
│   └── effects/                     # 特效精灵（图集或散图）
│       ├── water_drop.png           # 浇水水滴（序列帧）
│       ├── bloom_reveal.png         # 开花揭晓（序列帧）
│       ├── petal_falling.png        # 花瓣飘落（粒子图集）
│       └── rare_sparkle.png         # 稀有花微光（粒子）
│
├── audio/                           # 音频资源
│   ├── sfx/                         # 音效（触发型）
│   │   ├── sfx_click.wav
│   │   ├── sfx_water.wav
│   │   ├── sfx_grow.wav
│   │   ├── sfx_discover.wav
│   │   ├── sfx_breed_success.wav
│   │   └── sfx_rare.wav
│   └── bgm/                         # 背景音乐（循环型）
│       ├── bgm_breeding.ogg
│       └── bgm_garden.ogg           # 可选
│
└── fonts/                           # 字体资源
    ├── NotoSansSC-Regular.ttf       # 界面中文
    └── Nunito-Regular.ttf           # 英文/数字
```

---

## 2. 植物精灵命名规则

### 2.1 文件命名格式

```
{plant_type}_{stage_index}_{stage_name}.png
```

| 组成部分 | 说明 | 示例 |
|---------|------|------|
| `plant_type` | 植物品种代码（与 `PlantData.PLANT_DATABASE` 键名一致） | `rose_red`, `tulip_yellow`, `rare_rainbow_rose` |
| `stage_index` | 生长阶段序号（0-4） | `0`, `1`, `2`, `3`, `4` |
| `stage_name` | 阶段英文名 | `seed`, `sprout`, `seedling`, `mature`, `flowering` |

### 2.2 品种代码对照表

> **必须与 `PlantData.PLANT_DATABASE` 键名 100% 一致**，不得自行缩写或改名。

#### 花卉（flower）- 17 种

| 品种代码 | 中文名 | 培育组 | shape | size |
|---------|--------|--------|-------|------|
| `rose_red` | 红玫瑰 | 蔷薇系 | 0 | 1 |
| `rose_pink` | 粉玫瑰 | 蔷薇系 | 0 | 1 |
| `rose_white` | 白玫瑰 | 蔷薇系 | 0 | 1 |
| `sakura` | 樱花 | 蔷薇系 | 1 | 1 |
| `peony` | 牡丹 | 蔷薇系 | 1 | 2 |
| `daisy_white` | 白雏菊 | 菊系 | 1 | 0 |
| `sunflower` | 向日葵 | 菊系 | 0 | 2 |
| `carnation` | 康乃馨 | 菊系 | 2 | 1 |
| `gesang` | 格桑花 | 菊系 | 1 | 0 |
| `gypsophila` | 满天星 | 菊系 | 1 | 0 |
| `tulip_yellow` | 黄郁金香 | 百合系 | 1 | 1 |
| `tulip_orange` | 橙郁金香 | 百合系 | 1 | 1 |
| `tulip_purple` | 紫郁金香 | 百合系 | 1 | 1 |
| `lily` | 百合 | 百合系 | 1 | 2 |
| `hyacinth` | 风信子 | 百合系 | 0 | 0 |
| `lavender` | 薰衣草 | 兰系 | 0 | 1 |
| `orchid` | 蝴蝶兰 | 兰系 | 3 | 1 |

#### 多肉（succulent）- 4 种

| 品种代码 | 中文名 | 培育组 | shape | size |
|---------|--------|--------|-------|------|
| `succulent_echeveria` | 观音莲 | 多肉系 | 1 | 0 |
| `succulent_haworthia` | 玉露 | 多肉系 | 1 | 0 |
| `succulent_bear` | 熊童子 | 多肉系 | 2 | 0 |
| `succulent_dragon` | 玉龙观音 | 多肉系 | 1 | 1 |

#### 仙人掌（cactus）- 1 种

| 品种代码 | 中文名 | 培育组 | shape | size |
|---------|--------|--------|-------|------|
| `cactus` | 仙人掌 | 仙人掌 | 0 | 1 |

#### 稀有花（rare）- 5 种

| 品种代码 | 中文名 | 培育组 | shape | size | 特效 |
|---------|--------|--------|-------|------|------|
| `rare_rainbow_rose` | 彩虹玫瑰 | 蔷薇系 | 0 | 1 | 彩虹渐变 + 闪烁光点 |
| `rare_dark_mandrake` | 暗夜曼陀罗 | 蔷薇系 | 2 | 1 | 深色 + 发光边缘 |
| `rare_golden_sunflower` | 金色向日葵 | 菊系 | 0 | 2 | 金色 + 光晕 |
| `rare_moonlight_lily` | 月光百合 | 百合系 | 1 | 2 | 银白 + 柔和微光 |
| `rare_eternal_flower` | 永恒之花 | 蔷薇系 | 3 | 2 | 半透明 + 脉动光晕 |

### 2.3 生长阶段序号

| 序号 | 阶段名 | 中文名 | 对应 Plant.Stage |
|-----|--------|--------|-----------------|
| `0` | `seed` | 种子 | `SEED` |
| `1` | `sprout` | 发芽 | `SPROUT` |
| `2` | `seedling` | 幼苗 | `SEEDLING` |
| `3` | `mature` | 成株 | `MATURE` |
| `4` | `flowering` | 开花 | `FLOWERING` |

### 2.4 完整文件命名示例

```
rose_red_0_seed.png        # 红玫瑰 - 种子
rose_red_1_sprout.png      # 红玫瑰 - 发芽
rose_red_2_seedling.png    # 红玫瑰 - 幼苗
rose_red_3_mature.png      # 红玫瑰 - 成株
rose_red_4_flowering.png   # 红玫瑰 - 开花

rare_rainbow_rose_0_seed.png
rare_rainbow_rose_4_flowering.png   # 开花阶段有特殊光效

succulent_bear_2_seedling.png       # 熊童子 - 幼苗（锯齿形状）
```

### 2.5 图鉴剪影命名

```
silhouette_{plant_type}.png
```

- 纯黑轮廓，透明背景
- 基于 `flowering` 阶段精灵制作
- 格式示例：`silhouette_rose_red.png`、`silhouette_rare_rainbow_rose.png`

### 2.6 稀有花特殊命名

稀有花 flowering 阶段有两层精灵：

```
# 基础精灵（白底，半透明）
rare_rainbow_rose_4_flowering.png

# 发光层精灵（独立文件，与基础层叠加）
rare_rainbow_rose_4_flowering_glow.png
```

发光层用**黑色底+彩色发光区域**，游戏代码中做 `multiply` 混合或直接叠加。

---

## 3. UI 资源命名规则

### 3.1 图标命名格式

```
icon_{action}_{state}.png
```

| 组成部分 | 说明 | 示例 |
|---------|------|------|
| `action` | 功能动作 | `water`, `collect`, `remove`, `breed`, `encyclopedia`, `garden`, `desktop` |
| `state` | 状态（可省略默认态） | `normal`, `pressed`, `disabled` |

**常用图标：**

| 文件名 | 用途 | 规格 | 备注 |
|--------|------|------|------|
| `icon_water.png` | 浇水按钮 | 24×24 | 可加水滴装饰 |
| `icon_collect.png` | 收入仓库 | 24×24 | 向上箭头+箱子 |
| `icon_remove.png` | 移除 | 24×24 | 垃圾桶 |
| `icon_breed.png` | 培育 | 24×24 | 两朵花交叉 |
| `icon_encyclopedia.png` | 图鉴 | 24×24 | 书本 |
| `icon_garden.png` | 花圃场景切换 | 24×24 | 草地 |
| `icon_desktop.png` | 桌面场景切换 | 24×24 | 显示器 |
| `icon_close.png` | 关闭弹窗 | 20×20 | × 符号 |
| `icon_back.png` | 返回 | 20×20 | ← 箭头 |

**按钮状态变体（可选）：**

```
icon_water_normal.png    # 默认
icon_water_pressed.png  # 按下
icon_water_disabled.png  # 禁用（灰色）
```

### 3.2 面板背景命名

```
panel_{context}_{variant}.png
```

| 文件名 | 用途 | 规格 | 备注 |
|--------|------|------|------|
| `panel_garden_grid.png` | 花圃格子底 | 80×80 | 棕色泥土纹理 |
| `panel_breeding_room.png` | 培育室面板 | 300×220 | 半透明暗色 |
| `panel_tooltip.png` | 提示框 | 动态 | 小号圆角矩形 |
| `panel_encyclopedia_slot_normal.png` | 图鉴格子-已发现 | 64×80 | 明亮背景 |
| `panel_encyclopedia_slot_hidden.png` | 图鉴格子-未发现 | 64×80 | 暗色剪影 |

---

## 4. 场景背景命名规则

```
bg_{scene_name}.png
```

| 文件名 | 用途 | 规格 | 备注 |
|--------|------|------|------|
| `bg_garden.png` | 花圃场景 | 640×480 | 草地+围栏+阳光氛围 |
| `bg_desktop.png` | 桌面场景 | 640×480 | 深色半透明背景 |
| `bg_breeding_room.png` | 培育室场景 | 640×480 | 温暖室内工作台 |

> 背景尺寸应与游戏视口一致（默认 640×480）。如需支持高清缩放，制作 2x 尺寸（1280×960）并做好 `expand` 设置。

---

## 5. 特效动画命名规则

### 5.1 序列帧命名格式

```
eff_{effect_name}_{frame_index}.png
```

- 从 `0` 开始编号
- 帧数少的特效用散图（每个文件独立帧）
- 帧数多的用水平/垂直排列的图集

| 特效名 | 帧数 | 播放速度 | 说明 |
|--------|------|---------|------|
| `eff_water_drop_0.png` ~ `eff_water_drop_5.png` | 6 帧 | 快（0.3s） | 水滴落下 |
| `eff_stage_up_0.png` ~ `eff_stage_up_4.png` | 5 帧 | 中（0.5s） | 生长阶段切换 |
| `eff_bloom_0.png` ~ `eff_bloom_7.png` | 8 帧 | 中（0.8s） | 开花揭晓 |
| `eff_breed_success_0.png` ~ `eff_breed_success_6.png` | 7 帧 | 中（1s） | 培育成功 |

### 5.2 粒子图集命名

```
part_{particle_name}.png
```

| 文件名 | 描述 | 规格 | 备注 |
|--------|------|------|------|
| `part_petal.png` | 花瓣飘落 | 128×128，5 种颜色花瓣排列 | 重复平铺 |
| `part_water_splash.png` | 浇水飞溅 | 64×64 | 蓝色水滴 |
| `part_rare_sparkle_gold.png` | 稀有金光粒子 | 64×64 | 金色光点 |
| `part_rare_sparkle_silver.png` | 稀有银光粒子 | 64×64 | 银色光点 |
| `part_bloom_burst.png` | 开花扩散粒子 | 64×64，6 色 | 向四周扩散 |

### 5.3 图集排列方式

特效帧按**水平排列**（从左到右）：

```
+------+------+------+------+------+------+
|  0   |  1   |  2   |  3   |  4   |  5   |
+------+------+------+------+------+------+
```

游戏代码按 `frame_width = total_width / frame_count` 计算每帧位置。

---

## 6. 音效资源命名规则

### 6.1 音效（SFX）命名

```
sfx_{event}.{ext}
```

| 文件名 | 触发时机 | 推荐时长 | 风格描述 |
|--------|---------|---------|---------|
| `sfx_click.wav` | 按钮点击 | < 0.5s | 轻柔短促点击 |
| `sfx_water.wav` | 浇水 | < 1s | 清脆水滴声 |
| `sfx_grow.wav` | 生长阶段变化 | < 1s | 轻柔"叮"音 |
| `sfx_discover.wav` | 新品种收录图鉴 | < 1s | 欢快短促音效 |
| `sfx_breed_success.wav` | 培育出新品种 | 1-2s | 温暖和弦 |
| `sfx_rare.wav` | 稀有花出现 | 2-3s | 特殊庆祝音乐 |

### 6.2 背景音乐（BGM）命名

```
bgm_{scene}.{ext}
```

| 文件名 | 适用场景 | 循环 | 风格描述 |
|--------|---------|------|---------|
| `bgm_breeding.ogg` | 培育室 | 循环 | 轻柔温暖匠人坊 |
| `bgm_garden.ogg` | 花圃（可选开关） | 循环 | 自然轻音乐 |

### 6.3 音效格式要求

| 类型 | 格式 | 采样率 | 声道 | 单文件大小 |
|------|------|--------|------|-----------|
| SFX | WAV 或 OGG | 44.1kHz | 单声道 | < 100KB |
| BGM | OGG | 44.1kHz | 双声道 | ~2-3MB |

---

## 7. 代码配置方法

### 7.1 新建 `SpriteRegistry` 资源注册表

创建文件 `res://scripts/autoload/sprite_registry.gd`：

```gdscript
## sprite_registry.gd
## 植物精灵资源注册表（单例，自动加载）
extends Node

## 精灵根路径
const SPRITE_ROOT := "res://sprites/plants/"

## 类别子目录
const CATEGORY_DIR: Dictionary = {
    "flower": "flower/",
    "succulent": "succulent/",
    "cactus": "cactus/",
    "rare": "rare/",
}

## 阶段名称
const STAGE_NAMES: Array = ["seed", "sprout", "seedling", "mature", "flowering"]

## 缓存：已加载的 Texture
var _cache: Dictionary = {}


## 获取植物精灵的 Texture
## plant_type: 品种代码（如 "rose_red"）
## stage: 生长阶段（0-4）
## 返回：Texture2D 或 null（未找到）
func get_plant_sprite(plant_type: String, stage: int) -> Texture2D:
    var key := plant_type + "_" + str(stage)
    if _cache.has(key):
        return _cache[key]

    var category := _get_category(plant_type)
    var stage_name := STAGE_NAMES[stage] if stage < STAGE_NAMES.size() else "flowering"
    var path := SPRITE_ROOT + CATEGORY_DIR.get(category, "") + \
                plant_type + "_" + str(stage) + "_" + stage_name + ".png"

    if not ResourceLoader.exists(path):
        push_warning("[SpriteRegistry] Sprite not found: " + path)
        return null

    var tex := load(path) as Texture2D
    if tex:
        _cache[key] = tex
    return tex


## 获取剪影精灵
func get_silhouette(plant_type: String) -> Texture2D:
    var key := "silhouette_" + plant_type
    if _cache.has(key):
        return _cache[key]

    var path := SPRITE_ROOT + "silhouette_" + plant_type + ".png"
    if not ResourceLoader.exists(path):
        return null

    var tex := load(path) as Texture2D
    if tex:
        _cache[key] = tex
    return tex


## 预加载所有精灵（启动时调用一次）
func preload_all() -> void:
    for category in CATEGORY_DIR.values():
        var dir_path := SPRITE_ROOT + category
        var dir := DirAccess.open(dir_path)
        if dir == null:
            continue
        dir.list_dir_begin()
        var file_name := dir.get_file()
        while file_name != "":
            if file_name.ends_with(".png"):
                var full_path := dir_path + file_name
                _ = load(full_path)  # 预加载到缓存
            file_name = dir.get_file()
        dir.list_dir_end()


## 根据 plant_type 判断所属类别
func _get_category(plant_type: String) -> String:
    if plant_type.begins_with("rare_"):
        return "rare"
    if plant_type.begins_with("succulent_"):
        return "succulent"
    if plant_type == "cactus":
        return "cactus"
    return "flower"
```

### 7.2 修改 Plant 类添加精灵路径方法

在 `plant.gd` 中添加：

```gdscript
## 获取该植物当前阶段的精灵
func get_sprite() -> Texture2D:
    return SpriteRegistry.get_plant_sprite(plant_type, stage)

## 获取该植物开花阶段的精灵（用于剪影/永久展示）
func get_flowering_sprite() -> Texture2D:
    return SpriteRegistry.get_plant_sprite(plant_type, Plant.Stage.FLOWERING)
```

### 7.3 修改 GardenPlot 显示植物精灵

在 `garden_plot.gd` 中：

```gdscript
@onready var plant_sprite: Sprite2D = $VBox/PlantSprite  # 新增 Sprite2D 节点
@onready var plant_icon: Label = $VBox/PlantIcon        # 保留 Label 作为回退

func _update_display() -> void:
    if _current_plant == null:
        # ... 空格子处理 ...
        plant_sprite.visible = false
        return

    # 尝试加载精灵
    var tex := _current_plant.get_sprite()
    if tex != null:
        plant_sprite.texture = tex
        plant_sprite.visible = true
        plant_icon.visible = false
    else:
        # 回退到 Emoji 显示
        plant_sprite.visible = false
        plant_icon.visible = true
        var stage_icons: PackedStringArray = ["🟤", "🌱", "🌿", "🪴", "🌸"]
        plant_icon.text = stage_icons[_current_plant.stage]
        plant_icon.modulate = _current_plant.get_display_color()

    # 动态着色（运行时）
    if tex != null:
        plant_sprite.modulate = _current_plant.get_display_color()
```

### 7.4 修改 Encyclopedia 显示剪影/精灵

在 `encyclopedia.gd` 中：

```gdscript
func _make_plant_button(plant_type: String) -> Button:
    var btn := Button.new()
    var discovered := GameState.is_plant_discovered(plant_type)

    if discovered:
        # 已发现：显示精灵或 Emoji
        var tex := SpriteRegistry.get_plant_sprite(plant_type, Plant.Stage.FLOWERING)
        if tex != null:
            var tex_rect := TextureRect.new()
            tex_rect.texture = tex
            tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            tex_rect.custom_minimum_size = Vector2(40, 40)
            btn.add_child(tex_rect)
        else:
            btn.text = PlantData.get_name(plant_type)
    else:
        # 未发现：显示剪影
        var silhouette := SpriteRegistry.get_silhouette(plant_type)
        if silhouette != null:
            var tex_rect := TextureRect.new()
            tex_rect.texture = silhouette
            tex_rect.modulate = Color(0.3, 0.3, 0.3)  # 暗色
            tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            tex_rect.custom_minimum_size = Vector2(40, 40)
            btn.add_child(tex_rect)
        else:
            btn.text = "❓"
            btn.disabled = true

    return btn
```

---

## 8. 动态着色系统

### 8.1 设计原理

美术只制作**一套白底/灰底精灵**，游戏运行时通过 `modulate` 属性动态着色。

```
美术交付：白底灰线精灵 → 游戏运行时：modulate(r, g, b, a) → 最终显示
```

### 8.2 着色实现

`Plant.get_display_color()` 已实现从 `base_color` 读取 RGB：

```gdscript
## 获取用于显示的 Color（含 alpha）
func get_display_color() -> Color:
    return Color(
        color.r / 255.0,
        color.g / 255.0,
        color.b / 255.0,
        1.0
    )
```

游戏代码中对 Sprite2D 应用：

```gdscript
plant_sprite.modulate = plant.get_display_color()
```

### 8.3 特殊品种额外处理

| 品种 | 特殊处理 | 实现方式 |
|------|---------|---------|
| 彩虹玫瑰 | 彩虹渐变叠加层 | 额外加载 `_glow.png`，做 `add` 混合 |
| 暗夜曼陀罗 | 深色 + 发光边缘 | 深色底 + 外发光 shader |
| 金色向日葵 | 金色叠加 + 光晕 | gold overlay blend + glow |
| 月光百合 | 银白 + 微光粒子 | 银白底 + 循环粒子 |
| 永恒之花 | 半透明 + 脉动光晕 | alpha 0.8 + pulse shader |

对于稀有花的特殊效果，建议在 `Plant` 类中添加标记：

```gdscript
# Plant.gd 中
const RARE_EFFECTS: Array = ["rare_rainbow_rose", "rare_dark_mandrake",
                              "rare_golden_sunflower", "rare_moonlight_lily",
                              "rare_eternal_flower"]

func has_rare_effect() -> bool:
    return plant_type in RARE_EFFECTS
```

---

## 9. 懒加载与回退机制

### 9.1 懒加载策略

- **首次访问时加载**：`get_plant_sprite()` 每次查询未缓存的路径并加载
- **预加载选项**：启动画面调用 `SpriteRegistry.preload_all()` 预加载全部精灵
- **按类别预加载**：切换到花圃时预加载 `flower/`，切换到培育室时按需加载

### 9.2 回退机制

| 缺少的资源 | 回退方式 |
|-----------|---------|
| 某个植物精灵文件 | 回退到 Emoji + modulate 显示（`Label.text = "🌸"`） |
| 全部植物精灵 | 所有植物用 Emoji 临时显示 |
| UI 图标 | 文字按钮（如 "收入仓库"） |
| 背景图片 | 纯色背景（`ColorRect`） |
| 音效文件 | 静默（`SFXPlayer` 检查文件存在性） |

### 9.3 资源完整性检查

在游戏设置或关于页面添加"资源状态"诊断：

```gdscript
func check_resource_status() -> Dictionary:
    var missing: Array = []
    for plant_type in PlantData.get_all_types():
        for stage in range(5):
            var path := _get_sprite_path(plant_type, stage)
            if not ResourceLoader.exists(path):
                missing.append(path)
    return {
        "total_expected": PlantData.get_all_types().size() * 5,
        "missing_count": missing.size(),
        "missing_files": missing,
    }
```

---

## 10. 快速参考表

### 完整植物品种 → 文件名映射（17+4+1+5 = 27 种）

| 品种代码 | 开花阶段文件名 |
|---------|--------------|
| rose_red | `rose_red_4_flowering.png` |
| rose_pink | `rose_pink_4_flowering.png` |
| rose_white | `rose_white_4_flowering.png` |
| sakura | `sakura_4_flowering.png` |
| peony | `peony_4_flowering.png` |
| daisy_white | `daisy_white_4_flowering.png` |
| sunflower | `sunflower_4_flowering.png` |
| carnation | `carnation_4_flowering.png` |
| gesang | `gesang_4_flowering.png` |
| gypsophila | `gypsophila_4_flowering.png` |
| tulip_yellow | `tulip_yellow_4_flowering.png` |
| tulip_orange | `tulip_orange_4_flowering.png` |
| tulip_purple | `tulip_purple_4_flowering.png` |
| lily | `lily_4_flowering.png` |
| hyacinth | `hyacinth_4_flowering.png` |
| lavender | `lavender_4_flowering.png` |
| orchid | `orchid_4_flowering.png` |
| succulent_echeveria | `succulent_echeveria_4_flowering.png` |
| succulent_haworthia | `succulent_haworthia_4_flowering.png` |
| succulent_bear | `succulent_bear_4_flowering.png` |
| succulent_dragon | `succulent_dragon_4_flowering.png` |
| cactus | `cactus_4_flowering.png` |
| rare_rainbow_rose | `rare_rainbow_rose_4_flowering.png` (+ glow) |
| rare_dark_mandrake | `rare_dark_mandrake_4_flowering.png` (+ glow) |
| rare_golden_sunflower | `rare_golden_sunflower_4_flowering.png` (+ glow) |
| rare_moonlight_lily | `rare_moonlight_lily_4_flowering.png` (+ glow) |
| rare_eternal_flower | `rare_eternal_flower_4_flowering.png` (+ glow) |

**总计**：27 × 5 = **135 张植物精灵** + 27 张剪影 + 5 张稀有花发光层
