# AI 辅助生成精灵指南

> 配合 `ASSET_NAMING.md` 使用
> 目标：用免费 AI 工具生成 135 张植物精灵 + 27 张图鉴剪影

---

## 目录

1. [工具选择](#1-工具选择)
2. [风格定义（重要）](#2-风格定义重要)
3. [生成提示词模板](#3-生成提示词模板)
4. [各品种提示词](#4-各品种提示词)
5. [剪影生成](#5-剪影生成)
6. [工作流](#6-工作流)
7. [后期处理](#7-后期处理)

---

## 1. 工具选择

### 免费 AI 图像生成工具（任选其一）

| 工具 | 链接 | 说明 |
|------|------|------|
| **Stable Diffusion WebUI** | [本地部署](https://github.com/AUTOMATIC1111/stable-diffusion-webui) | 最高质量，需 GPU |
| **Fooocus** | [本地部署](https://github.com/lllyasviel/Fooocus) | Stable Diffusion 简化版，易上手 |
| **Bing Image Creator** | https://www.bing.com/create | 微软出品，免费，需账号 |
| **Playground AI** | https://playground.com | 每天 500 张免费 |
| **Leonardo.ai** | https://leonardo.ai | 每日免费额度 |
| **PixAI** | https://pixai.art | 二次元风格强 |

### 像素艺术专用工具

| 工具 | 链接 | 说明 |
|------|------|------|
| **Pixel Art AI Generator** | https://pixel-art.ai/ | 专门生成像素艺术 |
| **Sprite Generator (itch.io)** | 搜索 "pixel art generator" | 各种生成器 |

### 推荐组合

**最佳效果**：Fooocus（本地）+ 像素艺术 Checkpoint
**最简单**：Bing Image Creator（网页，无需安装）

---

## 2. 风格定义（重要）

复制以下内容作为你的风格参考：

```
PIXEL ART STYLE (LPC/Liberated Pixel Cup compatible):

分辨率: 64x64 像素（每个精灵）
或: 32x32 像素（小型植物/种子）
或: 16x16 像素（极小品种）

风格特点:
- 清晰的黑色轮廓线（1-2px）
- 有限的调色板（最多 16-24 色）
- 圆润的形状，无锐角
- 白色/浅灰色背景（方便动态着色）
- 俯视角度（top-down view）
- 无渐变，无抗锯齿
- 卡通可爱风格

导出格式: PNG，带透明通道
```

### 适合的 AI Model（Stable Diffusion）

推荐使用以下模型（从 Civitai/HuggingFace 下载）：

| 模型 | 特点 | 链接 |
|------|------|------|
| **pixel-art** | 专门的像素艺术模型 | Civitai 搜索 "pixel art" |
| **sd-px** | 像素艺术扩散模型 | HuggingFace |
| **rpg-ninja** | RPG 风格，含植物 | Civitai |
| **waifu diffusion** | 动漫风格也可用于花卉 | - |

**ControlNet（强烈推荐）**：
使用 Tile 或 Lineart ControlNet 保持线条清晰

---

## 3. 生成提示词模板

### 基础模板

```
[正面提示词]:
pixel art, 64x64, [PLANT_TYPE], [GROWTH_STAGE], top-down view,
white background, black outline, limited color palette, cute style,
no gradient, no anti-aliasing, game sprite, transparent background

[负面提示词]:
photo, realistic, photograph, 3d render, blurry, low quality,
watermark, text, signature, deformed, ugly
```

### 生长阶段对应的英文描述

| 阶段 | 英文描述 |
|------|---------|
| 种子 (seed) | tiny brown seed, just planted in soil, minimal detail |
| 发芽 (sprout) | small green sprout emerging, 2 small leaves, delicate stem |
| 幼苗 (seedling) | young seedling, 3-4 leaves, short stem, green and fresh |
| 成株 (mature) | fully grown plant, lush leaves, budding, not yet bloomed |
| 开花 (flowering) | beautiful bloom, full flower open, petals visible |

---

## 4. 各品种提示词

### 花卉类（17种）

#### 红玫瑰 / 粉玫瑰 / 白玫瑰
```
# seed
pixel art, 32x32, red rose seed, tiny brown oval seed, soil top-down, white background, black outline, limited palette

# sprout
pixel art, 48x48, red rose sprout, small green stem with 2 tiny leaves, white background, black outline, game sprite

# seedling
pixel art, 48x48, red rose seedling, young rose plant, 3-4 green leaves, small stem, white background, black outline

# mature
pixel art, 64x64, red rose plant mature, rose bush, many green leaves, closed rose bud, white background, black outline

# flowering
pixel art, 64x64, red rose flower blooming, open red rose with layered petals, black outline, white background, game sprite
```

> **换色方法**：将 "red" 替换为 "pink" 或 "white"，其余描述不变
> AI 会自动生成对应颜色的花瓣

#### 樱花
```
pixel art, 64x64, cherry blossom tree branch, pink sakura flowers, 5-petal round flowers, white background, black outline, game sprite
```

#### 牡丹
```
pixel art, 64x64, chinese peony flower, large round layered petals, pink, white background, black outline, game sprite
```

#### 白雏菊
```
pixel art, 64x64, white daisy flower, yellow center, thin white petals, simple shape, white background, black outline, game sprite
```

#### 向日葵
```
pixel art, 64x64, sunflower, large yellow flower, brown center, pointed petals, white background, black outline, game sprite
```

#### 康乃馨
```
pixel art, 64x64, carnation flower, pink, jagged wavy petals, white background, black outline, game sprite
```

#### 格桑花
```
pixel art, 64x64, gaillardia flower, small, pink and yellow petals, daisy-like, white background, black outline, game sprite
```

#### 满天星
```
pixel art, 64x64, gypsophila plant, baby's breath, many tiny white flowers clustered, delicate, white background, black outline, game sprite
```

#### 黄/橙/紫郁金香
```
# yellow
pixel art, 64x64, yellow tulip flower, cup shape, pointed petals, white background, black outline, game sprite

# orange/purple - just change "yellow" to "orange" or "purple"
```

#### 百合
```
pixel art, 64x64, white lily flower, large trumpet shape, 6 petals, orange stamens, white background, black outline, game sprite
```

#### 风信子
```
pixel art, 64x64, blue hyacinth flower, spike cluster of small flowers, purple-blue, white background, black outline, game sprite
```

#### 薰衣草
```
pixel art, 64x64, lavender plant, purple flower spikes, narrow leaves, white background, black outline, game sprite
```

#### 蝴蝶兰
```
pixel art, 64x64, phalaenopsis orchid, exotic shape, pink purple, wide flat petals, white background, black outline, game sprite
```

---

### 多肉类（4种）

#### 观音莲（Echeveria）
```
pixel art, 64x64, echeveria succulent, rosette shape, light green blue, layered thick leaves, white background, black outline, game sprite
```

#### 玉露（Haworthia）
```
pixel art, 64x64, haworthia succulent, small rosette, dark green with white stripes, translucent leaves, white background, black outline, game sprite
```

#### 熊童子（Bear Paw）
```
pixel art, 64x64, cotyledon熊童子 succulent, bear paw shaped leaves, green with toothed edges, white background, black outline, game sprite
```

#### 玉龙观音
```
pixel art, 64x64, jade dragon观音 succulent, large rosette, turquoise teal color, white background, black outline, game sprite
```

---

### 仙人掌（1种）

#### 仙人掌
```
pixel art, 64x64, small cactus, round shape with spines, green, white background, black outline, game sprite
```

---

### 稀有花（5种）- 需要特殊处理

#### 彩虹玫瑰
```
pixel art, 64x64, rainbow rose, petals with gradient rainbow colors, iridescent, sparkle effect, white background, black outline, game sprite
```
> 生成后需在 Photoshop 中叠加彩虹层

#### 暗夜曼陀罗
```
pixel art, 64x64, dark mandrake flower, deep black purple petals, glowing edges, mysterious, dark theme, white background, black outline, game sprite
```

#### 金色向日葵
```
pixel art, 64x64, golden sunflower, bright gold yellow petals, shiny, glow effect, white background, black outline, game sprite
```

#### 月光百合
```
pixel art, 64x64, moonlight lily flower, silver white petals, soft glow, ethereal, pale blue tint, white background, black outline, game sprite
```

#### 永恒之花
```
pixel art, 64x64, eternal flower, iridescent white, translucent petals, pulsing glow aura, mystical, white background, black outline, game sprite
```

---

## 5. 剪影生成

图鉴剪影 = 开花阶段精灵 → 去色 → 阈值处理 → 纯黑轮廓

### 快速方法（Photoshop/GIMP/在线工具）

1. 加载开花阶段精灵 PNG
2. 转换为灰度（Image → Mode → Grayscale）
3. 调整阈值（Threshold）：菜单 Image → Adjustments → Threshold
   - 或 `Image → Auto → Threshold`（自动）
4. 将黑色部分转为纯黑（#000000），白色部分转为透明
5. 保存为 PNG

### 命名
```
silhouette_{plant_type}.png
示例: silhouette_rose_red.png
```

### 特殊工具

| 工具 | 说明 |
|------|------|
| [remove.bg](https://remove.bg) | 移除背景，自动输出透明图 |
| [Pixelator](https://pixelator.app) | 将图片像素化 |
| GIMP（免费） | `Colors → Threshold` 处理剪影 |

---

## 6. 工作流

### 第一批（核心 5 种 × 5 阶段 = 25 张）

先验证流程，选 5 个代表性品种：

| 品种 | 理由 |
|------|------|
| rose_red | 蔷薇系代表，初始种子 |
| daisy_white | 菊系代表，初始种子 |
| tulip_yellow | 百合系代表，初始种子 |
| succulent_echeveria | 多肉代表 |
| cactus | 仙人掌代表 |

**验证步骤：**
1. 生成 25 张精灵
2. 按命名规则重命名：`{plant_type}_{stage}_{stage_name}.png`
3. 放入 `res://sprites/plants/flower/` 等目录
4. 运行游戏测试显示效果
5. 确认满意后批量生成其余 22 种

### 批量生成顺序

```
Phase 1: 初始种子（3种 × 5 = 15张）
  rose_red, daisy_white, tulip_yellow

Phase 2: 同色系混色（4种 × 5 = 20张）
  rose_pink, rose_white, tulip_orange, tulip_purple

Phase 3: 杂交品种（6种 × 5 = 30张）
  sakura, peony, hyacinth, gesang, gypsophila, succulent_dragon

Phase 4: 多步培育（5种 × 5 = 25张）
  lily, sunflower, carnation, lavender, orchid

Phase 5: 多肉/仙人掌（5种 × 5 = 25张）
  succulent_haworthia, succulent_bear, cactus

Phase 6: 稀有花（5种 × 5 = 25张）+ 5张glow层
```

### 每日目标

假设每天生成 10-15 张：
- Phase 1-2（约 45 张）：4-5 天
- Phase 3-4（约 55 张）：5-6 天
- Phase 5-6（约 55 张）：5-6 天
- **总计：约 15-18 个工作日**

---

## 7. 后期处理

### 统一尺寸

生成后可能尺寸不一，用以下工具批量调整：

```bash
# ImageMagick（免费命令行工具）
# 安装: sudo apt install imagemagick

# 批量调整到 64x64，居中，透明背景
mogrify -resize 64x64 -gravity center -background transparent -extent 64x64 *.png

# 或批量缩放到 64px 宽度（保持比例）
mogrify -resize 64x -extent 64x64 -background transparent *.png
```

### 批量重命名

```bash
# macOS/Linux - 使用 rename 或 mv
# 示例: rose_red_flowering.png → rose_red_4_flowering.png

# 编写脚本或用功能:
# Thunar, Caja, Dolphin 文件管理器支持批量重命名
```

### 检查清单

- [ ] 每张精灵有透明背景
- [ ] 尺寸统一（64x64 或约定的尺寸）
- [ ] 文件名符合命名规则
- [ ] 放入正确目录（flower/, succulent/, cactus/, rare/）
- [ ] 黑色轮廓清晰可见
- [ ] 颜色与品种对应正确

### 快速预览工具

生成后用以下工具快速预览整批素材：

| 工具 | 说明 |
|------|------|
| **IrfanView**（Windows） | 快速查看，支持缩略图 |
| **Quick Look**（macOS） | 空格键预览 |
| ** Gwenview**（Linux） | KDE 图片查看器 |
| **OpenSNP**（在线） | https://opensnp.org |

---

## 附录：批处理脚本模板

### Stable Diffusion WebUI API 批量生成

如果使用本地 SD WebUI，可以用以下脚本批量生成：

```python
# batch_generate.py
# 配合 SD WebUI 的 /sdapi/v1/txt2img 接口

import requests
import json
import os

API_URL = "http://localhost:7860/sdapi/v1/txt2img"

# 定义所有植物和阶段
PLANTS = [
    ("rose_red", ["seed", "sprout", "seedling", "mature", "flowering"]),
    ("daisy_white", ["seed", "sprout", "seedling", "mature", "flowering"]),
    # ... 其余品种
]

def generate(plant_type, stage, negative="..."):
    prompt = f"pixel art, 64x64, {plant_type}, {stage}, ..."
    payload = {
        "prompt": prompt,
        "negative_prompt": negative,
        "width": 64,
        "height": 64,
        "steps": 20,
        "cfg_scale": 7,
    }
    response = requests.post(API_URL, json=payload)
    return response.json()

# 遍历生成...
```

---

## 快速开始（今天就能做）

1. **现在**：用 Bing Image Creator 生成第一批 5 个品种 × 5 阶段 = 25 张
   - 用上面的提示词模板
   - 下载 PNG 结果
   - 按命名规则重命名

2. **明天**：创建目录结构，放入精灵，测试游戏

3. **后天起**：批量生成剩余品种
