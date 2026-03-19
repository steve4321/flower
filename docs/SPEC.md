# World of Warcraft Clone (2D Top-Down)

## Project Overview
- **Type**: Single-player RPG (WoW-inspired)
- **Engine**: Godot 4.x
- **Renderer**: 2D with optional shader effects
- **Platform**: PC (Windows/macOS/Linux)

## Core Features

### Must Have (MVP)
- [ ] Character creation (race/class selection)
- [ ] Isometric 2D movement (WASD + mouse)
- [ ] Basic combat system (auto-attack + abilities)
- [ ] Health/Mana/Energy resource bars
- [ ] Target selection and UI
- [ ] Experience and leveling system
- [ ] Basic inventory system
- [ ] One starter zone with quests

### Phase 1 - RPG Mechanics
- [ ] Character stats (Strength, Agility, Intellect, etc.)
- [ ] Class abilities (3-5 abilities per class)
- [ ] Talent/specialization system
- [ ] Equipment slots (Head, Chest, Weapon, etc.)

### Phase 2 - Combat Content
- [ ] Single-player dungeons (3-5 bosses)
- [ ] Boss AI with phase transitions
- [ ] Loot drops and itemization
- [ ] Boss mechanics (tank busters, AoE, buffs)

### Phase 3 - Economy & Social
- [ ] Gold currency and vendors
- [ ] Auction house (single-player version)
- [ ] Guild system (friends list)
- [ ] Mail system

## Technical Stack
- **Engine**: Godot 4.2+
- **Language**: GDScript
- **Assets**: Placeholder sprites (kenney.nl or similar)
- **Version Control**: Git

## Project Structure
```
wow-clone/
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── fonts/
│   └── audio/
├── scenes/
│   ├── characters/
│   ├── ui/
│   ├── world/
│   └── combat/
├── scripts/
│   ├── autoload/
│   ├── classes/
│   └── systems/
├── docs/
│   ├── design/
│   ├── api/
│   └── guides/
└── project.godot
```

## Development Phases

### Phase 0: Setup & Prototype (1-2 weeks)
1. Godot editor熟悉
2. 角色移动和控制
3. 简单的Sprite渲染
4. 基础碰撞检测

### Phase 1: Core RPG (2-4 weeks)
1. 角色属性系统
2. 战斗系统
3. 技能系统
4. UI框架

### Phase 2: Content (4-8 weeks)
1. 地图和任务系统
2. 副本设计
3. 敌人AI
4. 掉落系统

### Phase 3: Polish (2-4 weeks)
1. 经济系统
2. 社交功能
3. 音效和特效
4. 平衡调整

## References
- [Godot Documentation](https://docs.godotengine.org/)
- [Godot 4 Tutorial Series](https://www.youtube.com/c/GdCh)
- WoW Classic references for game design
