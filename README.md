# Flower Desktop 🌸

> 桌面悬浮插件式基因培育养花游戏

![Godot 4.2+](https://img.shields.io/badge/Godot-4.2+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 简介

Flower Desktop 是一款休闲养花游戏，以桌面悬浮窗的形式显示。你可以种植花卉和多肉植物，通过基因杂交培育稀有变种。

## 特性

- 🪴 **花盆形态悬浮窗** - 模拟真实花盆，桌面底部显示
- 🌱 **基因遗传系统** - 培育杂交，基因自由组合
- 🌈 **稀有花挑战** - 5%概率培育彩虹玫瑰、暗黑曼陀罗等稀有变种
- 🎮 **轻量挂机** - 每日简单照料，休闲养花
- 📖 **收集图鉴** - 解锁全部30种植物

## 游戏截图

```
┌─────────────────────────────────────────────────────────────┐
│  [🌷]    [🪴]    [🌸]    [空]    [🌻]                      │
│  [健康]  [健康]  [健康]  [空]    [健康]                     │
├─────────────────────────────────────────────────────────────┤
│  [💧浇水] [🌿施肥] [☀️晒太阳] [✂️修剪] │ [📖] [⚙️]          │
└─────────────────────────────────────────────────────────────┘
```

## 系统需求

- **操作系统**: Windows / Linux
- **引擎**: Godot 4.2+
- **分辨率**: 任意（推荐1920x1080）

## 安装

### 从源码运行

```bash
# 克隆仓库
git clone https://github.com/steve4321/flower-desktop.git
cd flower-desktop

# 使用 Godot Editor 打开
godot --editor

# 或headless运行
godot --headless --quit-after 60
```

### 构建发布版本

```bash
# Linux
godot --headless --export-release "Linux/X11" builds/game

# Windows
godot --headless --export-release "Windows" builds/game.exe
```

## 游戏玩法

### 基础操作
1. 点击空花盆 → 购买种子 → 种植
2. 定期浇水、施肥、晒太阳
3. 植物开花后 → 收获种子或进行培育

### 培育系统
1. 选择两株开花植物
2. 进行基因杂交
3. 获得新种子（5%概率稀有变异）

### 目标
- 收集全部30种植物图鉴
- 挑战培育5种稀有花卉

## 文档

- [游戏设计文档](docs/SPEC.md)
- [开发者指南](docs/AGENTS.md)
- [新手入门](docs/guides/getting-started.md)
- [基因系统设计](docs/references/gene-system.md)

## 项目结构

```
flower-desktop/
├── assets/              # 资源文件
│   ├── sprites/         # 精灵图
│   ├── audio/           # 音效音乐
│   └── fonts/           # 字体
├── scenes/              # 场景文件
│   ├── ui/             # UI组件
│   └── plants/         # 植物相关
├── scripts/            # GDScript脚本
│   ├── autoload/       # 全局脚本
│   ├── core/          # 核心系统
│   └── ui/            # UI逻辑
├── docs/              # 文档
│   ├── guides/        # 指南
│   └── references/    # 参考资料
└── project.godot      # Godot项目文件
```

## 开发计划

| 阶段 | 内容 | 状态 |
|-----|------|------|
| MVP | 基础种植和照料系统 | 🔨 开发中 |
| v0.5 | 基因遗传和培育系统 | 📋 计划中 |
| v1.0 | 图鉴和商店系统 | 📋 计划中 |
| v1.5 | 稀有花卉完整版 | 📋 计划中 |

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

---

🌸 祝您养花愉快！
