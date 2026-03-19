# Getting Started - WoW Clone with Godot

## 1. 安装 Godot

### 选项 A: 通过 SDK (推荐新手)
```bash
# 使用 SDKMAN (Linux/macOS)
curl -s "https://get.sdkman.io" | bash
sdk install godot 4.2.2

# 或直接从官网下载
# https://godotengine.org/download
```

### 选项 B: Steam
在 Steam 商店搜索 "Godot 4" 并安装

## 2. 创建新项目

1. 打开 Godot 编辑器
2. 点击 "New Project"
3. 设置路径为 `/root/work`
4. 选择 "Empty" 模板
5. 点击 "Create & Edit"

## 3. Godot 编辑器界面

```
┌─────────────────────────────────────────┐
│  FileSystem  │    3D/2D Viewport       │
│  (文件浏览器) │                          │
│              │                          │
│              │                          │
├──────────────┼──────────────────────────┤
│  Scene       │      Bottom Panel        │
│  (场景树)    │  (控制台、动画、文件系统) │
└──────────────┴──────────────────────────┘
```

### 主要面板
- **FileSystem**: 项目文件结构
- **Scene**: 当前场景的节点树
- **Viewport**: 场景预览和编辑
- **Inspector**: 选中节点的属性
- **Bottom Panel**: 输出、动画编辑器等

## 4. 第一个场景: 玩家角色

### 步骤 1: 创建场景
1. 点击 `FileSystem` 空白处右键
2. 选择 "New Script" 创建 `player.gd`
3. 创建新场景: `Scene > New Scene`
4. 添加节点: `CharacterBody2D` (右键 > 添加节点)
5. 重命名为 `Player`
6. 保存为 `scenes/characters/player/player.tscn`

### 步骤 2: 基础移动
```gdscript
# player.gd
extends CharacterBody2D

const MOVE_SPEED := 200.0

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direction * MOVE_SPEED
    move_and_slide()
```

### 步骤 3: 添加可视元素
1. 选中 Player 节点
2. 添加子节点: `Sprite2D` (用于显示角色)
3. 添加子节点: `CollisionShape2D` (用于碰撞检测)
4. 添加子节点: `AnimationPlayer` (用于动画)

## 5. 运行项目

- 按 `F5` 运行
- 按 `F6` 运行当前场景
- 按 `Shift+F5` 停止运行

## 6. 默认输入映射

Godot 预设的输入:
- `ui_left/right/up/down` - 方向键或 WASD
- `ui_accept` - 空格/回车
- `ui_cancel` - ESC

在 `Project > Project Settings > Input Map` 中修改

## 7. 学习资源

- [官方文档](https://docs.godotengine.org/)
- [Heartbeast 的 Godot 4 教程](https://www.youtube.com/@HeartbeastStudio)
- [GDQuest 免费教程](https://www.gdquest.com/)

## 8. 项目进度追踪

| 阶段 | 内容 | 预计时间 |
|-----|------|---------|
| 0 | 环境搭建、移动控制 | 1-2天 |
| 1 | 角色属性、技能系统 | 3-5天 |
| 2 | 战斗UI、目标系统 | 2-3天 |
| 3 | 第一个副本 | 5-7天 |
| 4 | 装备和掉落 | 3-5天 |
| 5 | 经济系统 | 2-3天 |

## 下一步

1. 完成 Godot 基础教程
2. 实现玩家移动
3. 创建简单的血条UI
4. 添加攻击动画
