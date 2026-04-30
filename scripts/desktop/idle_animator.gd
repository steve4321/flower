extends Node
## Idle动画：对目标Control应用摇曳/呼吸/弹跳效果
## 使用 sin/cos 数学实现，不用 AnimationPlayer，保证性能

## 按植物类型定义 idle 参数
## sway_speed: 摇摆频率, sway_amount: 摇摆幅度(弧度)
## breathe: 呼吸缩放幅度, bounce: 弹跳高度(px)
const IDLE_PRESETS: Dictionary = {
    # 向日葵：缓慢转头追光
    "sunflower": {"sway_speed": 0.3, "sway_amount": 0.04, "breathe": 0.0, "bounce": 0.0},
    # 樱花：轻柔飘动
    "sakura": {"sway_speed": 0.7, "sway_amount": 0.03, "breathe": 0.01, "bounce": 0.0},
    # 薰衣草：随风摆动
    "lavender": {"sway_speed": 1.0, "sway_amount": 0.05, "breathe": 0.0, "bounce": 0.0},
    # 玫瑰系：花瓣微微呼吸
    "rose": {"sway_speed": 0.5, "sway_amount": 0.015, "breathe": 0.02, "bounce": 0.0},
    # 百合系：优雅摇曳
    "lily": {"sway_speed": 0.4, "sway_amount": 0.02, "breathe": 0.015, "bounce": 0.0},
    # 菊系：轻柔摆动
    "daisy": {"sway_speed": 0.6, "sway_amount": 0.025, "breathe": 0.01, "bounce": 0.0},
    # 兰系：缓慢优雅
    "orchid": {"sway_speed": 0.35, "sway_amount": 0.02, "breathe": 0.01, "bounce": 0.0},
    # 多肉：几乎静止
    "succulent": {"sway_speed": 0.08, "sway_amount": 0.005, "breathe": 0.005, "bounce": 0.0},
    # 仙人掌：完全静止
    "cactus": {"sway_speed": 0.05, "sway_amount": 0.003, "breathe": 0.0, "bounce": 0.0},
    # 默认
    "_default": {"sway_speed": 0.5, "sway_amount": 0.02, "breathe": 0.01, "bounce": 0.0},
}

var _timer: float = 0.0
var _phase_offset: float = 0.0
var _preset: Dictionary = {}
var _target: Control = null
var _original_rotation: float = 0.0
var _original_scale: Vector2 = Vector2.ONE
var _original_position: Vector2 = Vector2.ZERO


var _initialized: bool = false


func setup(target: Control, plant_type: String) -> void:
    _target = target
    # 只在首次初始化时读取原始值，防止重复setup读取已被动画修改的值
    if not _initialized:
        _original_rotation = target.rotation
        _original_scale = target.scale
        _original_position = target.position
        _initialized = true
    else:
        # 后续setup先重置回原始状态
        target.rotation = _original_rotation
        target.scale = _original_scale
        target.position = _original_position

    # 查找预设：精确匹配 → 前缀匹配 → 默认
    _preset = IDLE_PRESETS.get(plant_type, {})
    if _preset.is_empty():
        var prefix: String = plant_type.split("_")[0]
        for key in IDLE_PRESETS:
            if key == "_default":
                continue
            if key.begins_with(prefix) or prefix.begins_with(key):
                _preset = IDLE_PRESETS[key]
                break
    if _preset.is_empty():
        _preset = IDLE_PRESETS["_default"]

    # 随机相位偏移，避免多朵花同步摇摆
    _phase_offset = randf() * TAU
    _timer = 0.0


func stop() -> void:
    if _target != null and is_instance_valid(_target):
        _target.rotation = _original_rotation
        _target.scale = _original_scale
        _target.position = _original_position
	set_process(false)


func _process(delta: float) -> void:
    if _target == null or not is_instance_valid(_target):
        set_process(false)
        return

    _timer += delta
    var t: float = _timer + _phase_offset

    # 摇曳（旋转）
    var sway_speed: float = _preset.get("sway_speed", 0.5)
    var sway_amount: float = _preset.get("sway_amount", 0.02)
    _target.rotation = _original_rotation + sin(t * sway_speed) * sway_amount

    # 呼吸（缩放脉冲）
    var breathe: float = _preset.get("breathe", 0.0)
    if breathe > 0.0:
        var s: float = 1.0 + sin(t * 1.5) * breathe
        _target.scale = _original_scale * s

    # 弹跳
    var bounce: float = _preset.get("bounce", 0.0)
    if bounce > 0.0:
        _target.position.y = _original_position.y - abs(sin(t * 2.0)) * bounce * 5.0
