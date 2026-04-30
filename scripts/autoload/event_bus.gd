extends Node
## 信号总线，解耦各系统

# 花圃操作
signal plant_watered(plot_index: int)
signal plant_planted(plot_index: int, plant_type: String)
signal plant_removed(plot_index: int)
signal stage_advanced(plot_index: int, new_stage: int)

# 培育
signal breeding_started(plot_index: int, parent_a: int, parent_b: int)
signal breeding_revealed(plot_index: int, plant_type: String)
signal breeding_done(plant_type: String, is_rare: bool, is_new: bool)

# 花仓库
signal flower_stored(plot_index: int)
signal flower_retrieved(plot_index: int)

# 发现
signal flower_discovered(plant_type: String)
signal rare_flower_found(plant_type: String)

# 花圃
signal garden_changed()
signal garden_expanded(new_size: int)

# 桌面
signal desktop_changed()

# 存档
signal game_saved()
signal game_loaded()
