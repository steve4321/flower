# AGENTS.md - Flower Desktop Project

## Project Overview
Desktop flower cultivation game with gene breeding system. Built with Godot 4.x as a floating desktop widget.

## Engine & Tools
- **Engine**: Godot 4.2+
- **Language**: GDScript
- **IDE**: VS Code with Godot Tools extension, or Godot editor

## Build & Run Commands

```bash
# Run the project (from project root)
godot --headless            # Editor mode
godot --headless --quit-after 60   # Run for 60 frames (testing)

# Export for Linux
godot --headless --export-release "Linux/X11" builds/game.x86_64

# Export for Windows
godot --headless --export-release "Windows" builds/game.exe

# Window mode (embedded)
godot --embedded
```

## Code Style Guidelines

### General
- **Indent**: 4 spaces (not tabs)
- **Line length**: 120 characters max
- **File naming**: snake_case.tscn, snake_case.gd

### GDScript Conventions
```gdscript
# Class name: PascalCase
class_name Plant extends Node2D

# Constants: SCREAMING_SNAKE_CASE
const MAX_WATER := 100
const GROWTH_DURATION := 3600.0

# Variables: snake_case
var current_water := 50
var genes: Dictionary

# Private variables: _snake_case
var _growth_timer: float
var _is_flowering := false

# Signals: snake_case with past tense
signal water_changed(old_value: int, new_value: int)
signal stage_changed(stage: String)
signal rare_flower_born(flower_type: String)

# Enums: PascalCase with UPPER_SNAKE_CASE values
enum GrowthStage {SEED, SPROUT, SEEDLING, MATURE, FLOWERING}
enum FlowerShape {POINTED, ROUND, SERRATED, FANCY}
enum Rarity {COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

# Functions: snake_case
func water_plant(amount: int) -> void:
    current_water = mini(current_water + amount, MAX_WATER)
    water_changed.emit(current_water, amount)

func get_gene(color: String) -> int:
    return genes.get(color, 128)
```

### Scene Structure
```
scenes/
├── main.tscn                      # Main entry point
├── ui/
│   ├── main_panel.tscn            # Main floating panel
│   ├── pot_slot.tscn               # Individual pot slot
│   ├── action_bar.tscn             # Care action buttons
│   ├── pot_detail.tscn             # Plant detail popup
│   ├── breeding.tscn               # Breeding chamber
│   ├── encyclopedia.tscn           # Collection book
│   └── shop.tscn                   # Shop interface
├── plants/
│   ├── base_plant.tscn             # Base plant scene
│   ├── stages/                     # Growth stage visuals
│   │   ├── seed.tscn
│   │   ├── sprout.tscn
│   │   ├── seedling.tscn
│   │   ├── mature.tscn
│   │   └── flowering.tscn
│   └── effects/
│       └── particle_effects.tscn
└── common/
    ├── color_rect.tscn             # Styled backgrounds
    └── animated_sprite2d.tscn       # Reusable animations
```

### Autoload (Singletons)
```
Project > Project Settings > Autoload
```
Use for global systems:
- `GameState` - All game data, save/load
- `GeneSystem` - Gene inheritance calculations
- `SaveManager` - Persistence logic
- `AudioManager` - Sound effects and music

### Node Naming Conventions
- Root node: Match filename (MainPanel, PotDetail)
- Child nodes: descriptive_role (WaterBar, GrowthProgress, ActionButtons)
- Use `$` for accessing children: `$WaterBar`, `$ActionButtons`
- Use `@onready` for caching:
```gdscript
@onready var water_bar: ProgressBar = $WaterBar
@onready var stage_label: Label = $StageLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
```

### Signals & Events
Prefer signals for:
- State changes (growth stage, care status)
- UI updates (water/fertilizer changed)
- Breeding events (new plant born, rare flower)
- Game events (save/load, achievement)

Use EventBus pattern to decouple systems:
```gdscript
# EventBus.gd (autoload)
signal plant_watered(pot_id: int, amount: int)
signal plant_bred(pot_id: int, parent_a: String, parent_b: String)
signal rare_flower_unlocked(flower_type: String)

# broadcaster.gd
EventBus.plant_watered.emit(pot_id, 30)

# listener.gd
func _ready() -> void:
    EventBus.plant_watered.connect(_on_plant_watered)
```

### Error Handling
```gdscript
# Check null for dynamically accessed nodes
if $WaterBar:
    $WaterBar.value = current_water

# Use assert in debug, graceful degradation in release
assert(is_instance_valid(plant), "Plant became invalid")

# Return error codes or null for functions that can fail
func get_plant(pot_id: int) -> Plant:
    return _plants.get(pot_id)  # Returns null if missing

# Validate input parameters
func water_plant(amount: int) -> bool:
    if amount < 0:
        push_warning("Negative water amount: %d" % amount)
        return false
    if amount > MAX_WATER:
        push_warning("Water overflow: %d > %d" % [amount, MAX_WATER])
        amount = MAX_WATER
    return true
```

### Gene System Implementation
```gdscript
# gene_system.gd
class_name GeneSystem extends Node

static func combine_genes(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
    var child: Dictionary = {}
    for color in ["r", "g", "b"]:
        child[color] = pick_gene(parent_a[color], parent_b[color])
    child.shape = pick_shape_gene(parent_a.shape, parent_b.shape)
    if randf() < 0.05:  # 5% mutation
        child = mutate_genes(child)
    return child

static func pick_gene(a: int, b: int) -> int:
    return a if randf() < 0.5 else b

static func mutate_genes(genes: Dictionary) -> Dictionary:
    genes.r = clampi(genes.r + randi_range(-20, 20), 0, 255)
    genes.g = clampi(genes.g + randi_range(-20, 20), 0, 255)
    genes.b = clampi(genes.b + randi_range(-20, 20), 0, 255)
    return genes

static func check_rare_flower(genes: Dictionary) -> String:
    # Rainbow Rose: high R, G, B all > 200
    if genes.r > 200 and genes.g > 200 and genes.b > 200:
        return "rainbow_rose"
    # Dark Mandrake: all < 50
    if genes.r < 50 and genes.g < 50 and genes.b < 50:
        return "dark_mandrake"
    # Golden Sunflower: high R, medium G, low B
    if genes.r > 200 and genes.g > 180 and genes.b < 50:
        return "golden_sunflower"
    return ""
```

### Growth System Pattern
```gdscript
# growth_system.gd
class_name GrowthSystem extends Node

var current_stage: GrowthStage = GrowthStage.SEED
var growth_progress: float = 0.0
var stage_durations: Dictionary = {
    GrowthStage.SEED: 3600.0,      # 1 hour
    GrowthStage.SPROUT: 7200.0,    # 2 hours
    GrowthStage.SEEDLING: 14400.0,  # 4 hours
    GrowthStage.MATURE: 28800.0,   # 8 hours
    GrowthStage.FLOWERING: 0.0     # Permanent
}

func _process(delta: float) -> void:
    growth_progress += delta
    check_stage_transition()

func check_stage_transition() -> void:
    var threshold: float = stage_durations[current_stage]
    if threshold > 0 and growth_progress >= threshold:
        growth_progress = 0.0
        advance_stage()

func advance_stage() -> void:
    var next_stage = _get_next_stage(current_stage)
    if next_stage != current_stage:
        current_stage = next_stage
        stage_changed.emit(current_stage)
```

### File Organization
- One script per scene node when possible
- Group related classes in separate files (plant.gd, gene_system.gd)
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
- Test gene inheritance, growth timing, rare flower probability
- Manual playtest for feel and balance

## Window Configuration
```gdscript
# window_setup.gd
func setup_window() -> void:
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EMBEDDED)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_EDITOR_ONLY, true)
    var screen_size = DisplayServer.screen_size_get(0)
    var window_width = int(screen_size.x * 0.4)
    var window_height = 180
    var window_pos = Vector2i(0, screen_size.y - window_height)
    DisplayServer.window_set_size(Vector2i(window_width, window_height), 0)
    DisplayServer.window_set_position(window_pos, 0)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
```

## Color Palette Reference
| Name | Hex | Usage |
|------|-----|-------|
| Primary Green | #4CAF50 | Main theme |
| Soil Brown | #8D6E63 | Pot/earth |
| Petal Pink | #F48FB1 | Accents |
| Background | #FFFFFF80 | Semi-transparent |
| Text Dark | #424242 | Primary text |
| Rare Gold | #FFD700 | Rare flowers |
| Rare Dark | #4A148C | Dark variants |

## Performance Tips
- Use object pooling for particle effects
- Cache gene calculations, don't recalculate every frame
- Use `Engine.get_physics_frame()` to throttle updates
- Prefer composition over inheritance for plant types
