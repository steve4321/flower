# Flower Desktop 🌸

> 桌面花圃养花游戏 — 种花、培育、收藏，没事浇浇水

![Godot 4.2+](https://img.shields.io/badge/Godot-4.2+-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 简介

Flower Desktop 是一款零压力的桌面养花游戏。在俯视花圃里种花浇水，培育新品种，把最喜欢的花摆在桌面上当屏保。花不会死，不玩也不会有损失。

## 特性

- 🌱 **花圃种植** — 2D俯视花圃，浇水就能看着花慢慢长大
- 🎲 **培育惊喜** — 两朵花配对培育，结果永远有惊喜
- 🖥️ **桌面屏保** — 把喜欢的花摆到桌面上，花会自己轻轻摇曳
- 📖 **收集图鉴** — 每种新花都是一次"新发现"
- 💚 **零压力** — 没有死亡、没有惩罚、没有损失

## 玩法

```
花圃里种下种子
      ↓
  浇几次水 → 看着它慢慢长大 → 开花
      ↓
  选两朵开花植物 → 培育 → 新花长出来
      ↓
  挑最喜欢的花 → 摆到桌面上当屏保
      ↓
  收集图鉴 → 看看还有什么没见过的花
```

### 两个空间

- **花圃** — 主游戏界面，浇水、培育、管理所有花
- **桌面** — 纯展示，从花圃挑喜欢的花摆上去当装饰

### 核心操作

- **浇水** — 点一下花就是浇水，推动生长
- **培育** — 选两朵花配对，生成意想不到的新花

## 系统需求

- **操作系统**: Windows / Linux
- **引擎**: Godot 4.2+

## 安装

```bash
# 克隆仓库
git clone https://github.com/steve4321/flower.git
cd flower

# 使用 Godot Editor 打开
godot --editor
```

### 构建发布版本

```bash
# Linux
godot --headless --export-release "Linux/X11" builds/game

# Windows
godot --headless --export-release "Windows" builds/game.exe
```

## 文档

- [游戏设计文档](docs/SPEC.md)
- [开发者指南](docs/AGENTS.md)

## 开发计划

| 阶段 | 内容 | 状态 |
|-----|------|------|
| MVP | 花圃 + 浇水生长 + 3种初始花 | 📋 计划中 |
| v0.3 | 桌面展示 + idle动画 | 📋 计划中 |
| v0.5 | 培育系统 + 图鉴 | 📋 计划中 |
| v0.7 | 跨品种培育 + 稀有花 | 📋 计划中 |
| v1.0 | 完整音效 + 存档 + 润色 | 📋 计划中 |

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

---

🌸 祝您养花愉快！
