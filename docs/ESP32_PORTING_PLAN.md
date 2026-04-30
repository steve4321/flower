# Flower Desktop ESP32 移植计划

> 目标：将 Godot 4.6.2 桌面养花游戏移植到 ESP32 平台
> 更新日期：2026-04-30

---

## 一、技术选型

### 1.1 硬件规格

| 组件 | 推荐型号 | 说明 |
|-----|---------|------|
| 主控 | **ESP32-S3-WROOM-1** | Xtensa dual-core 240MHz, WiFi/BT, 8MB Flash |
| 内存 | **ESP32-S3-WROOM-1-N16R8** | 16MB Flash + 8MB PSRAM（关键：PSRAM 扩展内存） |
| 显示 | **ST7789 240x240 TFT** | 1.3" IPS, SPI 接口, 全彩显示 |
| 触摸 | **FT3168 电容触控** | I2C 接口，支持单点触控 |
| 供电 | **LiPo 3.7V 1200mAh** | 通过 USB-C 充电 |
| 调试 | **USB-C** | 用于程序下载和串口调试 |

**推荐理由**：
- ESP32-S3 比标准 ESP32 有更多 GPIO，支持 PSRAM
- 240x240 分辨率足够显示 2x3 或 3x4 花圃网格
- 全彩 TFT 能完整展示花卉颜色和培育渐变效果
- 8MB PSRAM 解决 LVGL 内存需求（原生 520KB 不够）

**成本预估**（批量 10 件）：
- ESP32-S3 模块：¥28
- TFT 屏幕：¥16
- PCB + 电池：¥30
- 合计：¥74/台（略低于详细清单因批量折扣）

### 1.2 详细硬件成本（TFT 版）

| 组件 | 型号 | 单价 | 小计 | 采购渠道 |
|-----|------|-----|-----|---------|
| **主控** | ESP32-S3-WROOM-1-N16R8（16MB Flash + 8MB PSRAM） | ¥28 | ¥28 | 淘宝「安信可科技」/ 嘉立创 EAME |
| **TFT 屏幕** | 1.3" ST7789 IPS 240x240 SPI 接口 带触摸 | ¥16 | ¥16 | 淘宝「优信电子」/ 淘宝「晨航科技」 |
| **触控芯片** | FT3168 电容触控（可选） | ¥8 | ¥8 | 淘宝「华芯微尔」 |
| **电池** | LiPo 803040 1200mAh 1S 带保护板 | ¥12 | ¥12 | 淘宝「博邦电子」/ 拼多多「锂电池工厂店」 |
| **充电管理** | TP4056 USB-C 充电板 带保护 | ¥3 | ¥3 | 淘宝「亿雨电子」 |
| **升压芯片** | MT3608 3.3V/5V 升压模块（如果屏幕需要） | ¥2 | ¥2 | 淘宝「博创电子」 |
| **晶振** | 40MHz 无源晶振 3225 封装 | ¥0.5 | ¥0.5 | 淘宝「星光电子」 |
| **电阻电容** | 0805 贴片阻容套件（退耦电容上拉电阻） | ¥3 | ¥3 | 淘宝「容亮电子」 |
| **按键** | 6x6 轻触开关 4 个 | ¥1 | ¥1 | 淘宝「合泰电子」 |
| **USB-C 连接器** | USB-C 16P 贴片 矮款 | ¥2 | ¥2 | 淘宝「欣恒裕电子」 |
| **PCB** | 4 层 PCB 50x50mm 阻抗控制 SMT 贴片 | ¥23 | ¥23 | 嘉立创 PCB / 华秋 PCB |
| **屏幕连接器** | 0.5mm 24P FPC 连接器 抽拉式 | ¥1.5 | ¥1.5 | 淘宝「金丰电子」 |
| **外壳** | 3D 打印 PLA 外壳（需 3D 文件） | ¥10 | ¥10 | 拼多多「3D 打印工坊」/ 自己打 |
| **其他** | 螺丝、导线、测试线、散热片等 | ¥5 | ¥5 | 淘宝「五联电子」 |
| **合计** | | | **¥115** | |

---

### 1.2B 采购渠道详解

#### 电子元器件采购

| 类别 | 推荐店铺 | 说明 | 备注 |
|-----|---------|------|-----|
| **ESP32 模块** | 安信可科技（淘宝） | 官方代理商，品控稳定 | 认准「安信可」品牌 |
| | 嘉立创 EAME | 站式采购，含税发票 | 小批量首选 |
| **TFT 屏幕** | 优信电子（淘宝） | 多种尺寸可选，质保 1 年 | 记得问是否带字库 |
| | 晨航科技（淘宝） | 价格稍低，发货快 | 适合小批量测试 |
| **电池/电源** | 博邦电子（淘宝） | 带保护板，适合出口认证 | 需询问 UN38.3 认证 |
| | 亿雨电子（淘宝） | 充电管理板质量稳定 | |
| **阻容套件** | 容亮电子（淘宝） | 0805/0603 套件齐全 | 一次买够，后续不用再买 |
| **按键/连接器** | 合泰电子（淘宝） | 轻触开关型号齐全 | |
| | 欣恒裕电子（淘宝） | USB-C、FFC 连接器齐全 | |

#### PCB 和 SMT 加工

| 厂商 | 优势 | 交期 | 价格 |
|-----|------|-----|-----|
| **嘉立创** | 在线报价，全流程可视化，SMT 贴片服务 | 5-7 天 | 中等 |
| **华秋 PCB** | 便宜，库存充足 | 3-5 天 | 最低 |
| **捷配 PCB** | 快速交付，适合小批量 | 2-3 天 | 中等 |
| **猎板 PCB** | 阻抗控制好，适合高频 | 5-7 天 | 较高 |

**SMT 推荐**：嘉立创 SMT（贴片 + AI 检验），适合中小批量。

#### 3D 外壳

| 方式 | 渠道 | 说明 |
|-----|------|-----|
| **3D 打印** | 拼多多「3D 打印工坊」 | PLA/ABS，适合 10-50 件 |
| **CNC 加工** | 淘宝「精工CNC手板」 | 亚克力/铝合金，适合开模前验证 |
| **批量注塑** | 深圳注塑厂（1688） | 1000 件以上开模，¥2-5/件 |

#### 工具和调试

| 工具 | 推荐 | 价格 |
|-----|------|-----|
| **万用表** | 普源 DM3058 或 胜利 VC86E | ¥150-300 |
| **示波器** | 普源 DS1054Z（4 通道） | ¥1000 |
| **焊台** | 快克 936D 或 白光 951D | ¥200-400 |
| **逻辑分析仪** | Salae Logic 8 或 青一 LA1010 | ¥150-300 |
| **USB 调试板** | ESP32-DevKit-C（备用） | ¥30 |

---

### 1.3 批量采购参考（100 件）

| 组件 | 散件单价 | 100 件单价 | 采购渠道 |
|-----|----------|-----------|---------|
| ESP32-S3 模块 | ¥28 | ¥22 | 嘉立创（批量采购） |
| TFT 屏幕 | ¥16 | ¥12 | 优信电子（批发） |
| 电池 | ¥12 | ¥8 | 博邦电子（批量） |
| PCB+SMT | ¥23 | ¥15 | 嘉立创 SMT 批量价 |
| 外壳 | ¥10 | ¥5 | 拼多多（100 件起） |

**100 件批量总成本**：约 **¥75/台**（vs 散件 ¥115）

---

### 1.4 采购注意事项

| 注意事项 | 说明 |
|---------|-----|
| **屏幕批次** | 不同批次的屏幕可能有轻微色差，购买时尽量同一批次 |
| **电池认证** | 如需出口，需询问 UN38.3、MSDS、IEC62133 认证 |
| **原装 vs 替代** | ESP32 模块建议买原装安信可，替代模块可能有兼容问题 |
| **屏幕排线** | FPC 连接器务必确认间距（0.5mm 还是 0.3mm） |
| **关税** | 单独采购可能有关税，走集采或正规报关更省心 |

---

### 1.5 墨水屏版元器件采购

| 组件 | 型号 | 单价 | 采购渠道 |
|-----|------|-----|---------|
| **主控** | ESP32-S3-WROOM-1-N16R8 | ¥28 | 同 TFT 版 |
| **墨水屏** | GDEY0427T91 4.2" 7 色 480x280 | ¥42 | 淘宝「好氩科技」/ 淘宝「兴丰科技」 |
| **触控** | FT6336U 电容触控（可选） | ¥10 | 淘宝「华芯微尔」 |
| **电池** | LiPo 603050 2000mAh 带保护板 | ¥15 | 淘宝「博邦电子」 |
| **充电管理** | TP4056 USB-C 充电板 | ¥3 | 同 TFT 版 |
| **PCB+SMT** | 4 层 PCB 60x80mm + SMT | ¥30 | 嘉立创 |
| **FPC 线** | 24P 0.5mm 翻盖座 + 线 | ¥4 | 淘宝「金丰电子」 |
| **外壳** | 3D 打印 ABS 外壳 | ¥15 | 拼多多 |
| **其他** | 按键、晶振、电阻电容等 | ¥18 | 同 TFT 版 |
| **合计** | | **¥165** | |

**墨水屏采购注意**：
- 墨水屏单价高，建议先买 1-2 片样品测试，确认显示效果后再批量
- 墨水屏有使用寿命（一般 10 万次刷新），避免频繁全屏刷新
- 购买时确认屏幕接口是 SPI 还是 RGB，ESP32 通常用 SPI

---

### 1.3 软件框架

| 层级 | 技术选择 | 说明 |
|-----|---------|------|
| 固件框架 | **ESP-IDF 5.x** | 官方底层，性能最优 |
| 图形库 | **LVGL 8.3** | 嵌入式 GUI 标准，支持深色主题 |
| 字体 | **Noto Sans CJK SC** | 思源黑体，中文支持 |
| 数据存储 | **SPIFFS** | ESP-IDF 内置文件系统 |
| 编码 | **UTF-8** | 中文显示支持 |

**不采用方案**：
- ~~Arduino~~：生态不如 ESP-IDF 完整，内存控制粒度粗
- ~~MicroPython~~：运行慢，内存占用大，无法满足实时动画
- ~~u8g2~~：适合单色屏，不适合我们的全彩需求

---

## 二、系统架构

### 2.1 分层设计

```
┌─────────────────────────────────────────────┐
│                   UI 层                      │
│  LVGL Screen: GardenScreen / DesktopScreen  │
├─────────────────────────────────────────────┤
│                游戏逻辑层                    │
│  GameState | Plant | GeneSystem | Breeding  │
├─────────────────────────────────────────────┤
│                  数据层                      │
│  PlantDatabase | SaveManager | EventBus     │
├─────────────────────────────────────────────┤
│                  驱动层                      │
│  Display (ST7789) | Touch (FT3168) | Flash  │
└─────────────────────────────────────────────┘
```

### 2.2 内存管理策略

| 问题 | 解决方案 |
|-----|---------|
| LVGL 占用大 | 启用 PSRAM，LVGL 缓冲区指向 PSRAM |
| 花圃数据小 | 直接在 PSRAM 中维护，关闭时写入 SPIFFS |
| 植物图片 | 不存储图片，用代码绘制（圆形 + 颜色） |
| 字符串 | 所有中文用 FONT_CN 数组，动态加载 |

### 2.3 游戏状态机

```
┌─────────┐    点击格子     ┌─────────────┐
│  IDLE   │ ──────────────> │ SELECT_SEED │
└─────────┘                 └─────────────┘
     ^                            │
     │         点击植物            │
     │ +──────────────────────────┘
     │
     │ 浇水成功      开花       ┌─────────────┐
     └─────────────── > │ DISPLAY_PLANT │
                        └─────────────┘
                               │
                    点击"培育" │ 点击"移除"
                               v         v
                        ┌───────────┐ ┌────────┐
                        │ BREEDING  │ │REMOVE  │
                        └───────────┘ └────────┘
```

---

## 三、玩法修改

### 3.1 必要的改动

#### 显示屏限制
- 原版：640x480 窗口
- 移植版：240x240 像素（圆形或方形）

| 原版功能 | 修改方案 |
|---------|---------|
| 2x3 花圃 | 改为 2x3 格子，每格 70x70 像素 |
| 图鉴弹窗 | 改为全屏滚动列表 |
| 桌面展示 | 改为 2 个花位（原 3 个） |
| 种子选择菜单 | 改为下拉列表选择 |

#### 交互方式
- 原版：鼠标点击
- 移植版：触屏点击 + 侧边按钮

```
┌──────────────────────────┐
│                          │
│     240x240 显示屏        │
│                          │
│   [花圃 2x3 格子]        │
│                          │
│                          │
└──────────────────────────┘
[Btn A: 确定] [Btn B: 返回]
```

#### 动画简化
| 原版 | 移植版 |
|-----|-------|
| 生长渐变动画 | 直接切换图片 |
| 花瓣飘落特效 | 移除 |
| 稀有花闪光 | LED 闪烁代替 |
| idle 摇曳动画 | 极简 sin 动画（低帧率） |

#### 音频移除
- SFXPlayer 占位符 → 直接删除
- 音效会大幅增加固件体积和功耗

### 3.2 保留的核心玩法

| 玩法 | 描述 | 状态 |
|-----|------|-----|
| 种花 | 点击空格 → 选择种子 | 必须保留 |
| 浇水 | 点击植物 → 浇水推进生长 | 必须保留 |
| 培育 | 选择两朵开花植物 → 生成新芽苗 | 必须保留 |
| 颜色混合 | 基因系统完整移植 | 必须保留 |
| 稀有变异 | 3% 概率触发稀有花 | 必须保留 |
| 图鉴收集 | 记录已发现品种 | 必须保留 |
| 花圃扩展 | 每 5 种新花 +3 格 | 可选 |

### 3.3 游戏参数调整

| 参数 | 原版 | 调整后 | 原因 |
|-----|------|--------|-----|
| 种子→发芽 | 2 次浇水 | 2 次 | 保持 |
| 发芽→幼苗 | 2 次 | 2 次 | 保持 |
| 幼苗→成株 | 3 次 | 3 次 | 保持 |
| 成株→开花 | 3 次 | 3 次 | 保持 |
| 花圃初始大小 | 6 格 | 6 格 | 保持 |
| 花圃最大 | 20 格 | 12 格 | 屏幕限制 |
| 桌面展示位 | 3 个 | 2 个 | 屏幕限制 |
| 稀有变异概率 | 3% | 3% | 保持 |

---

## 四、组件映射

### 4.1 Godot → ESP32 映射表

| Godot (GDScript) | ESP32 (C++) | 说明 |
|------------------|-------------|-----|
| `GameState` | `GardenGame` class | 单例，管理全局状态 |
| `Plant` class | `Plant` class | 继承 RefCounted → 手动引用计数 |
| `PlantData` static DB | `PlantDatabase` class | 30 种植物数据 |
| `GeneSystem` static | `GeneSystem` class | 颜色混合 + 稀有检测 |
| `SaveManager` | `SaveManager` class | SPIFFS JSON 读写 |
| `EventBus` signal | `EventBus` class | 回调函数注册 |
| `GardenGrid` scene | `GardenScreen` LVGL screen | 主游戏界面 |
| `GardenPlot` scene | `PlotWidget` LVGL object | 单个格子 |
| `SeedMenu` popup | `SeedList` LVGL list | 种子选择 |
| `FlowerActionMenu` popup | `ActionDialog` LVGL dialog | 操作菜单 |
| `Encyclopedia` scene | `EncyclopediaScreen` | 图鉴界面 |
| `DesktopDisplay` scene | `DesktopScreen` | 桌面展示 |
| `IdleAnimator` | `IdleAnimation` class | sin/cos 动画 |

### 4.2 数据结构转换

**Plant 类 (GDScript → C++)**

```cpp
// GDScript
class_name Plant extends RefCounted
enum Stage {SEED, SPROUT, SEEDLING, MATURE, FLOWERING}
var stage: Stage = Stage.SEED
var water_count: int = 0
var color: Dictionary = {"r": 128, "g": 128, "b": 128}

// C++
struct Plant {
    enum Stage { SEED, SPROUT, SEEDLING, MATURE, FLOWERING };
    Stage stage = SEED;
    int water_count = 0;
    int stage_water_count = 0;
    uint8_t color_r = 128;
    uint8_t color_g = 128;
    uint8_t color_b = 128;
    String plant_type;
    String display_name;
    bool is_rare = false;
    bool is_breeding_sprout = false;
    uint8_t hidden_r = 128, hidden_g = 128, hidden_b = 128;
};
```

**颜色混合 (GDScript → C++)**

```cpp
// GDScript
var weight := randf()
child.r = clampi(int(lerpf(color_a.r, color_b.r, weight) + randf_range(-20, 20)), 0, 255)

// C++
float weight = (float)esp_random() / UINT32_MAX;
int r = clamp(lerp(color_a.r, color_b.r, weight) + random_range(-20, 20), 0, 255);
```

### 4.3 关键文件结构

```
flower-esp32/
├── main/
│   ├── main.cpp              # 入口，初始化 LVGL
│   ├── app.cpp               # 应用主循环
│   └── app.h
├── game/
│   ├── garden_game.cpp       # GameState 单例
│   ├── garden_game.h
│   ├── plant.cpp             # Plant 类
│   ├── plant.h
│   ├── plant_database.cpp    # 30 种植物数据
│   ├── plant_database.h
│   ├── gene_system.cpp       # 基因/颜色系统
│   ├── gene_system.h
│   └── save_manager.cpp      # 存档管理
├── ui/
│   ├── screens/
│   │   ├── garden_screen.cpp # 花圃主界面
│   │   ├── garden_screen.h
│   │   ├── desktop_screen.cpp # 桌面展示
│   │   ├── desktop_screen.h
│   │   └── encyclopedia_screen.cpp
│   └── widgets/
│       ├── plot_widget.cpp   # 单个格子
│       ├── plot_widget.h
│       ├── seed_list.cpp     # 种子选择
│       └── action_dialog.cpp # 操作菜单
├── event/
│   ├── event_bus.cpp         # 事件总线
│   └── event_bus.h
├── display/
│   ├── st7789.cpp            # 屏幕驱动
│   ├── st7789.h
│   └── touch_ft3168.cpp      # 触控驱动
├── assets/
│   ├── font_cn.c              # 中文字体数组
│   └── plant_icons.c          # 植物图形绘制数据
├── CMakeLists.txt
└── sdkconfig.defaults
```

---

## 五、实施阶段

### Phase 1: 基础设施（预计 2 周）

**目标**：点亮屏幕，显示静态 UI

**任务清单**：
- [ ] ESP-IDF 环境搭建
- [ ] ST7789 显示驱动调试
- [ ] LVGL 8.3 集成与显示测试
- [ ] 中文字体加载（Noto Sans CJK SC 12px）
- [ ] 触控驱动调试（单点触控识别）
- [ ] SPIFFS 初始化（存储空白存档）

**验收标准**：
- 屏幕显示 2x3 网格，每格有边框
- 触控能识别点击位置
- 关机重启后存档不丢失

**关键代码**：
```cpp
// main.cpp 伪代码
void app_main() {
    init_display();      // ST7789 240x240
    init_lvgl();         // LVGL 8.3
    init_touch();        // FT3168 I2C
    init_spiffs();       // 存档存储

    // 加载存档或创建新游戏
    GardenGame::getInstance().loadOrCreate();

    // 启动 UI
    lv_obj_t *screen = garden_screen_create();
    lv_disp_load_scr(screen);

    // 主循环
    while (true) {
        lv_task_handler();
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
```

---

### Phase 2: 核心玩法（预计 2 周）

**目标**：完成"种花 → 浇水 → 生长 → 开花"流程

**任务清单**：
- [ ] Plant 类实现（5 阶段 + 浇水系统）
- [ ] PlantDatabase 实现（30 种植物基础数据）
- [ ] GeneSystem 实现（颜色混合 + 稀有检测）
- [ ] GardenGame 单例（6 格花圃状态管理）
- [ ] GardenScreen UI（点击格子 → 种花 → 浇水）
- [ ] PlotWidget 状态显示（种子/发芽/幼苗/成株/开花图标）
- [ ] 生长动画简化实现（阶段切换提示）

**验收标准**：
- 点击空格弹出种子列表，选择后种植
- 点击植物浇水，阶段推进
- 10 次浇水后开花
- 开花时有视觉反馈（颜色变化）

**关键代码**：
```cpp
// 浇水逻辑
bool Plant::water() {
    if (stage == Stage::FLOWERING) return false;
    water_count++;
    stage_water_count++;

    int required = STAGE_WATER_REQUIREMENTS[stage];
    if (stage_water_count >= required) {
        advanceStage();
        return true;
    }
    return false;
}

// 花圃点击处理
void GardenScreen::onPlotClicked(int index) {
    Plant* plant = GardenGame::getInstance().getPlant(index);
    if (plant == nullptr) {
        showSeedList(index);  // 空格子 → 种花
    } else if (plant->stage == Stage::FLOWERING) {
        showActionDialog(index);  // 开花植物 → 操作菜单
    } else {
        GardenGame::getInstance().waterPlant(index);  // 浇水
        refreshPlot(index);
    }
}
```

---

### Phase 3: 培育系统（预计 2 周）

**目标**：完成两株花配对培育逻辑

**任务清单**：
- [ ] 培育模式选择 UI（点击开花植物 → 选择"培育"）
- [ ] 第二株选择高亮显示
- [ ] GeneSystem.breed() 移植（3 层概率：70% 混色 / 27% 杂交 / 3% 稀有）
- [ ] CROSS_BREED_TABLE 移植（6 组杂交配方）
- [ ] 培育芽苗生成（is_breeding_sprout + hidden_color）
- [ ] 培育揭晓动画（3 次浇水后显示真实颜色）
- [ ] 培育限制逻辑（花×多肉不可）

**验收标准**：
- 选择两朵开花玫瑰 → 生成粉玫瑰或白玫瑰（70%）
- 选择玫瑰+樱花 → 可能生成牡丹（27% 杂交）
- 任意培育有 3% 概率生成稀有花
- 培育芽苗浇水 3 次后揭晓颜色

**关键代码**：
```cpp
// GeneSystem.breed() 核心逻辑
BreedResult GeneSystem::breed(Plant* parentA, Plant* parentB) {
    int groupA = PlantDatabase::getGroup(parentA->plant_type);
    int groupB = PlantDatabase::getGroup(parentB->plant_type);

    // 1. 稀有变异（3%）
    if (esp_random() % 100 < 3) {
        Color mixed = mixColors(parentA, parentB);
        String rareType = checkRare(mixed, groupA);
        if (!rareType.isEmpty()) {
            return { rareType, mixed, true };
        }
    }

    // 2. 同组杂交（27%）
    bool sameGroup = (groupA == groupB);
    if (sameGroup && (esp_random() % 100 < 27)) {
        String crossResult = PlantDatabase::lookupCrossBreed(
            parentA->plant_type, parentB->plant_type);
        if (!crossResult.isEmpty()) {
            Color mixed = mixColors(parentA, parentB);
            return { crossResult, mixed, false };
        }
    }

    // 3. 混色（默认 70%）
    Color mixed = mixColors(parentA, parentB);
    return { parentA->plant_type, mixed, false };
}
```

---

### Phase 4: 图鉴与收集（预计 1 周）

**目标**：记录已发现品种，提供收集反馈

**任务清单**：
- [ ] Encyclopedia 数据结构（Dictionary → std::map）
- [ ] EncyclopediaScreen（全屏滚动列表，显示已收集/未收集）
- [ ] 新发现触发逻辑（FlowerDiscovered event）
- [ ] 花圃扩展逻辑（每 5 种新花 +3 格，上限 12）
- [ ] 新发现视觉反馈（短暂全屏提示）

**验收标准**：
- 图鉴显示所有 30 种植物
- 已收集显示彩色，未收集显示剪影
- 首次收集新花时显示动画
- 花圃自动扩展

---

### Phase 5: 桌面模式（预计 1 周）

**目标**：将喜欢的花展示在"桌面"

**任务清单**：
- [ ] DesktopScreen（2 个花位，底部显示）
- [ ] 发送至桌面功能（从花圃选择开花植物）
- [ ] Idle 动画简化（sin/cos 摇曳，1 FPS）
- [ ] 场景切换逻辑（花圃 ↔ 桌面）
- [ ] 从桌面快速返回花圃

**验收标准**：
- 花圃点击"桌面"按钮切换到 DesktopScreen
- 选择开花植物摆到桌面
- 桌面上的花有轻微摇曳动画
- 点击桌面返回花圃

---

### Phase 6: 完善与优化（预计 1 周）

**目标**：修复问题，优化功耗

**任务清单**：
- [ ] 深度睡眠：花圃无操作 5 分钟后进入 Deep Sleep
- [ ] 屏幕亮度：关闭背光进入休眠，触摸唤醒
- [ ] 存档完整性：异常断电不丢失存档
- [ ] 边界情况：花圃已满、种子库为空等
- [ ] 固件体积：优化到 < 4MB（SPI Flash 可存放下限）

---

## 六、阶段时间表

| 阶段 | 内容 | 周期 | 累计 |
|-----|------|-----|-----|
| Phase 0 | 环境搭建 + 显示测试 | 3 天 | Week 1 |
| Phase 1 | 基础设施（屏幕、触控、存储） | 4 天 | Week 1-2 |
| Phase 2 | 核心玩法（种花、浇水、生长） | 7 天 | Week 2-3 |
| Phase 3 | 培育系统 | 7 天 | Week 3-4 |
| Phase 4 | 图鉴与收集 | 4 天 | Week 4-5 |
| Phase 5 | 桌面模式 | 4 天 | Week 5-6 |
| Phase 6 | 完善优化 | 3 天 | Week 6-7 |

**总工期**：约 7 周

---

## 七、测试计划

| 测试场景 | 验证内容 | 工具 |
|---------|---------|-----|
| 种植流程 | 点击空格 → 选择 → 种子出现 | 手动测试 |
| 浇水流程 | 点击植物 → 阶段推进 → 10 次后开花 | 手动测试 |
| 培育流程 | 玫瑰+玫瑰 → 粉/白玫瑰（70%） | 100 次循环 |
| 杂交流程 | 玫瑰+樱花 → 牡丹（27% 或退混色） | 50 次循环 |
| 稀有触发 | 任意培育 × 100 次，验证 3% 触发 | 自动脚本 |
| 存档恢复 | 关机 → 重启 → 数据一致 | 手动测试 |
| 内存泄漏 | 运行 24 小时，无内存耗尽 | 压力测试 |
| 功耗测试 | 活跃 50mA / 深度睡眠 150μA | 万用表 |

---

## 八、风险与对策

| 风险 | 可能性 | 影响 | 对策 |
|-----|-------|-----|-----|
| PSRAM 初始化失败 | 中 | 高 | 使用原生 SRAM，但限制 LVGL 缓冲区大小 |
| 中文显示字库过大 | 低 | 中 | 使用 12px 字体，只包含常用汉字（约 2000 字） |
| 触控漂移 | 中 | 低 | 添加校准界面 |
| 培育概率偏差 | 低 | 中 | 移植后用脚本验证 1000 次统计分布 |
| 固件超过 4MB | 低 | 高 | 移除调试符号，使用 -Os 优化 |

---

## 九、附录

### A. 植物数据库（30 种）

| 类型 | 名称 | 培育组 | 初始颜色 |
|-----|------|--------|---------|
| rose_red | 红玫瑰 | ROSE | #E53935 |
| daisy_white | 白雏菊 | DAISY | #FFFFFF |
| tulip_yellow | 黄郁金香 | LILY | #FDD835 |
| rose_pink | 粉玫瑰 | ROSE | #F48FB1 |
| rose_white | 白玫瑰 | ROSE | #FAFAFA |
| tulip_orange | 橙郁金香 | LILY | #FF7043 |
| tulip_purple | 紫郁金香 | LILY | #7E57C2 |
| peony | 牡丹 | ROSE | #F8BBD9 |
| hyacinth | 风信子 | LILY | #6464DC |
| gesang | 格桑花 | DAISY | #DC78B4 |
| gypsophila | 满天星 | DAISY | #F5F5F5 |
| sakura | 樱花 | ROSE | #FFCDD2 |
| lily | 百合 | LILY | #FFEBEB |
| sunflower | 向日葵 | DAISY | #FFC107 |
| carnation | 康乃馨 | DAISY | #E91E63 |
| lavender | 薰衣草 | ORCHID | #9575CD |
| orchid | 蝴蝶兰 | ORCHID | #CE93D8 |
| succulent_echeveria | 观音莲 | SUCCULENT | #81C784 |
| succulent_haworthia | 玉露 | SUCCULENT | #66BB6A |
| succulent_bear | 熊童子 | SUCCULENT | #AED581 |
| succulent_dragon | 玉龙观音 | SUCCULENT | #4DB6AC |
| cactus | 仙人掌 | CACTUS | #8BC34A |
| rare_rainbow_rose | 彩虹玫瑰 | ROSE | #FFFFFF |
| rare_dark_mandrake | 暗夜曼陀罗 | ROSE | #1A1A1A |
| rare_golden_sunflower | 金色向日葵 | DAISY | #FFD700 |
| rare_moonlight_lily | 月光百合 | LILY | #C0C0C0 |
| rare_eternal_flower | 永恒之花 | ROSE | #FFFFFF |

### B. 杂交表

| 亲本 A | 亲本 B | 结果 |
|-------|-------|------|
| rose + sakura | | peony |
| tulip + lily | | hyacinth |
| daisy + sunflower | | gesang |
| daisy + carnation | | gypsophila |
| echeveria + haworthia | | dragon |
| echeveria + bear | | cactus |

### C. 稀有变异条件

| 稀有花 | 条件 |
|-------|------|
| rainbow_rose | 蔷薇系培育时，R>200 且 G>200 且 B>200 |
| golden_sunflower | 菊系培育时，R>200 且 G>180 且 B<50 |
| moonlight_lily | 百合系培育时，R<80 且 G>180 且 B>180 |
| dark_mandrake | 任意培育时，R<50 且 G<50 且 B<50 |
| eternal_flower | 以上都不匹配时的 fallback |

### 1.2 软件框架

| 层级 | 技术选择 | 说明 |
|-----|---------|------|
| 固件框架 | **ESP-IDF 5.x** | 官方底层，性能最优 |
| 图形库 | **LVGL 8.3** | 嵌入式 GUI 标准，支持深色主题 |
| 字体 | **Noto Sans CJK SC** | 思源黑体，中文支持 |
| 数据存储 | **SPIFFS** | ESP-IDF 内置文件系统 |
| 编码 | **UTF-8** | 中文显示支持 |

**不采用方案**：
- ~~Arduino~~：生态不如 ESP-IDF 完整，内存控制粒度粗
- ~~MicroPython~~：运行慢，内存占用大，无法满足实时动画
- ~~u8g2~~：适合单色屏，不适合我们的全彩需求

---

## 一、B 方案：墨水屏版本（Color E-Paper）

### 1.1B 硬件规格

| 组件 | 推荐型号 | 说明 |
|-----|---------|------|
| 主控 | **ESP32-S3-WROOM-1-N16R8** | 16MB Flash + 8MB PSRAM（同 TFT 版） |
| 显示 | **4.2" 彩色电子墨水屏** | 480x280 分辨率，4 色（黑白红黄）或 7 色 |
| 触摸 | **可选：电容触控** | 或使用物理按键导航 |
| 供电 | **LiPo 3.7V 2000mAh** | 超长续航，电池不一定要很小 |
| 调试 | **USB-C** | 用于程序下载和串口调试 |

**推荐型号**：
- **GDEY0427T91**（4.2" 7 色）：分辨率 480x280，显示效果最好
- **GDEH042Z96**（4.2" 4 色）：黑白红黄，价格较低

**成本预估**（批量 10 件）：
- ESP32-S3 模块：¥28
- 彩色墨水屏（4.2"）：¥42
- PCB + 电池：¥25
- 合计：¥98/台

### 1.2B 详细硬件成本（墨水屏版）

| 组件 | 型号 | 单价 | 数量 | 小计 | 采购渠道 |
|-----|------|-----|-----|-----|---------|
| **主控** | ESP32-S3-WROOM-1-N16R8（16MB Flash + 8MB PSRAM） | ¥28 | 1 | ¥28 | 淘宝/嘉立创 |
| **墨水屏** | GDEY0427T91 4.2" 7色 480x280 | ¥42 | 1 | ¥42 | 淘宝 |
| **触控芯片** | FT6336U 电容触控（可选） | ¥10 | 1 | ¥10 | 淘宝 |
| **电池** | LiPo 603050 2000mAh 1S | ¥15 | 1 | ¥15 | 淘宝 |
| **充电管理** | TP4056 USB-C 充电板 | ¥3 | 1 | ¥3 | 淘宝 |
| **晶振** | 40MHz 无源晶振 | ¥0.5 | 1 | ¥0.5 | 淘宝 |
| **电阻电容** | 0805 贴片阻容 | ¥3 | 1 | ¥3 | 淘宝 |
| **按键** | 6x6 轻触开关 4 个 | ¥1 | 4 | ¥1 | 淘宝 |
| **USB-C 连接器** | USB-C 16P 贴片 | ¥2 | 1 | ¥2 | 淘宝 |
| **FPC 连接线** | 24P 0.5mm 翻盖座 | ¥2 | 1 | ¥2 | 淘宝 |
| **PCB** | 4 层 PCB 60x80mm | ¥20 | 1 | ¥20 | 嘉立创/华秋 |
| **SMT 贴片** | 全贴片 | ¥10 | 1 | ¥10 | 嘉立创 |
| **外壳** | 3D 打印 ABS 外壳 | ¥15 | 1 | ¥15 | 拼多多/自己打 |
| **背板** | 亚克力切割背板 | ¥5 | 1 | ¥5 | 淘宝 |
| **其他** | 螺丝、导线、泡棉等 | ¥8 | 1 | ¥8 | 淘宝 |
| **合计** | | | | **¥165** | |

**批量折扣参考**（100 件）：
| 组件 | 10 件单价 | 100 件单价 | 节省 |
|-----|----------|-----------|-----|
| ESP32-S3 模块 | ¥28 | ¥22 | ¥6/件 |
| 墨水屏 | ¥42 | ¥35 | ¥7/件 |
| PCB + SMT | ¥30 | ¥20 | ¥10/件 |

**100 件批量总成本**：约 **¥110/台**（vs 散件 ¥165）

### 1.3B 显示特性对比

| 特性 | TFT 版 | 墨水屏版 |
|-----|--------|---------|
| 刷新速度 | 60 FPS | 1-4 秒/帧 |
| 显示颜色 | 65K 色 | 4 色或 7 色 |
| 功耗（活跃） | 50-80mA | 5-15mA（刷新时） |
| 功耗（休眠） | 3-5mA | **< 20μA** |
| 电池续航 | 1-2 天 | **2-4 周** |
| 日光可读性 | 一般 | **极佳** |
| 背光 | 需要 | **不需要** |
| 价格 | ¥18 | ¥45 |

**墨水屏的决定性优势**：续航长达数周，适合作为"桌面摆件"长期展示。

### 1.3B 图形库选择

| 方案 | 适用场景 | 说明 |
|-----|---------|------|
| **LVGL 8.3** | 需要触摸交互 | 完整 GUI 框架，但墨水屏刷新慢 |
| **GxEPD2** | 显示为主 | 仅刷新时耗电，适合静态展示 |

**推荐配置**：LVGL 渲染 + GxEPD2 输出
- LVGL 负责 UI 逻辑和图层合成
- 墨水屏仅在状态变化时刷新
- 空闲时完全断电，显示内容保持

---

## 二B、系统架构（墨水屏版）

### 2.1B 分层设计

```
┌─────────────────────────────────────────────┐
│                   UI 层                      │
│  LVGL Screen: GardenScreen / DesktopScreen  │
├─────────────────────────────────────────────┤
│                游戏逻辑层                    │
│  GameState | Plant | GeneSystem | Breeding  │
├─────────────────────────────────────────────┤
│                  数据层                      │
│  PlantDatabase | SaveManager | EventBus     │
├─────────────────────────────────────────────┤
│                  显示层                      │
│  LVGL Canvas → 墨水屏刷新（差异更新）        │
├─────────────────────────────────────────────┤
│                  驱动层                      │
│  E-Paper (GDEY0427T91) | 按键/触控 | Flash  │
└─────────────────────────────────────────────┘
```

### 2.2B 墨水屏刷新策略

| 场景 | 刷新方式 | 说明 |
|-----|---------|------|
| 植物浇水成功 | **局部刷新** | 只更新该格子区域，0.5-1 秒 |
| 阶段变化（开花） | **全屏刷新** | 重要状态变化，整体重绘 2-3 秒 |
| 界面切换 | **缓冲刷新** | LVGL 离屏渲染，一次性刷新 |
| 桌面展示（idle） | **不刷新** | 静态显示，完全不断电 |
| 深度睡眠唤醒 | **全屏刷新** | 从睡眠恢复时 2-3 秒 |

**关键优化**：墨水屏只在状态真正改变时刷新，避免频繁全屏刷新。

---

## 三B、玩法修改（墨水屏适配）

### 3.1B 核心挑战：刷新延迟

墨水屏最大问题是**刷新速度慢**（1-4 秒），这会影响：
- 浇水反馈：不能像 TFT 一样实时更新进度条
- 培育揭示：无法像 TFT 一样显示"颜色渐变暗示"

### 3.2B 解决方案：状态确认交互

**浇水交互设计**：
```
浇水前 → 显示"确定浇水？"
按确认 → 触发浇水 → 全屏更新 → 显示新状态
```
所有交互需要明确的"确认"步骤，避免误触后长时间等待。

**培育揭示设计**：
- 培育芽苗不再显示"颜色暗示"
- 改为浇水 3 次后直接揭晓结果（省去中间刷新）
- 揭晓时显示大字体："🌸 粉玫瑰！"

### 3.3B 显示模式适配

| 原版功能 | TFT 版 | 墨水屏版 |
|---------|--------|---------|
| 2x3 花圃 | 实时显示 | **静态显示 + 刷新指示** |
| 浇水动画 | 进度条渐变 | **"已浇水 X/2" 文字** |
| 培育颜色暗示 | 渐变显示 | **直接显示结果** |
| 图鉴弹窗 | 即时切换 | **确认后刷新** |
| 桌面 idle | 摇曳动画 | **静止显示** |

### 3.4B 墨水屏专属 UI 元素

```cpp
// 刷新状态指示器
enum RefreshState {
    IDLE,           // 静止，无刷新
    PARTIAL,        // 部分区域刷新中
    FULL,           // 全屏刷新中
};

// 显示刷新指示（避免用户不知道是否更新成功）
void showRefreshIndicator(RefreshState state) {
    if (state == FULL) {
        // 屏幕上显示旋转符号或"请稍候..."
        displayRefreshIcon();
    }
}
```

### 3.5B 桌面模式优化（墨水屏优势场景）

桌面模式非常适合墨水屏：
- **完全静止**：不需要动画，刷新一次即可
- **超低功耗**：2000mAh 电池可续航 2-4 周
- **日光可读**：适合作为桌面摆件

```
桌面模式流程：
1. 用户选择花朵摆到桌面 → 墨水屏刷新一次
2. 进入桌面模式 → 显示 2 朵花（静态）
3. 用户离开 → 墨水屏保持显示，完全不断电
4. 数周后电池没电 → 重新刷新显示（仍保持最后状态）
```

---

## 四B、组件映射（墨水屏版）

### 4.1B 驱动层替换

| TFT 版 | 墨水屏版 |
|--------|---------|
| ST7789.cpp | GxEPD2 (GDEY0427T91) |
| 60 FPS 刷新 | 1-4 秒刷新 |
| lvgl 直接绘制 | lvgl → framebuffer → 批量刷新 |

### 4.2B 显示缓冲区策略

```cpp
// 墨水屏需要完整的 framebuffer（480x280 = 134400 bytes）
// 使用 PSRAM 存储
static uint8_t* framebuffer = (uint8_t*)ps_malloc(480 * 280 / 2); // 4 色=2bit per pixel

// 脏区域追踪 - 只刷新变化的部分
struct DirtyRect {
    int x, y, w, h;
};
std::vector<DirtyRect> dirtyRegions;

void markDirty(int x, int y, int w, int h) {
    dirtyRegions.push_back({x, y, w, h});
}

void flushToEPaper() {
    if (dirtyRegions.empty()) return;

    if (dirtyRegions.size() == 1 && isSmall(dirtyRegions[0])) {
        // 局部刷新
        refreshRegion(dirtyRegions[0]);
    } else {
        // 变化区域太多，全屏刷新
        fullRefresh();
    }
    dirtyRegions.clear();
}
```

---

## 五B、实施阶段（墨水屏版）

### Phase 1B: 墨水屏驱动（预计 2 周）

**目标**：点亮墨水屏，实现基本显示

**任务清单**：
- [ ] ESP-IDF 环境搭建
- [ ] GxEPD2 库集成（GDEY0427T91 7 色墨水屏）
- [ ] LVGL 与墨水屏绑定（framebuffer 模式）
- [ ] 部分刷新 vs 全屏刷新逻辑
- [ ] 中文字体加载（12px）
- [ ] 物理按键或触控（根据硬件配置）

**验收标准**：
- 墨水屏显示静态图像（花圃格子）
- 刷新时间可接受（< 4 秒全屏）
- 局部刷新正常工作

**关键代码**：
```cpp
// 墨水屏初始化
void init_epaper() {
    // GxEPD2 初始化
    Init(GDEY0427T91);

    // 分配 framebuffer（在 PSRAM 中）
    framebuffer = (uint8_t*)psram_malloc(480 * 280 / 2);

    // LVGL 配置为全帧缓冲模式
    lv_display_set_buffer(lv_display_create(480, 280), framebuffer, sizeof(framebuffer));
}

// LVGL 脏区域检测
void onScreenChanged(lv_obj_t* obj) {
    // 计算脏区域
    lv_area_t area;
    if (lv_obj_get_coords(obj, &area)) {
        markDirty(area.x1, area.y1, area.x2 - area.x1, area.y2 - area.y1);
    }
}
```

---

### Phase 2B-5B（与 TFT 版相同）

墨水屏版的游戏逻辑部分（Phase 2-5）与 TFT 版相同：
- 核心玩法（种花、浇水、生长）
- 培育系统
- 图鉴与收集
- 桌面模式

差异在于**刷新策略**和**用户交互确认流程**。

---

### Phase 6B: 墨水屏功耗优化

**目标**：实现超长续航

**任务清单**：
- [ ] 深度睡眠：花圃无操作 30 秒后进入 Deep Sleep
- [ ] 墨水屏断电：显示完成后完全断电（不依赖维持显示）
- [ ] 触摸唤醒：任意触摸唤醒系统
- [ ] 电池续航测试：验证 2-4 周目标

**关键代码**：
```cpp
// 超低功耗休眠
void enterDeepSleep() {
    // 1. 让墨水屏断电（不再保持显示）
    epaper.powerOff();

    // 2. 配置唤醒源（触摸或定时）
    esp_sleep_enable_ext1_wakeup(PIN_TOUCH_WAKE, ESP_GPIO_WAKEUP_ANY_HIGH);
    esp_sleep_enable_timer_wakeup(60 * 1000000); // 60 秒后自动唤醒检查

    // 3. 进入深度睡眠
    esp_deep_sleep_start();
}

void wakeFromDeepSleep() {
    // 唤醒后重新初始化墨水屏（不丢失最后显示内容）
    epaper.init();
    epaper.refresh(); // 显示最后状态
}
```

---

## 六B、时间表对比

| 阶段 | TFT 版 | 墨水屏版 | 差异 |
|-----|--------|---------|-----|
| Phase 1 | 显示驱动 1 周 | 墨水屏驱动 2 周 | +1 周 |
| Phase 2-5 | 游戏逻辑 4 周 | 游戏逻辑 4 周 | 相同 |
| Phase 6 | 功耗优化 1 周 | 超低功耗 2 周 | +1 周 |
| **总工期** | **7 周** | **9 周** | **+2 周** |

---

## 七B、TFT vs 墨水屏 决策参考

| 场景 | 推荐方案 |
|-----|---------|
| 需要色彩细腻、动画流畅 | **TFT 版** |
| 需要超长续航（数周） | **墨水屏版** |
| 作为桌面长期展示 | **墨水屏版** |
| 儿童/新手学习嵌入式 | **TFT 版**（反馈即时） |
| 追求"更像真实植物"体验 | **墨水屏版**（显示稳定） |
| 需要培育颜色暗示 | **TFT 版**（实时变化） |
| 户外/明亮环境使用 | **墨水屏版**（日光可读） |
| 户外/明亮环境使用 | **墨水屏版**（日光可读） |
| 预算有限 | **TFT 版**（成本低 ¥20） |

---

## 八、成本汇总对比

### 8.1 两种方案硬件成本对比

| 成本类型 | TFT 版 | 墨水屏版 | 差异 |
|---------|--------|---------|-----|
| **散件成本（10 件）** | ¥115/台 | ¥165/台 | +¥50 |
| **批量成本（100 件）** | ¥75/台 | ¥110/台 | +¥35 |
| **开发工具（调试器等）** | ¥50（一次性） | ¥50（一次性） | 相同 |
| **PCB 首次打样（5 件）** | ¥200 | ¥250 | +¥50 |
| **外壳模具（如开模）** | ¥3000-5000 | ¥3000-5000 | 相同 |

### 8.2 开发时间成本

| 阶段 | TFT 版 | 墨水屏版 |
|-----|--------|---------|
| Phase 1（显示驱动） | 1 周 | 2 周 |
| Phase 2-5（游戏逻辑） | 4 周 | 4 周 |
| Phase 6（功耗优化） | 1 周 | 2 周 |
| **总开发周期** | **6-7 周** | **8-9 周** |
| **工程师工时** | ~300 小时 | ~400 小时 |

### 8.3 总拥有成本（TOTEXAMPLE）

假设生产 100 台：

| 成本项 | TFT 版 | 墨水屏版 |
|-------|--------|---------|
| 硬件物料（100 台） | ¥7,500 | ¥11,000 |
| PCB 打样 + SMT（首版） | ¥450 | ¥500 |
| 外壳（100 台） | ¥1,500 | ¥1,800 |
| 开发人力（7 周 vs 9 周） | ¥35,000 | ¥45,000 |
| 认证/测试（如需） | ¥5,000 | ¥5,000 |
| **总计** | **¥49,450** | **¥63,300** |
| **单台成本** | **¥494** | **¥633** |

*注：以上开发人力成本按 ¥500/工程师日估算，仅供参考。实际取决于团队配置。*

---

### 8.4 售价建议

| 方案 | 硬件成本 | 合理售价区间 | 利润率 |
|-----|---------|-------------|-------|
| TFT 版 | ¥75（批100） | ¥199-299 | 60-70% |
| 墨水屏版 | ¥110（批100） | ¥299-399 | 60-65% |

---

## 九、现有开发套件参考

### 9.1 直接可用方案（无需自己焊板）

| 产品 | 规格 | 价格 | 适合度 | 说明 |
|-----|------|-----|-------|-----|
| **ESP32-S3-BOX-3** | 2.4" 320x240 TFT 触控, ESP32-S3, 16MB Flash+16MB PSRAM | ¥180-250 | ★★★★☆ | Espressif 官方，带外壳/扬声器/麦克风 |
| **M5Stack Core2** | 2.0" 320x240 TFT, ESP32, 16MB Flash+4MB PSRAM | ¥199 | ★★★☆☆ | 成熟生态，Groove 接口丰富 |
| **M5Stack Paper** | 电子墨水 4.2", ESP32 | ¥199 | ★★★★☆ | 墨水屏版首选，超长续航 |
| **M5Stick C Plus** | 1.14" 135x240 TFT, ESP32, 带外壳电池 | ¥89 | ★★★☆☆ | 小巧紧凑，快速原型 |
| **TTGO T-Display** | 1.14" 135x240 TFT, ESP32 | ¥35 | ★★★☆☆ | 便宜，双列直插 DIY 友好 |
| **TTGO T-Display S3** | 1.9" 280x460 AMOLED, ESP32-S3 | ¥89 | ★★★★☆ | 高分辨率彩色屏 |
| **ELECROW 5.0" HMI** | 5.0" 800x480 RGB LCD 触控, ESP32 | ¥268 | ★★★★★ | 大屏高分辨率，适合游戏 |
| **ESP32-2432S028R** | 2.8" 320x240 TFT 触控, ESP32 | ¥85 | ★★★★☆ | 性价比高，社区支持多 |

---

### 9.2 散件组装（自己焊板）推荐

| 产品 | 规格 | 价格 | 说明 |
|-----|------|-----|------|
| **ESP32-S3-WROOM-1-N16R8** | ESP32-S3, 16MB Flash, 8MB PSRAM | ¥28 | 主流模块 |
| **Adafruit 1.28" Round TFT** | 240x240 圆形 IPS, GC9A01A, SPI | ¥125 | 圆形徽章设计首选 |
| **Adafruit 1.47" Round Rect TFT** | 172x320 圆角 IPS, ST7789 | ¥125 | 适合长方形徽章 |
| **Waveshare 4.2" e-Paper** | 400x300, 4 色（黑白红黄） | ¥98 | 墨水屏散件 |
| **GDEY0427T91 墨水屏** | 480x280, 7 色 | ¥42 | 彩色墨水屏（散件） |

---

### 9.3 现有套件对比

#### TFT 彩色屏方案

| 方案 | 成本 | 显示 | 触控 | 适合场景 |
|-----|-----|-----|-----|---------|
| **TTGO T-Display** | ¥35 | 135x240 小屏 | 无 | 简单显示，快速原型 |
| **ESP32-S3-BOX-3** | ¥200 | 320x240 中屏 | 电容 | 完整产品，开箱即用 |
| **ELECROW 5.0"** | ¥268 | 800x480 大屏 | 电容 | 视觉效果最佳 |
| **自己焊板（方案 A）** | ¥115 | 240x240 中屏 | 可选 | 成本最低，定制灵活 |

#### 墨水屏方案

| 方案 | 成本 | 显示 | 续航 | 适合场景 |
|-----|-----|-----|-----|---------|
| **M5Stack Paper** | ¥199 | 4.2" 4 色 | 数周 | 完整墨水屏产品 |
| **自己焊板（方案 B）** | ¥165 | 4.2" 7 色 | 数周 | 成本较低，定制灵活 |

---

### 9.4 社区资源参考

| 平台 | 资源 |
|-----|------|
| **M5Stack** | UiFlow 可视化编程, 庞大社区, 丰富教程 |
| **Espressif ESP-BOX** | 官方支持, ESP-IDF, Alexa 集成 |
| **TTGO (LilyGO)** | Arduino 社区活跃, 大量游戏示例 |
| **Adafruit** | 优质教程, Arduino/CircuitPython 双支持 |
| **ESP32-2432S028R** | 最多的游戏移植教程, 便宜又好用 |

---

*文档版本：1.4 - 新增现有开发套件参考*
*最后更新：2026-04-30*