# AGENTS.md - WoW Clone Godot Project

## Project Overview
This is a single-player World of Warcraft-inspired 2D top-down RPG built with Godot 4.x.

## Engine & Tools
- **Engine**: Godot 4.2+
- **Language**: GDScript
- **IDE**: VS Code with Godot Tools extension, or Godot editor

## Build & Run Commands

```bash
# Run the project (from project root)
godot --headless  # Editor mode
godot --headless --quit-after 60  # Run for 60 frames (for testing)

# Export (when ready for builds)
godot --headless --export-release "Linux/X11" builds/game.x86_64

# Run tests (if using GUT testing framework)
godot --headless -s addons/gut/gut_cmdline.gd -gdir=res://tests/
```

## Code Style Guidelines

### General
- **Indent**: 4 spaces (not tabs)
- **Line length**: 120 characters max
- **File naming**: snake_case.tscn, snake_case.gd

### GDScript Conventions
```gdscript
# Class name: PascalCase
class_name Player extends CharacterBody2D

# Constants: SCREAMING_SNAKE_CASE
const MAX_HEALTH := 100
const MOVE_SPEED := 200.0

# Variables: snake_case
var current_health := 100
var target_node: Node2D

# Private variables: _snake_case
var _inventory := []
var _cooldown_timer: Timer

# Signals: snake_case with past tense
signal health_changed(old_value: int, new_value: int)
signal player_died
signal item_equipped(slot: String, item: Item)

# Enums: PascalCase with UPPER_SNAKE_CASE values
enum ItemRarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}
enum CharacterClass {WARRIOR, MAGE, ROGUE, PRIEST, HUNTER}

# Functions: snake_case
func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, amount)

# Type hints: Always use when type is known
var damage: int = 50
var position: Vector2 = Vector2.ZERO
var enemies: Array[CharacterBody2D] = []
```

### Scene Structure
```
scenes/
├── characters/
│   ├── player/
│   │   ├── player.tscn          # Main player scene
│   │   ├── player_controller.gd # Input handling
│   │   ├── player_stats.gd     # Stats component
│   │   └── states/
│   │       ├── player_state.gd  # State machine base
│   │       ├── idle_state.gd
│   │       ├── move_state.gd
│   │       └── attack_state.gd
├── enemies/
│   ├── base_enemy.tscn
│   ├── skeleton.tscn
│   └── boss_drake.tscn
├── ui/
│   ├── hud/
│   │   ├── hud.tscn
│   │   ├── health_bar.gd
│   │   └── action_bar.gd
│   ├── menus/
│   │   ├── inventory_menu.tscn
│   │   ├── character_menu.tscn
│   │   └── quest_log.tscn
│   └── combat/
│       ├── target_frame.tscn
│       └── damage_number.tscn
└── world/
    ├── zones/
    │   └── starter_zone.tscn
    ├── tilesets/
    │   └── world_tileset.tres
    └── objects/
        ├── loot_bag.tscn
        └── quest_giver.tscn
```

### Autoload (Singletons)
```
Project > Project Settings > Autoload
```
Use for global systems:
- `GameState` - Player data, save/load
- `CombatManager` - Battle logic, threat, targeting
- `InventoryManager` - Item operations
- `EventBus` - Decoupled signals
- `AudioManager` - Sound effects and music

### Node Naming Conventions
- Root node: Match filename (Player, SkeletonBoss)
- Child nodes: descriptive_role (HealthBar, HitboxArea, StateMachine)
- Use `$` for accessing children: `$HealthBar`, `$StateMachine`
- Use `@onready` for caching:
```gdscript
@onready var health_bar: ProgressBar = $HealthBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer
```

### Signals & Events
Prefer signals for:
- State changes
- UI updates
- Item/equipment changes
- Combat events

Use EventBus pattern to decouple systems:
```gdscript
# EventBus.gd (autoload)
signal item_equipped(item: Item, slot: String)
signal xp_gained(amount: int, source: String)

# broadcaster.gd
EventBus.item_equipped.emit(loot_item, "main_hand")

# listener.gd
func _ready() -> void:
    EventBus.item_equipped.connect(_on_item_equipped)
```

### Error Handling
```gdscript
# Always check null for dynamically accessed nodes
if $HealthBar:
    $HealthBar.value = current_health

# Use assert in debug, graceful degradation in release
assert(is_instance_valid(target), "Target became invalid")

# Return error codes or null for functions that can fail
func get_item(id: String) -> Item:
    return _items.get(id)  # Returns null if missing

# Validate input parameters
func deal_damage(amount: int, target: Node) -> bool:
    if amount < 0:
        push_warning("Negative damage: %d" % amount)
        return false
    if not is_instance_valid(target):
        return false
    return true
```

### State Machine Pattern
```gdscript
# StateMachine.gd
class_name StateMachine extends Node

@export var initial_state: State
var current_state: State

func _ready() -> void:
    for child in get_children():
        if child is State:
            child.state_machine = self
    if initial_state:
        transition_to(initial_state.name)

func _process(delta: float) -> void:
    current_state.process_state(delta)

func _physics_process(delta: float) -> void:
    current_state.physics_process_state(delta)

func transition_to(state_name: String) -> void:
    current_state.exit_state()
    current_state = get_node(state_name)
    current_state.enter_state()
```

### Performance Tips
- Use `set_deferred` for physics-related property changes
- Pool frequently created/destroyed objects (damage numbers, projectiles)
- Use `Engine.get_physics_frame()` to throttle updates
- Prefer composition over inheritance for game objects

## File Organization
- One script per scene node when possible
- Group related classes in separate files (e.g., `item.gd`, `item_database.gd`)
- Keep scenes self-contained where possible
- All external assets go in `assets/` folder

## Git Ignore (Godot)
```
.godot/
*.import
*.ogg.import
*.wav.import
*.png.import
*.jpg.import
*.webp.import
export/
*.pck
*.exe
*.dmg
*.app
```

## Recommended Extensions (VS Code)
- Godot Tools (GDP Tools)
- GDScript formatter

## Testing
- Use GUT framework for unit testing
- Test combat math, stat calculations, item effects
- Manual playtest for feel and balance
