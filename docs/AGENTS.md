# AGENTS.md - Flower Desktop Project

## Project Overview
Desktop flower cultivation game with breeding and collection. Built with Godot 4.x.
Two spaces: desktop display (screensaver) + garden window (gameplay).
Core loop: water plants to grow → breed for surprises → collect in encyclopedia → display favorites on desktop.

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
```

## Code Style Guidelines

### General
- **Indent**: 4 spaces (not tabs)
- **Line length**: 120 characters max
- **File naming**: snake_case.tscn, snake_case.gd

### GDScript Conventions
```gdscript
# Class name: PascalCase
class_name Plant extends RefCounted

# Constants: SCREAMING_SNAKE_CASE
const WATER_PER_CLICK := 1

# Variables: snake_case
var plant_type: String = ""
var stage: Stage = Stage.SEED
var water_count: int = 0
var color: Dictionary = {"r": 128, "g": 128, "b": 128}

# Private variables: _snake_case
var _is_rare := false
var _rare_type: String = ""

# Signals: snake_case
signal stage_changed(new_stage: int)
signal flower_discovered(plant_type: String)
signal breed_completed(child_genes: Dictionary)

# Enums: PascalCase with UPPER_SNAKE_CASE values
enum Stage {SEED, SPROUT, SEEDLING, MATURE, FLOWERING}
enum FlowerShape {POINTED, ROUND, SERRATED, FANCY, ROSETTE, COLUMNAR}

# Functions: snake_case
func water() -> void:
    water_count += 1
    _check_stage_advance()

func get_display_color() -> Color:
    return Color(color.r / 255.0, color.g / 255.0, color.b / 255.0)
```

### Project Structure
```
flower-desktop/
├── assets/
│   ├── sprites/
│   │   ├── plants/           # Plant sprites (per-type directories)
│   │   │   ├── rose_red/
│   │   │   │   ├── seed.png
│   │   │   │   ├── sprout.png
│   │   │   │   ├── seedling.png
│   │   │   │   ├── mature.png
│   │   │   │   └── flowering.png
│   │   │   └── ...
│   │   ├── garden/           # Garden decorations (soil, fence, stones)
│   │   ├── ui/               # UI elements
│   │   └── effects/          # Particle effects
│   ├── audio/
│   │   ├── bgm/
│   │   └── sfx/
│   └── fonts/
├── scenes/
│   ├── desktop.tscn          # Desktop display scene
│   ├── garden.tscn           # Garden main scene
│   ├── ui/
│   │   ├── garden_plot.tscn  # Single planting grid cell
│   │   ├── encyclopedia.tscn # Encyclopedia panel
│   │   └── plant_detail.tscn # Plant detail popup
│   └── effects/
│       ├── water_drop.tscn   # Watering effect
│       ├── bloom_reveal.tscn # Bloom reveal effect
│       └── rare_sparkle.tscn # Rare flower effect
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd     # Global state (garden, desktop, seeds)
│   │   ├── gene_system.gd    # Color mixing, breeding logic
│   │   └── save_manager.gd   # Save/load persistence
│   ├── core/
│   │   ├── plant.gd          # Plant data class
│   │   └── plant_data.gd     # Plant database (all varieties)
│   ├── garden/
│   │   ├── garden_grid.gd    # Garden grid management
│   │   ├── garden_plot.gd    # Single plot cell
│   │   └── breeding.gd       # Breeding logic
│   ├── desktop/
│   │   ├── desktop_display.gd # Desktop display manager
│   │   └── idle_animator.gd  # Idle animation controller
│   └── ui/
│       ├── encyclopedia.gd   # Encyclopedia UI
│       └── plant_detail.gd   # Plant detail popup
├── project.godot
└── README.md
```

### Autoload (Singletons)
```
Project > Project Settings > Autoload
```
- `GameState` - Garden data, desktop slots, seed inventory, encyclopedia
- `GeneSystem` - Color mixing, breeding calculations, rare detection
- `SaveManager` - JSON persistence, auto-save

### Node Naming Conventions
- Root node: Match filename (GardenGrid, PlantDetail)
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
- State changes (growth stage, breeding complete)
- UI updates (garden changed, encyclopedia updated)
- Discovery events (new flower discovered, rare flower found)

Use EventBus pattern to decouple systems:
```gdscript
# EventBus.gd (autoload)
signal plant_watered(plot_id: int)
signal plant_bred(plot_id: int, parent_a_id: String, parent_b_id: String)
signal stage_advanced(plot_id: int, new_stage: int)
signal flower_discovered(plant_type: String)
signal rare_flower_found(plant_type: String)
signal garden_changed()

# broadcaster.gd
EventBus.plant_watered.emit(plot_id)

# listener.gd
func _ready() -> void:
    EventBus.plant_watered.connect(_on_plant_watered)
```

### Error Handling
```gdscript
# Check null for dynamically accessed nodes
if $WaterBar:
    $WaterBar.value = water_count

# Return null for functions that can fail
func get_plant_at(plot_id: int) -> Plant:
    return _plants.get(plot_id)  # Returns null if missing

# Validate input parameters
func breed(parent_a_id: int, parent_b_id: int) -> Plant:
    if parent_a_id == parent_b_id:
        push_warning("Cannot breed a plant with itself")
        return null
    var parent_a: Plant = get_plant_at(parent_a_id)
    var parent_b: Plant = get_plant_at(parent_b_id)
    if parent_a == null or parent_b == null:
        return null
    if parent_a.stage != Stage.FLOWERING or parent_b.stage != Stage.FLOWERING:
        return null
    return _create_child(parent_a, parent_b)
```

### Plant Data Model
```gdscript
# scripts/core/plant.gd
class_name Plant extends RefCounted

enum Stage {SEED, SPROUT, SEEDLING, MATURE, FLOWERING}

const STAGE_WATER_REQUIREMENTS: Dictionary = {
    Stage.SEED: 2,
    Stage.SPROUT: 3,
    Stage.SEEDLING: 3,
    Stage.MATURE: 4,
    Stage.FLOWERING: 0  # No more watering needed
}

var id: String = ""
var plant_type: String = ""
var display_name: String = ""
var stage: Stage = Stage.SEED
var water_count: int = 0
var stage_water_count: int = 0  # Water count within current stage
var color: Dictionary = {"r": 128, "g": 128, "b": 128}
var shape: int = 0
var size: int = 1
var is_rare: bool = false
var rare_type: String = ""

func water() -> bool:
    if stage == Stage.FLOWERING:
        return false
    water_count += 1
    stage_water_count += 1
    var requirement: int = STAGE_WATER_REQUIREMENTS[stage]
    if stage_water_count >= requirement:
        _advance_stage()
    return true

func _advance_stage() -> void:
    if stage < Stage.FLOWERING:
        stage += 1
        stage_water_count = 0
        stage_changed.emit(stage)

func get_display_color() -> Color:
    return Color(color.r / 255.0, color.g / 255.0, color.b / 255.0)

func to_dictionary() -> Dictionary:
    return {
        "id": id,
        "plant_type": plant_type,
        "stage": stage,
        "water_count": water_count,
        "stage_water_count": stage_water_count,
        "color": color,
        "shape": shape,
        "size": size,
        "is_rare": is_rare,
        "rare_type": rare_type
    }
```

### Gene System (Color Mixing & Breeding)
```gdscript
# scripts/autoload/gene_system.gd
class_name GeneSystem extends Node

# Color mixing with random offset for surprise
static func mix_colors(color_a: Dictionary, color_b: Dictionary) -> Dictionary:
    var child: Dictionary = {}
    # Weighted random between parents + noise
    var weight := randf()
    child.r = clampi(lerpf(color_a.r, color_b.r, weight) + randf_range(-20, 20), 0, 255)
    child.g = clampi(lerpf(color_a.g, color_b.g, weight) + randf_range(-20, 20), 0, 255)
    child.b = clampi(lerpf(color_a.b, color_b.b, weight) + randf_range(-20, 20), 0, 255)
    return child

# Check for rare flower (hidden condition, small probability)
static func check_rare(genes: Dictionary) -> String:
    if randf() > 0.03:  # 3% base chance to even check
        return ""
    # Rare flower determination based on color ranges
    if genes.r > 200 and genes.g > 200 and genes.b > 200:
        return "rainbow_rose"
    if genes.r < 50 and genes.g < 50 and genes.b < 50:
        return "dark_mandrake"
    if genes.r > 200 and genes.g > 180 and genes.b < 50:
        return "golden_sunflower"
    if genes.r < 80 and genes.g > 180 and genes.b > 180:
        return "moonlight_lily"
    if genes.r > 230 and genes.g > 230 and genes.b > 230:
        return "eternal_flower"
    return ""
```

### Garden Grid System
```gdscript
# scripts/garden/garden_grid.gd
class_name GardenGrid extends Node2D

var plots: Array = []        # Array of Plant or null
var grid_size: int = 6       # Starting size, expandable

func _ready() -> void:
    plots.resize(grid_size)
    plots.fill(null)

func plant_seed(plot_index: int, plant_type: String) -> bool:
    if plot_index < 0 or plot_index >= plots.size():
        return false
    if plots[plot_index] != null:
        return false
    var new_plant := Plant.new()
    new_plant.plant_type = plant_type
    new_plant.id = _generate_id()
    # Set initial color from plant data
    var data: Dictionary = PlantData.get_data(plant_type)
    new_plant.color = data.get("base_genes", {}).duplicate(true)
    new_plant.display_name = data.get("name", "???")
    plots[plot_index] = new_plant
    EventBus.garden_changed.emit()
    return true

func expand_grid() -> void:
    grid_size += 3
    plots.resize(grid_size)
    # Fill new slots with null
    for i in range(plots.size()):
        if plots[i] == null:
            plots[i] = null

func _generate_id() -> String:
    return "plant_%d_%d" % [Time.get_ticks_msec(), randi()]
```

### Idle Animation System
```gdscript
# scripts/desktop/idle_animator.gd
class_name IdleAnimator extends Node2D

# Each plant type has unique idle parameters
const IDLE_PRESETS: Dictionary = {
    "sunflower": {"sway_speed": 0.5, "sway_amount": 3.0, "bounce": 0.0, "petal_drop": false},
    "sakura": {"sway_speed": 0.8, "sway_amount": 2.0, "bounce": 0.0, "petal_drop": true},
    "lavender": {"sway_speed": 1.2, "sway_amount": 4.0, "bounce": 0.0, "petal_drop": false},
    "succulent": {"sway_speed": 0.1, "sway_amount": 0.5, "bounce": 0.3, "petal_drop": false},
    "rose": {"sway_speed": 0.6, "sway_amount": 1.5, "bounce": 0.5, "petal_drop": false},
}

var _timer: float = 0.0
var _preset: Dictionary = {}

func setup(plant_type: String) -> void:
    _preset = IDLE_PRESETS.get(plant_type, IDLE_PRESETS["rose"])

func _process(delta: float) -> void:
    _timer += delta
    var sway := sin(_timer * _preset.sway_speed) * _preset.sway_amount
    var bounce := abs(sin(_timer * 2.0)) * _preset.bounce
    position.x = sway
    position.y = -bounce
```

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
- Test: color mixing, breeding results, growth stages, rare detection
- Manual playtest for feel and idle animation quality

## Desktop Window Configuration
```gdscript
# Desktop display window: bottom of screen, semi-transparent, always-on-top
func setup_desktop_window() -> void:
    var screen_size := DisplayServer.screen_size_get(0)
    var window_width := int(screen_size.x * 0.4)
    var window_height := 120
    var window_pos := Vector2i(
        (screen_size.x - window_width) / 2,
        screen_size.y - window_height
    )
    DisplayServer.window_set_size(Vector2i(window_width, window_height), 0)
    DisplayServer.window_set_position(window_pos, 0)
    DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
```

## Color Palette Reference
| Name | Hex | Usage |
|------|-----|-------|
| Primary Green | #4CAF50 | Main theme, healthy plants |
| Soil Brown | #8D6E63 | Garden soil, pots |
| Garden Background | #E8F5E9 | Garden scene background |
| Petal Pink | #F48FB1 | UI accents |
| Desktop Background | #FFFFFF80 | Semi-transparent desktop |
| Text Dark | #424242 | Primary text |
| Rare Gold | #FFD700 | Rare flower highlights |
| Rare Dark | #4A148C | Dark variant accents |

## Performance Tips
- Use object pooling for particle effects (water drops, petals)
- Idle animations: use simple sin/cos math, not AnimationPlayer for every plant
- Throttle garden updates: only process visible plots
- Desktop display: keep draw calls minimal, it's a screensaver
