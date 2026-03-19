# 基因系统设计文档

## 概述

基因系统是 Flower Desktop 的核心玩法。通过基因遗传和突变机制，玩家可以培育出稀有花卉。

## 1. 基因结构

### 1.1 基因组成
每株植物包含以下基因：

```gdscript
var genes: Dictionary = {
    "r": 229,           # 红色基因 (0-255)
    "g": 57,            # 绿色基因 (0-255)
    "b": 53,            # 蓝色基因 (0-255)
    "shape": 0,         # 形状基因 (0-3)
    "size": 1,          # 大小基因 (0-2)
    "bloom": 1          # 花期基因 (0-2)
}
```

### 1.2 基因类型

| 基因 | 类型 | 取值范围 | 说明 |
|-----|------|---------|------|
| r, g, b | 数量性状 | 0-255 | 颜色三原色 |
| shape | 显性/隐性 | 0-3 | 0=尖瓣, 1=圆瓣, 2=锯齿, 3=异形 |
| size | 数量性状 | 0-2 | 0=小, 1=中, 2=大 |
| bloom | 数量性状 | 0-2 | 0=短, 1=中, 2=长 |

## 2. 遗传规则

### 2.1 颜色基因遗传

**孟德尔遗传法则**：
- 每对等位基因随机继承一个
- 50% 概率继承父本A的基因
- 50% 概率继承父本B的基因

```gdscript
func inherit_color_gene(parent_a: int, parent_b: int) -> int:
    return parent_a if randf() < 0.5 else parent_b
```

**示例**：
```
Parent A: R=229 (红玫瑰)
Parent B: R=255 (白玫瑰)

Child: 50% 概率 R=229，50% 概率 R=255
```

### 2.2 形状基因遗传

**显性基因优先**：
- 显性形状基因优先表达
- 如果两个都是隐性，则随机选择一个

```gdscript
enum FlowerShape {POINTED, ROUND, SERRATED, FANCY}

func inherit_shape_gene(parent_a: int, parent_b: int) -> int:
    # 显性基因 (0, 1) 优先
    if parent_a <= 1 and parent_b <= 1:
        return parent_a if randf() < 0.5 else parent_b
    # 至少一个是显性
    if parent_a <= 1 or parent_b <= 1:
        return parent_a if parent_a <= 1 else parent_b
    # 都是隐性 (2, 3)
    return parent_a if randf() < 0.5 else parent_b
```

### 2.3 大小基因遗传

**数量性状**：
- 取中间值，有轻微随机偏移

```gdscript
func inherit_size_gene(parent_a: int, parent_b: int) -> int:
    var base = (parent_a + parent_b) / 2
    var offset = randi_range(-1, 1)
    return clampi(int(base) + offset, 0, 2)
```

### 2.4 花期基因遗传

**数量性状**：
- 与大小基因类似

```gdscript
func inherit_bloom_gene(parent_a: int, parent_b: int) -> int:
    var base = (parent_a + parent_b) / 2
    var offset = randi_range(-1, 1)
    return clampi(int(base) + offset, 0, 2)
```

## 3. 基因突变

### 3.1 突变概率
- **基础概率**: 5%
- **稀有催化剂**: +2% (使用道具后)

### 3.2 突变范围
```gdscript
const MUTATION_RANGE = 20  # 基因偏移范围

func mutate_gene(gene_value: int) -> int:
    var offset = randi_range(-MUTATION_RANGE, MUTATION_RANGE)
    return clampi(gene_value + offset, 0, 255)
```

### 3.3 突变效果
| 基因类型 | 突变效果 |
|---------|---------|
| r, g, b | 颜色深浅变化 |
| shape | 形状变异 |
| size | 大小变化 |
| bloom | 花期长短变化 |

## 4. 稀有花触发

### 4.1 稀有花基因条件

```gdscript
# 彩虹玫瑰
func is_rainbow_rose(genes: Dictionary) -> bool:
    return genes.r > 200 and genes.g > 200 and genes.b > 200

# 暗夜曼陀罗
func is_dark_mandrake(genes: Dictionary) -> bool:
    return genes.r < 50 and genes.g < 50 and genes.b < 50

# 金色向日葵
func is_golden_sunflower(genes: Dictionary) -> bool:
    return genes.r > 200 and genes.g > 180 and genes.b < 50

# 月光百合
func is_moonlight_lily(genes: Dictionary) -> bool:
    return genes.r < 50 and genes.g > 200 and genes.b > 200

# 永恒之花
func is_eternal_flower(genes: Dictionary) -> bool:
    var all_high = (genes.r > 200 and genes.g > 200 and genes.b > 200)
    var all_low = (genes.r < 50 and genes.g < 50 and genes.b < 50)
    return all_high or all_low
```

### 4.2 稀有花检查流程

```
培育完成
    ↓
检查基因突变
    ↓
应用突变
    ↓
检查稀有条件 ──→ 满足 ──→ 生成稀有花
    ↓ 不满足
生成普通花
```

## 5. 完整培育流程

```gdscript
func breed(parent_a: Plant, parent_b: Plant) -> Dictionary:
    var child_genes: Dictionary = {}
    
    # 颜色基因
    child_genes.r = inherit_color_gene(parent_a.genes.r, parent_b.genes.r)
    child_genes.g = inherit_color_gene(parent_a.genes.g, parent_b.genes.g)
    child_genes.b = inherit_color_gene(parent_a.genes.b, parent_b.genes.b)
    
    # 形状基因
    child_genes.shape = inherit_shape_gene(parent_a.genes.shape, parent_b.genes.shape)
    
    # 大小基因
    child_genes.size = inherit_size_gene(parent_a.genes.size, parent_b.genes.size)
    
    # 花期基因
    child_genes.bloom = inherit_bloom_gene(parent_a.genes.bloom, parent_b.genes.bloom)
    
    # 5% 突变概率
    if randf() < 0.05:
        child_genes = apply_mutations(child_genes)
    
    # 检查稀有花
    var rare_type = check_rare_flower(child_genes)
    if rare_type != "":
        child_genes.rare_type = rare_type
    
    return child_genes
```

## 6. 基因显示

### 6.1 颜色显示
基因颜色直接用于植物精灵的 `modulate` 属性：

```gdscript
func get_display_color(genes: Dictionary) -> Color:
    return Color(
        genes.r / 255.0,
        genes.g / 255.0,
        genes.b / 255.0,
        1.0
    )
```

### 6.2 形状显示
根据 shape 基因选择不同的精灵帧：

```gdscript
func get_shape_sprite_index(genes: Dictionary) -> int:
    return genes.shape  # 0-3 对应不同精灵帧
```

## 7. 基因数据表

### 7.1 基础植物基因

| 植物 | r | g | b | shape | size | bloom |
|-----|---|---|---|-------|------|-------|
| 红玫瑰 | 229 | 57 | 53 | 0 | 1 | 1 |
| 白玫瑰 | 250 | 250 | 250 | 0 | 1 | 1 |
| 粉玫瑰 | 244 | 143 | 177 | 0 | 1 | 1 |
| 黄郁金香 | 253 | 216 | 53 | 1 | 1 | 1 |
| 橙郁金香 | 255 | 112 | 67 | 1 | 1 | 1 |
| 紫郁金香 | 126 | 87 | 194 | 1 | 1 | 1 |
| 向日葵 | 255 | 193 | 7 | 0 | 2 | 2 |
| 雏菊 | 255 | 255 | 255 | 1 | 0 | 1 |
| 薰衣草 | 149 | 117 | 205 | 0 | 1 | 1 |
| 百合 | 255 | 235 | 238 | 1 | 2 | 1 |
| 康乃馨 | 233 | 30 | 99 | 2 | 1 | 1 |
| 牡丹 | 248 | 187 | 208 | 1 | 2 | 2 |
| 樱花 | 255 | 205 | 210 | 1 | 1 | 0 |
| 蝴蝶兰 | 206 | 147 | 216 | 3 | 1 | 1 |

### 7.2 多肉植物基因

| 植物 | r | g | b | shape | size | bloom |
|-----|---|---|---|-------|------|-------|
| 观音莲 | 129 | 199 | 132 | 1 | 0 | 0 |
| 玉露 | 102 | 187 | 106 | 1 | 0 | 0 |
| 熊童子 | 174 | 213 | 129 | 2 | 0 | 0 |
| 玉龙观音 | 77 | 182 | 172 | 1 | 1 | 0 |
| 仙人掌 | 139 | 195 | 74 | 0 | 1 | 0 |

## 8. 调试工具

### 8.1 基因查看
```gdscript
func print_genes(genes: Dictionary) -> String:
    return "R=%d G=%d B=%d Shape=%d Size=%d Bloom=%d" % [
        genes.r, genes.g, genes.b,
        genes.shape, genes.size, genes.bloom
    ]
```

### 8.2 基因验证
```gdscript
func validate_genes(genes: Dictionary) -> bool:
    if not (0 <= genes.r and genes.r <= 255): return false
    if not (0 <= genes.g and genes.g <= 255): return false
    if not (0 <= genes.b and genes.b <= 255): return false
    if not (0 <= genes.shape and genes.shape <= 3): return false
    if not (0 <= genes.size and genes.size <= 2): return false
    if not (0 <= genes.bloom and genes.bloom <= 2): return false
    return true
```
